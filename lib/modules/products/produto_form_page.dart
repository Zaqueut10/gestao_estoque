import 'package:flutter/material.dart';
import '../../data/services/firestore_service.dart';

class ProdutoFormPage extends StatefulWidget {
  final String? produtoId;
  final Map<String, dynamic>? dadosIniciais;

  const ProdutoFormPage({
    super.key,
    this.produtoId,
    this.dadosIniciais,
  });

  @override
  State<ProdutoFormPage> createState() => _ProdutoFormPageState();
}

class _ProdutoFormPageState extends State<ProdutoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _estoqueController = TextEditingController();
  final _estoqueMinimoController = TextEditingController();
  final _precoController = TextEditingController();

  final FirestoreService _service = FirestoreService();

  bool get editando => widget.produtoId != null;

  @override
  void initState() {
    super.initState();

    final dados = widget.dadosIniciais;
    if (dados != null) {
      _nomeController.text = dados['nome'] ?? '';
      _descricaoController.text = dados['descricao'] ?? '';
      _estoqueController.text = '${dados['estoque'] ?? 0}';
      _estoqueMinimoController.text = '${dados['estoqueMinimo'] ?? 0}';
      _precoController.text =
          dados['preco'] != null ? dados['preco'].toString() : '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _estoqueController.dispose();
    _estoqueMinimoController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeController.text.trim();
    final descricao = _descricaoController.text.trim();
    final estoque = int.tryParse(_estoqueController.text) ?? 0;
    final estoqueMinimo =
        int.tryParse(_estoqueMinimoController.text) ?? 0;
    final preco = _precoController.text.isEmpty
        ? null
        : double.tryParse(_precoController.text.replaceAll(',', '.'));

    if (editando) {
      await _service.atualizarProduto(
        produtoId: widget.produtoId!,
        nome: nome,
        descricao: descricao.isEmpty ? null : descricao,
        estoque: estoque,
        estoqueMinimo: estoqueMinimo,
        preco: preco,
      );
    } else {
      await _service.adicionarProduto(
        nome: nome,
        descricao: descricao.isEmpty ? null : descricao,
        estoqueInicial: estoque,
        estoqueMinimo: estoqueMinimo,
        preco: preco,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar Produto' : 'Novo Produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Informe o nome do produto'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _estoqueController,
                decoration: const InputDecoration(
                  labelText: 'Estoque atual / inicial',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _estoqueMinimoController,
                decoration: const InputDecoration(
                  labelText: 'Estoque mínimo (alerta)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(
                  labelText: 'Preço (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: Text(editando ? 'Salvar alterações' : 'Cadastrar'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
