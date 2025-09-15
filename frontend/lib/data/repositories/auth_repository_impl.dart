import 'dart:convert';
import '../../core/network/api_response.dart';
import '../../core/storage/token_storage.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _service;
  final TokenStorage _storage;

  AuthRepositoryImpl(this._service, this._storage);

  @override
  Future<ApiResponse<LoginResponse>> loginWithGoogleIdToken(String idToken) async {
    final res = await _service.loginWithGoogleIdToken(idToken);
    if (res.isSuccess && res.data != null) {
      await saveSession(res.data!);
    }
    return res;
  }

  @override
  Future<ApiResponse<LoginResponse>> loginWithGoogleTokens({String? idToken, String? accessToken}) async {
    final res = await _service.loginWithGoogleTokens(idToken: idToken, accessToken: accessToken);
    if (res.isSuccess && res.data != null) {
      await saveSession(res.data!);
    }
    return res;
  }

  @override
  Future<ApiResponse<UserModel>> submitOnboarding(OnboardingRequest request) {
    return _service.submitOnboarding(request);
  }

  @override
  Future<ApiResponse<UserModel>> me() {
    return _service.me();
  }

  @override
  Future<void> saveSession(LoginResponse login) async {
    await _storage.saveAccessToken(login.accessToken);
    await _storage.saveUserData(jsonEncode(login.user.toJson()));
  }

  @override
  Future<bool> hasToken() async => (await _storage.getAccessToken())?.isNotEmpty == true;

  @override
  Future<void> clear() => _storage.clear();

  @override
  Future<UserModel?> getSavedUser() async {
    final raw = await _storage.getUserData();
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ApiResponse<NicknameCheckResult>> checkNickname(String nickname) {
    return _service.checkNickname(nickname);
  }

  @override
  Future<ApiResponse<void>> sendEmailOtp(String email) {
    return _service.sendEmailOtp(email);
  }

  @override
  Future<ApiResponse<void>> verifyEmailOtp(String email, String code) {
    return _service.verifyEmailOtp(email, code);
  }

  @override
  Future<ApiResponse<String>> logout() async {
    final res = await _service.logout();
    if (res.isSuccess) {
      await clear();
    }
    return res;
  }
}
