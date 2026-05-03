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
                            ? 'Treated items stay on the grid (slightly faded, with a check).'
                            : 'Hide treated items so only active detections appear.',
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
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.grid_on_outlined, color: _green),
                      title: const Text(
                        'Field layout',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '3 columns × 20 rows (1-based grid_row / grid_col). '
                        'The middle column is the equipment path.',
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
                        subtitle: 'Firestore type_wp: weed',
                      ),
                      const Divider(height: 1),
                      _legendRow(
                        icon: Icons.pest_control,
                        iconColor: Colors.amber.shade800,
                        title: 'Pest / bug',
                        subtitle: 'Firestore type_wp: pest (shown as “Bugs”)',
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
                    ListTile(
                      leading: Icon(Icons.help_outline, color: _green),
                      title: const Text(
                        'Something look wrong?',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Confirm Anonymous sign-in and Firestore rules in the '
                        'Firebase console if lists stay empty.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
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
    required String subtitle,
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
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
      ),
    );
  }
}
