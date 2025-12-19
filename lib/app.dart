import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'features/auth/auth_gate_screen.dart';

class FixMateApp extends StatelessWidget {
  const FixMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "FixMate",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGateScreen(),
    );
  }
}
