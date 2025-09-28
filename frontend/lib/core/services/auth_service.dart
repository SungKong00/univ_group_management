import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';
import '../constants/app_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  DioClient? _dioClient;
  UserInfo? _currentUser;

  void initialize() {
    _dioClient ??= DioClient();
  }

  UserInfo? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// 테스트 계정으로 로그인 (개발용)
  Future<LoginResponse> loginWithTestAccount() async {
    try {
      // 실제 백엔드 API 호출을 위한 더미 토큰 생성
      // 백엔드에서는 test 토큰을 받으면 castlekong1019@gmail.com 계정으로 로그인 처리
      final response = await _dioClient!.post<Map<String, dynamic>>(
        '/auth/google/callback',
        data: {
          'id_token': 'mock_google_token_for_castlekong1019',
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          final loginResponse = apiResponse.data!;
          await _saveTokens(loginResponse.accessToken, loginResponse.tokenType);
          await _saveUserInfo(loginResponse.user);
          _currentUser = loginResponse.user;
          return loginResponse;
        } else {
          throw Exception(apiResponse.message ?? 'Login failed');
        }
      } else {
        throw Exception('No response data');
      }
    } catch (e) {
      print('Test login error details: $e');
      throw Exception('테스트 로그인 실패: ${e.toString()}');
    }
  }

  /// Google ID Token으로 로그인
  Future<LoginResponse> loginWithGoogleToken(String idToken) async {
    try {
      final response = await _dioClient!.post<Map<String, dynamic>>(
        '/auth/google/callback',
        data: {
          'id_token': idToken,
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          final loginResponse = apiResponse.data!;
          await _saveTokens(loginResponse.accessToken, loginResponse.tokenType);
          await _saveUserInfo(loginResponse.user);
          _currentUser = loginResponse.user;
          return loginResponse;
        } else {
          throw Exception(apiResponse.message ?? 'Login failed');
        }
      } else {
        throw Exception('No response data');
      }
    } catch (e) {
      throw Exception('Google login failed: $e');
    }
  }

  /// 저장된 토큰으로 자동 로그인 시도
  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(AppConstants.accessTokenKey);
      final userDataJson = prefs.getString(AppConstants.userDataKey);

      if (accessToken != null && userDataJson != null) {
        final userData = json.decode(userDataJson) as Map<String, dynamic>;
        _currentUser = UserInfo.fromJson(userData);

        // TODO: 토큰 유효성 검증 API 호출
        // 현재는 저장된 정보만으로 자동 로그인 처리
        return true;
      }

      return false;
    } catch (e) {
      print('Auto login failed: $e');
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      // 서버에 로그아웃 요청
      await _dioClient!.post('/auth/logout');
    } catch (e) {
      print('Server logout failed: $e');
      // 서버 로그아웃 실패해도 로컬 토큰은 삭제
    }

    // 로컬 토큰 및 사용자 정보 삭제
    await _clearTokens();
    _currentUser = null;
  }

  /// 토큰 저장
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, accessToken);
    await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
  }

  /// 사용자 정보 저장
  Future<void> _saveUserInfo(UserInfo userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userDataKey, json.encode(userInfo.toJson()));
  }

  /// 토큰 및 사용자 정보 삭제
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
  }

  /// 저장된 액세스 토큰 반환
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  /// 저장된 리프레시 토큰 반환
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.refreshTokenKey);
  }
}