import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../security/password_policy.dart';

class PasswordPolicyService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<int> getUserPolicyVersion() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data();

    final v = data?['passwordPolicyVersion'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 1; // padrão para contas antigas (sem campo)
  }

  Future<void> setUserPolicyVersion(int version) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set(
      {'passwordPolicyVersion': version},
      SetOptions(merge: true),
    );
  }

  Future<void> markUserAsUpToDate() =>
      setUserPolicyVersion(PasswordPolicy.currentVersion);

  Future<bool> needsPasswordUpdate() async {
    final v = await getUserPolicyVersion();
    return v < PasswordPolicy.currentVersion;
  }
}