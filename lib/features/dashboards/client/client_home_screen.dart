import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/storage.dart';
import '../../jobs/job_create_screen.dart';
import '../../jobs/job_detail_screen.dart';
import '../../jobs/job_model.dart';
import '../../jobs/jobs_api.dart';
import '../../jobs/jobs_list_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _initAndLoad();
  }

  Future<Map<String, dynamic>> _initAndLoad() async {
    final uid = await AppStorage.getUserId();
    _currentUserId = uid ?? 0;
    return _loadDashboardData();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    final res = await JobsApi.getDashboardStats();

    debugPrint("📦 Dashboard raw response: $res");

    if (res is Map && res['status'] != null && res['status'] != 'ok') {
      throw Exception(res['msg'] ?? 'Dashboard API error');
    }

    final root = (res['data'] is Map)
        ? Map<String, dynamic>.from(res['data'])
        : Map<String, dynamic>.from(res);

    final stats = (root['stats'] is Map)
        ? Map<String, dynamic>.from(root['stats'])
        : <String, dynamic>{};

    final rawRecent = (root['recent_jobs'] is List)
        ? List.from(root['recent_jobs'])
        : <dynamic>[];

    final recentJobs = rawRecent
        .where((e) => e is Map)
        .map((e) => JobModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return {"stats": stats, "recent_jobs": recentJobs};
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = _initAndLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: !isWide
          ? FloatingActionButton.extended(
              onPressed: () async {
                final ok = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JobCreateScreen()),
                );
                if (ok == true) _refresh();
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Post Job",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const _HeroHeader(
                    name: "Client",
                    subtitle: "Quick overview of your jobs and activity.",
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Dashboard Error",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${snapshot.error}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final stats = (data['stats'] is Map<String, dynamic>)
              ? data['stats'] as Map<String, dynamic>
              : <String, dynamic>{};

          final jobs = (data['recent_jobs'] is List<JobModel>)
              ? data['recent_jobs'] as List<JobModel>
              : <JobModel>[];

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HeroHeader(
                        name: "Client",
                        subtitle: "Quick overview of your jobs and activity.",
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(
                        title: "Overview",
                        icon: Icons.analytics_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildStatsGrid(stats, isLoading),
                      const SizedBox(height: 32),
                      isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(flex: 4, child: _QuickActions()),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 6,
                                  child: _RecentJobs(
                                    jobs: jobs,
                                    isLoading: isLoading,
                                    onRefresh: _refresh,
                                    currentUserId:
                                        _currentUserId, // replaced below
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                const _QuickActions(),
                                const SizedBox(height: 24),
                                _RecentJobs(
                                  jobs: jobs,
                                  isLoading: isLoading,
                                  onRefresh: _refresh,
                                  currentUserId: _currentUserId,
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, bool isLoading) {
    String v(String key) => isLoading ? "..." : (stats[key]?.toString() ?? "0");

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth >= 900 ? 1.6 : 1.1,
          children: [
            _StatCard(
              title: "Active Jobs",
              value: v('active_jobs'),
              icon: Icons.grid_view_rounded,
              accentColor: AppColors.secondary,
            ),
            _StatCard(
              title: "New Proposals",
              value: v('new_proposals'),
              icon: Icons.chat_bubble_outline_rounded,
              accentColor: AppColors.primary,
            ),
            _StatCard(
              title: "Near Deadline",
              value: v('near_deadline'),
              icon: Icons.hourglass_empty_rounded,
              accentColor: AppColors.secondary,
            ),
            _StatCard(
              title: "Completed Jobs",
              value: v('completed_jobs'),
              icon: Icons.check_circle_outline_rounded,
              accentColor: AppColors.primary,
            ),
          ],
        );
      },
    );
  }
}

/* -------------------- COMPONENT CLASSES -------------------- */

class _HeroHeader extends StatelessWidget {
  final String name, subtitle;
  const _HeroHeader({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CLIENT DASHBOARD",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Welcome, $name 👋",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color accentColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentJobs extends StatelessWidget {
  final List<JobModel> jobs;
  final bool isLoading;
  final VoidCallback onRefresh;
  final int currentUserId;

  const _RecentJobs({
    required this.jobs,
    required this.isLoading,
    required this.onRefresh,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "Your Recent Jobs",
      trailing: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const JobsListScreen(mode: "client"),
          ),
        ),
        child: const Text(
          "Show all →",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          : jobs.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "No jobs posted yet.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            )
          : Column(
              children: jobs
                  .map(
                    (job) => _JobMiniCard(
                      job: job,
                      currentUserId: currentUserId,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailScreen(jobId: job.id),
                          ),
                        );
                        onRefresh();
                      },
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _JobMiniCard extends StatelessWidget {
  final JobModel job;
  final int currentUserId;
  final VoidCallback onTap;

  const _JobMiniCard({
    required this.job,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final display = job.getStatusDisplay(
      viewerRole: 'client',
      viewerUserId: currentUserId,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (display['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          display['text'] as String,
                          style: TextStyle(
                            color: display['color'] as Color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Posted: ${job.createdAt}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
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
            icon: Icons.add_circle_outline,
            title: "Post a new job",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobCreateScreen()),
            ),
          ),
          const Divider(height: 1),
          _ActionTile(
            icon: Icons.history,
            title: "Manage My Jobs",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const JobsListScreen(mode: "client"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: child,
        ),
      ],
    );
  }
}
