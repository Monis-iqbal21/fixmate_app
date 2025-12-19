import 'package:flutter/material.dart';
import 'chat_thread_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = const [
      {"name": "Ali Electrician", "last": "Aaj 6 baje aa jaunga", "time": "2m", "unread": 2},
      {"name": "Hassan Plumber", "last": "Budget confirm kar dein", "time": "18m", "unread": 0},
      {"name": "Sana Cleaning", "last": "Kal morning available", "time": "1h", "unread": 1},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inbox"),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final c = chats[i];
          final unread = (c["unread"] as int);

          return _ChatTile(
            name: (c["name"] as String),
            last: (c["last"] as String),
            time: (c["time"] as String),
            unread: unread,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatThreadScreen(title: (c["name"] as String)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name, last, time;
  final int unread;
  final VoidCallback onTap;
  const _ChatTile({
    required this.name,
    required this.last,
    required this.time,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.primary.withOpacity(0.12),
              child: Icon(Icons.person_rounded, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(last, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 6),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(999)),
                    child: Text("$unread", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
