import 'package:flutter/material.dart';
import '../../jobs/jobs_list_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../profile/profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _i = 0;

  final _pages = const [
    JobsListScreen(mode: "admin"),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: "Jobs"),
          NavigationDestination(icon: Icon(Icons.notifications_none), label: "Alerts"),
          NavigationDestination(icon: Icon(Icons.person_outline), label: "Me"),
        ],
      ),
    );
  }
}
