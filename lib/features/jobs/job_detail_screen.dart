import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'jobs_api.dart';
import 'job_model.dart';

class JobDetailScreen extends StatefulWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Future<JobModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<JobModel> _load() async {
    final raw = await JobsApi.detail(widget.jobId);
    return JobModel.fromJson(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text("Job Detail")),
      body: FutureBuilder<JobModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Detail error:\n${snap.error}", textAlign: TextAlign.center),
              ),
            );
          }

          final j = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(j.description, style: const TextStyle(color: AppColors.textLight, height: 1.4)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _kv("Status", j.status)),
                        Expanded(child: _kv("Budget", j.budget.isEmpty ? "-" : "Rs ${j.budget}")),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _kv("Location", "${j.city}${j.area.isNotEmpty ? ", ${j.area}" : ""}"),
                    const SizedBox(height: 10),
                    _kv("Created", j.createdAt.isEmpty ? "-" : j.createdAt),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
