import 'package:fixmate_app/features/jobs/jobs_list_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../jobs/my_jobs_screen.dart';
import 'client_home_screen.dart';
import 'client_chat_screen.dart';
import 'client_notifications_screen.dart';
import 'client_profile_screen.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  final _titles = const ["Dashboard","My Jobs", "Messages", "Notifications", "Profile"];

  final _pages = const [
    ClientHomeScreen(),
    JobsListScreen(),
    ClientChatScreen(),
    ClientNotificationsScreen(),
    ClientProfileScreen(),
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: "Home"),
          NavigationDestination(icon: Icon(Icons.work_rounded), label: "Jobs"),
          NavigationDestination(icon: Icon(Icons.chat_bubble_rounded), label: "Chat"),
          NavigationDestination(icon: Icon(Icons.notifications_rounded), label: "Alerts"),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}
