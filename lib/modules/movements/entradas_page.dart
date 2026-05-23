import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/firestore_paths.dart';

class EntradasPage extends StatefulWidget {
  const EntradasPage({super.key});

  @override
  State<EntradasPage> createState() => _EntradasPageState();
}

class _EntradasPageState extends State<EntradasPage> {
  final _quantidadeController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  String? _produtoIdSelecionado;
  bool _salvando = false;

  @override
  void dispose() {
    _quantidadeController.dispose();
    super.dispose();
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _salvarEntrada({
    required String produtoId,
    required String produtoNome,
  }) async {
    final quantidade = int.tryParse(_quantidadeController.text.trim());

    if (quantidade == null || quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade válida (> 0).')),
      );
      return;
    }

    setState(() => _salvando = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final produtoRef = FirestorePaths.produtoDoc(_firestore, produtoId);
      final movimentoRef = FirestorePaths.movimentos(_firestore).doc();

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(produtoRef);
        final data = snap.data();
        if (data == null) throw Exception('Produto não encontrado');

        final estoqueAtual = _toInt(data['estoque']);
        final novoEstoque = estoqueAtual + quantidade;

        tx.update(produtoRef, {
          'estoque': novoEstoque,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });

        tx.set(movimentoRef, {
          'produtoId': produtoId,
          'produtoNome': produtoNome,
          'tipo': 'entrada',
          'quantidade': quantidade,
          'data': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Entrada registrada: +$quantidade em "$produtoNome"')),
      );

      _quantidadeController.clear();
      setState(() => _produtoIdSelecionado = null);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao salvar entrada: $e')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final produtosQuery = FirestorePaths.produtos(_firestore).orderBy('nome');

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Entrada de Estoque')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: produtosQuery.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro ao carregar produtos: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Cadastre um produto primeiro.'));
          }

          final selecionado = _produtoIdSelecionado == null
              ? null
              : docs.where((d) => d.id == _produtoIdSelecionado).cast<QueryDocumentSnapshot<Map<String, dynamic>>?>().firstOrNull;

          final produtoSelecionadoData = selecionado?.data();
          final produtoNome = (produtoSelecionadoData?['nome'] ?? '').toString();
          final estoqueAtual = _toInt(produtoSelecionadoData?['estoque']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _produtoIdSelecionado,
                  items: docs.map((doc) {
                    final nome = (doc.data()['nome'] ?? 'Sem nome').toString();
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(nome),
                    );
                  }).toList(),
                  onChanged: _salvando ? null : (v) => setState(() => _produtoIdSelecionado = v),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Produto',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                if (_produtoIdSelecionado != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2),
                      title: Text(produtoNome, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('Estoque atual: $estoqueAtual'),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _quantidadeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_salvando || _produtoIdSelecionado == null)
                        ? null
                        : () => _salvarEntrada(
                              produtoId: _produtoIdSelecionado!,
                              produtoNome: produtoNome,
                            ),
                    child: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar Entrada'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Pequena extensão útil (evita package extra)
extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
