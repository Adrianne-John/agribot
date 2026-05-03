import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agribot/components/stat_card.dart';

/// Pins shown on [DetectionFieldGrid] (Firestore `pest`; UI may say Bugs).
enum FieldPinsFilter {
  all,
  weeds,
  pests,
}

/// 3 × 20 field (1-based `grid_row` / `grid_col` in Firestore).
const int fieldGridCols = 3;
const int fieldGridRows = 20;
const int _pathCol1Based = 2;

const Color _fieldGreen = Color(0xFFA5D6A7);
const Color _pathStripeGreen = Color(0xFFDCE775);

int? _parseGridIndex(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString());
}

({int row, int col})? coordsFromDetectionDoc(Map<String, dynamic> data) {
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
  if (col < 1 || col > fieldGridCols || row < 1 || row > fieldGridRows) {
    return null;
  }
  return (row: row, col: col);
}

bool detectionEliminated(Map<String, dynamic> data) {
  final e = data['eliminated'];
  if (e == true) return true;
  if (e is String && e.toLowerCase().trim() == 'true') return true;
  return false;
}

String? detectionTypeWp(Map<String, dynamic> data) =>
    data['type_wp']?.toString().toLowerCase();

Map<String, List<_MapPin>> _pinsByCellFromDocs(
  List<QueryDocumentSnapshot> docs, {
  required FieldPinsFilter filter,
  required bool showNeutralizedPins,
}) {
  final map = <String, List<_MapPin>>{};
  for (final doc in docs) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? raw : null;
    if (data == null) continue;

    final coords = coordsFromDetectionDoc(data);
    if (coords == null) continue;

    if (!showNeutralizedPins && detectionEliminated(data)) continue;

    final t = detectionTypeWp(data);
    final isWeed = t == 'weed';
    final isPest = t == 'pest' || t == 'bug' || t == 'bugs';
    if (!isWeed && !isPest) continue;

    switch (filter) {
      case FieldPinsFilter.all:
        break;
      case FieldPinsFilter.weeds:
        if (!isWeed) continue;
        break;
      case FieldPinsFilter.pests:
        if (!isPest) continue;
        break;
    }

    final key = '${coords.row}_${coords.col}';
    map.putIfAbsent(key, () => []).add(
          _MapPin(
            isWeed: isWeed,
            eliminated: detectionEliminated(data),
          ),
        );
  }
  return map;
}

/// Filter pills used above embedded maps (Data Logs expansions).
class FieldPinsFilterBar extends StatelessWidget {
  final FieldPinsFilter filter;
  final ValueChanged<FieldPinsFilter> onChanged;

