import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvExportService {
  final FirebaseFirestore firestore;

  CsvExportService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  // CSV manual (com escape correto)
  String _csvEscape(dynamic value) {
    final s = (value ?? '').toString();
    final needsQuotes =
        s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
    if (!needsQuotes) return s;

    final escaped = s.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _toCsv(List<List<dynamic>> rows) {
    return rows.map((row) => row.map(_csvEscape).join(',')).join('\n');
  }

  Future<File> _writeCsvFile({
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    final csvText = _toCsv(rows);

    final Directory dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvText, flush: true);
    return file;
  }

  Future<void> exportarEstoqueAtual() async {
    final snap = await firestore.collection('produtos').orderBy('nome').get();

    final rows = <List<dynamic>>[
      ['produtoId', 'nome', 'estoque', 'estoqueMinimo', 'preco'],
    ];

    for (final doc in snap.docs) {
      final data = doc.data();
      rows.add([
        doc.id,
        (data['nome'] ?? '').toString(),
        _toInt(data['estoque']),
        _toInt(data['estoqueMinimo']),
        _toDouble(data['preco']).toStringAsFixed(2),
      ]);
    }

    final file = await _writeCsvFile(
      fileName: 'estoque_atual.csv',
      rows: rows,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Exportação - Estoque atual',
        subject: 'Estoque atual (CSV)',
      ),
    );
  }

  Future<void> exportarMovimentosPorPeriodo({
    required DateTime inicio,
    required DateTime fimExclusivo,
  }) async {
    final query = firestore
        .collection('movimentos')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fimExclusivo))
        .orderBy('data', descending: false);

    final snap = await query.get();

    final rows = <List<dynamic>>[
      ['movimentoId', 'data', 'produtoId', 'produtoNome', 'tipo', 'quantidade', 'motivo'],
    ];

    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = data['data'] as Timestamp?;
      final dt = ts?.toDate();

      rows.add([
        doc.id,
        _fmtDateTime(dt),
        (data['produtoId'] ?? '').toString(),
        (data['produtoNome'] ?? '').toString(),
        (data['tipo'] ?? '').toString(),
        _toInt(data['quantidade']),
        (data['motivo'] ?? '').toString(),
      ]);
    }

    final ini = inicio.toIso8601String().split('T').first;
    final fim = fimExclusivo.toIso8601String().split('T').first;

    final file = await _writeCsvFile(
      fileName: 'movimentos_${ini}_a_$fim.csv',
      rows: rows,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Exportação - Movimentos',
        subject: 'Movimentos (CSV)',
      ),
    );
  }
}
