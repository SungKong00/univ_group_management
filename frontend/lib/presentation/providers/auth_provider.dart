import 'package:flutter/foundation.dart';
import '../../core/network/api_response.dart';
import '../../data/models/auth_models.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, needsOnboarding, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  AuthProvider(this._repo);

  AuthState _state = AuthState.initial;
  AuthState get state => _state;
  UserModel? _user;
  UserModel? get user => _user;
  String? _error;
  String? get error => _error;

  bool get isLoading => _state == AuthState.loading;

  Future<void> check() async {
    _set(AuthState.loading);
    if (await _repo.hasToken()) {
      final me = await _repo.me();
      if (me.isSuccess && me.data != null) {
        _user = me.data;
        _set(AuthState.authenticated);
      } else {
        _set(AuthState.unauthenticated);
      }
    } else {
      _set(AuthState.unauthenticated);
    }
  }

  Future<bool> loginWithGoogle(String idToken) async {
    _set(AuthState.loading);
    final ApiResponse<LoginResponse> res = await _repo.loginWithGoogleIdToken(idToken);
    if (res.isSuccess && res.data != null) {
      _user = res.data!.user;
      if (res.data!.firstLogin) {
        _set(AuthState.needsOnboarding);
      } else {
        _set(AuthState.authenticated);
      }
      return true;
    }
    _error = res.error?.message ?? '로그인에 실패했습니다.';
    _set(AuthState.error);
    return false;
  }

  Future<bool> loginWithGoogleTokens({String? idToken, String? accessToken}) async {
    _set(AuthState.loading);
    final ApiResponse<LoginResponse> res = await _repo.loginWithGoogleTokens(idToken: idToken, accessToken: accessToken);
    if (res.isSuccess && res.data != null) {
      _user = res.data!.user;
      if (res.data!.firstLogin) {
        _set(AuthState.needsOnboarding);
      } else {
        _set(AuthState.authenticated);
      }
      return true;
    }
    _error = res.error?.message ?? '로그인에 실패했습니다.';
    _set(AuthState.error);
    return false;
  }

  Future<bool> submitOnboarding(OnboardingRequest req) async {
    _set(AuthState.loading);
    final res = await _repo.submitOnboarding(req);
    if (res.isSuccess && res.data != null) {
      _user = res.data;
      _set(AuthState.authenticated);
      return true;
    }
    _error = res.error?.message ?? '회원가입에 실패했습니다.';
    _set(AuthState.error);
    return false;
  }

  void clearError() {
    _error = null;
    if (_state == AuthState.error) {
      _set(_user != null ? AuthState.authenticated : AuthState.unauthenticated);
    }
  }

  void _set(AuthState s) {
    _state = s;
    notifyListeners();
  }

  // Nickname check does not mutate auth state; returns result or null on failure.
  Future<NicknameCheckResult?> checkNickname(String nickname) async {
    final res = await _repo.checkNickname(nickname);
    if (res.isSuccess && res.data != null) return res.data;
    return null;
  }

  Future<bool> sendEmailOtp(String email) async {
    final res = await _repo.sendEmailOtp(email);
    return res.isSuccess;
  }

  Future<bool> verifyEmailOtp(String email, String code) async {
    final res = await _repo.verifyEmailOtp(email, code);
    return res.isSuccess;
  }
}
