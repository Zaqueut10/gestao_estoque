import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/services/password_policy_service.dart';
import 'force_password_change_page.dart';

class PasswordPolicyGate extends StatefulWidget {
  final Widget child; // aqui você passa o seu AuthGate

  const PasswordPolicyGate({super.key, required this.child});

  @override
  State<PasswordPolicyGate> createState() => _PasswordPolicyGateState();
}

class _PasswordPolicyGateState extends State<PasswordPolicyGate> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;

        // Se não está logado, deixa o AuthGate cuidar do fluxo (Login etc.)
        if (user == null) return widget.child;

        // Se está logado, verifica se precisa forçar troca de senha
        return FutureBuilder<bool>(
          future: PasswordPolicyService().needsPasswordUpdate(),
          builder: (context, needsSnap) {
            if (needsSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final needsUpdate = needsSnap.data ?? false;

            if (needsUpdate) {
              return ForcePasswordChangePage(onSuccess: _refresh);
            }

            return widget.child;
          },
        );
      },
    );
  }
}