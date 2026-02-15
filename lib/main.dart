import 'package:flutter/material.dart';
import 'package:agribot/screens/dashboard_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriBot', // Changed title to match project
      debugShowCheckedModeBanner: false, // Removes the 'debug' banner
      theme: ThemeData(
        // Set the primary color seed to Green to match your design
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A651)),
        useMaterial3: true,
      ),
      // Point directly to your DashboardScreen
      home: const DashboardScreen(),
    );
  }
}