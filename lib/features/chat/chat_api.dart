import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';

class ChatApi {
  static Map<String, dynamic> _map(dynamic v) =>
      (v is Map) ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<Map<String, dynamic>> _list(dynamic v) {
    if (v is List) return v.map((e) => _map(e)).toList();
    return <Map<String, dynamic>>[];
  }

  static Future<List<Map<String, dynamic>>> inbox() async {
    final res = await ApiClient.get(ApiEndpoints.chatInbox);
    final data = _map(res.data);
    if (data["data"] is List) return _list(data["data"]);
    if (data["inbox"] is List) return _list(data["inbox"]);
    if (res.data is List) return _list(res.data);
    return [];
  }

  static Future<List<Map<String, dynamic>>> messages(int convId) async {
    final res = await ApiClient.get(ApiEndpoints.chatMessages, queryParameters: {"conv_id": convId});
    final data = _map(res.data);
    if (data["data"] is List) return _list(data["data"]);
    if (data["messages"] is List) return _list(data["messages"]);
    if (res.data is List) return _list(res.data);
    return [];
  }
}
