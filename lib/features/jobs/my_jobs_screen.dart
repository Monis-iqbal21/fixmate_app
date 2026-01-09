import 'package:flutter/material.dart';
import 'jobs_api.dart';
import 'job_detail_screen.dart';
import 'job_create_screen.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = JobsApi.myJobs();
  }

  Future<void> _refresh() async {
    setState(() => _future = JobsApi.myJobs());
  }

  Future<void> _goToCreateJob() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JobCreateScreen()),
    );
    _refresh(); // refresh after posting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Jobs"),
        actions: [
          TextButton.icon(
            onPressed: _goToCreateJob,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Post Job", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreateJob,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error: ${snap.error}", textAlign: TextAlign.center),
              ),
            );
          }

          final jobs = snap.data ?? [];

          if (jobs.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.work_outline, size: 64),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      "No jobs posted yet.",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _goToCreateJob,
                      icon: const Icon(Icons.add),
                      label: const Text("Post a Job"),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: jobs.length,
              itemBuilder: (context, i) {
                final j = jobs[i];
                final id = int.tryParse("${j["id"]}") ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(j["title"] ?? ""),
                    subtitle: Text("${j["location"] ?? ""} • ${j["category"] ?? ""}"),
                    trailing: Text("PKR ${j["price"] ?? ""}"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: id)),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
