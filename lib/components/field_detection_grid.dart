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
const int _gridRowStep = 5;
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
  if (col < 1 || col > fieldGridCols || row < 1) {
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

bool isWeedType(String? typeWp) =>
    typeWp == 'weed' || typeWp == 'weeda' || typeWp == 'weedb';

bool isPestType(String? typeWp) =>
    typeWp == 'pest' || typeWp == 'bug' || typeWp == 'bugs';

double? _parseAccuracyPercent(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.trim().replaceAll('%', '');
  final parsed = double.tryParse(cleaned);
  if (parsed == null) return null;
  if (parsed <= 1) return parsed * 100;
  return parsed;
}

int _rowsForDocs(List<QueryDocumentSnapshot> docs) {
  var maxRow = 0;
  for (final doc in docs) {
    final raw = doc.data();
    if (raw is! Map<String, dynamic>) continue;
    final coords = coordsFromDetectionDoc(raw);
    if (coords == null) continue;
    if (coords.row > maxRow) maxRow = coords.row;
  }
  final safeMax = maxRow <= 0 ? _gridRowStep : maxRow;
  return ((safeMax + _gridRowStep - 1) ~/ _gridRowStep) * _gridRowStep;
}

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
    final isWeed = isWeedType(t);
    final isPest = isPestType(t);
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
            timestamp: data['timestamp'],
            typeWp: t,
            neutralizationAccuracy:
                data['neutralization_accuracy']?.toString().trim(),
            neutralizationAccuracyPercent: _parseAccuracyPercent(
              data['neutralization_accuracy']?.toString(),
            ),
            imageUrl: data['img']?.toString().trim(),
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
const double _fieldMapHeightScale = 0.5;

/// Raster map for weeds/pests inside a bounded area (Data Logs expansions).
class DetectionFieldGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final FieldPinsFilter filter;
  final bool showNeutralizedPins;
  final bool showStatusBadges;

  const DetectionFieldGrid({
    super.key,
    required this.docs,
    required this.filter,
    this.showNeutralizedPins = true,
    this.showStatusBadges = true,
  });

  static const Color _brandGreen = AgriBotStatCard.brandGreen;

  @override
  Widget build(BuildContext context) {
    final fieldGridRows = _rowsForDocs(docs);
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
        final pestIconSize = (minCellEdge * 0.55).clamp(12.0, 19.0);
        final weedIconSize = (minCellEdge * 0.48).clamp(11.0, 17.0);
        final checkBadgeSize = (minCellEdge * 0.32).clamp(8.0, 13.0);

        return SizedBox(
          height: h,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _brandGreen.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _brandGreen.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
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
                    showStatusBadges: showStatusBadges,
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
  final dynamic timestamp;
  final String? typeWp;
  final String? neutralizationAccuracy;
  final double? neutralizationAccuracyPercent;
  final String? imageUrl;

  const _MapPin({
    required this.isWeed,
    required this.eliminated,
    this.timestamp,
    this.typeWp,
    this.neutralizationAccuracy,
    this.neutralizationAccuracyPercent,
    this.imageUrl,
  });
}

class _FieldGridCell extends StatelessWidget {
  final bool isPathStripe;
  final List<_MapPin> pins;
  final double pestIconSize;
  final double weedIconSize;
  final double checkBadgeSize;
  final bool showStatusBadges;

  const _FieldGridCell({
    required this.isPathStripe,
    required this.pins,
    required this.pestIconSize,
    required this.weedIconSize,
    required this.checkBadgeSize,
    required this.showStatusBadges,
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
                      pin: pins[i],
                      isWeed: pins[i].isWeed,
                      eliminated: pins[i].eliminated,
                      pestIconSize: pestIconSize,
                      weedIconSize: weedIconSize,
                      checkBadgeSize: checkBadgeSize,
                      showStatusBadges: showStatusBadges,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Glyph extends StatelessWidget {
  final _MapPin pin;
  final bool isWeed;
  final bool eliminated;
  final double pestIconSize;
  final double weedIconSize;
  final double checkBadgeSize;
  final bool showStatusBadges;

  const _Glyph({
    required this.pin,
    required this.isWeed,
    required this.eliminated,
    required this.pestIconSize,
    required this.weedIconSize,
    required this.checkBadgeSize,
    required this.showStatusBadges,
  });

  String _categoryFromType(String? typeWp) {
    switch (typeWp) {
      case 'weeda':
        return 'A';
      case 'weedb':
        return 'B';
      case 'pest':
      case 'bug':
      case 'bugs':
        return 'Pest';
      default:
        return isWeed ? 'Unknown' : 'Pest';
    }
  }

  String? _toDirectGoogleDriveImage(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (!uri.host.contains('drive.google.com')) return url;
    final segments = uri.pathSegments;
    final fileIndex = segments.indexOf('d');
    if (fileIndex != -1 && fileIndex + 1 < segments.length) {
      final id = segments[fileIndex + 1];
      if (id.isNotEmpty) {
        return 'https://drive.google.com/uc?export=view&id=$id';
      }
    }
    final id = uri.queryParameters['id'];
    if (id != null && id.isNotEmpty) {
      return 'https://drive.google.com/uc?export=view&id=$id';
    }
    return url;
  }

  Future<void> _showWeedPopup(BuildContext context) async {
    final typeLabel = _categoryFromType(pin.typeWp);
    final accuracy = (pin.neutralizationAccuracy ?? '').isEmpty
        ? 'N/A'
        : pin.neutralizationAccuracy!;
    final imageUrl = _toDirectGoogleDriveImage(pin.imageUrl);
    final titleText = isWeed ? 'Weed Detection' : 'Pest Detection';
    final typePrefix = isWeed ? 'Weed Type' : 'Pest Type';
    final iconColor = isWeed ? Colors.green.shade800 : Colors.amber.shade800;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: AgriBotStatCard.brandGreen.withValues(alpha: 0.35),
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          title: Row(
            children: [
              Icon(
                isWeed ? Icons.grass_rounded : Icons.pest_control,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Text(
                titleText,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$typePrefix: $typeLabel',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Laser Accuracy: $accuracy',
                        style: TextStyle(
                          color: Colors.grey.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 260,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl == null || imageUrl.isEmpty
                      ? Center(
                          child: Text(
                            'No image available',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) {
                            return Center(
                              child: Text(
                                'Image could not be loaded',
                                style: TextStyle(color: Colors.grey.shade700),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

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

    final isLowAccuracyEliminated =
        eliminated && (pin.neutralizationAccuracyPercent ?? 100) < 80;
    final isNotEliminated = !eliminated;

    Widget? statusBadge;
    if (isNotEliminated) {
      statusBadge = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.yellow.shade700,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Icon(
          Icons.remove,
          color: Colors.black87,
          size: checkBadgeSize,
        ),
      );
    } else if (isLowAccuracyEliminated) {
      statusBadge = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.shade700,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Icon(
          Icons.close,
          color: Colors.white,
          size: checkBadgeSize * 0.9,
        ),
      );
    } else if (eliminated) {
      statusBadge = Container(
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
      );
    }

    return GestureDetector(
      onTap: () => _showWeedPopup(context),
      child: Opacity(
        opacity: eliminated ? 0.82 : 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            glyph,
            if (showStatusBadges && statusBadge != null)
              Positioned(
                right: -checkBadgeSize * 0.22,
                bottom: -checkBadgeSize * 0.22,
                child: statusBadge,
              ),
          ],
        ),
      ),
    );
  }
}
