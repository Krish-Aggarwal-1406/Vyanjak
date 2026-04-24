import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vyanjak/core/services/firestore_service.dart';
import '../../core/constants/app_theme.dart';
import '../../widgets/frosted_card.dart';

class TherapistStatScreen extends StatefulWidget {
  const TherapistStatScreen({super.key});

  @override
  State<TherapistStatScreen> createState() => _TherapistStatScreenState();
}

class _TherapistStatScreenState extends State<TherapistStatScreen> {
  List<Map<String, dynamic>> _bridgeSessions = [];
  List<Map<String, dynamic>> _practiceSessions = [];
  List<Map<String, dynamic>> _struggleWords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  final FirestoreService _db = FirestoreService();

  Future<void> _loadData() async {
    final bridge = await _db.getBridgeSessions();
    final practice = await _db.getPracticeSessions();
    final struggle = await _db.getStruggleWords();
    setState(() {
      _bridgeSessions = bridge;
      _practiceSessions = practice;
      _struggleWords = struggle;
      _isLoading = false;
    });
  }

  int get _totalBridgeAttempts => _bridgeSessions.length;

  double get _avgConfidence {
    if (_bridgeSessions.isEmpty) return 0;
    final sum = _bridgeSessions.fold<double>(
        0,
            (prev, s) =>
        prev + ((s['confidence'] ?? 0.0) as num).toDouble());
    return sum / _bridgeSessions.length;
  }

  double get _practiceAccuracy {
    if (_practiceSessions.isEmpty) return 0;
    final sum = _practiceSessions.fold<double>(
        0,
            (prev, s) =>
        prev + ((s['accuracy'] ?? 0.0) as num).toDouble());
    return sum / _practiceSessions.length;
  }

