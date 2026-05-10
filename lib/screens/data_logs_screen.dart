import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agribot/components/field_detection_grid.dart';
import 'package:agribot/components/header.dart';
import 'package:agribot/components/stat_card.dart';
import 'package:agribot/services/firebase_service.dart';
import 'package:agribot/services/map_display_settings.dart';

class DataLogsScreen extends StatelessWidget {
  const DataLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AgriBotHeader(subtitle: 'Data Logs'),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: svc.getDetectionStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AgriBotStatCard.brandGreen,
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Could not load logs:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No detections yet.\nRuns appear here grouped by calendar day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }

              final rawDocs = snapshot.data!.docs.cast<QueryDocumentSnapshot>();
              final grouped = _groupDocsByCalendarDay(rawDocs);

              return ListenableBuilder(
                listenable: Listenable.merge([
                  MapDisplaySettings.showNeutralizedOnMap,
                  MapDisplaySettings.showStatusBadgesOnMap,
                ]),
                builder: (context, _) {
                  final showNeutralized =
                      MapDisplaySettings.showNeutralizedOnMap.value;
                  final showStatusBadges =
                      MapDisplaySettings.showStatusBadgesOnMap.value;
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: grouped.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final runNumber = index + 1;
                      final day = grouped[index].day;
                      final docs = grouped[index].docs;
                      return _DailyRunExpansionCard(
                        runNumber: runNumber,
                        day: day,
                        docs: docs,
                        showNeutralizedOnMap: showNeutralized,
                        showStatusBadgesOnMap: showStatusBadges,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayGroup {
  final DateTime? day;
  final List<QueryDocumentSnapshot> docs;

  _DayGroup({required this.day, required this.docs});
}

List<_DayGroup> _groupDocsByCalendarDay(
  List<QueryDocumentSnapshot> docs,
) {
  final map = <DateTime?, List<QueryDocumentSnapshot>>{};
  for (final doc in docs) {
    final dayKey = _calendarDayFromDoc(doc);
    map.putIfAbsent(dayKey, () => []).add(doc);
  }

  final keys = map.keys.toList();
  keys.sort((a, b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  });

  return [
    for (final k in keys)
      _DayGroup(day: k, docs: map[k]!),
  ];
}

/// Local calendar date from document [timestamp]; `null` if missing.
DateTime? _calendarDayFromDoc(QueryDocumentSnapshot doc) {
  final raw = doc.data();
  if (raw is! Map<String, dynamic>) return null;
  final t = raw['timestamp'];
  if (t is! Timestamp) return null;
  final d = t.toDate().toLocal();
  return DateTime(d.year, d.month, d.day);
}

String _formatDateOnly(DateTime d) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

int _countNeutralized(List<QueryDocumentSnapshot> docs, String typeWp) {
  double? parseAccuracyPercent(dynamic raw) {
    if (raw == null) return null;
    final cleaned = raw.toString().trim().replaceAll('%', '');
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;
    if (parsed <= 1) return parsed * 100;
    return parsed;
  }

  bool matchesFamily(String? value) {
    if (typeWp == 'weed') {
      return value == 'weed' || value == 'weeda' || value == 'weedb';
    }
    if (typeWp == 'pest') {
      return value == 'pest' || value == 'bug' || value == 'bugs';
    }
    return value == typeWp;
  }

  return docs.where((doc) {
    final raw = doc.data();
    if (raw is! Map<String, dynamic>) return false;
    final eliminated = raw['eliminated'] == true;
    final tw = raw['type_wp']?.toString().toLowerCase();
    final accuracy = parseAccuracyPercent(raw['neutralization_accuracy']);
    if (typeWp == 'weed') {
      return eliminated && matchesFamily(tw) && (accuracy != null && accuracy > 80);
    }
    return eliminated && matchesFamily(tw);
  }).length;
}

double? _parseAccuracyPercent(dynamic raw) {
  if (raw == null) return null;
  final cleaned = raw.toString().trim().replaceAll('%', '');
  final parsed = double.tryParse(cleaned);
  if (parsed == null) return null;
  if (parsed <= 1) return parsed * 100;
  return parsed;
}

bool _matchesTypeFamily(String? tw, String typeFamily) {
  if (typeFamily == 'weed') {
    return tw == 'weed' || tw == 'weeda' || tw == 'weedb';
  }
  if (typeFamily == 'pest') {
    return tw == 'pest' || tw == 'bug' || tw == 'bugs';
  }
  return false;
}

String _formatPercent(double value) {
  final rounded1 = (value * 10).roundToDouble() / 10;
  final isWhole = rounded1 == rounded1.roundToDouble();
  return isWhole ? '${rounded1.toInt()}%' : '${rounded1.toStringAsFixed(1)}%';
}

String _averageAccuracyForRun({
  required List<QueryDocumentSnapshot> docs,
  required String typeFamily,
  required String fieldName,
  bool excludeZero = false,
}) {
  var sum = 0.0;
  var count = 0;
  for (final doc in docs) {
    final raw = doc.data();
    if (raw is! Map<String, dynamic>) continue;
    final tw = raw['type_wp']?.toString().toLowerCase();
    if (!_matchesTypeFamily(tw, typeFamily)) continue;
    final val = _parseAccuracyPercent(raw[fieldName]);
    if (val == null) continue;
    if (excludeZero && val <= 0) continue;
    sum += val;
    count++;
  }
  if (count == 0) return '0%';
  return _formatPercent(sum / count);
}

class _DailyRunExpansionCard extends StatefulWidget {
  final int runNumber;
  final DateTime? day;
  final List<QueryDocumentSnapshot> docs;
  final bool showNeutralizedOnMap;
  final bool showStatusBadgesOnMap;

  const _DailyRunExpansionCard({
    required this.runNumber,
    required this.day,
    required this.docs,
    required this.showNeutralizedOnMap,
    required this.showStatusBadgesOnMap,
  });

  @override
  State<_DailyRunExpansionCard> createState() => _DailyRunExpansionCardState();
}

class _DailyRunExpansionCardState extends State<_DailyRunExpansionCard> {
  FieldPinsFilter _filter = FieldPinsFilter.all;

  @override
  Widget build(BuildContext context) {
    final green = AgriBotStatCard.brandGreen;
    final dateLabel = widget.day != null
        ? _formatDateOnly(widget.day!)
        : 'Unknown date';

    final weedCount = _countNeutralized(widget.docs, 'weed');
    final pestCount = _countNeutralized(widget.docs, 'pest');
    final avgWeedDetection = _averageAccuracyForRun(
      docs: widget.docs,
      typeFamily: 'weed',
      fieldName: 'confidence_level',
    );
    final avgPestDetection = _averageAccuracyForRun(
      docs: widget.docs,
      typeFamily: 'pest',
      fieldName: 'confidence_level',
    );
    final avgWeedNeutralization = _averageAccuracyForRun(
      docs: widget.docs,
      typeFamily: 'weed',
      fieldName: 'neutralization_accuracy',
      excludeZero: true,
    );
    final avgPestNeutralization = _averageAccuracyForRun(
      docs: widget.docs,
      typeFamily: 'pest',
      fieldName: 'neutralization_accuracy',
      excludeZero: true,
    );

    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AgriBotStatCard.brandGreen,
          width: 1.5,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          initiallyExpanded: false,
          iconColor: green,
          collapsedIconColor: green,
          title: Text(
            'Run ${widget.runNumber}:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 18, color: green.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: green.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AgriBotStatCard(
                      icon: Icons.eco_outlined,
                      label: 'Weeds Neutralized',
                      value: weedCount.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AgriBotStatCard(
                      icon: Icons.bug_report_outlined,
                      label: 'Pests Neutralized',
                      value: pestCount.toString(),
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AgriBotStatCard(
                      icon: Icons.grass_outlined,
                      label: 'Average Weed Detection Accuracy',
                      value: avgWeedDetection,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AgriBotStatCard(
                      icon: Icons.pest_control_outlined,
                      label: 'Average Pest Detection Accuracy',
                      value: avgPestDetection,
                      color: Colors.brown,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AgriBotStatCard(
                      icon: Icons.track_changes_outlined,
                      label: 'Average Weed Neutralization Accuracy',
                      value: avgWeedNeutralization,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AgriBotStatCard(
                      icon: Icons.gps_fixed,
                      label: 'Average Pest Neutralization Accuracy',
                      value: avgPestNeutralization,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FieldPinsFilterBar(
              filter: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 10),
            DetectionFieldGrid(
              docs: widget.docs,
              filter: _filter,
              showNeutralizedPins: widget.showNeutralizedOnMap,
              showStatusBadges: widget.showStatusBadgesOnMap,
            ),
          ],
        ),
      ),
    );
  }
}
