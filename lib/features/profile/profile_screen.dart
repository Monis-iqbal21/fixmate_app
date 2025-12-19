import 'package:flutter/material.dart';
import '../../core/storage.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AppStorage.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: cs.surface,
              border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primary.withOpacity(0.12),
                  child: Icon(Icons.person_rounded, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Client User", style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
                      const SizedBox(height: 4),
                      Text("client@example.com", style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(Icons.verified_rounded),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _Tile(icon: Icons.settings_rounded, title: "Settings", onTap: () {}),
          const SizedBox(height: 10),
          _Tile(icon: Icons.help_rounded, title: "Help & Support", onTap: () {}),
          const SizedBox(height: 10),
          _Tile(icon: Icons.privacy_tip_rounded, title: "Privacy", onTap: () {}),
          const SizedBox(height: 18),

          FilledButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
