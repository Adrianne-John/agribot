import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agribot/components/header.dart';
import 'package:agribot/components/stat_card.dart';
import 'package:agribot/services/map_display_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _green = AgriBotStatCard.brandGreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AgriBotHeader(subtitle: 'Settings'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _sectionLabel('Map & data'),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _green.withValues(alpha: 0.35)),
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: MapDisplaySettings.showNeutralizedOnMap,
                  builder: (context, showNeutralized, _) {
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: const Text(
                        'Show neutralized on field map',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        showNeutralized
                            ? 'Shows both active and neutralized detections on the map.'
                            : 'Hides neutralized detections and shows active ones only.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      value: showNeutralized,
                      activeThumbColor: Colors.white,
                      activeTrackColor: _green,
                      onChanged: (v) =>
                          MapDisplaySettings.setShowNeutralizedOnMap(v),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _green.withValues(alpha: 0.35)),
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: MapDisplaySettings.showStatusBadgesOnMap,
                  builder: (context, showBadges, _) {
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: const Text(
                        'Show map status badges',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        showBadges
                            ? 'Displays -, X, and check badges on icons.'
                            : 'Hides status badges and keeps only weed/pest icons.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      value: showBadges,
                      activeThumbColor: Colors.white,
                      activeTrackColor: _green,
                      onChanged: (v) =>
                          MapDisplaySettings.setShowStatusBadgesOnMap(v),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _green.withValues(alpha: 0.35)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.cloud_sync_outlined, color: _green),
                      title: const Text(
                        'Live Firestore sync',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Detection runs update automatically when your backend '
                        'writes to the configured collection.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _sectionLabel('Map legend'),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _green.withValues(alpha: 0.35)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _legendRow(
                        icon: Icons.grass_rounded,
                        iconColor: Colors.green.shade900,
                        iconBg: Colors.white,
                        ring: Border.all(color: Colors.red.shade700, width: 2),
                        title: 'Weed',
                      ),
                      const Divider(height: 1),
                      _legendRow(
                        icon: Icons.pest_control,
                        iconColor: Colors.amber.shade800,
                        title: 'Pest / bug',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _green.withValues(alpha: 0.35)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _legendRow(
                        icon: Icons.remove,
                        iconColor: Colors.black87,
                        iconBg: Colors.yellow.shade700,
                        title: 'Can\'t Neutralize',
                      ),
                      const Divider(height: 1),
                      _legendRow(
                        icon: Icons.close,
                        iconColor: Colors.white,
                        iconBg: Colors.red.shade700,
                        title: 'Low neutralization',
                      ),
                      const Divider(height: 1),
                      _legendRow(
                        icon: Icons.check_circle,
                        iconColor: _green,
                        iconBg: Colors.white,
                        title: 'Neutralized',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _sectionLabel('Session'),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _green.withValues(alpha: 0.35)),
                ),
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final signedIn = user != null;
                    final anon = user?.isAnonymous ?? false;
                    final detail = !signedIn
                        ? 'Not signed in. Firestore may still be readable depending on rules.'
                        : anon
                            ? 'Anonymous Firebase session (typical for this demo app).'
                            : () {
                                final id = user.uid;
                                final short = id.length > 12
                                    ? '${id.substring(0, 8)}…'
                                    : id;
                                return 'Signed in as $short.';
                              }();

                    return ListTile(
                      leading: Icon(
                        signedIn ? Icons.verified_user_outlined : Icons.lock_open_outlined,
                        color: _green,
                      ),
                      title: Text(
                        signedIn ? 'Firebase authentication' : 'Authentication',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        detail,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              _sectionLabel('About'),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _green.withValues(alpha: 0.35)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.agriculture_outlined, color: _green),
                          const SizedBox(width: 10),
                          const Text(
                            'AgriBot',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Version 1.0.0 · Build 1',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Companion dashboard for autonomous field monitoring. '
                        'Counts and maps reflect documents from your detection stream.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showAboutDialog(context),
                          icon: const Icon(Icons.info_outline),
                          label: const Text('About this application'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _green,
                            side: BorderSide(color: _green.withValues(alpha: 0.6)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _green.withValues(alpha: 0.35)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.health_and_safety_outlined, color: _green),
                      title: const Text(
                        'System diagnostics',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Core services report healthy status.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statusChip('Firebase', true),
                          _statusChip('Field Mapping', true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: _green.withValues(alpha: 0.35)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.storage_outlined, color: _green),
                      title: const Text(
                        'Local preferences',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Map options are stored only on this device.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'AgriBot · Field operations toolkit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _green.withValues(alpha: 0.85),
        letterSpacing: 0.4,
      ),
    );
  }

  static Widget _legendRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? iconBg,
    BoxBorder? ring,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconBg ?? Colors.amber.shade50,
          border: ring,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  static Widget _statusChip(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ok ? _green.withValues(alpha: 0.35) : Colors.orange.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.error_outline,
            color: ok ? _green : Colors.orange.shade700,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showAboutDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _green.withValues(alpha: 0.3)),
          ),
          title: Row(
            children: [
              Icon(Icons.agriculture_outlined, color: _green),
              const SizedBox(width: 8),
              const Text('About AgriBot'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'AgriBot is an operational monitoring application built to '
                  'receive and present run data from autonomous field activities.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(height: 1.45),
                ),
                SizedBox(height: 10),
                Text(
                  'It centralizes detections, map positions, neutralization outcomes, '
                  'and confidence/accuracy values so operators can quickly review '
                  'performance and make informed interventions.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(height: 1.45),
                ),
                SizedBox(height: 10),
                Text(
                  'The interface is optimized for live Firebase-backed updates, '
                  'daily run summaries, and actionable field status indicators.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(height: 1.45),
                ),
                SizedBox(height: 10),
                Text(
                  'Primary capabilities include field-map visualization by grid '
                  'position, weed/pest categorization, neutralization-quality '
                  'evaluation, and image-assisted detection review for operators.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(height: 1.45),
                ),
                SizedBox(height: 10),
                Text(
                  'AgriBot supports data-driven decision making by organizing '
                  'raw detection logs into operational insights that can be used '
                  'for reporting, auditing, and intervention planning.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(height: 1.45),
                ),
                SizedBox(height: 10),
                Text(
                  'This application is designed as a professional control '
                  'interface for real-time agricultural robotics workflows.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(height: 1.45),
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
}
