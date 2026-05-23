class PasswordPolicy {
  static const int currentVersion = 2;

  /// Regras:
  /// - mínimo 8 caracteres
  /// - pelo menos 1 letra maiúscula
  /// - pelo menos 1 caractere especial (qualquer coisa que não seja letra/número)
  static String? validate(String senha) {
    if (senha.trim().isEmpty) return 'Informe a senha';
    if (senha.length < 8) return 'A senha deve ter pelo menos 8 caracteres';

    final temMaiuscula = RegExp(r'[A-Z]').hasMatch(senha);
    if (!temMaiuscula) {
      return 'A senha deve conter pelo menos 1 letra maiúscula';
    }

    final temEspecial = RegExp(r'[^A-Za-z0-9]').hasMatch(senha);
    if (!temEspecial) {
      return 'A senha deve conter pelo menos 1 caractere especial';
    }

    return null;
  }
}