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
                listenable: MapDisplaySettings.showNeutralizedOnMap,
                builder: (context, _) {
                  final showNeutralized =
                      MapDisplaySettings.showNeutralizedOnMap.value;
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
  return docs.where((doc) {
    final raw = doc.data();
    if (raw is! Map<String, dynamic>) return false;
    final eliminated = raw['eliminated'] == true;
    final tw = raw['type_wp']?.toString().toLowerCase();
    return eliminated && tw == typeWp;
  }).length;
}

class _DailyRunExpansionCard extends StatefulWidget {
  final int runNumber;
  final DateTime? day;
  final List<QueryDocumentSnapshot> docs;
  final bool showNeutralizedOnMap;

  const _DailyRunExpansionCard({
    required this.runNumber,
    required this.day,
    required this.docs,
    required this.showNeutralizedOnMap,
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
            FieldPinsFilterBar(
              filter: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 10),
            DetectionFieldGrid(
              docs: widget.docs,
              filter: _filter,
              showNeutralizedPins: widget.showNeutralizedOnMap,
            ),
          ],
        ),
      ),
    );
  }
}
