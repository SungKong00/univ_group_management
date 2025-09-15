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

  Future<ApiResponse<T>> get<T>(
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

