import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';

class JobsApi {
  static Map<String, dynamic> _map(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
    }

  static List<Map<String, dynamic>> _list(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  // -------------------------
  // LIST
  // -------------------------
  static Future<List<Map<String, dynamic>>> list({
    String q = "",
    String status = "all",
  }) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.jobsList,
        queryParameters: {
          "q": q,
          "status": status,
        },
      );

      final data = res.data;

      if (data is String) {
        throw Exception("Server returned non-JSON: ${data.substring(0, data.length > 120 ? 120 : data.length)}");
      }

      final m = _map(data);
      final st = (m["status"] ?? "").toString().toLowerCase();
      if (st != "ok") {
        throw Exception(m["msg"]?.toString() ?? "Jobs list failed");
      }

      return _list(m["data"]);
    } on DioException catch (e) {
      final r = e.response;
      throw Exception("Dio: ${e.type} | code:${r?.statusCode} | data:${r?.data}");
    }
  }

  // -------------------------
  // DETAIL
  // -------------------------
  static Future<Map<String, dynamic>> detail(int jobId) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.jobsDetail,
        queryParameters: {"id": jobId},
      );

      final data = res.data;

      if (data is String) {
        throw Exception("Server returned non-JSON: ${data.substring(0, data.length > 120 ? 120 : data.length)}");
      }

      final m = _map(data);
      final st = (m["status"] ?? "").toString().toLowerCase();
      if (st != "ok") {
        throw Exception(m["msg"]?.toString() ?? "Job detail failed");
      }

      final payload = m["data"];
      if (payload is Map) return Map<String, dynamic>.from(payload);

      return <String, dynamic>{};
    } on DioException catch (e) {
      final r = e.response;
      throw Exception("Dio: ${e.type} | code:${r?.statusCode} | data:${r?.data}");
    }
  }

  // -------------------------
  // CREATE
  // -------------------------
  static Future<Map<String, dynamic>> create({
    required String title,
    required String description,
    required String category,
    required String city,
    required String areaName,
    required String address,
    String budget = "",
    List<String> imagesBase64 = const [], // optional
  }) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.jobsCreate,
        data: {
          "title": title,
          "description": description,
          "category": category,
          "city": city,
          "area_name": areaName,
          "home_address": address,
          "budget": budget,
          "images": imagesBase64,
        },
      );

      final data = res.data;

      if (data is String) {
        throw Exception("Server returned non-JSON: ${data.substring(0, data.length > 120 ? 120 : data.length)}");
      }

      final m = _map(data);
      final st = (m["status"] ?? "").toString().toLowerCase();
      if (st != "ok") {
        throw Exception(m["msg"]?.toString() ?? "Job create failed");
      }

      return m;
    } on DioException catch (e) {
      final r = e.response;
      throw Exception("Dio: ${e.type} | code:${r?.statusCode} | data:${r?.data}");
    }
  }
}
