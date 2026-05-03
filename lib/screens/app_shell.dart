import 'package:flutter/material.dart';
import 'package:agribot/components/footer.dart';
import 'package:agribot/screens/dashboard_screen.dart';
import 'package:agribot/screens/data_logs_screen.dart';
import 'package:agribot/screens/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            DashboardScreen(),
            DataLogsScreen(),
            SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: AgriBotFooter(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
