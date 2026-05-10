import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribot/components/header.dart';
import 'package:agribot/components/stat_card.dart';
import 'package:agribot/services/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isWeedType(String? typeWp) =>
      typeWp == 'weed' || typeWp == 'weeda' || typeWp == 'weedb';

  bool _isPestType(String? typeWp) =>
      typeWp == 'pest' || typeWp == 'bug' || typeWp == 'bugs';

  bool _matchesTypeFamily(String? typeWp, String family) {
    if (family == 'weed') return _isWeedType(typeWp);
    if (family == 'pest') return _isPestType(typeWp);
    return false;
  }

  double? _parseAccuracyPercent(dynamic raw) {
    if (raw == null) return null;
    final cleaned = raw.toString().trim().replaceAll('%', '');
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;
    if (parsed <= 1) return parsed * 100;
    return parsed;
  }

  String _formatPercent(double value) {
    final rounded1 = (value * 10).roundToDouble() / 10;
    final isWhole = rounded1 == rounded1.roundToDouble();
    return isWhole ? '${rounded1.toInt()}%' : '${rounded1.toStringAsFixed(1)}%';
  }

  String _getAverageAccuracyByType({
    required List<QueryDocumentSnapshot> docs,
    required String typeFamily,
    required String fieldName,
    bool excludeZero = false,
  }) {
    var sum = 0.0;
    var count = 0;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final typeWp = data['type_wp']?.toString().toLowerCase();
      if (!_matchesTypeFamily(typeWp, typeFamily)) continue;
      final parsed = _parseAccuracyPercent(data[fieldName]);
      if (parsed == null) continue;
      if (excludeZero && parsed <= 0) continue;
      sum += parsed;
      count++;
    }
    if (count == 0) return '0%';
    return _formatPercent(sum / count);
  }

  String _getAverageDetectionAccuracyByType(
    List<QueryDocumentSnapshot> docs,
    String typeFamily,
  ) =>
      _getAverageAccuracyByType(
        docs: docs,
        typeFamily: typeFamily,
        fieldName: 'confidence_level',
      );

  String _getAverageNeutralizationAccuracyByType(
    List<QueryDocumentSnapshot> docs,
    String typeFamily,
  ) =>
      _getAverageAccuracyByType(
        docs: docs,
        typeFamily: typeFamily,
        fieldName: 'neutralization_accuracy',
        excludeZero: true,
      );

  int _countNeutralizedByType(
    List<QueryDocumentSnapshot> docs,
    String typeFamily,
  ) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final isEliminated = data['eliminated'] == true;
      final typeWp = data['type_wp']?.toString().toLowerCase();
      final accuracy = _parseAccuracyPercent(data['neutralization_accuracy']);

      if (typeFamily == 'weed') {
        return isEliminated &&
            _matchesTypeFamily(typeWp, typeFamily) &&
            (accuracy != null && accuracy > 80);
      }

      return isEliminated && _matchesTypeFamily(typeWp, typeFamily);
    }).length;
  }

  Widget _buildTopTotalNeutralizedCard(int totalNeutralizedCount) {
    const accent = Color(0xFF00A651);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_outline, color: accent, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalNeutralizedCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total Neutralized',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Live',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeutralizationTrendCard({
    required List<QueryDocumentSnapshot> docs,
  }) {
    final byDay = <DateTime, ({int weed, int pest})>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['timestamp'];
      if (ts is! Timestamp) continue;
      final d = ts.toDate().toLocal();
      final day = DateTime(d.year, d.month, d.day);
      final t = data['type_wp']?.toString().toLowerCase();
      final eliminated = data['eliminated'] == true;
      final acc = _parseAccuracyPercent(data['neutralization_accuracy']);
      final weedOk = eliminated &&
          _isWeedType(t) &&
          acc != null &&
          acc > 80;
      final pestOk = eliminated && _isPestType(t);
      final old = byDay[day] ?? (weed: 0, pest: 0);
      byDay[day] = (
        weed: old.weed + (weedOk ? 1 : 0),
        pest: old.pest + (pestOk ? 1 : 0),
      );
    }

    final days = byDay.keys.toList()..sort();
    final weedValues = [for (final d in days) byDay[d]!.weed.toDouble()];
    final pestValues = [for (final d in days) byDay[d]!.pest.toDouble()];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Neutralized Trend',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: days.length < 2
                ? Center(
                    child: Text(
                      'Need at least 2 dates to show trend',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  )
                : CustomPaint(
                    painter: _TrendLinePainter(
                      weedValues: weedValues,
                      pestValues: pestValues,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _LegendDot(color: Colors.green, label: 'Weeds'),
              SizedBox(width: 16),
              _LegendDot(color: Colors.red, label: 'Pests'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AgriBotHeader(),
        Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firebaseService.getDetectionStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00A651),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "Error loading field data:\n${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final List<QueryDocumentSnapshot> docs =
                      FirebaseService.sortDetectionsByTimestampDesc(
                    snapshot.data!.docs,
                  );

                  final int weedNeutralizedCount =
                      _countNeutralizedByType(docs, 'weed');

                  final int pestNeutralizedCount =
                      _countNeutralizedByType(docs, 'pest');

                  final String avgWeedDetectionAccuracy =
                      _getAverageDetectionAccuracyByType(docs, 'weed');
                  final String avgPestDetectionAccuracy =
                      _getAverageDetectionAccuracyByType(docs, 'pest');
                  final String avgWeedNeutralizationAccuracy =
                      _getAverageNeutralizationAccuracyByType(docs, 'weed');
                  final String avgPestNeutralizationAccuracy =
                      _getAverageNeutralizationAccuracyByType(docs, 'pest');
                  final totalNeutralizedCount =
                      weedNeutralizedCount + pestNeutralizedCount;

                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildTopTotalNeutralizedCard(totalNeutralizedCount),

                      const SizedBox(height: 16),

                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: AgriBotStatCard(
                                icon: Icons.eco_outlined,
                                label: "Weeds Neutralized",
                                value: weedNeutralizedCount.toString(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AgriBotStatCard(
                                icon: Icons.bug_report_outlined,
                                label: "Pests Neutralized",
                                value: pestNeutralizedCount.toString(),
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: AgriBotStatCard(
                                icon: Icons.grass_outlined,
                                label: "Average Weed Detection Accuracy",
                                value: avgWeedDetectionAccuracy,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AgriBotStatCard(
                                icon: Icons.pest_control_outlined,
                                label: "Average Pest Detection Accuracy",
                                value: avgPestDetectionAccuracy,
                                color: Colors.brown,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: AgriBotStatCard(
                                icon: Icons.track_changes_outlined,
                                label: "Average Weed Neutralization Accuracy",
                                value: avgWeedNeutralizationAccuracy,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AgriBotStatCard(
                                icon: Icons.gps_fixed,
                                label: "Average Pest Neutralization Accuracy",
                                value: avgPestNeutralizationAccuracy,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildNeutralizationTrendCard(docs: docs),
                    ],
                  );
                },
              ),
            ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Waiting for Data...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Add a document in the Firestore 'detections' collection to see it here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> weedValues;
  final List<double> pestValues;

  _TrendLinePainter({
    required this.weedValues,
    required this.pestValues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 10.0;
    final plotW = size.width - pad * 2;
    final plotH = size.height - pad * 2;
    if (plotW <= 0 || plotH <= 0) return;

    final maxVal = [
      ...weedValues,
      ...pestValues,
    ].fold<double>(1, (a, b) => b > a ? b : a);

    final axisPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(pad, pad, plotW, plotH),
      axisPaint..style = PaintingStyle.stroke,
    );

    void drawLine(List<double> values, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke;
      final dot = Paint()..color = color;
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final x = pad + (plotW * i / (values.length - 1));
        final y = pad + plotH - (values[i] / maxVal * plotH);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
      for (var i = 0; i < values.length; i++) {
        final x = pad + (plotW * i / (values.length - 1));
        final y = pad + plotH - (values[i] / maxVal * plotH);
        canvas.drawCircle(Offset(x, y), 2.5, dot);
      }
    }

    drawLine(weedValues, Colors.green);
    drawLine(pestValues, Colors.red);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.weedValues != weedValues ||
        oldDelegate.pestValues != pestValues;
  }
}