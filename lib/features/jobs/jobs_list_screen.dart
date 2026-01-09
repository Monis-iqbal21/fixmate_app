import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/storage.dart';
import 'job_create_screen.dart';
import 'job_detail_screen.dart';
import 'job_model.dart';
import 'jobs_api.dart';

class JobsListScreen extends StatefulWidget {
  final String mode; // 'client' or 'worker'
  const JobsListScreen({super.key, this.mode = "client"});

  @override
  State<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends State<JobsListScreen> {
  late Future<List<JobModel>> _future;

  final _search = TextEditingController();
  String _selectedStatus = "all";
  int _currentUserId = 0;

  bool get _isClientMode => widget.mode.toLowerCase() == 'client';
  String get _viewerRole => _isClientMode ? 'client' : 'worker';

  @override
  void initState() {
    super.initState();
    _future = Future.value(<JobModel>[]);
    _init();
  }

  Future<void> _init() async {
    final uid = await AppStorage.getUserId();
    _currentUserId = uid ?? 0;

    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Future<List<JobModel>> _load() async {
    final List<Map<String, dynamic>> raw;

    if (_isClientMode) {
      raw = await JobsApi.myJobs(
        q: _search.text.trim(),
        status: _selectedStatus,
      );
    } else {
      raw = await JobsApi.list(q: _search.text.trim(), status: _selectedStatus);
    }

    return raw.map(JobModel.fromJson).toList();
  }

  void _applyFilter() {
    setState(() {
      _future = _load();
    });
  }

  void _resetFilter() {
    _search.clear();
    _selectedStatus = "all";
    _applyFilter();
  }

  List<DropdownMenuItem<String>> get _clientStatusItems => const [
    DropdownMenuItem(value: "all", child: Text("All")),
    DropdownMenuItem(value: "open", child: Text("Live / Open")),
    DropdownMenuItem(value: "assigned", child: Text("Assigned")),
    DropdownMenuItem(
      value: "completion_pending",
      child: Text("Completion pending"),
    ),
    DropdownMenuItem(value: "completed", child: Text("Completed")),
    DropdownMenuItem(value: "review_pending", child: Text("Review pending")),
    DropdownMenuItem(value: "reviewed", child: Text("Reviewed")),
  ];

  List<DropdownMenuItem<String>> get _workerStatusItems => const [
    DropdownMenuItem(value: "all", child: Text("All")),
    DropdownMenuItem(value: "open", child: Text("Live / Open")),
    DropdownMenuItem(value: "my_bids", child: Text("My bids")),
    DropdownMenuItem(value: "hired_you", child: Text("Hired you")),
    DropdownMenuItem(value: "assigned", child: Text("Assigned (any)")),
    DropdownMenuItem(
      value: "completion_pending",
      child: Text("Completion pending"),
    ),
    DropdownMenuItem(value: "completed", child: Text("Completed")),
    DropdownMenuItem(value: "review_pending", child: Text("Review pending")),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _isClientMode ? _clientStatusItems : _workerStatusItems;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_isClientMode ? "My Jobs" : "Jobs"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: _applyFilter, icon: const Icon(Icons.refresh)),
        ],
      ),

      floatingActionButton: _isClientMode
          ? FloatingActionButton.extended(
              onPressed: () async {
                final ok = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JobCreateScreen()),
                );
                if (ok == true) _applyFilter();
              },
              backgroundColor: AppColors.primary,
              label: const Text("Post Job"),
              icon: const Icon(Icons.add),
            )
          : null,

      body: Column(
        children: [
          // FILTER BAR
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: "Search by title, category...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _applyFilter(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: items,
                        onChanged: (v) {
                          if (v == null) return;
                          _selectedStatus = v;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyFilter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Apply"),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _resetFilter,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Reset"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: FutureBuilder<List<JobModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text("Error: ${snap.error}"));
                }

                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_off_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isClientMode
                              ? "You haven't posted any jobs."
                              : "No jobs found for this filter.",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _JobCard(
                    job: list[i],
                    isEditable: _isClientMode,
                    viewerRole: _viewerRole,
                    viewerUserId: _currentUserId,
                    onRefresh: _applyFilter,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final bool isEditable; // client => true
  final String viewerRole; // 'client' or 'worker'
  final int viewerUserId;
  final VoidCallback onRefresh;

  const _JobCard({
    required this.job,
    required this.isEditable,
    required this.viewerRole,
    required this.viewerUserId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final display = job.getStatusDisplay(
      viewerRole: viewerRole,
      viewerUserId: viewerUserId,
    );
    final extras = job.extraBadges(
      viewerRole: viewerRole,
      viewerUserId: viewerUserId,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
        ).then((_) => onRefresh());
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(text: display['text'], color: display['color']),
                ],
              ),

              // Extra badges (worker: Bid sent / Hired you, both: Review pending/Reviewed)
              if (extras.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: extras
                      .map(
                        (b) => _StatusBadge(text: b['text'], color: b['color']),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 6),
              Text(
                job.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${job.city}, ${job.area}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                "Posted: ${job.createdAt}",
                style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Rs ${job.budget}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  // Actions
                  Row(
                    children: [
                      if (!isEditable)
                        const Row(
                          children: [
                            Text(
                              "View Details",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),

                      if (isEditable) ...[
                        // client can edit only if no worker hired
                        if (job.hiredWorkerId == null || job.hiredWorkerId == 0)
                          TextButton(
                            onPressed: () async {
                              final ok = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      JobCreateScreen(jobToEdit: job),
                                ),
                              );
                              if (ok == true) onRefresh();
                            },
                            child: const Text("Edit"),
                          ),

                        // delete only when no hired worker, and not deleted/completed
                        if ((job.hiredWorkerId == null ||
                                job.hiredWorkerId == 0) &&
                            job.isCompleted == false &&
                            job.status.toLowerCase() != 'deleted')
                          TextButton(
                            onPressed: () => _showDeleteDialog(context),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete job?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await JobsApi.deleteJob(job.id);
              if (ok) onRefresh();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
