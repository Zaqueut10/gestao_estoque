import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/firestore_paths.dart';

enum PeriodoVendas { hoje, ultimos7, ultimos30 }

class RelatorioVendasPage extends StatefulWidget {
  const RelatorioVendasPage({super.key});

  @override
  State<RelatorioVendasPage> createState() => _RelatorioVendasPageState();
}

class _RelatorioVendasPageState extends State<RelatorioVendasPage> {
  final db = FirebaseFirestore.instance;
  PeriodoVendas _periodo = PeriodoVendas.hoje;

  DateTime _inicio(PeriodoVendas p, DateTime now) {
    final hoje = DateTime(now.year, now.month, now.day);
    return switch (p) {
      PeriodoVendas.hoje => hoje,
      PeriodoVendas.ultimos7 => hoje.subtract(const Duration(days: 6)),
      PeriodoVendas.ultimos30 => hoje.subtract(const Duration(days: 29)),
    };
  }

  DateTime _fimExclusivo(DateTime now) {
    final hoje = DateTime(now.year, now.month, now.day);
    return hoje.add(const Duration(days: 1));
  }

  String _fmtDia(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final inicio = _inicio(_periodo, now);
    final fimExc = _fimExclusivo(now);

    final query = FirestorePaths.vendas(db)
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fimExc))
        .orderBy('data', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatório de Vendas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<PeriodoVendas>(
              initialValue: _periodo,
              items: const [
                DropdownMenuItem(value: PeriodoVendas.hoje, child: Text('Hoje')),
                DropdownMenuItem(value: PeriodoVendas.ultimos7, child: Text('Últimos 7 dias')),
                DropdownMenuItem(value: PeriodoVendas.ultimos30, child: Text('Últimos 30 dias')),
              ],
              onChanged: (v) => setState(() => _periodo = v ?? PeriodoVendas.hoje),
              decoration: const InputDecoration(
                labelText: 'Período',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: query.get(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Erro ao gerar relatório: ${snap.error}'));
                  }

                  final docs = snap.data?.docs ?? [];

                  // Total do período
                  final totalPeriodo = docs.fold<double>(
                    0.0,
                    (acc, d) => acc + _toDouble(d.data()['total']),
                  );

                  // Vendas por dia (ordenado)
                  final vendasPorDiaTotal = SplayTreeMap<DateTime, double>((a, b) => a.compareTo(b));
                  final vendasPorDiaQtd = SplayTreeMap<DateTime, int>((a, b) => a.compareTo(b));

                  // Produtos mais vendidos
                  final qtdPorProduto = <String, int>{};
                  final totalPorProduto = <String, double>{};

                  for (final d in docs) {
                    final data = d.data();
                    final ts = data['data'] as Timestamp?;
                    final dt = ts?.toDate();
                    if (dt == null) continue;

                    final dia = DateTime(dt.year, dt.month, dt.day);
                    final total = _toDouble(data['total']);
                    final qtd = _toInt(data['quantidade']);
                    final produtoNome = (data['produtoNome'] ?? 'Sem nome').toString();

                    vendasPorDiaTotal[dia] = (vendasPorDiaTotal[dia] ?? 0.0) + total;
                    vendasPorDiaQtd[dia] = (vendasPorDiaQtd[dia] ?? 0) + 1;

                    qtdPorProduto[produtoNome] = (qtdPorProduto[produtoNome] ?? 0) + qtd;
                    totalPorProduto[produtoNome] = (totalPorProduto[produtoNome] ?? 0.0) + total;
                  }

                  final topPorQtd = qtdPorProduto.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  final topPorTotal = totalPorProduto.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return ListView(
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.assessment),
                          title: const Text('Total vendido no período'),
                          subtitle: Text('${docs.length} venda(s)'),
                          trailing: Text(
                            'R\$ ${totalPeriodo.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text('Vendas por dia', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      if (vendasPorDiaTotal.isEmpty)
                        const Text('Nenhuma venda no período.')
                      else
                        ...vendasPorDiaTotal.entries.map((e) {
                          final qtdVendasNoDia = vendasPorDiaQtd[e.key] ?? 0;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: Text(_fmtDia(e.key)),
                              subtitle: Text('$qtdVendasNoDia venda(s)'),
                              trailing: Text(
                                'R\$ ${e.value.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 12),
                      const Text('Produtos mais vendidos (quantidade)', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      if (topPorQtd.isEmpty)
                        const Text('Sem dados no período.')
                      else
                        ...topPorQtd.take(10).map((e) {
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.local_fire_department),
                              title: Text(e.key),
                              trailing: Text('${e.value} un.', style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          );
                        }),

                      const SizedBox(height: 12),
                      const Text('Produtos com maior faturamento', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      if (topPorTotal.isEmpty)
                        const Text('Sem dados no período.')
                      else
                        ...topPorTotal.take(10).map((e) {
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.monetization_on),
                              title: Text(e.key),
                              trailing: Text(
                                'R\$ ${e.value.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}