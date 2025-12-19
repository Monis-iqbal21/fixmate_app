import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../jobs/jobs_list_screen.dart';
import '../chat/inbox_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _i = 0;

  final _pages = const [
    HomeScreen(),
    JobsListScreen(),
    InboxScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_i],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _i,
        onTap: (v) => setState(() => _i = v),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.work_rounded), label: "Jobs"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Inbox"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: "Alerts"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}
