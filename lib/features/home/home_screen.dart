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
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.bg,
        centerTitle: false,
        title: Text(
          "Dashboard",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        actions: [
          _CircleIconButton(icon: Icons.search_rounded, onPressed: () {}),
          const SizedBox(width: 8),
          _CircleIconButton(icon: Icons.refresh_rounded, onPressed: () {}),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
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
                const SizedBox(height: 24),

                const _SectionLabel(label: "Performance Overview"),
                const SizedBox(height: 12),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int columns = width > 900 ? 4 : 2;
                    double ratio = width > 900 ? 1.4 : (width > 600 ? 1.6 : 1.1);

                    return GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: ratio,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        _StatCard(title: "Active Jobs", value: "2", icon: Icons.work_outline_rounded),
                        _StatCard(title: "Pending Bids", value: "5", icon: Icons.gavel_rounded),
                        _StatCard(title: "Messages", value: "3", icon: Icons.chat_bubble_outline_rounded),
                        _StatCard(title: "Alerts", value: "1", icon: Icons.notifications_none_rounded),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(flex: 4, child: _QuickActions()),
                          SizedBox(width: 16),
                          Expanded(flex: 6, child: _RecentJobs()),
                        ],
                      )
                    : Column(
                        children: const [
                          _QuickActions(),
                          SizedBox(height: 16),
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

/* -------------------- HERO -------------------- */

class _HeroHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  const _HeroHeader({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary, // ✅ replaced hard-coded orange
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assalam o Alaikum, $name 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Post Job", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

/* -------------------- STAT CARD -------------------- */

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/* -------------------- QUICK ACTIONS -------------------- */

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
            subtitle: "Find professional help",
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.assignment_turned_in_outlined,
            title: "My Jobs",
            subtitle: "Manage active tasks",
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.support_agent_rounded,
            title: "Support",
            subtitle: "24/7 Assistance",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/* -------------------- SHARED -------------------- */

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.textLight,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.textDark, size: 20),
      ),
    );
  }
}
