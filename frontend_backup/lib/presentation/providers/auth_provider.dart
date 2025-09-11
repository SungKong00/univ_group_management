import 'package:flutter/foundation.dart';
import '../../core/network/api_response.dart';
import '../../data/models/user_model.dart';
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
    _setState(AuthState.loading);

    try {
      await _authRepository.logout();
      _currentUser = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      // 로그아웃 실패해도 로컬 상태는 클리어
      _currentUser = null;
      _setState(AuthState.unauthenticated);
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