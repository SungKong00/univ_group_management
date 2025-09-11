import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<LoginResponse>.fromJson(
          response.data,
          (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
        );
        return apiResponse;
      } else {
        return ApiResponse.failure(
          error: ErrorResponse(
            code: 'LOGIN_FAILED',
            message: '로그인에 실패했습니다.',
            details: response.statusMessage,
          ),
        );
      }
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: ErrorResponse(
          code: 'UNKNOWN_ERROR',
          message: '알 수 없는 오류가 발생했습니다.',
          details: e.toString(),
        ),
      );
    }
  }

  Future<ApiResponse<UserModel>> register(RegisterRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final apiResponse = ApiResponse<UserModel>.fromJson(
          response.data,
          (json) => UserModel.fromJson(json as Map<String, dynamic>),
        );
        return apiResponse;
      } else {
        return ApiResponse.failure(
          error: ErrorResponse(
            code: 'REGISTER_FAILED',
            message: '회원가입에 실패했습니다.',
            details: response.statusMessage,
          ),
        );
      }
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: ErrorResponse(
          code: 'UNKNOWN_ERROR',
          message: '알 수 없는 오류가 발생했습니다.',
          details: e.toString(),
        ),
      );
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _dioClient.dio.post(ApiEndpoints.logout);

      if (response.statusCode == 200) {
        return ApiResponse.success(data: null, message: '로그아웃되었습니다.');
      } else {
        return ApiResponse.failure(
          error: ErrorResponse(
            code: 'LOGOUT_FAILED',
            message: '로그아웃에 실패했습니다.',
            details: response.statusMessage,
          ),
        );
      }
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: ErrorResponse(
          code: 'UNKNOWN_ERROR',
          message: '알 수 없는 오류가 발생했습니다.',
          details: e.toString(),
        ),
      );
    }
  }

  ApiResponse<T> _handleDioException<T>(DioException e) {
    String code;
    String message;
    String? details;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        code = 'TIMEOUT_ERROR';
        message = '요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.';
        break;
      case DioExceptionType.badResponse:
        code = _getErrorCodeFromResponse(e.response);
        message = _getErrorMessageFromResponse(e.response);
        details = e.response?.data?.toString();
        break;
      case DioExceptionType.connectionError:
        code = 'CONNECTION_ERROR';
        message = '네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요.';
        break;
      default:
        code = 'NETWORK_ERROR';
        message = '네트워크 오류가 발생했습니다.';
        details = e.message;
    }

    return ApiResponse.failure(
      error: ErrorResponse(code: code, message: message, details: details),
    );
  }

  String _getErrorCodeFromResponse(Response? response) {
    if (response?.data is Map<String, dynamic>) {
      final errorData = response!.data['error'];
      if (errorData is Map<String, dynamic>) {
        return errorData['code'] ?? 'UNKNOWN_ERROR';
      }
    }
    return 'HTTP_${response?.statusCode ?? 'UNKNOWN'}';
  }

  String _getErrorMessageFromResponse(Response? response) {
    if (response?.data is Map<String, dynamic>) {
      final errorData = response!.data['error'];
      if (errorData is Map<String, dynamic>) {
        return errorData['message'] ?? '요청 처리 중 오류가 발생했습니다.';
      }
    }
    
    switch (response?.statusCode) {
      case 400:
        return '잘못된 요청입니다.';
      case 401:
        return '인증이 필요합니다.';
      case 403:
        return '접근 권한이 없습니다.';
      case 404:
        return '요청한 리소스를 찾을 수 없습니다.';
      case 409:
        return '이미 존재하는 데이터입니다.';
      case 422:
        return '입력 데이터가 유효하지 않습니다.';
      case 500:
        return '서버 내부 오류가 발생했습니다.';
      default:
        return '요청 처리 중 오류가 발생했습니다.';
    }
  }
}