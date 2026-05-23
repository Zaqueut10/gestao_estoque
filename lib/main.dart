import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'auth/auth_gate.dart';

// Rotas existentes
import 'modules/dashboard/produtos_page.dart';
import 'modules/movements/entradas_page.dart';
import 'modules/movements/saidas_page.dart';
import 'modules/movements/ajuste_estoque_page.dart';
import 'modules/movements/movimentos_page.dart';
import 'modules/reports/estoque_critico_page.dart';
import 'modules/reports/relatorio_page.dart';
import 'modules/exports/exportacoes_page.dart';
import 'auth/password_policy_gate.dart';

// ✅ NOVAS TELAS (Vendas)
import 'modules/sales/vendas_page.dart';
import 'modules/reports/relatorio_vendas_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão de Estoque',
      debugShowCheckedModeBanner: false,
      home: PasswordPolicyGate(child: const AuthGate()),
      routes: {
        '/produtos': (context) => const ProdutosPage(),
        '/entradas': (context) => const EntradasPage(),
        '/saidas': (context) => const SaidasPage(),
        '/ajuste': (context) => const AjusteEstoquePage(),
        '/estoque-critico': (context) => const EstoqueCriticoPage(),
        '/movimentos': (context) => const MovimentosPage(),
        '/relatorios': (context) => const RelatorioPage(),
        '/exportacoes': (context) => const ExportacoesPage(),

        // ✅ NOVAS ROTAS (Item 6)
        '/vendas': (context) => const VendasPage(),
        '/relatorio-vendas': (context) => const RelatorioVendasPage(),
      },
    );
  }
}