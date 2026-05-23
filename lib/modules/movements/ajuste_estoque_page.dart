import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/firestore_paths.dart';

class AjusteEstoquePage extends StatefulWidget {
  const AjusteEstoquePage({super.key});

  @override
  State<AjusteEstoquePage> createState() => _AjusteEstoquePageState();
}

class _AjusteEstoquePageState extends State<AjusteEstoquePage> {
  final _firestore = FirebaseFirestore.instance;

  final _quantidadeController = TextEditingController();
  final _motivoController = TextEditingController();

  String? _produtoIdSelecionado;
  bool _salvando = false;
  bool _aumentar = true;

  @override
  void dispose() {
    _quantidadeController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _salvarAjuste({
    required String produtoId,
    required String produtoNome,
  }) async {
    final qtd = int.tryParse(_quantidadeController.text.trim());
    if (qtd == null || qtd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade válida (> 0).')),
      );
      return;
    }

    final motivo = _motivoController.text.trim();
    if (motivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um motivo para o ajuste.')),
      );
      return;
    }

    final delta = _aumentar ? qtd : -qtd;

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
        final novoEstoque = estoqueAtual + delta;

        if (novoEstoque < 0) {
          throw StateError('Ajuste inválido: estoque ficaria negativo (atual: $estoqueAtual).');
        }

        tx.update(produtoRef, {
          'estoque': novoEstoque,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });

        tx.set(movimentoRef, {
          'produtoId': produtoId,
          'produtoNome': produtoNome,
          'tipo': 'ajuste',
          'quantidade': delta, // com sinal
          'motivo': motivo,
          'data': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Ajuste registrado: ${delta >= 0 ? '+' : ''}$delta em "$produtoNome"')),
      );

      _quantidadeController.clear();
      _motivoController.clear();
      setState(() {
        _produtoIdSelecionado = null;
        _aumentar = true;
      });
    } catch (e) {
      if (!mounted) return;

      final msg = e is StateError ? e.message : 'Erro ao salvar ajuste: $e';
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final produtosQuery = FirestorePaths.produtos(_firestore).orderBy('nome');

    return Scaffold(
      appBar: AppBar(title: const Text('Ajuste de Estoque')),
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
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Aumentar (+)')),
                    ButtonSegment(value: false, label: Text('Reduzir (-)')),
                  ],
                  selected: {_aumentar},
                  onSelectionChanged: _salvando ? null : (set) => setState(() => _aumentar = set.first),
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
                const SizedBox(height: 12),
                TextField(
                  controller: _motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo (ex.: Inventário, Perda, Quebra)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_salvando || _produtoIdSelecionado == null)
                        ? null
                        : () => _salvarAjuste(
                              produtoId: _produtoIdSelecionado!,
                              produtoNome: produtoNome,
                            ),
                    child: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar ajuste'),
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

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
