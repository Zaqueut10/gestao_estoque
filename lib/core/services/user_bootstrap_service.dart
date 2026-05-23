import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserBootstrapService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  UserBootstrapService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  Future<void> ensureUserDoc() async {
    final user = auth.currentUser;
    if (user == null) return;

    final userRef = firestore.collection('users').doc(user.uid);

    await userRef.set({
      'email': user.email ?? '',
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
