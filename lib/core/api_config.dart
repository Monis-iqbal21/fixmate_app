import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String lanIp = "192.168.20.57"; // your PC IP (for real phone)

  static String get host {
    if (kIsWeb) return "http://localhost";
    return "http://10.0.2.2"; // Android emulator
    // for real phone:
    // return "http://$lanIp";
  }

  // ✅ CORRECT API BASE
  static String get baseUrl => "$host/fixmate/api";

  // ✅ CORRECT UPLOAD BASE (images/videos)
  static String get uploadsBase => "$host/fixmate/uploads/jobs";

  static const connectTimeoutMs = 30000;
  static const receiveTimeoutMs = 30000;
}
