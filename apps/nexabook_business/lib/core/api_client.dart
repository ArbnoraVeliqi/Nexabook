import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    final String baseUrl = _getBaseUrl();

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final preferences = await SharedPreferences.getInstance();
          final token = preferences.getString('token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );
  }

  String _getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:5080/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5080/api';
    }

    return 'http://localhost:5080/api';
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await dio.get(
      path,
      queryParameters: query,
    );

    return response.data;
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
  }) async {
    final response = await dio.post(
      path,
      data: data,
    );

    return response.data;
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
  }) async {
    final response = await dio.put(
      path,
      data: data,
    );

    return response.data;
  }

  Future<void> delete(String path) async {
    await dio.delete(path);
  }
}