  Map<String, int> get _wordFrequency {
    final map = <String, int>{};
    for (final s in _bridgeSessions) {
      final word = (s['word'] ?? '').toString();
      if (word.isNotEmpty) map[word] = (map[word] ?? 0) + 1;
    }
    final sorted = Map.fromEntries(
        map.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)));
    return Map.fromEntries(sorted.entries.take(5));
  }

  List<double> get _weeklyAccuracy {
    if (_practiceSessions.isEmpty) return List.filled(7, 0);
    final now = DateTime.now();
    final result = <double>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final daySessions = _practiceSessions.where((s) {
        final date = DateTime.tryParse(s['date'] ?? '');
        return date != null &&
            date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }).toList();
      if (daySessions.isEmpty) {
        result.add(0);
      } else {
        final avg = daySessions.fold<double>(
            0,
                (prev, s) =>
            prev +
                ((s['accuracy'] ?? 0.0) as num).toDouble()) /
            daySessions.length;
        result.add(avg);
      }
    }
    return result;
  }

  Future<void> _generatePDF() async {
    try {
      final pdf = pw.Document();
      final date = DateTime.now();
      final dateStr = '${date.day}/${date.month}/${date.year}';

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Vyanjak Clinical Report',
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Generated: $dateStr',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.grey)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('Speech Rehabilitation Progress Summary',
                  style: const pw.TextStyle(
                      fontSize: 13, color: PdfColors.grey600)),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),
              pw.Text('Overview',
                  style: pw.TextStyle(
                      fontSize: 15, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                _pdfStatBox('Bridge Sessions', '$_totalBridgeAttempts'),
                pw.SizedBox(width: 12),
                _pdfStatBox('AI Confidence',
                    '${(_avgConfidence * 100).toStringAsFixed(0)}%'),
                pw.SizedBox(width: 12),
                _pdfStatBox(
                    'Practice Sessions', '${_practiceSessions.length}'),
                pw.SizedBox(width: 12),
                _pdfStatBox('Practice Accuracy',
                    '${(_practiceAccuracy * 100).toStringAsFixed(0)}%'),
              ]),
              pw.SizedBox(height: 24),
              if (_struggleWords.isNotEmpty) ...[
                pw.Text('High Friction / Struggle Words',
                    style: pw.TextStyle(
                        fontSize: 15, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'Words the patient consistently struggled to recall or pronounce correctly.',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: [
                    'Word', 'Total Attempts', 'Failed',
                    'Failure Rate', 'Priority'
                  ],
                  data: _struggleWords.take(10).map((w) {
                    final failRate =
                    ((w['fail_rate'] as double) * 100).toStringAsFixed(0);
                    final priority = (w['fail_rate'] as double) > 0.6
                        ? 'HIGH'
                        : (w['fail_rate'] as double) > 0.3
                        ? 'MEDIUM'
                        : 'LOW';
                    return [
                      (w['word'] as String).toUpperCase(),
                      '${w['attempts']}',
                      '${w['failures']}',
                      '$failRate%',
                      priority,
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11),
                  cellStyle: const pw.TextStyle(fontSize: 11),
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
                ),
                pw.SizedBox(height: 24),
              ],
              if (_wordFrequency.isNotEmpty) ...[
                pw.Text('Most Requested Words (Bridge Mode)',
                    style: pw.TextStyle(
                        fontSize: 15, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['Word', 'Times Requested'],
                  data: _wordFrequency.entries
                      .map((e) => [e.key, '${e.value}'])
                      .toList(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11),
                  cellStyle: const pw.TextStyle(fontSize: 11),
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
                ),
                pw.SizedBox(height: 24),
              ],
              if (_practiceSessions.isNotEmpty) ...[
                pw.Text('Recent Practice Sessions',
                    style: pw.TextStyle(
                        fontSize: 15, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Score', 'Accuracy'],
                  data: _practiceSessions.reversed.take(5).map((s) {
                    final d = DateTime.tryParse(s['date'] ?? '');
                    final dateLabel = d != null
                        ? '${d.day}/${d.month}/${d.year}'
                        : '—';
                    return [
                      dateLabel,
                      '${s['score']}/${s['total']}',
                      '${((s['accuracy'] as num) * 100).toStringAsFixed(0)}%',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11),
                  cellStyle: const pw.TextStyle(fontSize: 11),
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
                ),
              ],
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 6),
              pw.Text(
                  'This report was auto-generated by Vyanjak — AI Speech Rehabilitation App.',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey)),
            ],
          );
        },
      ));

      final Uint8List bytes = await pdf.save();
      await Printing.sharePdf(
          bytes: bytes, filename: 'vyanjak_report_$dateStr.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to generate PDF: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  pw.Widget _pdfStatBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius:
          const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekly = _weeklyAccuracy;
    final bool hasData = _bridgeSessions.isNotEmpty ||
        _practiceSessions.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.frostyWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme:
        const IconThemeData(color: AppTheme.spaceNavy),
        title: Text('Clinical Analytics',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.spaceNavy)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(
              color: AppTheme.electricTeal))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasData)
              Center(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 64,
                          color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No sessions yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                              color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                          'Complete a Bridge Mode or Practice session to see your data here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                              color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else ...[
              Row(children: [
                Expanded(
                    child: _StatCard(
                        icon: Icons.graphic_eq_rounded,
                        value: '$_totalBridgeAttempts',
                        label: 'Bridge Sessions')),
                const SizedBox(width: 14),
                Expanded(
                    child: _StatCard(
                        icon: Icons.psychology_outlined,
                        value:
                        '${(_avgConfidence * 100).toStringAsFixed(0)}%',
                        label: 'AI Confidence')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _StatCard(
                        icon:
                        Icons.record_voice_over_rounded,
                        value:
                        '${_practiceSessions.length}',
                        label: 'Practice Sessions')),
                const SizedBox(width: 14),
                Expanded(
                    child: _StatCard(
                        icon: Icons
                            .check_circle_outline_rounded,
                        value:
                        '${(_practiceAccuracy * 100).toStringAsFixed(0)}%',
                        label: 'Practice Accuracy')),
              ]),
              const SizedBox(height: 28),
              Text('Weekly Practice Trend',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                      color: AppTheme.spaceNavy)),
              const SizedBox(height: 16),
              FrostedCard(
                child: SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                    children: List.generate(7, (i) {
                      final val = weekly[i];
                      return Column(
                        mainAxisAlignment:
                        MainAxisAlignment.end,
                        children: [
                          if (val > 0)
                            Text(
                                '${(val * 100).toInt()}%',
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            width: 28,
                            height: val > 0
                                ? 100 * val
                                : 4,
                            decoration: BoxDecoration(
                              color: val > 0
                                  ? AppTheme.electricTeal
                                  .withOpacity(
                                  i == 6 ? 1 : 0.4)
                                  : Colors.grey.shade200,
                              borderRadius:
                              BorderRadius.circular(
                                  8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(days[i],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                  color: Colors.grey)),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              if (_struggleWords.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Struggle Words',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                        color: AppTheme.spaceNavy)),
                const SizedBox(height: 6),
                Text(
                    'Words with highest failure rate across all practice sessions.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey)),
                const SizedBox(height: 16),
                FrostedCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount: _struggleWords.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.shade100),
                    itemBuilder: (context, i) {
                      final w = _struggleWords[i];
                      final failRate =
                      (w['fail_rate'] as double);
                      final priority = failRate > 0.6
                          ? 'HIGH'
                          : failRate > 0.3
                          ? 'MED'
                          : 'LOW';
                      final priorityColor = failRate > 0.6
                          ? AppTheme.errorRed
                          : failRate > 0.3
                          ? Colors.orange.shade400
                          : AppTheme.electricTeal;
                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14),
                        child: Row(children: [
                        Expanded(
                        child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                          children: [
                            Text(
                              (w['word'] as String)
                                  .toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                  color: AppTheme
                                      .spaceNavy,
                                  fontWeight:
                                  FontWeight
                                      .bold),
                            ),
                            Text(
                                '${w['failures']}/${w['attempts']} failed',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                    color:
                                    Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                      width: 80,
                      child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                      value: failRate,
                      minHeight: 8,
                      backgroundColor:
                      Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(priorityColor),
                      ),
                      ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                      padding:
                      const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4),
                      decoration: BoxDecoration(
                      color: priorityColor
                          .withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(8),
                      ),
                      child: Text(priority,
                      style: TextStyle(
                      color: priorityColor,
                      fontWeight:
                      FontWeight.w700,
                      fontSize: 11)),
                      ),
                      ]),
                      );
                    },
                  ),
                ),
              ],
              if (_wordFrequency.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Most Requested (Bridge Mode)',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                        color: AppTheme.spaceNavy)),
                const SizedBox(height: 16),
                FrostedCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount: _wordFrequency.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.shade100),
                    itemBuilder: (context, i) {
                      final entry = _wordFrequency.entries
                          .elementAt(i);
                      final maxCount =
                      _wordFrequency.values.first
                          .toDouble();
                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14),
                        child: Row(children: [
                        Expanded(
                        child: Text(entry.key,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                color: AppTheme
                                    .spaceNavy,
                                fontWeight:
                                FontWeight.bold)),
                      ),
                      SizedBox(
                      width: 80,
                      child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                      value: entry.value /
                      maxCount,
                      minHeight: 8,
                      backgroundColor:
                      Colors.grey.shade100,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.electricTeal),
                      ),
                      ),
                      ),
                      const SizedBox(width: 10),
                      Text('${entry.value}x',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                      fontWeight:
                      FontWeight.w700,
                      color: AppTheme
                          .spaceNavy)),
                      ]),
                      );
                    },
                  ),
                ),
              ],
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed:
              hasData ? _generatePDF : null,
              icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.white),
              label: const Text(
                  'Generate Report for Therapist',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasData
                    ? AppTheme.spaceNavy
                    : Colors.grey.shade300,
                minimumSize:
                const Size(double.infinity, 58),
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(18)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard(
      {required this.icon,
        required this.value,
        required this.label});

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.electricTeal, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(fontSize: 26)),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}