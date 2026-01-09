import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/api_client.dart';
import '../../core/api_endpoints.dart';

class JobsApi {
  // -------------------------
  // HELPERS
  // -------------------------
  static Map<String, dynamic> _map(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _list(dynamic data) {
    if (data is List) {
      final out = <Map<String, dynamic>>[];
      for (final item in data) {
        if (item is Map) out.add(Map<String, dynamic>.from(item));
      }
      return out;
    }
    return <Map<String, dynamic>>[];
  }

  static bool _isOk(Map<String, dynamic> m) {
    final st = (m["status"] ?? m["state"] ?? m["success"] ?? "")
        .toString()
        .toLowerCase()
        .trim();

    if (st == "ok" || st == "success" || st == "true") return true;
    if (m["success"] is bool) return m["success"] == true;
    return false;
  }

  static String _msg(Map<String, dynamic> m) =>
      (m["msg"] ?? m["message"] ?? m["error"] ?? "Request failed").toString();

  static dynamic _payload(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k)) return m[k];
    }
    return null;
  }

  // -------------------------
  // LIST (Worker uses this)
  // list.php returns: {status:"ok", jobs:[...]}
  // -------------------------
  static Future<List<Map<String, dynamic>>> list({
    String q = "",
    String status = "all",
  }) async {
    try {
      final res = await ApiClient.get(
        "/jobs/list.php",
        queryParameters: {"q": q, "status": status},
      );

      // list.php returns a Map wrapper
      final m = _map(res.data);
      if (m.isNotEmpty && !_isOk(m)) throw Exception(_msg(m));

      final payload = _payload(m, ["jobs", "data", "list"]);
      return _list(payload);
    } on DioException catch (e) {
      final r = e.response;
      throw Exception(
        "List Load Failed: ${r?.statusCode} | ${r?.data ?? e.message}",
      );
    }
  }

  // -------------------------
  // MY JOBS (Client uses this)
  // myjob.php returns: {status:"ok", data:[...]}
  // -------------------------
  static Future<List<Map<String, dynamic>>> myJobs({
    String q = "",
    String status = "all",
  }) async {
    try {
      final res = await ApiClient.get(
        "/jobs/myjob.php",
        queryParameters: {"q": q, "status": status, "mine": 1},
      );

      final m = _map(res.data);
      if (m.isNotEmpty && !_isOk(m)) throw Exception(_msg(m));

      final payload = _payload(m, ["data", "jobs", "list"]);
      return _list(payload);
    } on DioException catch (e) {
      final r = e.response;
      throw Exception(
        "My Jobs Load Failed: ${r?.statusCode} | ${r?.data ?? e.message}",
      );
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

      final m = _map(res.data);
      if (!_isOk(m)) throw Exception(_msg(m));

      final payload = _payload(m, ["job", "data"]);
      if (payload is Map) return Map<String, dynamic>.from(payload);

      throw Exception("Invalid job payload");
    } on DioException catch (e) {
      final r = e.response;
      throw Exception(
        "Detail Load Failed: ${r?.statusCode} | ${r?.data ?? e.message}",
      );
    }
  }

  // -------------------------
  // MEDIA LIST
  // -------------------------
  static Future<List<Map<String, dynamic>>> mediaList(int jobId) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.jobsMediaList,
        queryParameters: {"id": jobId},
      );

      final m = _map(res.data);
      if (!_isOk(m)) return [];

      final payload = _payload(m, ["data", "media", "list"]);
      return _list(payload);
    } catch (e) {
      debugPrint("mediaList error: $e");
      return [];
    }
  }

  // ---------------------------------------------------------
  // CREATE (Text + Media)
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>> create({
    required String title,
    required String description,
    required String category,
    required String location,
    required int price,
    required String deadline,
    List<XFile> mediaFiles = const [],
    List<String> mediaKinds = const [],
    String? audioBase64,
    String? audioMime,
  }) async {
    try {
      final form = FormData();

      form.fields.addAll([
        MapEntry("title", title),
        MapEntry("description", description),
        MapEntry("category", category),
        MapEntry("location", location),
        MapEntry("price", price.toString()),
        MapEntry("deadline", deadline),
      ]);

      if (audioBase64 != null && audioBase64.isNotEmpty) {
        form.fields.add(MapEntry("audio_base64", audioBase64));
      }
      if (audioMime != null && audioMime.isNotEmpty) {
        form.fields.add(MapEntry("audio_mime", audioMime));
      }

      for (int i = 0; i < mediaFiles.length; i++) {
        final file = mediaFiles[i];
        final bytes = await file.readAsBytes();

        final kind = (i < mediaKinds.length) ? mediaKinds[i] : "file";
        form.fields.add(MapEntry("media_kind[]", kind));

        MediaType contentType;
        try {
          contentType = MediaType.parse(
            file.mimeType ?? "application/octet-stream",
          );
        } catch (_) {
          contentType = MediaType("application", "octet-stream");
        }

        form.files.add(
          MapEntry(
            "media[]",
            MultipartFile.fromBytes(
              bytes,
              filename: file.name,
              contentType: contentType,
            ),
          ),
        );
      }

      final res = await ApiClient.post(ApiEndpoints.jobsCreate, data: form);

      final m = _map(res.data);
      if (!_isOk(m)) throw Exception(_msg(m));
      return m;
    } on DioException catch (e) {
      final r = e.response;
      throw Exception(
        "Post Failed: ${r?.statusCode} | ${r?.data ?? e.message}",
      );
    } catch (e) {
      throw Exception("General Error: $e");
    }
  }

  // ✅ MARK COMPLETE (Handshake)
  static Future<bool> markComplete(int jobId) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.clientMarkDone,
        data: {"job_id": jobId},
      );
      final m = _map(res.data);
      return _isOk(m);
    } catch (e) {
      debugPrint("markComplete error: $e");
      return false;
    }
  }

  // ✅ DELETE JOB
  static Future<bool> deleteJob(int jobId) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.deleteJob,
        data: {"job_id": jobId.toString()},
      );
      final m = _map(res.data);
      return _isOk(m);
    } catch (e) {
      debugPrint("Delete Error: $e");
      return false;
    }
  }

  // ✅ UPDATE JOB
  static Future<bool> updateJob(int jobId, Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      payload['job_id'] = jobId;

      final res = await ApiClient.post(ApiEndpoints.updateJob, data: payload);
      final m = _map(res.data);
      return _isOk(m);
    } catch (e) {
      debugPrint("Update Job Error: $e");
      return false;
    }
  }

  // -------------------------
  // BIDS
  // -------------------------
  static Future<List<Map<String, dynamic>>> getBids(int jobId) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.jobsGetBids, // ✅ make sure this exists in endpoints
        queryParameters: {"job_id": jobId},
      );

      // some APIs return list directly
      if (res.data is List) return _list(res.data);

      final m = _map(res.data);
      if (!_isOk(m)) return [];

      final payload = _payload(m, ["bids", "data", "list"]);
      return _list(payload);
    } catch (e) {
      debugPrint("getBids error: $e");
      return [];
    }
  }

  static Future<bool> placeBid(
    int jobId,
    double amount,
    String proposal,
    int credits,
    String timeEstimate,
    bool includeMaterials,
  ) async {
    try {
      final res = await ApiClient.post(
        "/jobs/place_bid.php",
        data: {
          "job_id": jobId,
          "bid_amount": amount,
          "bid_message": proposal,
          "credits_to_use": credits,
          "time_estimate": timeEstimate,
          "include_materials": includeMaterials ? 1 : 0,
        },
      );

      final m = _map(res.data);
      return _isOk(m);
    } catch (e) {
      debugPrint("placeBid error: $e");
      return false;
    }
  }

  static Future<bool> assignWorker(int jobId, int bidId) async {
    try {
      final res = await ApiClient.post(
        "/jobs/assign_worker.php",
        data: {"job_id": jobId, "bid_id": bidId},
      );
      final m = _map(res.data);
      return _isOk(m);
    } catch (e) {
      debugPrint("assignWorker error: $e");
      return false;
    }
  }

  // -------------------------
  // REVIEWS
  // -------------------------
  static Future<bool> submitReview(
    int jobId,
    int rating,
    String comment,
  ) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.submitReview,
        data: {"job_id": jobId, "rating": rating, "comment": comment},
      );

      debugPrint("submitReview statusCode: ${res.statusCode}");
      debugPrint("submitReview res: ${res.data}");

      final m = _map(res.data);
      return (m["status"]?.toString() == "ok");
    } on DioException catch (e) {
      debugPrint("submitReview DioException: ${e.message}");
      debugPrint("submitReview statusCode: ${e.response?.statusCode}");
      debugPrint("submitReview response: ${e.response?.data}");
      return false;
    } catch (e) {
      debugPrint("submitReview error: $e");
      return false;
    }
  }

  // -------------------------
  // CREDITS
  // -------------------------
  static Future<int> myCredits() async {
    try {
      final res = await ApiClient.get("/worker/my_credits.php");
      final m = _map(res.data);
      if (!_isOk(m)) return 0;

      final v = m["credits"] ?? (m["data"] is Map ? (m["data"]["credits"]) : 0);
      return int.tryParse(v.toString()) ?? 0;
    } catch (e) {
      debugPrint("myCredits error: $e");
      return 0;
    }
  }

  // -------------------------
  // WORKER MARK DONE
  // -------------------------
  static Future<bool> workerMarkDone(int jobId) async {
    try {
      final res = await ApiClient.post(
        "/jobs/worker_mark_done.php",
        data: {"job_id": jobId},
      );
      final m = _map(res.data);
      return _isOk(m);
    } catch (e) {
      debugPrint("workerMarkDone error: $e");
      return false;
    }
  }

  // -------------------------
  // CLIENT DASHBOARD STATS
  // -------------------------
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await ApiClient.get(ApiEndpoints.clientStats);

    final m = _map(res.data);
    if (m.isNotEmpty && !_isOk(m)) throw Exception(_msg(m));

    final root = (m["data"] is Map) ? Map<String, dynamic>.from(m["data"]) : m;

    return {
      "status": "ok",
      "stats": root["stats"] ?? <String, dynamic>{},
      "recent_jobs": root["recent_jobs"] ?? <dynamic>[],
    };
  }

  static Future<bool> updateBid(int bidId, Map<String, dynamic> changes) async {
    try {
      final payload = Map<String, dynamic>.from(changes);
      payload["bid_id"] = bidId;

      final res = await ApiClient.post("/jobs/update_bid.php", data: payload);
      final m = _map(res.data);
      return _isOk(m);
    } catch (e) {
      debugPrint("updateBid error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> reviewsByJob(int jobId) async {
    final res = await ApiClient.get(
      ApiEndpoints.reviewsByJob,
      queryParameters: {"job_id": jobId},
    );

    final m = _map(res.data);
    if (!_isOk(m)) throw Exception(_msg(m));

    final payload = _payload(m, ["data"]);
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return {};
  }
}
