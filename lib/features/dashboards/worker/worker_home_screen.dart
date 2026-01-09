
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../jobs/job_model.dart';
import '../../jobs/job_detail_screen.dart';
import '../../jobs/jobs_list_screen.dart'; 
import 'worker_api.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final data = await WorkerApi.getDashboardStats();
    final List rawRecent = data['recent_jobs'] ?? [];
    return {
      "stats": data['stats'],
      "recent_jobs": rawRecent.map((e) => JobModel.fromJson(e)).toList(),
    };
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Worker Hero Header
                  _HeroHeader(subtitle: "Find jobs & track earnings."),
                  const SizedBox(height: 28),

                  // 2. Stats Grid
                  const _SectionTitle(title: "Performance", icon: Icons.insights),
                  const SizedBox(height: 16),
                  _buildStatsGrid(data?['stats'], isLoading),
                  
                  const SizedBox(height: 32),

                  // 3. Quick Actions
                  const _QuickActions(),
                  const SizedBox(height: 24),
                  
                  // 4. Current Active Jobs
                  _ActiveJobsList(
                    jobs: data?['recent_jobs'] ?? [], 
                    isLoading: isLoading,
                    onRefresh: _refresh
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic>? stats, bool isLoading) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(title: "Total Earnings", value: stats?['earnings'] ?? "Rs 0", icon: Icons.account_balance_wallet, color: Colors.green),
        _StatCard(title: "Jobs Done", value: stats?['completed_jobs'] ?? "0", icon: Icons.check_circle, color: Colors.blue),
        _StatCard(title: "Active Bids", value: stats?['pending_bids'] ?? "0", icon: Icons.gavel, color: Colors.orange),
        _StatCard(title: "Rating", value: stats?['rating'] ?? "N/A", icon: Icons.star, color: Colors.amber),
      ],
    );
  }
}

// --- SUB WIDGETS ---

class _HeroHeader extends StatelessWidget {
  final String subtitle;
  const _HeroHeader({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // Worker Theme: Dark Teal Gradient
        gradient: const LinearGradient(colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)]), 
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("WORKER DASHBOARD", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Welcome Back 👋", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: "Quick Actions", icon: Icons.bolt),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              // Pass "mode: worker" to JobsListScreen so it fetches ALL open jobs instead of user's own jobs
              _ActionTile(icon: Icons.search, title: "Find New Jobs", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsListScreen(mode: "worker")))), 
              const Divider(height: 1),
              _ActionTile(icon: Icons.history, title: "My Bids History", onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveJobsList extends StatelessWidget {
  final List<dynamic> jobs; // Using dynamic list of JobModel
  final bool isLoading;
  final VoidCallback onRefresh;
  const _ActiveJobsList({required this.jobs, required this.isLoading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionTitle(title: "My Active Jobs", icon: Icons.work_outline),
          ],
        ),
        const SizedBox(height: 12),
        isLoading 
          ? const Center(child: CircularProgressIndicator())
          : jobs.isEmpty 
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Text("No active jobs right now.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
                )
              : Column(
                  children: jobs.map((job) => _JobMiniCard(job: job, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id))))).toList(),
                ),
      ],
    );
  }
}

class _JobMiniCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  const _JobMiniCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Budget: ${job.budget}", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 18, color: Colors.blueGrey), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]);
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: Colors.teal, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }
}