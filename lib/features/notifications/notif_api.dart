import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';

class NotifApi {
  static Map<String, dynamic> _map(dynamic v) =>
      (v is Map) ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<Map<String, dynamic>> _list(dynamic v) {
    if (v is List) return v.map((e) => _map(e)).toList();
    return <Map<String, dynamic>>[];
  }

  static Future<List<Map<String, dynamic>>> list() async {
    final res = await ApiClient.get(ApiEndpoints.notificationsList);
    final data = _map(res.data);
    if (data["data"] is List) return _list(data["data"]);
    if (data["notifications"] is List) return _list(data["notifications"]);
    if (res.data is List) return _list(res.data);
    return [];
  }
}
