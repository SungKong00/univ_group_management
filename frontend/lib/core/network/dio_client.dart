import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'api_response.dart';

class DioClient {
  final Dio dio;

  DioClient(TokenStorage tokenStorage)
      : dio = Dio(BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(milliseconds: 30000),
          receiveTimeout: const Duration(milliseconds: 30000),
          sendTimeout: const Duration(milliseconds: 30000),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.delete(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> patch(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.patch(path, data: data, queryParameters: queryParameters);
  }

  // Legacy API for backwards compatibility
  Future<ApiResponse<T>> getWithParser<T>(
    String path,
    T Function(dynamic data) parser, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(path, queryParameters: queryParameters);
      return ApiResponse<T>(
        success: true,
        data: parser(response.data['data']),
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: ApiError(code: 'NETWORK_ERROR', message: e.toString()),
      );
    }
  }
}

