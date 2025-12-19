import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/storage.dart';

class AuthService {
  final Dio _dio = ApiClient.dio;

  String _niceMsg(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data["msg"] != null) return data["msg"].toString();
      return e.message ?? "Network error";
    }
    return e.toString();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final res = await _dio.post("/auth/register", data: {
        "name": name,
        "email": email,
        "password": password,
        "role": role,
      });

      final data = Map<String, dynamic>.from(res.data);
      if (data["status"] != "ok") throw Exception(data["msg"] ?? "Register failed");

      final token = data["token"] as String;
      final user = Map<String, dynamic>.from(data["user"]);
      final userRole = (user["role"] ?? role).toString();

      await AppStorage.saveAuth(token: token, role: userRole);
    } catch (e) {
      throw Exception(_niceMsg(e));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post("/auth/login", data: {
        "email": email,
        "password": password,
      });

      final data = Map<String, dynamic>.from(res.data);
      if (data["status"] != "ok") throw Exception(data["msg"] ?? "Login failed");

      final token = data["token"] as String;
      final user = Map<String, dynamic>.from(data["user"]);
      final role = (user["role"] ?? "client").toString();

      await AppStorage.saveAuth(token: token, role: role);
    } catch (e) {
      throw Exception(_niceMsg(e));
    }
  }

  Future<void> logout() async {
    await AppStorage.clear();
  }
}
