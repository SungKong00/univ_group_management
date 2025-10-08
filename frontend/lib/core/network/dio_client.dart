import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../services/local_storage.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => developer.log(object.toString(), name: 'Dio'),
      ));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 401 Unauthorized 에러 처리
        if (error.response?.statusCode == 401) {
          final requestOptions = error.requestOptions;

          // 이미 재시도한 요청이면 에러 반환 (무한 루프 방지)
          if (requestOptions.extra['retry'] == true) {
            developer.log('Token refresh retry failed, rejecting request', name: 'Dio', level: 900);
            return handler.reject(error);
          }

          try {
            // 토큰 갱신 시도
            await _handleTokenRefresh();

            // 갱신 성공 시 원래 요청 재시도
            final newToken = await _storage.getAccessToken();
            if (newToken != null) {
              requestOptions.headers['Authorization'] = 'Bearer $newToken';
              requestOptions.extra['retry'] = true; // 재시도 플래그 설정

              developer.log('Retrying request after token refresh: ${requestOptions.path}', name: 'Dio');

              // 원래 요청 재시도
              final response = await _dio.fetch(requestOptions);
              return handler.resolve(response);
            } else {
              developer.log('No access token after refresh', name: 'Dio', level: 900);
              return handler.reject(error);
            }
          } catch (refreshError) {
            developer.log('Token refresh error: $refreshError', name: 'Dio', level: 900);
            // 토큰 갱신 실패 시 로그아웃 처리는 _handleTokenRefresh에서 수행
            return handler.reject(error);
          }
        } else {
          handler.next(error);
        }
      },
    ));
  }

  late final Dio _dio;
  final LocalStorage _storage = LocalStorage.instance;

  // 토큰 갱신 중복 요청 방지를 위한 플래그
  bool _isRefreshing = false;

  Dio get dio => _dio;

  Future<void> _handleTokenRefresh() async {
    // 이미 갱신 중이면 대기
    if (_isRefreshing) {
      throw Exception('Token refresh already in progress');
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      developer.log('Attempting token refresh...', name: 'Dio');

      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];

        await _storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        developer.log('Token refresh successful', name: 'Dio');
      } else {
        throw Exception('Token refresh failed with status: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Token refresh failed: $e', name: 'Dio', level: 900);
      await clearTokens();
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> clearTokens() async {
    await _storage.clearAuthData();
  }

  // HTTP methods with proper typing
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}
