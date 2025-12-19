import 'package:flutter/material.dart';
import 'chat_api.dart';

class ThreadScreen extends StatefulWidget {
  final int conversationId;
  final String title;

  const ThreadScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _c = TextEditingController();
  bool _loading = true;
  List<dynamic> _msgs = [];
  String _err = "";

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = "";
    });
    try {
      final data = await ChatApi.messages(widget.conversationId);
      setState(() => _msgs = data);
      await ChatApi.markRead(widget.conversationId);
    } catch (e) {
      setState(() => _err = "Messages error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    _c.clear();
    try {
      await ChatApi.send(conversationId: widget.conversationId, text: t);
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Send failed: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err.isNotEmpty
              ? Center(child: Text(_err))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _msgs.length,
                        itemBuilder: (c, i) {
                          final m = _msgs[i] as Map<String, dynamic>;
                          final text = (m["message"] ?? m["text"] ?? "").toString();
                          final me = (m["is_me"] == true) || (m["sender_is_me"] == true);
                          return Align(
                            alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              constraints: const BoxConstraints(maxWidth: 320),
                              decoration: BoxDecoration(
                                color: me ? Colors.orange : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black.withOpacity(0.06)),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(color: me ? Colors.white : Colors.black87),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _c,
                              decoration: const InputDecoration(hintText: "Type a message…"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded)),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
