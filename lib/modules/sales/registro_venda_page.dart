import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/firestore_paths.dart';

class RegistroVendaPage extends StatefulWidget {
  const RegistroVendaPage({super.key});

  @override
  State<RegistroVendaPage> createState() => _RegistroVendaPageState();
}

class _RegistroVendaPageState extends State<RegistroVendaPage> {
  final _firestore = FirebaseFirestore.instance;

  final _clienteController = TextEditingController();
  final _quantidadeController = TextEditingController(text: '1');
  final _precoController = TextEditingController();

  String? _produtoIdSelecionado;
  bool _salvando = false;

  @override
  void dispose() {
    _clienteController.dispose();
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
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

  double? _parsePreco(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  Future<void> _registrarVenda({
    required String produtoId,
    required String produtoNome,
    required int estoqueAtual,
  }) async {
    final quantidade = int.tryParse(_quantidadeController.text.trim()) ?? 0;
    if (quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade válida (> 0).')),
      );
      return;
    }

    final precoUnit = _parsePreco(_precoController.text) ?? 0.0;
    if (precoUnit < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preço unitário inválido.')),
      );
      return;
    }

    if (estoqueAtual - quantidade < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estoque insuficiente. Atual: $estoqueAtual')),
      );
      return;
    }

    final cliente = _clienteController.text.trim();
    final total = precoUnit * quantidade;

    setState(() => _salvando = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final produtoRef = FirestorePaths.produtoDoc(_firestore, produtoId);
      final vendaRef = FirestorePaths.vendas(_firestore).doc();
      final movimentoRef = FirestorePaths.movimentos(_firestore).doc();

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(produtoRef);
        final data = snap.data();
        if (data == null) throw Exception('Produto não encontrado');

        final estoqueDb = _toInt(data['estoque']);
        final novoEstoque = estoqueDb - quantidade;

        if (novoEstoque < 0) {
          throw StateError('Estoque insuficiente. Atual: $estoqueDb');
        }

        tx.update(produtoRef, {
          'estoque': novoEstoque,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });

        tx.set(vendaRef, {
          'data': FieldValue.serverTimestamp(),
          'cliente': cliente,
          'produtoId': produtoId,
          'produtoNome': produtoNome,
          'quantidade': quantidade,
          'precoUnit': precoUnit,
          'total': total,
        });

        tx.set(movimentoRef, {
          'data': FieldValue.serverTimestamp(),
          'tipo': 'venda',
          'produtoId': produtoId,
          'produtoNome': produtoNome,
          'quantidade': quantidade,
          'cliente': cliente,
          'total': total,
          'vendaId': vendaRef.id,
        });
      });

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Venda registrada: $quantidade x $produtoNome (R\$ ${total.toStringAsFixed(2)})')),
      );

      _clienteController.clear();
      _quantidadeController.text = '1';
      _precoController.clear();
      setState(() => _produtoIdSelecionado = null);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erro ao registrar venda: $e')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final produtosQuery = FirestorePaths.produtos(_firestore).orderBy('nome');

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar venda')),
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
              : docs.where((d) => d.id == _produtoIdSelecionado).firstOrNull;

          final dataSel = selecionado?.data();
          final nomeSel = (dataSel?['nome'] ?? '').toString();
          final estoqueSel = _toInt(dataSel?['estoque']);
          final precoSel = _toDouble(dataSel?['preco']);

          // Auto-preenche preço ao selecionar (se campo estiver vazio)
          if (_produtoIdSelecionado != null && _precoController.text.trim().isEmpty && precoSel > 0) {
            _precoController.text = precoSel.toStringAsFixed(2);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _produtoIdSelecionado,
                  items: docs.map((doc) {
                    final nome = (doc.data()['nome'] ?? 'Sem nome').toString();
                    return DropdownMenuItem(value: doc.id, child: Text(nome));
                  }).toList(),
                  onChanged: _salvando ? null : (v) => setState(() {
                    _produtoIdSelecionado = v;
                    _precoController.clear();
                  }),
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
                      title: Text(nomeSel, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('Estoque atual: $estoqueSel'),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clienteController,
                  decoration: const InputDecoration(
                    labelText: 'Cliente (opcional)',
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 12),
                TextField(
                  controller: _precoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Preço unitário',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (_salvando || _produtoIdSelecionado == null)
                        ? null
                        : () => _registrarVenda(
                              produtoId: _produtoIdSelecionado!,
                              produtoNome: nomeSel,
                              estoqueAtual: estoqueSel,
                            ),
                    icon: _salvando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.point_of_sale),
                    label: Text(_salvando ? 'Salvando...' : 'Confirmar venda'),
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