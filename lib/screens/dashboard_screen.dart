import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribot/components/header.dart';
import 'package:agribot/components/stat_card.dart';
import 'package:agribot/services/firebase_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getLatestConfidenceByType(
    List<QueryDocumentSnapshot> docs,
    String type,
  ) {
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final typeWp = data['type_wp']?.toString().toLowerCase();
      final confidence = data['confidence_level']?.toString();

      if (typeWp == type && confidence != null && confidence.isNotEmpty) {
        return confidence;
      }
    }

    return "0%";
  }

  int _countNeutralizedByType(
    List<QueryDocumentSnapshot> docs,
    String type,
  ) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final isEliminated = data['eliminated'] == true;
      final typeWp = data['type_wp']?.toString().toLowerCase();

      return isEliminated && typeWp == type;
    }).length;
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

                  final String latestWeedConfidence =
                      _getLatestConfidenceByType(docs, 'weed');

                  final String latestPestConfidence =
                      _getLatestConfidenceByType(docs, 'pest');

                  final bool hasData =
                      weedNeutralizedCount > 0 || pestNeutralizedCount > 0;

                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // IntrinsicHeight: ListView gives unbounded vertical space; stretch
                      // needs a finite cross-axis — wrap so rows don't get infinite height.
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            Expanded(
                              child: AgriBotStatCard(
                                icon: Icons.battery_charging_full,
                                value: "85%",
                                label: "Battery",
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: AgriBotStatCard(
                                icon: Icons.wifi,
                                value: "ON",
                                label: "Sync Mode",
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
                                label: "Latest Weed Accuracy",
                                value: latestWeedConfidence,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AgriBotStatCard(
                                icon: Icons.pest_control_outlined,
                                label: "Latest Pest Accuracy",
                                value: latestPestConfidence,
                                color: Colors.brown,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildAlertBox(hasData),
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

  Widget _buildAlertBox(bool hasData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasData ? const Color(0xFFFFF54F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Icon(
            hasData ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 40,
            color: hasData ? Colors.black54 : Colors.green,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasData ? "System Monitoring" : "System Idle",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasData
                      ? "Actively processing weed and pest detections."
                      : "Standing by. Deploy AgriBot to begin.",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}