import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:agribot/screens/app_shell.dart';
import 'package:agribot/services/map_display_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await FirebaseAuth.instance.signInAnonymously();
  } on FirebaseAuthException catch (e) {
    // Web / production projects often disable Anonymous sign-in; Firestore rules may
    // still allow reads. See: Firebase Console → Authentication → Sign-in method.
    if (kDebugMode && e.code == 'admin-restricted-operation') {
      debugPrint(
        'Firebase Auth anonymous sign-in is disabled (${e.code}). '
        'Enable Anonymous authentication in Firebase Console, or loosen Firestore rules for development.',
      );
    }
  }

  await MapDisplaySettings.load();

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
      home: const AppShell(),
    );
  }
}