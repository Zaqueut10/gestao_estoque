import 'package:flutter/material.dart';
import '../../core/services/csv_export_service.dart';

enum PeriodoExportacao { hoje, ultimos7, ultimos30 }

class ExportacoesPage extends StatefulWidget {
  const ExportacoesPage({super.key});

  @override
  State<ExportacoesPage> createState() => _ExportacoesPageState();
}

class _ExportacoesPageState extends State<ExportacoesPage> {
  final CsvExportService _exportService = CsvExportService();

  PeriodoExportacao _periodo = PeriodoExportacao.hoje;
  bool _exportando = false;

  DateTime _inicio(PeriodoExportacao p, DateTime now) {
    final hoje = DateTime(now.year, now.month, now.day);
    return switch (p) {
      PeriodoExportacao.hoje => hoje,
      PeriodoExportacao.ultimos7 => hoje.subtract(const Duration(days: 6)),
      PeriodoExportacao.ultimos30 => hoje.subtract(const Duration(days: 29)),
    };
  }

  DateTime _fimExclusivo(DateTime now) {
    final hoje = DateTime(now.year, now.month, now.day);
    return hoje.add(const Duration(days: 1));
  }

  Future<void> _exportarEstoque() async {
    if (_exportando) return;

    setState(() => _exportando = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _exportService.exportarEstoqueAtual();
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('CSV do estoque gerado e pronto para compartilhar.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erro ao exportar estoque: $e')));
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _exportarMovimentos() async {
    if (_exportando) return;

    setState(() => _exportando = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final now = DateTime.now();
      final inicio = _inicio(_periodo, now);
      final fimExc = _fimExclusivo(now);

      await _exportService.exportarMovimentosPorPeriodo(
        inicio: inicio,
        fimExclusivo: fimExc,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('CSV de movimentos gerado e pronto para compartilhar.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erro ao exportar movimentos: $e')));
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportações (CSV)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Exportar estoque atual'),
              subtitle: const Text('Gera um CSV com estoque, mínimo e preço.'),
              trailing: _exportando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              onTap: _exportando ? null : _exportarEstoque,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Exportar movimentos por período',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<PeriodoExportacao>(
                    initialValue: _periodo,
                    items: const [
                      DropdownMenuItem(value: PeriodoExportacao.hoje, child: Text('Hoje')),
                      DropdownMenuItem(value: PeriodoExportacao.ultimos7, child: Text('Últimos 7 dias')),
                      DropdownMenuItem(value: PeriodoExportacao.ultimos30, child: Text('Últimos 30 dias')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _periodo = v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Período',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _exportando ? null : _exportarMovimentos,
                      icon: const Icon(Icons.download),
                      label: Text(_exportando ? 'Gerando...' : 'Gerar CSV e compartilhar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
