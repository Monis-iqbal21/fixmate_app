import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const _kToken = "token";
  static const _kRole = "role";
  static const _kUserId = "user_id";

  /// Save auth token
  static Future<void> saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kToken, token);
  }

  /// Get auth token
  static Future<String?> getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kToken);
  }

  /// Save role (client / worker / admin)
  static Future<void> saveRole(String role) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString(_kRole, role.trim().toLowerCase());
}


  static Future<String?> getRole() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kRole);
  }

  /// ✅ SAVE USER ID (THIS WAS MISSING)
  static Future<void> saveUserId(int id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kUserId, id);
  }

  /// Get user id
  static Future<int?> getUserId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kUserId);
  }

  /// Check logged in
  static Future<bool> isLoggedIn() async {
    final sp = await SharedPreferences.getInstance();
    return sp.containsKey(_kToken);
  }

  /// Clear everything (logout)
  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
  }
   /// Logout user (clear all stored data)
  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
  }
}
