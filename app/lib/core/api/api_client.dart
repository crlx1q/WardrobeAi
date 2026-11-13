import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';

/// Thin wrapper around Dio that injects the JWT and normalizes errors.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'capsule_token';

  Dio get dio => _dio;

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  /// Extracts a human-readable Russian error message from a Dio failure.
  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] != null) return data['error'].toString();
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Нет соединения с сервером';
      }
      return 'Ошибка сервера';
    }
    return 'Что-то пошло не так';
  }

  static bool isPremiumRequired(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['code'] == 'PREMIUM_REQUIRED') return true;
      return error.response?.statusCode == 402;
    }
    return false;
  }
}
