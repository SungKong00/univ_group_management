import 'dart:convert';
import 'dart:developer' as developer;
import '../models/auth_models.dart';
import '../network/dio_client.dart';
import '../services/local_storage.dart';

/// 인증 관련 Repository
///
/// 유저 정보 저장 경로를 단일화하고, 3-Layer Architecture를 준수합니다.
/// - LocalStorage를 통한 토큰/유저 정보 영속화
/// - DioClient를 통한 서버 API 호출
/// - 상태 진실의 원천(Single Source of Truth) 역할
abstract class AuthRepository {
  /// 저장된 토큰으로 자동 로그인 시도
  ///
  /// Returns:
  /// - UserInfo: 토큰 검증 성공 및 유저 정보 조회 성공
  /// - null: 토큰 없음 또는 만료됨
  Future<UserInfo?> tryAutoLogin();

  /// Google OAuth 로그인
  ///
  /// Parameters:
  /// - idToken: Google ID Token (선택)
  /// - accessToken: Google Access Token (선택)
  ///
  /// 최소 하나의 토큰이 필요합니다.
  ///
  /// Returns: 로그인 성공 시 UserInfo
  /// Throws: 로그인 실패 시 Exception
  Future<UserInfo> login({String? idToken, String? accessToken});

  /// 로그아웃
  ///
  /// - 서버에 로그아웃 요청 (실패해도 로컬 토큰 삭제)
  /// - LocalStorage의 모든 인증 데이터 삭제
  /// - 네비게이션 상태 초기화
  Future<void> logout();

  /// 현재 저장된 유저 정보 조회
  ///
  /// Returns:
  /// - UserInfo: LocalStorage에 유저 정보가 있음
  /// - null: 유저 정보 없음
  Future<UserInfo?> getCurrentUser();

  /// 유저 정보 업데이트
  ///
  /// Parameters:
  /// - updatedUser: 업데이트할 유저 정보
  ///
  /// LocalStorage에 새 유저 정보를 저장합니다.
  Future<void> updateUser(UserInfo updatedUser);
}

/// AuthRepository의 실제 API 연동 구현체
class ApiAuthRepository implements AuthRepository {
  final LocalStorage _localStorage;
  final DioClient _dioClient;

  ApiAuthRepository({
    required LocalStorage localStorage,
    required DioClient dioClient,
  }) : _localStorage = localStorage,
       _dioClient = dioClient;

  @override
  Future<UserInfo?> tryAutoLogin() async {
    try {
      final accessToken = await _localStorage.getAccessToken();
      final userDataJson = await _localStorage.getUserData();

      if (accessToken == null || userDataJson == null) {
        return null;
      }

      // 토큰 유효성 검증 API 호출
      try {
        final response = await _dioClient.get<Map<String, dynamic>>(
          '/auth/verify',
        );

        if (response.statusCode == 200 && response.data != null) {
          final apiResponse = ApiResponse.fromJson(
            response.data!,
            (json) => UserInfo.fromJson(json as Map<String, dynamic>),
          );

          if (apiResponse.success && apiResponse.data != null) {
            // ✅ Repository에서만 저장
            await _localStorage.saveUserData(
              json.encode(apiResponse.data!.toJson()),
            );
            return apiResponse.data;
          } else {
            throw Exception(
              'Token verification failed: ${apiResponse.message}',
            );
          }
        } else {
          throw Exception('Invalid response from verification endpoint');
        }
      } catch (e) {
        developer.log(
          'Token verification failed: $e',
          name: 'AuthRepository',
          level: 900,
        );

        // 토큰 검증 실패 시 로컬 데이터 삭제 (만료된 토큰)
        await _localStorage.clearAuthData();
        return null;
      }
    } catch (e) {
      developer.log(
        'Auto login failed: $e',
        name: 'AuthRepository',
        level: 900,
      );
      // 예외 발생 시 로컬 데이터 정리
      await _localStorage.clearAuthData();
      return null;
    }
  }

  @override
  Future<UserInfo> login({String? idToken, String? accessToken}) async {
    developer.log(
      '[Login] Starting login (${DateTime.now()})',
      name: 'AuthRepository',
    );

    if ((idToken == null || idToken.isEmpty) &&
        (accessToken == null || accessToken.isEmpty)) {
      throw Exception('ID 토큰 또는 Access 토큰이 필요합니다.');
    }

    final payload = <String, String>{};
    if (idToken != null && idToken.isNotEmpty) {
      payload['googleAuthToken'] = idToken;
    }
    if (accessToken != null && accessToken.isNotEmpty) {
      payload['googleAccessToken'] = accessToken;
    }

    final response = await _dioClient.post<Map<String, dynamic>>(
      '/auth/google',
      data: payload,
    );

    if (response.data == null) {
      throw Exception('No response data');
    }

    final apiResponse = ApiResponse.fromJson(
      response.data!,
      (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message ?? 'Login failed');
    }

    final loginResponse = apiResponse.data!;

    developer.log(
      '[Login] API call completed, saving tokens (${DateTime.now()})',
      name: 'AuthRepository',
    );

    // ✅ Repository에서만 저장
    await _localStorage.saveTokens(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken ?? '', // ✅ 수정: tokenType → refreshToken
    );

    developer.log(
      '[Login] Tokens saved (${DateTime.now()})',
      name: 'AuthRepository',
    );

    await _localStorage.saveUserData(json.encode(loginResponse.user.toJson()));

    developer.log(
      '[Login] Login completed (${DateTime.now()})',
      name: 'AuthRepository',
    );

    return loginResponse.user;
  }

  @override
  Future<void> logout() async {
    developer.log(
      '[Logout] Starting logout (${DateTime.now()})',
      name: 'AuthRepository',
    );

    try {
      // 서버에 로그아웃 요청
      await _dioClient.post('/auth/logout');
    } catch (e) {
      developer.log(
        'Server logout failed: $e',
        name: 'AuthRepository',
        level: 900,
      );
      // 서버 로그아웃 실패해도 로컬 토큰은 삭제
    }

    developer.log(
      '[Logout] Clearing auth data (${DateTime.now()})',
      name: 'AuthRepository',
    );

    // ✅ Repository에서만 삭제
    await _localStorage.clearAuthData();
    await _localStorage.clearNavigationState();

    developer.log(
      '[Logout] Logout completed (${DateTime.now()})',
      name: 'AuthRepository',
    );
  }

  @override
  Future<UserInfo?> getCurrentUser() async {
    final userDataJson = await _localStorage.getUserData();
    if (userDataJson == null) return null;

    try {
      final jsonMap = jsonDecode(userDataJson) as Map<String, dynamic>;
      return UserInfo.fromJson(jsonMap);
    } catch (e) {
      developer.log(
        'Failed to parse user data: $e',
        name: 'AuthRepository',
        level: 900,
      );
      return null;
    }
  }

  @override
  Future<void> updateUser(UserInfo updatedUser) async {
    await _localStorage.saveUserData(json.encode(updatedUser.toJson()));
  }
}
