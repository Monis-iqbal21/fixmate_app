import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashPage(title: "Home", icon: Icons.home_rounded),
      _DashPage(title: "Jobs", icon: Icons.work_rounded),
      _DashPage(title: "Chat", icon: Icons.chat_bubble_rounded),
      _DashPage(title: "Profile", icon: Icons.person_rounded),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pages[_index].title),
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: "Home"),
          NavigationDestination(icon: Icon(Icons.work_rounded), label: "Jobs"),
          NavigationDestination(icon: Icon(Icons.chat_bubble_rounded), label: "Chat"),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}

class _DashPage extends StatelessWidget {
  final String title;
  final IconData icon;
  const _DashPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text("UI abhi static hai ✅ Backend baad mein"),
          ],
        ),
      ),
    );
  }
}
