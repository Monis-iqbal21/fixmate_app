import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      {"title": "Offer received", "body": "Ali Electrician sent an offer.", "time": "2m", "read": false},
      {"title": "Job updated", "body": "Your job status changed to In Progress.", "time": "1h", "read": true},
      {"title": "Reminder", "body": "Please confirm the worker schedule.", "time": "Yesterday", "read": true},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts"),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.done_all_rounded))],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = items[i];
          final read = (n["read"] as bool);
          return _NotifTile(
            title: (n["title"] as String),
            body: (n["body"] as String),
            time: (n["time"] as String),
            read: read,
          );
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String title, body, time;
  final bool read;
  const _NotifTile({required this.title, required this.body, required this.time, required this.read});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: read ? cs.surfaceContainerHighest : cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                color: read ? cs.onSurfaceVariant : cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(time, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}
