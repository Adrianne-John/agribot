import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribot/components/header.dart';
import 'package:agribot/services/firebase_service.dart';

/// Filter chips: All (both), Weeds, Bugs UI label (Firestore: `pest`).
enum _FieldMapFilter { all, weeds, pests }

/// Field grid for map UI and Firestore: 3 columns × 20 rows (1-based indexing in DB).
const int _gridCols = 3;
const int _gridRows = 20;

/// Middle column ("path" stripe) — 1-based column **2** when there are 3 columns.
const int _pathCol1Based = 2;

/// Cell fill when not center path stripe.
const Color _fieldGreen = Color(0xFFA5D6A7);

/// Lighter stripe for central column.
const Color _pathStripeGreen = Color(0xFFDCE775);

const Color _brandGreen = Color(0xFF00A651);
const Color _filterSelectedBg = Color(0xFF1B5E20);

class FieldMapScreen extends StatefulWidget {
  const FieldMapScreen({super.key});

  @override
  State<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends State<FieldMapScreen> {
  final FirebaseService _firebase = FirebaseService();
  _FieldMapFilter _filter = _FieldMapFilter.all;

  static int? _parseGridIndex(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }

  /// Returns canonical 1-based row/col if in range, else null.
  static ({int row, int col})? _coordsFromDoc(Map<String, dynamic> data) {
    final col = _parseGridIndex(
          data['grid_col'] ??
              data['gridCol'] ??
              data['field_col'] ??
              data['col'] ??
              data['column'],
        ) ??
        _parseGridIndex(data['x']);
    final row = _parseGridIndex(
          data['grid_row'] ??
              data['gridRow'] ??
              data['field_row'] ??
              data['row'] ??
              data['y'],
        );
    if (col == null || row == null) return null;
    if (col < 1 ||
        col > _gridCols ||
        row < 1 ||
        row > _gridRows) {
      return null;
    }
    return (row: row, col: col);
  }

  /// True when neutralized — still drawn on map, styled differently.
  static bool _eliminated(Map<String, dynamic> data) {
    final e = data['eliminated'];
    if (e == true) return true;
    if (e is String && e.toLowerCase().trim() == 'true') return true;
    return false;
  }

  static String? _typeWp(Map<String, dynamic> data) {
    return data['type_wp']?.toString().toLowerCase();
  }

  Map<String, List<_MapPin>> _pinsByCellKey(
    List<QueryDocumentSnapshot> docs,
  ) {
    final map = <String, List<_MapPin>>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final coords = _coordsFromDoc(data);
      if (coords == null) continue;

      final t = _typeWp(data);
      final isWeed = t == 'weed';
      final isPest = t == 'pest' || t == 'bug' || t == 'bugs';
      if (!isWeed && !isPest) continue;

      bool include = false;
      switch (_filter) {
        case _FieldMapFilter.all:
          include = true;
          break;
        case _FieldMapFilter.weeds:
          include = isWeed;
          break;
        case _FieldMapFilter.pests:
          include = isPest;
          break;
      }
      if (!include) continue;

      final key = '${coords.row}_${coords.col}';
      map.putIfAbsent(key, () => []).add(
            _MapPin(
              isWeed: isWeed,
              eliminated: _eliminated(data),
            ),
          );
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AgriBotHeader(subtitle: 'Field Health Map'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _FilterChip(
                  label: 'All',
                  icon: Icons.filter_alt_rounded,
                  selected: _filter == _FieldMapFilter.all,
                  onTap: () => setState(() => _filter = _FieldMapFilter.all),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterChip(
                  label: 'Weeds',
                  icon: Icons.eco_outlined,
                  selected: _filter == _FieldMapFilter.weeds,
                  onTap: () => setState(() => _filter = _FieldMapFilter.weeds),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterChip(
                  label: 'Bugs',
                  icon: Icons.pest_control_outlined,
                  selected: _filter == _FieldMapFilter.pests,
                  onTap: () => setState(() => _filter = _FieldMapFilter.pests),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _brandGreen.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _brandGreen.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firebase.getDetectionStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Could not load map:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final waitingInitial = snapshot.connectionState ==
                            ConnectionState.waiting &&
                        !snapshot.hasData;

                    if (waitingInitial ||
                        snapshot.connectionState == ConnectionState.none) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: _brandGreen,
                        ),
                      );
                    }

                    final docs =
                        snapshot.data!.docs.cast<QueryDocumentSnapshot>();
                    final pins = _pinsByCellKey(docs);

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 2.0;
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        final cellW =
                            (w - gap * (_gridCols - 1)) / _gridCols;
                        final cellH =
                            (h - gap * (_gridRows - 1)) / _gridRows;
                        final aspect = cellW / cellH;

                        return GridView.count(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: _gridCols,
                          mainAxisSpacing: gap,
                          crossAxisSpacing: gap,
                          childAspectRatio: aspect,
                          children: List.generate(_gridCols * _gridRows, (i) {
                            final row1 = i ~/ _gridCols + 1;
                            final col1 = i % _gridCols + 1;
                            final isPathStripe = col1 == _pathCol1Based;
                            final pinsHere =
                                pins['${row1}_$col1'] ?? const <_MapPin>[];
                            return _FieldCell(
                              isPathStripe: isPathStripe,
                              pins: pinsHere,
                            );
                          }),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? _filterSelectedBg : Colors.white;
    final foreground = selected ? Colors.white : _brandGreen;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      elevation: selected ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : _brandGreen.withValues(alpha: 0.65),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPin {
  final bool isWeed;
  final bool eliminated;

  const _MapPin({
    required this.isWeed,
    required this.eliminated,
  });
}

class _FieldCell extends StatelessWidget {
  final bool isPathStripe;
  final List<_MapPin> pins;

  const _FieldCell({
    required this.isPathStripe,
    required this.pins,
  });

  @override
  Widget build(BuildContext context) {
    final bg =
        isPathStripe ? _pathStripeGreen.withValues(alpha: 0.9) : _fieldGreen;

    return Container(
      color: bg,
      alignment: Alignment.center,
      child: pins.isEmpty
          ? null
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pins.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    _MapGlyph(
                      isWeed: pins[i].isWeed,
                      eliminated: pins[i].eliminated,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _MapGlyph extends StatelessWidget {
  final bool isWeed;
  final bool eliminated;

  const _MapGlyph({
    required this.isWeed,
    required this.eliminated,
  });

  @override
  Widget build(BuildContext context) {
    final glyph = !isWeed
        ? Icon(
            Icons.pest_control,
            color: Colors.amber.shade700,
            size: 24,
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black.withValues(alpha: 0.35),
                offset: const Offset(0.5, 1),
              ),
            ],
          )
        : Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.shade700, width: 2),
              color: Colors.white.withValues(alpha: 0.92),
            ),
            child: Icon(
              Icons.grass_rounded,
              size: 20,
              color: Colors.green.shade800,
            ),
          );

    return Opacity(
      opacity: eliminated ? 0.5 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          glyph,
          if (eliminated)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: _brandGreen,
                  size: 14,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
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
