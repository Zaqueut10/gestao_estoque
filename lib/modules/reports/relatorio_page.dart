import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firestore_paths.dart';

enum PeriodoRelatorio { hoje, ultimos7, ultimos30 }

class RelatorioPage extends StatefulWidget {
  const RelatorioPage({super.key});

  @override
  State<RelatorioPage> createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PeriodoRelatorio _periodo = PeriodoRelatorio.hoje;

  DateTime _inicioPeriodo(PeriodoRelatorio p, DateTime now) {
    final hoje = DateTime(now.year, now.month, now.day);
    return switch (p) {
      PeriodoRelatorio.hoje => hoje,
      PeriodoRelatorio.ultimos7 => hoje.subtract(const Duration(days: 6)),
      PeriodoRelatorio.ultimos30 => hoje.subtract(const Duration(days: 29)),
    };
  }

  DateTime _fimPeriodoExclusivo(DateTime now) {
    final hoje = DateTime(now.year, now.month, now.day);
    return hoje.add(const Duration(days: 1));
  }

  String _tituloPeriodo(PeriodoRelatorio p) {
    return switch (p) {
      PeriodoRelatorio.hoje => 'Hoje',
      PeriodoRelatorio.ultimos7 => 'Últimos 7 dias',
      PeriodoRelatorio.ultimos30 => 'Últimos 30 dias',
    };
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
    final inicio = _inicioPeriodo(_periodo, now);
    final fimExclusivo = _fimPeriodoExclusivo(now);

    final movimentosRef = FirestorePaths.movimentos(_firestore);

    final query = movimentosRef
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fimExclusivo))
        .orderBy('data', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<PeriodoRelatorio>(
              initialValue: _periodo,
              items: const [
                DropdownMenuItem(value: PeriodoRelatorio.hoje, child: Text('Hoje')),
                DropdownMenuItem(value: PeriodoRelatorio.ultimos7, child: Text('Últimos 7 dias')),
                DropdownMenuItem(value: PeriodoRelatorio.ultimos30, child: Text('Últimos 30 dias')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _periodo = v);
              },
              decoration: const InputDecoration(
                labelText: 'Período',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar relatório: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                int entradas = 0;
                int saidas = 0;
                int ajustePos = 0;
                int ajusteNegAbs = 0;
                int totalMov = 0;

                final Map<String, int> saidasPorProduto = {};

                for (final d in docs) {
                  final data = d.data();
                  final tipo = (data['tipo'] ?? '').toString();
                  final produtoNome = (data['produtoNome'] ?? 'Sem nome').toString();
                  final qtd = _toInt(data['quantidade']);
                  totalMov++;

                  if (tipo == 'entrada') {
                    entradas += qtd.abs();
                  } else if (tipo == 'saida') {
                    final v = qtd.abs();
                    saidas += v;
                    saidasPorProduto[produtoNome] = (saidasPorProduto[produtoNome] ?? 0) + v;
                  } else if (tipo == 'ajuste') {
                    if (qtd >= 0) {
                      ajustePos += qtd;
                    } else {
                      ajusteNegAbs += qtd.abs();
                    }
                  }
                }

                final saldoLiquido = entradas + ajustePos - saidas - ajusteNegAbs;

                final ranking = saidasPorProduto.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Resumo • ${_tituloPeriodo(_periodo)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    _ResumoCard(
                      totalMovimentos: totalMov,
                      entradas: entradas,
                      saidas: saidas,
                      ajustePos: ajustePos,
                      ajusteNegAbs: ajusteNegAbs,
                      saldoLiquido: saldoLiquido,
                    ),
                    const SizedBox(height: 16),
                    const Text('Top saídas por produto', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (ranking.isEmpty)
                      const Text('Nenhuma saída no período.')
                    else
                      ...ranking.take(10).map((e) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.trending_down, color: Colors.red),
                            title: Text(e.key),
                            trailing: Text(
                              '-${e.value}',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.red),
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
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final int totalMovimentos;
  final int entradas;
  final int saidas;
  final int ajustePos;
  final int ajusteNegAbs;
  final int saldoLiquido;

  const _ResumoCard({
    required this.totalMovimentos,
    required this.entradas,
    required this.saidas,
    required this.ajustePos,
    required this.ajusteNegAbs,
    required this.saldoLiquido,
  });

  @override
  Widget build(BuildContext context) {
    final Color saldoCor = saldoLiquido > 0
        ? Colors.green
        : saldoLiquido < 0
            ? Colors.red
            : Colors.blueGrey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Movimentações: $totalMovimentos'),
            const SizedBox(height: 8),
            _linha('Entradas', '+$entradas', Colors.green),
            _linha('Saídas', '-$saidas', Colors.red),
            _linha('Ajustes (+)', '+$ajustePos', Colors.green),
            _linha('Ajustes (-)', '-$ajusteNegAbs', Colors.red),
            const Divider(),
            _linha(
              'Saldo líquido',
              (saldoLiquido >= 0 ? '+$saldoLiquido' : '$saldoLiquido'),
              saldoCor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(String titulo, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(valor, style: TextStyle(fontWeight: FontWeight.w800, color: cor)),
        ],
      ),
    );
  }
}
