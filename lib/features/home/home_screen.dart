import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 900;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            tooltip: "Search",
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: "Refresh",
            onPressed: () {},
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroHeader(
                  name: "Client",
                  subtitle: "Quick actions aur active jobs yahan se manage karo",
                ),
                const SizedBox(height: 14),

                // stats
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _StatCard(
                      title: "Active Jobs",
                      value: "2",
                      icon: Icons.work_outline_rounded,
                    ),
                    _StatCard(
                      title: "Pending Bids",
                      value: "5",
                      icon: Icons.gavel_rounded,
                    ),
                    _StatCard(
                      title: "Unread Messages",
                      value: "3",
                      icon: Icons.chat_bubble_outline_rounded,
                    ),
                    _StatCard(
                      title: "Alerts",
                      value: "1",
                      icon: Icons.notifications_none_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Quick actions + recent jobs
                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(flex: 4, child: _QuickActions()),
                          SizedBox(width: 14),
                          Expanded(flex: 6, child: _RecentJobs()),
                        ],
                      )
                    : const Column(
                        children: [
                          _QuickActions(),
                          SizedBox(height: 14),
                          _RecentJobs(),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  const _HeroHeader({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(Icons.handyman_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assalam o Alaikum, $name 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(
            onPressed: () {
              // Later: navigate to create job screen
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.18),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: Colors.white.withOpacity(0.22)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18),
                SizedBox(width: 6),
                Text("Post Job", style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.primary.withOpacity(0.10),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, color: AppColors.textLight)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "Quick Actions",
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.add_task_rounded,
            title: "Post a new job",
            subtitle: "Service requirements add karo",
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.assignment_turned_in_outlined,
            title: "My Jobs",
            subtitle: "Active / completed jobs dekho",
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.support_agent_rounded,
            title: "Support",
            subtitle: "Help & FAQs",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _RecentJobs extends StatelessWidget {
  const _RecentJobs();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "Recent Jobs",
      trailing: TextButton(
        onPressed: () {},
        child: const Text("View all"),
      ),
      child: Column(
        children: const [
          _JobMiniCard(
            title: "AC Repair",
            location: "Gulshan, Karachi",
            status: "In Progress",
            budget: "PKR 5,000 - 8,000",
          ),
          SizedBox(height: 10),
          _JobMiniCard(
            title: "Plumber Needed",
            location: "Johar Town, Lahore",
            status: "Bids Open",
            budget: "PKR 2,000 - 4,000",
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.bg,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.secondary.withOpacity(0.10),
              ),
              child: Icon(icon, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _JobMiniCard extends StatelessWidget {
  final String title;
  final String location;
  final String status;
  final String budget;

  const _JobMiniCard({
    required this.title,
    required this.location,
    required this.status,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {},
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.bg,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.primary.withOpacity(0.10),
              ),
              child: const Icon(Icons.work_outline_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(location, style: const TextStyle(color: AppColors.textLight, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Pill(text: status),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          budget,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.secondary.withOpacity(0.12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}
