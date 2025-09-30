import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/auth_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/navigation/navigation_controller.dart';

class AuthState {
  final UserInfo? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    UserInfo? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  AuthState clearError() {
    return AuthState(
      user: user,
      isLoading: isLoading,
      error: null,
    );
  }

  AuthState clearUser() {
    return const AuthState(
      user: null,
      isLoading: false,
      error: null,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);

    try {
      _authService.initialize();

      final success = await _authService.tryAutoLogin();

      if (success && _authService.currentUser != null) {
        state = state.copyWith(
          user: _authService.currentUser,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Auto login failed: ${e.toString()}',
      );
    }
  }

  Future<LoginResponse> loginWithGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.loginWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );

      state = state.copyWith(
        user: response.user,
        isLoading: false,
      );

      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<LoginResponse> loginWithTestAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.loginWithTestAccount();

      state = state.copyWith(
        user: response.user,
        isLoading: false,
      );

      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.logout();

      // NavigationController 초기화 (홈으로 리셋)
      final navigationController = _ref.read(navigationControllerProvider.notifier);
      navigationController.resetToHome();

      state = state.clearUser();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Logout failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> updateUser(UserInfo updatedUser) async {
    try {
      await _authService.updateCurrentUser(updatedUser);
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      state = state.copyWith(
        error: 'User update failed: ${e.toString()}',
      );
      rethrow;
    }
  }

  void clearError() {
    state = state.clearError();
  }

  void clearUser() {
    state = state.clearUser();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// 현재 로그인된 사용자 정보만 제공하는 컨비니언스 프로바이더
final currentUserProvider = Provider<UserInfo?>((ref) {
  return ref.watch(authProvider).user;
});

// 로그인 상태만 제공하는 컨비니언스 프로바이더
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

// 로딩 상태만 제공하는 컨비니언스 프로바이더
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

// 에러 상태만 제공하는 컨비니언스 프로바이더
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});