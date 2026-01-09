import '../../../../core/api_client.dart';
import '../../../../core/api_config.dart'; // Ensure you have this for endpoints

class WorkerApi {
  // Uses the endpoint you specified
  static Future<Map<String, dynamic>> getDashboardStats() async {
    // You can use ApiConfig.workerStats if defined there, or the string directly
    final res = await ApiClient.get("/jobs/worker_stats.php");
    
    if (res.data['status'] == 'ok') {
      return res.data;
    }
    throw Exception("Failed to load worker stats");
  }
}