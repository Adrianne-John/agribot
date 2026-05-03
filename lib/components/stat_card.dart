import 'package:flutter/material.dart';

class AgriBotStatCard extends StatelessWidget {
  /// Matches AgriBotHeader background.
  static const Color brandGreen = Color(0xFF00A651);

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isFullWidth; // To switch between Small and Big card styles

  const AgriBotStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = brandGreen,
    this.isFullWidth = false,
  });

  static const double _smallCardMinHeight = 152;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: isFullWidth
          ? null
          : const BoxConstraints(minHeight: _smallCardMinHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: brandGreen,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: brandGreen.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isFullWidth ? _buildBigLayout() : _buildSmallLayout(),
    );
  }

  // Layout for Weeds/Pests (Wide)
  Widget _buildBigLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // Layout for Battery / neutralized counts / accuracy (compact, uniform tiles)
  Widget _buildSmallLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 12),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}