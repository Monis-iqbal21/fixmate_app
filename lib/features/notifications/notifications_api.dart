import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';

class NotifApi {
  static Map<String, dynamic> _map(dynamic d) => d is Map ? Map<String, dynamic>.from(d) : {};
  static List<dynamic> _list(dynamic d) => d is List ? d : [];

  static Future<List<dynamic>> list() async {
    final res = await ApiClient.get(ApiEndpoints.notifList);
    final m = _map(res.data);
    if ((m["status"] ?? "").toString().toLowerCase() != "ok") return [];
    return _list(m["data"]);
  }

  static Future<Map<String, dynamic>> markRead(int id) async {
    final res = await ApiClient.post(ApiEndpoints.notifMarkRead, data: {"id": id});
    return _map(res.data);
  }
}
