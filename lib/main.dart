import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
import 'package:agribot/screens/dashboard_screen.dart';

void main() async {
  // Required for Firebase initialization
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriBot Dashboard',
      debugShowCheckedModeBanner: false, // Removes the red "Debug" banner
      theme: ThemeData(
        // Using Green as the seed color to match your AgriBot brand
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A651)),
        useMaterial3: true,
        // Optional: Force a light theme for better contrast with your mountain design
        brightness: Brightness.light,
      ),
      // This is where your app starts
      home: const DashboardScreen(),
    );
  }
}