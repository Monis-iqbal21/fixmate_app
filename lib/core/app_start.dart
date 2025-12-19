import 'package:flutter/material.dart';
import 'storage.dart';
import '../features/auth/login_screen.dart';
import '../features/shell/app_shell.dart';

class AppStart extends StatefulWidget {
  const AppStart({super.key});

  @override
  State<AppStart> createState() => _AppStartState();
}

class _AppStartState extends State<AppStart> {
  Future<bool> _check() async {
    final token = await AppStorage.getToken();
    return (token != null && token.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _check(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snap.data == true ? const AppShell() : const LoginScreen();
      },
    );
  }
}
