import 'dart:convert';
import '../../core/network/api_response.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl(this._authService, this._tokenStorage);

  @override
  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    final result = await _authService.login(request);
    
    if (result.isSuccess && result.data != null) {
      await saveUserSession(result.data!);
    }
    
    return result;
  }

  @override
  Future<ApiResponse<UserModel>> register(RegisterRequest request) async {
    return await _authService.register(request);
  }

  @override
  Future<ApiResponse<void>> logout() async {
    final result = await _authService.logout();
    
    // 로그아웃 성공 여부와 관계없이 로컬 세션은 클리어
    await clearUserSession();
    
    return result;
  }

  @override
  Future<ApiResponse<LoginResponse>> loginWithGoogle(String idToken) async {
    final result = await _authService.loginWithGoogle(idToken);
    if (result.isSuccess && result.data != null) {
      await saveUserSession(result.data!);
    }
    return result;
  }

  @override
  Future<ApiResponse<LoginResponse>> loginWithGoogleAccessToken(String accessToken) async {
    final result = await _authService.loginWithGoogleAccessToken(accessToken);
    if (result.isSuccess && result.data != null) {
      await saveUserSession(result.data!);
    }
    return result;
  }

  @override
  Future<ApiResponse<UserModel>> completeProfile(ProfileUpdateRequest request) async {
    final response = await _authService.completeProfile(request);
    
    // 프로필 완성 성공 시 로컬에 저장된 사용자 정보 업데이트
    if (response.success && response.data != null) {
      await _tokenStorage.saveUserData(jsonEncode(response.data!.toJson()));
    }
    
    return response;
  }

  @override
  Future<bool> isLoggedIn() async {
    final accessToken = await _tokenStorage.getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final userDataJson = await _tokenStorage.getUserData();
      if (userDataJson != null) {
        final userMap = jsonDecode(userDataJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      }
    } catch (e) {
      // JSON 파싱 오류 등의 경우 null 반환
      print('Error parsing user data: $e');
    }
    return null;
  }

  @override
  Future<void> saveUserSession(LoginResponse loginResponse) async {
    await Future.wait([
      _tokenStorage.saveAccessToken(loginResponse.accessToken),
      _tokenStorage.saveUserData(jsonEncode(loginResponse.user.toJson())),
    ]);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? userJson,
  }) async {
    final futures = <Future<void>>[
      _tokenStorage.saveAccessToken(accessToken),
    ];
    if (refreshToken != null) futures.add(_tokenStorage.saveRefreshToken(refreshToken));
    if (userJson != null) futures.add(_tokenStorage.saveUserData(userJson));
    await Future.wait(futures);
  }

  @override
  Future<void> clearUserSession() async {
    await Future.wait([
      _tokenStorage.clearTokens(),
      _tokenStorage.clearUserData(),
    ]);
  }
}
