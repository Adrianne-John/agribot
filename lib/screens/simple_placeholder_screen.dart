import 'package:flutter/material.dart';
import 'package:agribot/components/header.dart';

class SimplePlaceholderScreen extends StatelessWidget {
  final String headerSubtitle;
  final String message;

  const SimplePlaceholderScreen({
    super.key,
    required this.headerSubtitle,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AgriBotHeader(subtitle: headerSubtitle),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
