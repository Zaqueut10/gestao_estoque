import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firestore_paths.dart';

class EstoqueCriticoPage extends StatelessWidget {
  const EstoqueCriticoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final produtosRef = FirestorePaths.produtos(firestore);

    return Scaffold(
      appBar: AppBar(title: const Text('Estoque Crítico')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: produtosRef.orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar produtos: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final criticos = docs.where((d) {
            final data = d.data();
            final estoque = (data['estoque'] is num) ? (data['estoque'] as num).toInt() : 0;
            final minimo = (data['estoqueMinimo'] is num) ? (data['estoqueMinimo'] as num).toInt() : 0;
            return minimo > 0 && estoque <= minimo;
          }).toList();

          if (criticos.isEmpty) {
            return const Center(child: Text('Nenhum produto em estoque crítico.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: criticos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final data = criticos[index].data();

              final nome = (data['nome'] ?? 'Sem nome').toString();
              final estoque = (data['estoque'] is num) ? (data['estoque'] as num).toInt() : 0;
              final minimo = (data['estoqueMinimo'] is num) ? (data['estoqueMinimo'] as num).toInt() : 0;

              final zerado = estoque <= 0;

              return Card(
                color: (zerado ? Colors.red : Colors.orange).withValues(alpha: 0.10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (zerado ? Colors.red : Colors.orange).withValues(alpha: 0.18),
                    child: Icon(
                      zerado ? Icons.warning_amber : Icons.report_problem,
                      color: zerado ? Colors.red : Colors.orange,
                    ),
                  ),
                  title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Estoque: $estoque • Mínimo: $minimo'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
