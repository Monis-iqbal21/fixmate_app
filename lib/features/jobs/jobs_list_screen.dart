import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'job_model.dart';
import 'jobs_api.dart';
import 'job_detail_screen.dart';
import 'job_create_screen.dart';

class JobsListScreen extends StatefulWidget {
  const JobsListScreen({super.key});

  @override
  State<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends State<JobsListScreen> {
  late Future<List<JobModel>> _future;
  final _search = TextEditingController();
  String _status = ""; // "", open, assigned, done etc

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<JobModel>> _load() async {
    final raw = await JobsApi.list(q: _search.text, status: _status);
    return raw.map(JobModel.fromJson).toList();
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Jobs"),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JobCreateScreen()),
          );
          if (ok == true) _refresh();
        },
        label: const Text("Post Job"),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: "Search jobs...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onSubmitted: (_) => _refresh(),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: "", child: Text("All")),
                    DropdownMenuItem(value: "open", child: Text("Open")),
                    DropdownMenuItem(value: "assigned", child: Text("Assigned")),
                    DropdownMenuItem(value: "done", child: Text("Done")),
                  ],
                  onChanged: (v) {
                    _status = v ?? "";
                    _refresh();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<JobModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Jobs load error:\n${snap.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text("No jobs found"));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final j = list[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: j.id)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    j.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                _StatusPill(status: j.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              j.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textLight),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textLight),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "${j.city}${j.area.isNotEmpty ? ", ${j.area}" : ""}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.textLight),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  j.budget.isEmpty ? "" : "Rs ${j.budget}",
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    String text = status.isEmpty ? "open" : s;

    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF334155);

    if (s == "open") { bg = const Color(0xFFFFF7ED); fg = const Color(0xFFC2410C); }
    if (s == "assigned") { bg = const Color(0xFFEFF6FF); fg = const Color(0xFF1D4ED8); }
    if (s == "done") { bg = const Color(0xFFECFDF5); fg = const Color(0xFF047857); }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
