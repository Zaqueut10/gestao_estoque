import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/firestore_paths.dart';
import 'produto_detalhe_page.dart';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _estoqueMinimoController = TextEditingController();

  final TextEditingController _buscaController = TextEditingController();
  String _busca = '';

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _buscaController.addListener(() {
      setState(() => _busca = _buscaController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _estoqueMinimoController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  double? _parsePreco(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  int? _parseInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _abrirDialogNovoProduto() async {
    _nomeController.clear();
    _precoController.clear();
    _estoqueMinimoController.clear();

    await _dialogProduto(
      titulo: 'Novo Produto',
      onSalvar: () async {
        final nome = _nomeController.text.trim();
        final preco = _parsePreco(_precoController.text);
        final minimo = _parseInt(_estoqueMinimoController.text);

        if (nome.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Informe o nome do produto')),
          );
          return;
        }
        if (preco != null && preco < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preço inválido')),
          );
          return;
        }
        if (minimo != null && minimo < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estoque mínimo inválido')),
          );
          return;
        }

        setState(() => _salvando = true);
        final messenger = ScaffoldMessenger.of(context);

        try {
          await FirestorePaths.produtos(_firestore).add({
            'nome': nome,
            'preco': preco ?? 0.0,
            'estoque': 0,
            'estoqueMinimo': minimo ?? 0,
            'criadoEm': FieldValue.serverTimestamp(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Produto cadastrado com sucesso!')),
          );
          Navigator.of(context).pop();
        } catch (e) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('Erro ao salvar produto: $e')),
          );
        } finally {
          if (mounted) setState(() => _salvando = false);
        }
      },
    );
  }

  Future<void> _abrirDialogEditarProduto({
    required String produtoId,
    required Map<String, dynamic> data,
  }) async {
    _nomeController.text = (data['nome'] ?? '').toString();
    final preco = (data['preco'] is num) ? (data['preco'] as num).toDouble() : 0.0;
    final minimo = (data['estoqueMinimo'] is num) ? (data['estoqueMinimo'] as num).toInt() : 0;

    _precoController.text = preco > 0 ? preco.toStringAsFixed(2) : '';
    _estoqueMinimoController.text = minimo > 0 ? minimo.toString() : '';

    await _dialogProduto(
      titulo: 'Editar Produto',
      onSalvar: () async {
        final nome = _nomeController.text.trim();
        final precoNovo = _parsePreco(_precoController.text);
        final minimoNovo = _parseInt(_estoqueMinimoController.text);

        if (nome.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Informe o nome do produto')),
          );
          return;
        }
        if (precoNovo != null && precoNovo < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preço inválido')),
          );
          return;
        }
        if (minimoNovo != null && minimoNovo < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estoque mínimo inválido')),
          );
          return;
        }

        setState(() => _salvando = true);
        final messenger = ScaffoldMessenger.of(context);

        try {
          await FirestorePaths.produtoDoc(_firestore, produtoId).update({
            'nome': nome,
            'preco': precoNovo ?? 0.0,
            'estoqueMinimo': minimoNovo ?? 0,
            'atualizadoEm': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;
          messenger.showSnackBar(const SnackBar(content: Text('Produto atualizado!')));
          Navigator.of(context).pop();
        } catch (e) {
          if (!mounted) return;
          messenger.showSnackBar(SnackBar(content: Text('Erro ao atualizar produto: $e')));
        } finally {
          if (mounted) setState(() => _salvando = false);
        }
      },
    );
  }

  Future<void> _dialogProduto({
    required String titulo,
    required Future<void> Function() onSalvar,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _precoController,
                  decoration: const InputDecoration(
                    labelText: 'Preço (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _estoqueMinimoController,
                  decoration: const InputDecoration(
                    labelText: 'Estoque mínimo (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _salvando ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _salvando ? null : () => onSalvar(),
              child: _salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _excluirProduto({
    required String produtoId,
    required String nome,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Excluir o produto "$nome"?\n\nObs.: as movimentações antigas permanecerão no histórico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await FirestorePaths.produtoDoc(_firestore, produtoId).delete();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Produto excluído.')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final produtosRef = FirestorePaths.produtos(_firestore);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          IconButton(
            onPressed: _abrirDialogNovoProduto,
            icon: const Icon(Icons.add),
            tooltip: 'Novo produto',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                labelText: 'Buscar produto',
                hintText: 'Digite parte do nome...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busca.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => _buscaController.clear(),
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: produtosRef.orderBy('nome').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar produtos: ${snapshot.error}'));
                }

                final docsAll = snapshot.data?.docs ?? [];
                final docs = _busca.isEmpty
                    ? docsAll
                    : docsAll.where((d) {
                        final nome = (d.data()['nome'] ?? '').toString().toLowerCase();
                        return nome.contains(_busca);
                      }).toList();

                if (docsAll.isEmpty) {
                  return const Center(child: Text('Nenhum produto cadastrado.'));
                }
                if (docs.isEmpty) {
                  return const Center(child: Text('Nenhum produto encontrado com esse filtro.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();

                    final nome = (data['nome'] ?? 'Sem nome').toString();
                    final estoque = (data['estoque'] is num) ? (data['estoque'] as num).toInt() : 0;
                    final minimo = (data['estoqueMinimo'] is num) ? (data['estoqueMinimo'] as num).toInt() : 0;
                    final preco = (data['preco'] is num) ? (data['preco'] as num).toDouble() : 0.0;

                    final critico = minimo > 0 && estoque <= minimo;

                    return Card(
                      color: critico ? Colors.red.withValues(alpha: 0.08) : null,
                      child: ListTile(
                        title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          'Estoque: $estoque • Mínimo: $minimo'
                          '${preco > 0 ? ' • Preço: R\$ ${preco.toStringAsFixed(2)}' : ''}',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProdutoDetalhePage(produtoId: doc.id),
                            ),
                          );
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'historico') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProdutoDetalhePage(produtoId: doc.id),
                                ),
                              );
                            } else if (v == 'editar') {
                              await _abrirDialogEditarProduto(produtoId: doc.id, data: data);
                            } else if (v == 'excluir') {
                              await _excluirProduto(produtoId: doc.id, nome: nome);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'historico', child: Text('Ver histórico')),
                            PopupMenuItem(value: 'editar', child: Text('Editar')),
                            PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}