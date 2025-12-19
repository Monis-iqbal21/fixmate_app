import 'package:flutter/material.dart';
import '../jobs/jobs_list_screen.dart';
import '../chat/inbox_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  int _i = 0;

  final _pages = const [
    JobsListScreen(mode: "worker"),
    InboxScreen(),
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
          NavigationDestination(icon: Icon(Icons.work_outline), label: "Jobs"),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
          NavigationDestination(icon: Icon(Icons.notifications_none), label: "Alerts"),
          NavigationDestination(icon: Icon(Icons.person_outline), label: "Me"),
        ],
      ),
    );
  }
}
