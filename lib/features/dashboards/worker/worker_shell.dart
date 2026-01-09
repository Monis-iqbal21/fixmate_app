import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';

// ✅ Worker Screens
import 'worker_home_screen.dart'; // The new dashboard we built
import '../../jobs/jobs_list_screen.dart'; // Reused (with mode='worker')
import '../client/client_chat_screen.dart'; // Assuming shared chat logic
import '../client/client_notifications_screen.dart'; // Assuming shared notification logic
import '../client/client_profile_screen.dart'; // Assuming shared profile logic

class WorkerShell extends StatefulWidget {
  const WorkerShell({super.key});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _index = 0;

  final _titles = const ["Dashboard", "Find Jobs", "Messages", "Notifications", "Profile"];

  final _pages = const [
    WorkerHomeScreen(), // 🏠 Worker Dashboard
    JobsListScreen(mode: 'worker'), // 💼 Find Jobs (All open jobs)
    ClientChatScreen(), // 💬 Reused Chat
    ClientNotificationsScreen(), // 🔔 Reused Notifications
    ClientProfileScreen(), // 👤 Reused Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          _titles[_index],
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: "Home"),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: "Find Jobs"), // Changed icon for worker
          NavigationDestination(icon: Icon(Icons.chat_bubble_rounded), label: "Chat"),
          NavigationDestination(icon: Icon(Icons.notifications_rounded), label: "Alerts"),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}