import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firestore_paths.dart';

class MovimentosPage extends StatelessWidget {
  const MovimentosPage({super.key});

  String _formatarData(DateTime? dt) {
    if (dt == null) return 'Data não informada';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final movimentosRef = FirestorePaths.movimentos(firestore);

    return Scaffold(
      appBar: AppBar(title: const Text('Movimentações')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: movimentosRef.orderBy('data', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar movimentações: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Nenhuma movimentação registrada.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final data = docs[index].data();

              final tipo = (data['tipo'] ?? '').toString();
              final produtoNome = (data['produtoNome'] ?? 'Sem nome').toString();
              final int qtdRaw = _toInt(data['quantidade']);

              final ts = data['data'] as Timestamp?;
              final dt = ts?.toDate();

              late final String label;
              late final Color cor;
              late final IconData icon;
              late final String qtdTexto;

              if (tipo == 'entrada') {
                label = 'Entrada';
                cor = Colors.green;
                icon = Icons.arrow_downward;
                qtdTexto = '+${qtdRaw.abs()}';
              } else if (tipo == 'saida' || tipo == 'venda') {
                // ✅ VENDA tratada como saída
                label = (tipo == 'venda') ? 'Venda' : 'Saída';
                cor = Colors.red;
                icon = Icons.arrow_upward;
                qtdTexto = '-${qtdRaw.abs()}';
              } else if (tipo == 'ajuste') {
                label = 'Ajuste';
                cor = Colors.amber[800]!;
                icon = Icons.tune;
                qtdTexto = '${qtdRaw >= 0 ? '+' : ''}$qtdRaw';
              } else {
                label = 'Movimento';
                cor = Colors.blueGrey;
                icon = Icons.swap_horiz;
                qtdTexto = '$qtdRaw';
              }

              final motivo = (data['motivo'] ?? '').toString().trim();

              // Extras da venda (se existirem no movimento)
              final cliente = (data['cliente'] ?? '').toString().trim();
              final total = _toDouble(data['total']);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cor.withValues(alpha: 0.12),
                    child: Icon(icon, color: cor),
                  ),
                  title: Text(
                    produtoNome,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatarData(dt)),
                      if (tipo == 'ajuste' && motivo.isNotEmpty) Text('Motivo: $motivo'),
                      if (tipo == 'venda' && cliente.isNotEmpty) Text('Cliente: $cliente'),
                      if (tipo == 'venda' && total > 0) Text('Total: R\$ ${total.toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(label, style: TextStyle(color: cor, fontWeight: FontWeight.w700)),
                      Text(qtdTexto),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}