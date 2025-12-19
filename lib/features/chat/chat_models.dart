class ChatThread {
  final int conversationId;
  final int otherUserId;
  final String otherName;
  final String otherRole;
  final String lastMessage;
  final String lastAt;
  final int unread;

  ChatThread({
    required this.conversationId,
    required this.otherUserId,
    required this.otherName,
    required this.otherRole,
    required this.lastMessage,
    required this.lastAt,
    required this.unread,
  });

  factory ChatThread.fromJson(Map<String, dynamic> j) {
    return ChatThread(
      conversationId: (j["conversation_id"] ?? j["id"] ?? 0) as int,
      otherUserId: (j["other_user_id"] ?? j["related_user_id"] ?? 0) as int,
      otherName: (j["other_name"] ?? j["name"] ?? "User").toString(),
      otherRole: (j["other_role"] ?? j["role"] ?? "").toString(),
      lastMessage: (j["last_message"] ?? j["message"] ?? "").toString(),
      lastAt: (j["last_at"] ?? j["last_message_at"] ?? "").toString(),
      unread: int.tryParse((j["unread"] ?? 0).toString()) ?? 0,
    );
  }
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String type;
  final String body;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    return ChatMessage(
      id: int.tryParse((j["id"] ?? 0).toString()) ?? 0,
      conversationId: int.tryParse((j["conversation_id"] ?? 0).toString()) ?? 0,
      senderId: int.tryParse((j["sender_id"] ?? 0).toString()) ?? 0,
      type: (j["message_type"] ?? j["type"] ?? "text").toString(),
      body: (j["body"] ?? "").toString(),
      createdAt: (j["created_at"] ?? "").toString(),
    );
  }
}
