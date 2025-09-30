import 'dart:convert';
import 'dart:developer' as developer;
import '../models/auth_models.dart';
import '../network/dio_client.dart';
import '../router/app_router.dart';
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

          // GoRouter에 인증 상태 변경 알림
          authChangeNotifier.notifyAuthChanged();

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

  /// Google OAuth 토큰으로 로그인 (ID Token 또는 Access Token)
  Future<LoginResponse> loginWithGoogle({String? idToken, String? accessToken}) async {
    // DioClient가 초기화되지 않은 경우 자동 초기화
    if (_dioClient == null) {
      initialize();
    }

    if ((idToken == null || idToken.isEmpty) && (accessToken == null || accessToken.isEmpty)) {
      throw Exception('ID 토큰 또는 Access 토큰이 필요합니다.');
    }

    final payload = <String, String>{};
    if (idToken != null && idToken.isNotEmpty) {
      payload['googleAuthToken'] = idToken;
    }
    if (accessToken != null && accessToken.isNotEmpty) {
      payload['googleAccessToken'] = accessToken;
    }

    try {
      final response = await _dioClient!.post<Map<String, dynamic>>(
        '/auth/google',
        data: payload,
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

          // GoRouter에 인증 상태 변경 알림
          authChangeNotifier.notifyAuthChanged();

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

  /// Google ID Token으로 로그인 (하위 호환용)
  Future<LoginResponse> loginWithGoogleToken(String idToken) {
    return loginWithGoogle(idToken: idToken);
  }

  /// 저장된 토큰으로 자동 로그인 시도
  Future<bool> tryAutoLogin() async {
    try {
      final accessToken = await _storage.getAccessToken();
      final userDataJson = await _storage.getUserData();

      if (accessToken == null || userDataJson == null) {
        developer.log('No stored token or user data found', name: 'AuthService');
        return false;
      }

      // DioClient가 초기화되지 않은 경우 자동 초기화
      if (_dioClient == null) {
        initialize();
      }

      developer.log('Attempting auto login with stored token', name: 'AuthService');

      // 토큰 유효성 검증 API 호출
      try {
        final response = await _dioClient!.get<Map<String, dynamic>>('/auth/verify');

        if (response.statusCode == 200 && response.data != null) {
          // API 응답에서 사용자 정보 파싱
          final apiResponse = ApiResponse.fromJson(
            response.data!,
            (json) => UserInfo.fromJson(json as Map<String, dynamic>),
          );

          if (apiResponse.success && apiResponse.data != null) {
            _currentUser = apiResponse.data!;
            // 최신 사용자 정보로 로컬 스토리지 업데이트
            await _saveUserInfo(_currentUser!);

            developer.log('Auto login successful: ${_currentUser!.email}', name: 'AuthService');
            return true;
          } else {
            throw Exception('Token verification failed: ${apiResponse.message}');
          }
        } else {
          throw Exception('Invalid response from verification endpoint');
        }
      } catch (e) {
        developer.log('Token verification failed: $e', name: 'AuthService', level: 900);

        // 토큰 검증 실패 시 로컬 데이터 삭제 (만료된 토큰)
        await _clearTokens();
        _currentUser = null;

        return false;
      }
    } catch (e) {
      developer.log('Auto login failed: $e', name: 'AuthService', level: 900);
      // 예외 발생 시 로컬 데이터 정리
      await _clearTokens();
      _currentUser = null;
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

    // GoRouter에 인증 상태 변경 알림
    authChangeNotifier.notifyAuthChanged();
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
