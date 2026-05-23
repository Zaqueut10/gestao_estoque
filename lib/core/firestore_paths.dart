import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestorePaths {
  static String uidOrThrow() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Usuário não autenticado.');
    }
    return uid;
  }

  static DocumentReference<Map<String, dynamic>> userDoc(FirebaseFirestore db) {
    final uid = uidOrThrow();
    return db.collection('users').doc(uid);
  }

  static CollectionReference<Map<String, dynamic>> produtos(FirebaseFirestore db) {
    return userDoc(db).collection('produtos');
  }

  static DocumentReference<Map<String, dynamic>> produtoDoc(
    FirebaseFirestore db,
    String produtoId,
  ) {
    return produtos(db).doc(produtoId);
  }

  static CollectionReference<Map<String, dynamic>> movimentos(FirebaseFirestore db) {
    return userDoc(db).collection('movimentos');
  }

  static CollectionReference<Map<String, dynamic>> vendas(FirebaseFirestore db) {
    return userDoc(db).collection('vendas');
  }

  static DocumentReference<Map<String, dynamic>> vendaDoc(
    FirebaseFirestore db,
    String vendaId,
  ) {
    return vendas(db).doc(vendaId);
  }
}