  const FieldPinsFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  static const Color _brandGreen = AgriBotStatCard.brandGreen;
  static const Color _selectedBg = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _chip(
            label: 'All',
            icon: Icons.filter_alt_rounded,
            sel: FieldPinsFilter.all,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chip(
            label: 'Weeds',
            icon: Icons.eco_outlined,
            sel: FieldPinsFilter.weeds,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chip(
            label: 'Bugs',
            icon: Icons.pest_control_outlined,
            sel: FieldPinsFilter.pests,
          ),
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required FieldPinsFilter sel,
  }) {
    final selected = filter == sel;
    final foreground = selected ? Colors.white : _brandGreen;

    return Material(
      color: selected ? _selectedBg : Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: selected ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: () => onChanged(sel),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
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
              Icon(icon, color: foreground, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

/// Shorter than full 3:20 aspect so the map does not dominate the card.
const double _fieldMapHeightScale = 0.56;

/// Raster map for weeds/pests inside a bounded area (Data Logs expansions).
class DetectionFieldGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final FieldPinsFilter filter;
  final bool showNeutralizedPins;

  const DetectionFieldGrid({
    super.key,
    required this.docs,
    required this.filter,
    this.showNeutralizedPins = true,
  });

  static const Color _brandGreen = AgriBotStatCard.brandGreen;

  @override
  Widget build(BuildContext context) {
    final pins = _pinsByCellFromDocs(
      docs,
      filter: filter,
      showNeutralizedPins: showNeutralizedPins,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 2.0;
        final w = constraints.maxWidth;
        final fullProportionalH = w * fieldGridRows / fieldGridCols;
        final h = fullProportionalH * _fieldMapHeightScale;
        final cellW = (w - gap * (fieldGridCols - 1)) / fieldGridCols;
        final cellH = (h - gap * (fieldGridRows - 1)) / fieldGridRows;
        final aspect = cellW / cellH;
        final minCellEdge = math.min(cellW, cellH);
        final pestIconSize = (minCellEdge * 0.56).clamp(14.0, 21.0);
        final weedIconSize = (minCellEdge * 0.46).clamp(12.0, 18.0);
        final checkBadgeSize = (minCellEdge * 0.34).clamp(9.0, 14.0);

        return SizedBox(
          height: h,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _brandGreen.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _brandGreen.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: GridView.count(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: fieldGridCols,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                childAspectRatio: aspect,
                children:
                    List.generate(fieldGridCols * fieldGridRows, (i) {
                  final row1 = i ~/ fieldGridCols + 1;
                  final col1 = i % fieldGridCols + 1;
                  final isPathStripe = col1 == _pathCol1Based;
                  final pinsHere =
                      pins['${row1}_$col1'] ?? const <_MapPin>[];
                  return _FieldGridCell(
                    isPathStripe: isPathStripe,
                    pins: pinsHere,
                    pestIconSize: pestIconSize,
                    weedIconSize: weedIconSize,
                    checkBadgeSize: checkBadgeSize,
                  );
                }),
              ),
            ),
          ),
        );
      },
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

class _FieldGridCell extends StatelessWidget {
  final bool isPathStripe;
  final List<_MapPin> pins;
  final double pestIconSize;
  final double weedIconSize;
  final double checkBadgeSize;

  const _FieldGridCell({
    required this.isPathStripe,
    required this.pins,
    required this.pestIconSize,
    required this.weedIconSize,
    required this.checkBadgeSize,
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
                    if (i > 0) const SizedBox(width: 4),
                    _Glyph(
                      isWeed: pins[i].isWeed,
                      eliminated: pins[i].eliminated,
                      pestIconSize: pestIconSize,
                      weedIconSize: weedIconSize,
                      checkBadgeSize: checkBadgeSize,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Glyph extends StatelessWidget {
  final bool isWeed;
  final bool eliminated;
  final double pestIconSize;
  final double weedIconSize;
  final double checkBadgeSize;

  const _Glyph({
    required this.isWeed,
    required this.eliminated,
    required this.pestIconSize,
    required this.weedIconSize,
    required this.checkBadgeSize,
  });

  @override
  Widget build(BuildContext context) {
    const brandGreen = AgriBotStatCard.brandGreen;
    final ringW = math.max(1.5, weedIconSize * 0.09);
    final weedPad = weedIconSize * 0.12;

    final glyph = !isWeed
        ? Icon(
            Icons.pest_control,
            color: Colors.amber.shade800,
            size: pestIconSize,
            shadows: [
              Shadow(
                blurRadius: 3,
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(0.5, 1),
              ),
            ],
          )
        : Container(
            padding: EdgeInsets.all(weedPad),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.shade700, width: ringW),
              color: Colors.white.withValues(alpha: 0.98),
            ),
            child: Icon(
              Icons.grass_rounded,
              size: weedIconSize,
              color: Colors.green.shade900,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 0.5),
                ),
              ],
            ),
          );

    return Opacity(
      opacity: eliminated ? 0.82 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          glyph,
          if (eliminated)
            Positioned(
              right: -checkBadgeSize * 0.22,
              bottom: -checkBadgeSize * 0.22,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: brandGreen,
                  size: checkBadgeSize,
                  shadows: [
                    Shadow(
                      blurRadius: 2,
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 0.5),
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
