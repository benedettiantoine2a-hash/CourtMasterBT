import 'package:flutter/material.dart';
import 'screens/setup_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CourtMasterApp());
}

class CourtMasterApp extends StatelessWidget {
  const CourtMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CourtMaster BT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SetupScreen(),
    );
  }
}
