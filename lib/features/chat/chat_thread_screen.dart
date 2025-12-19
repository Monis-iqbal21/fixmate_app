import 'package:flutter/material.dart';

class ChatThreadScreen extends StatefulWidget {
  final String title;
  const ChatThreadScreen({super.key, required this.title});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _c = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {"me": false, "text": "Salam! job detail share kar dein.", "time": "10:01"},
    {"me": true, "text": "Walaikum salam. AC cooling issue hai.", "time": "10:02"},
    {"me": false, "text": "Ok. Main 6pm available hoon.", "time": "10:03"},
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add({"me": true, "text": t, "time": "now"});
    });
    _c.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final me = m["me"] as bool;
                final text = m["text"] as String;
                final time = m["time"] as String;

                return Align(
                  alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: me ? cs.primary : cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: me ? null : Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text, style: TextStyle(color: me ? Colors.white : cs.onSurface, height: 1.25)),
                        const SizedBox(height: 6),
                        Text(time, style: TextStyle(color: me ? Colors.white70 : cs.onSurfaceVariant, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    decoration: const InputDecoration(
                      hintText: "Type message…",
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _send,
                  child: const Icon(Icons.send_rounded),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
