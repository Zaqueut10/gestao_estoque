import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/security/password_policy.dart';
import '../core/services/password_policy_service.dart';

class ForcePasswordChangePage extends StatefulWidget {
  final VoidCallback onSuccess;

  const ForcePasswordChangePage({super.key, required this.onSuccess});

  @override
  State<ForcePasswordChangePage> createState() => _ForcePasswordChangePageState();
}

class _ForcePasswordChangePageState extends State<ForcePasswordChangePage> {
  final _senhaAtual = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmacao = TextEditingController();

  bool _carregando = false;

  @override
  void dispose() {
    _senhaAtual.dispose();
    _novaSenha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _atualizarSenha() async {
    final atual = _senhaAtual.text.trim();
    final nova = _novaSenha.text.trim();
    final conf = _confirmacao.text.trim();

    if (atual.isEmpty || nova.isEmpty || conf.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    if (nova != conf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A confirmação não confere')),
      );
      return;
    }

    final erro = PasswordPolicy.validate(nova);
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro)),
      );
      return;
    }

    setState(() => _carregando = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Reautenticação (o Firebase geralmente exige "login recente")
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: atual,
      );
      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(nova);

      await PasswordPolicyService().markUserAsUpToDate();

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Senha atualizada com sucesso')),
      );

      // Faz o gate reavaliar e liberar o app
      widget.onSuccess();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erro ao atualizar senha')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviarReset() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Email de redefinição enviado para $email')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Falha ao enviar email: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualize sua senha'),
        automaticallyImplyLeading: false, // impede "voltar" e burlar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Por segurança, você precisa atualizar sua senha para continuar.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _senhaAtual,
              decoration: const InputDecoration(
                labelText: 'Senha atual',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _novaSenha,
              decoration: const InputDecoration(
                labelText: 'Nova senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmacao,
              decoration: const InputDecoration(
                labelText: 'Confirmar nova senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _carregando ? null : _atualizarSenha,
                child: _carregando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Atualizar senha'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _carregando ? null : _enviarReset,
              child: const Text('Esqueci minha senha'),
            ),
          ],
        ),
      ),
    );
  }
}