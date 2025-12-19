import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';

class AuthApi {
  static Map<String, dynamic> _map(dynamic v) =>
      (v is Map) ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post(
      ApiEndpoints.login,
      data: {"email": email.trim(), "password": password},
    );
    return _map(res.data);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = "client",
  }) async {
    final res = await ApiClient.post(
      ApiEndpoints.register,
      data: {"name": name.trim(), "email": email.trim(), "password": password, "role": role},
    );
    return _map(res.data);
  }
}
