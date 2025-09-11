import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class DioClient {
  late final Dio _dio;
  
  DioClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
      sendTimeout: Duration(milliseconds: AppConstants.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  Dio get dio => _dio;
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 토큰 자동 추가 로직 (향후 구현)
          // final token = await _getAccessToken();
          // if (token != null) {
          //   options.headers['Authorization'] = 'Bearer $token';
          // }
          
          print('Request: ${options.method} ${options.path}');
          print('Headers: ${options.headers}');
          print('Data: ${options.data}');
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('Response: ${response.statusCode} ${response.requestOptions.path}');
          print('Data: ${response.data}');
          
          handler.next(response);
        },
        onError: (error, handler) async {
          print('Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('Error Data: ${error.response?.data}');
          
          // 401 에러 시 토큰 갱신 로직 (향후 구현)
          if (error.response?.statusCode == 401) {
            // final refreshed = await _refreshToken();
            // if (refreshed) {
            //   final clonedRequest = await _retry(error.requestOptions);
            //   return handler.resolve(clonedRequest);
            // }
          }
          
          handler.next(error);
        },
      ),
    );
  }
  
  // Future<String?> _getAccessToken() async {
  //   // SharedPreferences 또는 Secure Storage에서 토큰 가져오기
  //   return null;
  // }
  
  // Future<bool> _refreshToken() async {
  //   // 토큰 갱신 로직
  //   return false;
  // }
  
  // Future<Response> _retry(RequestOptions requestOptions) async {
  //   // 요청 재시도 로직
  //   return _dio.request(
  //     requestOptions.path,
  //     data: requestOptions.data,
  //     queryParameters: requestOptions.queryParameters,
  //     options: Options(
  //       method: requestOptions.method,
  //       headers: requestOptions.headers,
  //     ),
  //   );
  // }
}