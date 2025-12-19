import 'package:dio/dio.dart';
import 'api_config.dart';
import 'storage.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConfig.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeoutMs),
      headers: {
        "Accept": "application/json",
      },
      validateStatus: (code) => code != null && code >= 200 && code < 500,
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AppStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
            options.headers["X-Auth-Token"] = token;
          }
          handler.next(options);
        },
      ),
    );

  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  // ✅ data ko dynamic rakho (Map bhi chale, FormData bhi)
  static Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }
}
