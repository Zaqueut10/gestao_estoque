import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/services/user_bootstrap_service.dart';
import '../modules/dashboard/home_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snap.data;
        if (user == null) {
          return const LoginPage();
        }

        // ✅ Garante users/{uid} antes de entrar no app
        return FutureBuilder<void>(
          future: UserBootstrapService().ensureUserDoc(),
          builder: (context, bootSnap) {
            if (bootSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (bootSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Erro ao inicializar usuário: ${bootSnap.error}'),
                ),
              );
            }

            return const HomePage();
          },
        );
      },
    );
  }
}
