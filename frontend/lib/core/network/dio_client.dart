import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Dio get dio => _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => print(object),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _handleTokenRefresh();
          handler.next(error);
        } else {
          handler.next(error);
        }
      },
    ));
  }

  Future<void> _handleTokenRefresh() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken != null) {
        final response = await _dio.post('/auth/refresh', data: {
          'refreshToken': refreshToken,
        });

        if (response.statusCode == 200) {
          final newAccessToken = response.data['accessToken'];
          final newRefreshToken = response.data['refreshToken'];

          await _storage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
          await _storage.write(key: AppConstants.refreshTokenKey, value: newRefreshToken);
        }
      }
    } catch (e) {
      await clearTokens();
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userDataKey);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }
}