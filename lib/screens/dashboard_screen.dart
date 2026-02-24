import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribot/components/header.dart';
import 'package:agribot/components/footer.dart';
import 'package:agribot/components/stat_card.dart';
import 'package:agribot/services/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // Light green background
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER COMPONENT ---
            const AgriBotHeader(),

            // --- MAIN DASHBOARD CONTENT (Real-time) ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firebaseService.getDetectionStream(),
                builder: (context, snapshot) {
                  // 1. Handle Loading State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00A651)),
                    );
                  }

                  // 2. Handle Errors
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading field data"));
                  }

                  // 3. Handle Empty Database (No dummy data yet)
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  // 4. Data Processing
                  final List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                  
                  // Count total neutralized weeds
                  int neutralizedCount = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['eliminated'] == true;
                  }).length;

                  // Get the confidence level of the most recent weed detection
                  final latestData = docs.first.data() as Map<String, dynamic>;
                  String latestConfidence = latestData['confidence_level'] ?? "0%";

                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Row 1: Hardware Status
                      Row(
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
                      const SizedBox(height: 16),

                      // Row 2: Weeds Neutralized (Dynamic)
                      AgriBotStatCard(
                        icon: Icons.eco_outlined,
                        label: "Weeds Neutralized",
                        value: neutralizedCount.toString(),
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),

                      // Row 3: Latest Detection Confidence (Dynamic)
                      AgriBotStatCard(
                        icon: Icons.track_changes,
                        label: "Latest Accuracy",
                        value: latestConfidence,
                        isFullWidth: true,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(height: 16),

                      // Row 4: Alert Box
                      _buildAlertBox(neutralizedCount > 0),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      bottomNavigationBar: AgriBotFooter(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  // UI for when there is no data in Firestore
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Waiting for Data...",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
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

  // Yellow alert box logic
  Widget _buildAlertBox(bool hasData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasData ? const Color(0xFFFFF54F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  hasData 
                    ? "Actively processing field detections." 
                    : "Standing by. Deploy AgriBot to begin.",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}