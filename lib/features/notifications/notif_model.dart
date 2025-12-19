class AppNotif {
  final int id;
  final String type;
  final String title;
  final String message;
  final String linkUrl;
  final int isRead;
  final String createdAt;

  AppNotif({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.linkUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotif.fromJson(Map<String, dynamic> j) {
    return AppNotif(
      id: int.tryParse((j["id"] ?? 0).toString()) ?? 0,
      type: (j["type"] ?? "").toString(),
      title: (j["title"] ?? "").toString(),
      message: (j["message"] ?? "").toString(),
      linkUrl: (j["link_url"] ?? "").toString(),
      isRead: int.tryParse((j["is_read"] ?? 0).toString()) ?? 0,
      createdAt: (j["created_at"] ?? "").toString(),
    );
  }
}
