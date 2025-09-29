import 'dart:convert';
import 'dart:developer' as developer;
import '../models/auth_models.dart';
import '../network/dio_client.dart';
import 'local_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  DioClient? _dioClient;
  UserInfo? _currentUser;
  final LocalStorage _storage = LocalStorage.instance;

  void initialize() {
    _dioClient ??= DioClient();
  }

  UserInfo? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> updateCurrentUser(UserInfo userInfo) async {
    _currentUser = userInfo;
    await _saveUserInfo(userInfo);
  }

  /// 테스트 계정으로 로그인 (개발용)
  Future<LoginResponse> loginWithTestAccount() async {
    // DioClient가 초기화되지 않은 경우 자동 초기화
    if (_dioClient == null) {
      initialize();
    }

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
      developer.log('Test login error details: $e', name: 'AuthService', level: 900);
      throw Exception('테스트 로그인 실패: ${e.toString()}');
    }
  }

  /// Google ID Token으로 로그인
  Future<LoginResponse> loginWithGoogleToken(String idToken) async {
    // DioClient가 초기화되지 않은 경우 자동 초기화
    if (_dioClient == null) {
      initialize();
    }

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
      final accessToken = await _storage.getAccessToken();
      final userDataJson = await _storage.getUserData();

      if (accessToken != null && userDataJson != null) {
        final userData = json.decode(userDataJson) as Map<String, dynamic>;
        _currentUser = UserInfo.fromJson(userData);
        // 토큰 캐시 동기화
        await _storage.getRefreshToken();

        // TODO: 토큰 유효성 검증 API 호출
        // 현재는 저장된 정보만으로 자동 로그인 처리
        return true;
      }

      return false;
    } catch (e) {
      developer.log('Auto login failed: $e', name: 'AuthService', level: 900);
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      // DioClient가 초기화되지 않은 경우 자동 초기화
      if (_dioClient == null) {
        initialize();
      }

      // 서버에 로그아웃 요청
      await _dioClient!.post('/auth/logout');
    } catch (e) {
      developer.log('Server logout failed: $e', name: 'AuthService', level: 900);
      // 서버 로그아웃 실패해도 로컬 토큰은 삭제
    }

    // 로컬 토큰 및 사용자 정보 삭제
    await _clearTokens();
    _currentUser = null;
  }

  /// 토큰 저장
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  /// 사용자 정보 저장
  Future<void> _saveUserInfo(UserInfo userInfo) async {
    await _storage.saveUserData(json.encode(userInfo.toJson()));
  }

  /// 토큰 및 사용자 정보 삭제
  Future<void> _clearTokens() async {
    await _storage.clearAuthData();
  }

  /// 저장된 액세스 토큰 반환
  Future<String?> getAccessToken() => _storage.getAccessToken();

  /// 저장된 리프레시 토큰 반환
  Future<String?> getRefreshToken() => _storage.getRefreshToken();
}
