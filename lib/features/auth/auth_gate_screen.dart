import 'package:flutter/material.dart';
import '../../core/storage.dart';

// ✅ IMPORTANT: use your real dashboards path
import '../dashboards/client/client_dashboard.dart';
import '../dashboards/worker/worker_dashboard.dart';
import '../dashboards/admin/admin_dashboard.dart';

import 'login_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final token = await AppStorage.getToken();
    final role = (await AppStorage.getRole())?.trim().toLowerCase();

    // ✅ Debug (keep for now)
    debugPrint("AUTHGATE token exists: ${token != null && token.isNotEmpty}");
    debugPrint("AUTHGATE role: $role");

    if (!mounted) return;

    // Not logged in -> Login
    if (token == null || token.isEmpty || role == null || role.isEmpty) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    // ✅ Role-based redirect
    if (role == 'admin') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
        (_) => false,
      );
      return;
    }

    if (role == 'worker') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WorkerDashboard()),
        (_) => false,
      );
      return;
    }

    if (role == 'client') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ClientDashboard()),
        (_) => false,
      );
      return;
    }

    // Unknown role -> clear + Login
    await AppStorage.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
