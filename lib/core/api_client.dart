import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'storage.dart';

class ApiClient {
  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: Duration(milliseconds: ApiConfig.connectTimeoutMs),
            receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeoutMs),

            // ✅ Important
            headers: {"Accept": "application/json"},

            // ✅ Force Dio to treat responses as JSON when possible
            responseType: ResponseType.json,

            // keep this as you had
            validateStatus: (code) => code != null && code >= 200 && code < 500,
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              debugPrint("API REQUEST => ${options.method} ${options.uri}");

              final token = await AppStorage.getToken();
              if (token != null && token.isNotEmpty) {
                debugPrint(
                  "API TOKEN => ${token.substring(0, token.length > 10 ? 10 : token.length)}...",
                );
                options.headers["Authorization"] = "Bearer $token";
                options.headers["X-Auth-Token"] = token;
              }

              handler.next(options);
            },

            // ✅ NEW: decode JSON even if server returns it as String
            onResponse: (response, handler) {
              final data = response.data;

              // Many PHP endpoints return JSON as plain text (wrong headers)
              // So Dio gives String. Decode it safely here once for all APIs.
              if (data is String) {
                final s = data.trim();
                if ((s.startsWith("{") && s.endsWith("}")) ||
                    (s.startsWith("[") && s.endsWith("]"))) {
                  try {
                    response.data = jsonDecode(s);
                  } catch (_) {
                    // leave as is
                  }
                }
              }

              handler.next(response);
            },

            onError: (e, handler) {
              debugPrint("API ERROR => ${e.message}");
              handler.next(e);
            },
          ),
        );

  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  static Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    debugPrint("API REQUEST => POST ${_dio.options.baseUrl}$path");
    debugPrint("POST DATA TYPE => ${data.runtimeType}");

    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
