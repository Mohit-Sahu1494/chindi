import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiClient {
  static const String tokenKey = 'chindi_jwt_token';
  static const String userKey = 'chindi_cached_user';

  final Dio _dio;
  final FlutterSecureStorage _storage;
  VoidCallback? onUnauthorized;

  ApiClient({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                contentType: 'application/json',
                responseType: ResponseType.json,
              ),
            ),
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final path = error.requestOptions.path;
          final isAuthPath = path.contains('/auth/login') || path.contains('/auth/signup');
          if (error.response?.statusCode == 401 && !isAuthPath) {
            // Auto logout ONLY on verified 401 Unauthorized for authenticated requests
            await clearAuth();
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Token & User persistence
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  Future<void> saveUser(UserModel user) async {
    try {
      final jsonStr = jsonEncode(user.toJson());
      await _storage.write(key: userKey, value: jsonStr);
    } catch (e) {
      debugPrint('[ApiClient] Error saving cached user: $e');
    }
  }

  Future<UserModel?> getCachedUser() async {
    try {
      final jsonStr = await _storage.read(key: userKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return UserModel.fromJson(map);
      }
    } catch (e) {
      debugPrint('[ApiClient] Error reading cached user: $e');
    }
    return null;
  }

  Future<void> clearAuth() async {
    try {
      await _storage.delete(key: tokenKey);
      await _storage.delete(key: userKey);
    } catch (_) {}
  }

  ApiException handleError(dynamic error) {
    if (error is DioException) {
      final res = error.response;
      if (res != null) {
        Map<String, dynamic>? data;
        if (res.data is Map) {
          data = Map<String, dynamic>.from(res.data as Map);
        } else if (res.data is String && (res.data as String).trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(res.data as String);
            if (decoded is Map) {
              data = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {}
        }

        if (data != null) {
          String? detailedError;
          if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
            final list = data['errors'] as List;
            final messages = list.map((item) {
              if (item is Map && item['message'] != null) {
                return item['message'].toString();
              }
              return item.toString();
            }).where((msg) => msg.isNotEmpty).toList();
            if (messages.isNotEmpty) {
              detailedError = messages.join('\n');
            }
          }

          final rawMessage = data['message']?.toString();
          final finalMessage = (detailedError != null &&
                  (rawMessage == null || rawMessage == 'Validation error' || rawMessage.isEmpty))
              ? detailedError
              : (rawMessage ?? detailedError ?? _getDefaultStatusMessage(res.statusCode));

          return ApiException(
            finalMessage,
            statusCode: res.statusCode,
            errors: data['errors'],
          );
        }

        return ApiException(
          _getDefaultStatusMessage(res.statusCode),
          statusCode: res.statusCode,
        );
      }

      // No response from server (Network or connection failure)
      return ApiException(
        _getNetworkErrorMessage(error),
        statusCode: null,
      );
    }

    if (error is ApiException) {
      return error;
    }

    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return ApiException(str.substring('Exception: '.length));
    }
    return ApiException(str);
  }

  static String _getDefaultStatusMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Galat jankari darj ki gayi hai (Bad Request)';
      case 401:
        return 'Email and password is incorrect';
      case 403:
        return 'Aapko is data ko dekhne ki anumati nahi hai (Forbidden)';
      case 404:
        return 'Email not found';
      case 409:
        return 'User with this email or mobile already exists';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server par kuch takniki samasya hai. Kripya baad mein prayas karein.';
      default:
        return 'Server error occurred (${statusCode ?? "unknown"})';
    }
  }

  static String _getNetworkErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server connection timeout ho gaya. Kripya internet connection check karein.';
      case DioExceptionType.connectionError:
        return 'Server se connect nahi ho paya. Kripya check karein ki backend server chal raha hai aur network sahi hai.';
      case DioExceptionType.badCertificate:
        return 'Security certificate invalid hai.';
      case DioExceptionType.cancel:
        return 'Request cancel ho gayi.';
      case DioExceptionType.unknown:
      default:
        if (error.error != null && error.error.toString().contains('SocketException')) {
          return 'Internet connection uplabdh nahi hai ya server band hai.';
        }
        return error.message ?? 'Server se sampark nahi ho saka.';
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParameters);
      if (res.data is Map<String, dynamic> && res.data.containsKey('data')) {
        return res.data['data'];
      }
      return res.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      if (res.data is Map<String, dynamic> && res.data.containsKey('data')) {
        return res.data['data'];
      }
      return res.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final res = await _dio.patch(path, data: data);
      if (res.data is Map<String, dynamic> && res.data.containsKey('data')) {
        return res.data['data'];
      }
      return res.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<dynamic> delete(String path, {dynamic data}) async {
    try {
      final res = await _dio.delete(path, data: data);
      if (res.data is Map<String, dynamic> && res.data.containsKey('data')) {
        return res.data['data'];
      }
      return res.data;
    } catch (e) {
      throw handleError(e);
    }
  }
}
