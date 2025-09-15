import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../models/auth_models.dart';

class AuthService {
  final DioClient _dio;
  AuthService(this._dio);

  Future<ApiResponse<LoginResponse>> loginWithGoogleIdToken(String idToken) async {
    try {
      final Response resp = await _dio.dio.post(
        ApiEndpoints.googleCallback,
        data: {'id_token': idToken},
      );
      return ApiResponse.fromJson(
        resp.data as Map<String, dynamic>,
        (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _errorFromDio<LoginResponse>(e);
    }
  }

  Future<ApiResponse<LoginResponse>> loginWithGoogleTokens({String? idToken, String? accessToken}) async {
    if (idToken != null && idToken.isNotEmpty) {
      return loginWithGoogleIdToken(idToken);
    }
    try {
      final Response resp = await _dio.dio.post(
        ApiEndpoints.googleFallback,
        data: {
          if (idToken != null && idToken.isNotEmpty) 'googleAuthToken': idToken,
          if (accessToken != null && accessToken.isNotEmpty) 'googleAccessToken': accessToken,
        },
      );
      return ApiResponse.fromJson(
        resp.data as Map<String, dynamic>,
        (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _errorFromDio<LoginResponse>(e);
    }
  }

  Future<ApiResponse<UserModel>> submitOnboarding(OnboardingRequest request) async {
    try {
      final Response resp = await _dio.dio.post(
        ApiEndpoints.users,
        data: request.toJson(),
      );
      return ApiResponse.fromJson(
        resp.data as Map<String, dynamic>,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _errorFromDio<UserModel>(e);
    }
  }

  Future<ApiResponse<UserModel>> me() async {
    try {
      final Response resp = await _dio.dio.get(ApiEndpoints.me);
      return ApiResponse.fromJson(
        resp.data as Map<String, dynamic>,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _errorFromDio<UserModel>(e);
    }
  }

  Future<ApiResponse<NicknameCheckResult>> checkNickname(String nickname) async {
    try {
      final Response resp = await _dio.dio.get(
        ApiEndpoints.nicknameCheck(nickname),
      );
      return ApiResponse.fromJson(
        resp.data as Map<String, dynamic>,
        (json) => NicknameCheckResult.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _errorFromDio<NicknameCheckResult>(e);
    }
  }

  Future<ApiResponse<String>> logout() async {
    try {
      final Response resp = await _dio.dio.post(ApiEndpoints.logout);
      return ApiResponse.fromJson(
        resp.data as Map<String, dynamic>,
        (json) => json as String,
      );
    } on DioException catch (e) {
      return _errorFromDio<String>(e);
    }
  }

  ApiResponse<T> _errorFromDio<T>(DioException e) {
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
        code: 'NETWORK_ERROR',
        message: e.message ?? '네트워크 오류가 발생했습니다.',
        details: e.response?.statusMessage,
      ),
    );
  }

  // --- Email OTP (mockable for MVP) ---
  Future<ApiResponse<void>> sendEmailOtp(String email) async {
    if (AppConstants.mockEmailVerification) {
      // Immediately succeed without network
      return ApiResponse<void>(success: true);
    }
    try {
      final Response resp = await _dio.dio.post(ApiEndpoints.emailSend, data: {'email': email});
      return ApiResponse<void>.fromJson(resp.data as Map<String, dynamic>, (json) => null);
    } on DioException catch (e) {
      return _errorFromDio<void>(e);
    }
  }

  Future<ApiResponse<void>> verifyEmailOtp(String email, String code) async {
    if (AppConstants.mockEmailVerification) {
      // Immediately succeed without network
      return ApiResponse<void>(success: true);
    }
    try {
      final Response resp = await _dio.dio.post(ApiEndpoints.emailVerify, data: {'email': email, 'code': code});
      return ApiResponse<void>.fromJson(resp.data as Map<String, dynamic>, (json) => null);
    } on DioException catch (e) {
      return _errorFromDio<void>(e);
    }
  }
}
