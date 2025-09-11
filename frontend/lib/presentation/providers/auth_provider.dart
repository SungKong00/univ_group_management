import 'package:flutter/foundation.dart';
import '../../injection/injection.dart';
import '../../core/auth/google_signin.dart';
import '../../data/models/user_model.dart';
import '../../core/network/api_response.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  AuthState _state = AuthState.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  Future<void> checkAuthStatus() async {
    _setState(AuthState.loading);

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          _currentUser = user;
          _setState(AuthState.authenticated);
        } else {
          _setState(AuthState.unauthenticated);
        }
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError('인증 상태 확인 중 오류가 발생했습니다.');
    }
  }

  Future<bool> login(String email, String password) async {
    _setState(AuthState.loading);

    try {
      final request = LoginRequest(email: email, password: password);
      final result = await _authRepository.login(request);

      if (result.isSuccess && result.data != null) {
        _currentUser = result.data!.user;
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setError(result.error?.message ?? '로그인에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('로그인 중 오류가 발생했습니다.');
      return false;
    }
  }

  Future<bool> loginWithGoogle(String idToken) async {
    _setState(AuthState.loading);

    try {
      final result = await _authRepository.loginWithGoogle(idToken);
      if (result.isSuccess && result.data != null) {
        _currentUser = result.data!.user;
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setError(result.error?.message ?? 'Google 로그인에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('Google 로그인 중 오류가 발생했습니다.');
      return false;
    }
  }

  Future<bool> loginWithGoogleTokens({String? idToken, String? accessToken}) async {
    _setState(AuthState.loading);
    try {
      ApiResponse<LoginResponse> result;
      if (idToken != null && idToken.isNotEmpty) {
        result = await _authRepository.loginWithGoogle(idToken);
      } else if (accessToken != null && accessToken.isNotEmpty) {
        result = await _authRepository.loginWithGoogleAccessToken(accessToken);
      } else {
        _setError('유효한 Google 토큰이 없습니다.');
        return false;
      }

      if (result.isSuccess && result.data != null) {
        _currentUser = result.data!.user;
        // 디버그: 사용자 정보 출력
        print('DEBUG: User logged in - profileCompleted: ${_currentUser!.profileCompleted}');
        print('DEBUG: User info - name: ${_currentUser!.name}, email: ${_currentUser!.email}');
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setError(result.error?.message ?? 'Google 로그인에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('Google 로그인 중 오류가 발생했습니다.');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setState(AuthState.loading);

    try {
      final request = RegisterRequest(name: name, email: email, password: password);
      final result = await _authRepository.register(request);

      if (result.isSuccess && result.data != null) {
        // 회원가입 성공 후 자동 로그인
        return await login(email, password);
      } else {
        _setError(result.error?.message ?? '회원가입에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('회원가입 중 오류가 발생했습니다.');
      return false;
    }
  }

  Future<void> logout() async {
    // 즉시 로컬 세션 해제 후 UI 전환이 가능하도록 처리
    try {
      await _authRepository.clearUserSession();
    } catch (_) {}
    _currentUser = null;
    _setState(AuthState.unauthenticated);

    // 백그라운드로 서버 로그아웃 및 Google 세션 해제 시도 (실패 무시)
    Future.microtask(() async {
      try {
        await _authRepository.logout();
      } catch (_) {}
      try {
        final google = getIt<GoogleSignInService>();
        await google.signOut();
      } catch (_) {}
    });
  }

  Future<bool> completeProfile(ProfileUpdateRequest request) async {
    try {
      _setState(AuthState.loading);
      final response = await _authRepository.completeProfile(request);
      
      if (response.success && response.data != null) {
        _currentUser = response.data;
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setError(response.error?.message ?? '프로필 완성에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('프로필 완성 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _setState(_currentUser != null 
          ? AuthState.authenticated 
          : AuthState.unauthenticated);
    }
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(AuthState.error);
  }
}
