import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================
  // PRODUTOS
  // ===========================

  Stream<QuerySnapshot> getProdutosStream() {
    return _db
        .collection('produtos')
        .orderBy('nome')
        .snapshots();
  }

  Future<void> adicionarProduto({
    required String nome,
    String? descricao,
    int estoqueInicial = 0,
    int estoqueMinimo = 0,
    double? preco,
  }) async {
    await _db.collection('produtos').add({
      'nome': nome,
      'descricao': descricao,
      'estoque': estoqueInicial,
      'estoqueMinimo': estoqueMinimo,
      'preco': preco,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizarProduto({
    required String produtoId,
    required String nome,
    String? descricao,
    required int estoque,
    required int estoqueMinimo,
    double? preco,
  }) async {
    await _db.collection('produtos').doc(produtoId).update({
      'nome': nome,
      'descricao': descricao,
      'estoque': estoque,
      'estoqueMinimo': estoqueMinimo,
      'preco': preco,
    });
  }

  Future<void> deletarProduto(String produtoId) async {
    await _db.collection('produtos').doc(produtoId).delete();
  }

  // ===========================
  // MOVIMENTOS (ENTRADA / SAÍDA)
  // ===========================

  Future<void> adicionarEntrada({
    required String produtoId,
    required int quantidade,
  }) async {
    // Registrar movimento
    await _db.collection('movimentos').add({
      'produtoId': produtoId,
      'quantidade': quantidade,
      'tipo': 'entrada',
      'data': FieldValue.serverTimestamp(),
    });

    // Atualizar estoque
    await _db.collection('produtos').doc(produtoId).update({
      'estoque': FieldValue.increment(quantidade),
    });
  }

  Future<void> adicionarSaida({
    required String produtoId,
    required int quantidade,
  }) async {
    // Registrar movimento
    await _db.collection('movimentos').add({
      'produtoId': produtoId,
      'quantidade': quantidade,
      'tipo': 'saida',
      'data': FieldValue.serverTimestamp(),
    });

    // Atualizar estoque
    await _db.collection('produtos').doc(produtoId).update({
      'estoque': FieldValue.increment(-quantidade),
    });
  }
}
