import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao sair: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Estoque'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: isWide ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _card(context, 'Produtos', Icons.inventory_2, Colors.deepPurple, '/produtos'),
            _card(context, 'Entradas', Icons.add_shopping_cart, Colors.green, '/entradas'),
            _card(context, 'Saídas', Icons.shopping_bag, Colors.red, '/saidas'),
            _card(context, 'Ajuste', Icons.tune, Colors.amber, '/ajuste'),
            _card(context, 'Estoque crítico', Icons.report_problem, Colors.orange, '/estoque-critico'),
            _card(context, 'Movimentações', Icons.history, Colors.teal, '/movimentos'),

            // ✅ NOVOS (Item 6)
            _card(context, 'Vendas', Icons.point_of_sale, Colors.indigo, '/vendas'),
            _card(context, 'Relatório de Vendas', Icons.assessment, Colors.blueGrey, '/relatorio-vendas'),

            // Mantidos
            _card(context, 'Relatórios', Icons.analytics, Colors.indigoAccent, '/relatorios'),
            _card(context, 'Exportações', Icons.file_download, Colors.brown, '/exportacoes'),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}