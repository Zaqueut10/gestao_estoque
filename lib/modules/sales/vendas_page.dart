import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/firestore_paths.dart';
import 'registro_venda_page.dart';

class VendasPage extends StatelessWidget {
  const VendasPage({super.key});

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return 0.0;
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final vendasQuery = FirestorePaths.vendas(db).orderBy('data', descending: true).limit(50);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendas'),
        actions: [
          IconButton(
            tooltip: 'Nova venda',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistroVendaPage()),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: vendasQuery.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro ao carregar vendas: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Nenhuma venda registrada ainda.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final cliente = (data['cliente'] ?? '').toString().trim();
              final produtoNome = (data['produtoNome'] ?? '').toString();
              final quantidade = _toInt(data['quantidade']);
              final total = _toDouble(data['total']);

              final ts = data['data'] as Timestamp?;
              final dt = ts?.toDate();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.withValues(alpha: 0.12),
                    child: const Icon(Icons.point_of_sale, color: Colors.indigo),
                  ),
                  title: Text('$produtoNome • $quantidade un.'),
                  subtitle: Text('${_fmt(dt)}${cliente.isEmpty ? '' : '\nCliente: $cliente'}'),
                  trailing: Text(
                    'R\$ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroVendaPage()));
        },
        icon: const Icon(Icons.point_of_sale),
        label: const Text('Nova venda'),
      ),
    );
  }
}