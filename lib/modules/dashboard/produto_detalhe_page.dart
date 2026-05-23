import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/firestore_paths.dart';

class ProdutoDetalhePage extends StatefulWidget {
  final String produtoId;

  const ProdutoDetalhePage({
    super.key,
    required this.produtoId,
  });

  @override
  State<ProdutoDetalhePage> createState() => _ProdutoDetalhePageState();
}

class _ProdutoDetalhePageState extends State<ProdutoDetalhePage> {
  final db = FirebaseFirestore.instance;

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _movs = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _carregando = false;
  bool _temMais = true;

  static const int _pageSize = 25;

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

  String _formatarData(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Query<Map<String, dynamic>> _baseQuery() {
    return FirestorePaths.movimentos(db)
        .where('produtoId', isEqualTo: widget.produtoId)
        .orderBy('data', descending: true);
  }

  @override
  void initState() {
    super.initState();
    _carregarMais(reset: true);
  }

  Future<void> _carregarMais({bool reset = false}) async {
    if (_carregando) return;

    setState(() => _carregando = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (reset) {
        _movs.clear();
        _lastDoc = null;
        _temMais = true;
      }
      if (!_temMais) return;

      Query<Map<String, dynamic>> q = _baseQuery().limit(_pageSize);
      if (_lastDoc != null) {
        q = q.startAfterDocument(_lastDoc!);
      }

      final snap = await q.get();
      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last;
        _movs.addAll(snap.docs);
      }

      if (snap.docs.length < _pageSize) {
        _temMais = false;
      }

      if (mounted) setState(() {});
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro ao carregar histórico: $e')));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final produtoRef = FirestorePaths.produtoDoc(db, widget.produtoId);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do produto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: produtoRef.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (snap.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Erro ao carregar produto: ${snap.error}'),
                  ),
                );
              }

              final data = snap.data?.data();
              if (data == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Produto não encontrado (talvez tenha sido excluído).'),
                  ),
                );
              }

              final nome = (data['nome'] ?? '').toString();
              final estoque = _toInt(data['estoque']);
              final minimo = _toInt(data['estoqueMinimo']);
              final preco = _toDouble(data['preco']);

              final critico = minimo > 0 && estoque <= minimo;

              return Card(
                color: critico ? Colors.red.withValues(alpha: 0.08) : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.inventory_2, size: 18),
                            label: Text('Estoque: $estoque'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.report_problem, size: 18),
                            label: Text('Mínimo: $minimo'),
                          ),
                          if (preco > 0)
                            Chip(
                              avatar: const Icon(Icons.attach_money, size: 18),
                              label: Text('Preço: R\$ ${preco.toStringAsFixed(2)}'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Histórico de movimentações',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          if (_movs.isEmpty && _carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            ),

          if (_movs.isEmpty && !_carregando)
            const Text('Nenhuma movimentação para este produto.'),

          ..._movs.map((d) {
            final m = d.data();
            final tipo = (m['tipo'] ?? '').toString();
            final qtd = _toInt(m['quantidade']);
            final motivo = (m['motivo'] ?? '').toString();

            final cliente = (m['cliente'] ?? '').toString().trim();
            final totalVenda = _toDouble(m['total']);

            final ts = m['data'] as Timestamp?;
            final dt = ts?.toDate();

            late final Color cor;
            late final String titulo;
            late final String qtdTexto;
            late final IconData icon;

            // ✅ ITEM 5 (COMPLETO): trata 'venda' como saída (cor/vermelho, quantidade negativa)
            if (tipo == 'entrada') {
              cor = Colors.green;
              titulo = 'Entrada';
              qtdTexto = '+${qtd.abs()}';
              icon = Icons.arrow_downward;
            } else if (tipo == 'saida' || tipo == 'venda') {
              cor = Colors.red;
              titulo = (tipo == 'venda') ? 'Venda' : 'Saída';
              qtdTexto = '-${qtd.abs()}';
              icon = Icons.arrow_upward;
            } else if (tipo == 'ajuste') {
              cor = Colors.amber[800]!;
              titulo = 'Ajuste';
              qtdTexto = '${qtd >= 0 ? '+' : ''}$qtd';
              icon = Icons.tune;
            } else {
              cor = Colors.blueGrey;
              titulo = 'Movimento';
              qtdTexto = '$qtd';
              icon = Icons.swap_horiz;
            }

            final linhas = <String>[
              _formatarData(dt),
              if (tipo == 'ajuste' && motivo.isNotEmpty) 'Motivo: $motivo',
              if (tipo == 'venda' && cliente.isNotEmpty) 'Cliente: $cliente',
              if (tipo == 'venda' && totalVenda > 0) 'Total: R\$ ${totalVenda.toStringAsFixed(2)}',
            ];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cor.withValues(alpha: 0.12),
                  child: Icon(icon, color: cor),
                ),
                title: Text(
                  '$titulo • $qtdTexto',
                  style: TextStyle(color: cor, fontWeight: FontWeight.w800),
                ),
                subtitle: Text(linhas.join('\n')),
              ),
            );
          }),

          const SizedBox(height: 8),
          if (_temMais)
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _carregando ? null : () => _carregarMais(),
                icon: _carregando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text(_carregando ? 'Carregando...' : 'Carregar mais'),
              ),
            )
          else if (_movs.isNotEmpty)
            Text(
              'Fim do histórico.',
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}