import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Estoque'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(
              context,
              title: "Produtos",
              icon: Icons.inventory_2,
              color: Colors.deepPurple,
              onTap: () {
                Navigator.pushNamed(context, '/produtos');
              },
            ),
            _buildCard(
              context,
              title: "Entradas",
              icon: Icons.add_shopping_cart,
              color: Colors.green,
              onTap: () {
                Navigator.pushNamed(context, '/entradas');
              },
            ),
            _buildCard(
              context,
              title: "Saídas",
              icon: Icons.shopping_bag,
              color: Colors.red,
              onTap: () {
                Navigator.pushNamed(context, '/saidas');
              },
            ),
            _buildCard(
              context,
              title: "Movimentações",
              icon: Icons.history,
              color: Colors.teal,
              onTap: () {
                Navigator.pushNamed(context, '/movimentos');
              },
            ),
            _buildCard(
              context,
              title: "Relatórios",
              icon: Icons.bar_chart,
              color: Colors.blue,
              onTap: () {
                // futura tela de relatórios
              },
            ),
            _buildCard(
              context,
              title: "Configurações",
              icon: Icons.settings,
              color: Colors.grey,
              onTap: () {
                // futura tela de configurações
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.22),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
