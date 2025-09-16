import 'package:dio/dio.dart';
import '../network/api_response.dart';

class ErrorHandler {
  static ApiResponse<T> handleDioError<T>(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      try {
        return ApiResponse<T>.fromJson(
          data,
          (json) => json as T,
        );
      } catch (_) {}
    }

    return ApiResponse<T>(
      success: false,
      error: ApiError(
        code: _getErrorCode(e),
        message: _getErrorMessage(e),
        details: e.response?.statusMessage,
      ),
    );
  }

  static String _getErrorCode(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'TIMEOUT_ERROR';
      case DioExceptionType.connectionError:
        return 'CONNECTION_ERROR';
      case DioExceptionType.badResponse:
        return 'HTTP_${e.response?.statusCode ?? 'UNKNOWN'}';
      case DioExceptionType.cancel:
        return 'REQUEST_CANCELLED';
      default:
        return 'NETWORK_ERROR';
    }
  }

  static String _getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '연결 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.';
      case DioExceptionType.sendTimeout:
        return '요청 전송 시간이 초과되었습니다.';
      case DioExceptionType.receiveTimeout:
        return '응답 수신 시간이 초과되었습니다.';
      case DioExceptionType.connectionError:
        return '네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요.';
      case DioExceptionType.badResponse:
        return _getHttpErrorMessage(e.response?.statusCode);
      case DioExceptionType.cancel:
        return '요청이 취소되었습니다.';
      default:
        return e.message ?? '알 수 없는 네트워크 오류가 발생했습니다.';
    }
  }

  static String _getHttpErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다.';
      case 401:
        return '인증이 필요합니다. 다시 로그인해주세요.';
      case 403:
        return '접근 권한이 없습니다.';
      case 404:
        return '요청한 리소스를 찾을 수 없습니다.';
      case 409:
        return '요청이 현재 서버 상태와 충돌합니다.';
      case 422:
        return '입력 데이터를 처리할 수 없습니다.';
      case 500:
        return '서버 내부 오류가 발생했습니다.';
      case 502:
        return '서버가 응답하지 않습니다.';
      case 503:
        return '서비스를 사용할 수 없습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '서버 오류가 발생했습니다. (HTTP $statusCode)';
    }
  }

  static ApiResponse<T> handleGenericError<T>(dynamic error) {
    return ApiResponse<T>(
      success: false,
      error: ApiError(
        code: 'UNKNOWN_ERROR',
        message: '예상치 못한 오류가 발생했습니다: ${error.toString()}',
      ),
    );
  }
}