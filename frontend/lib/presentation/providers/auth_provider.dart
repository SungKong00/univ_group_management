import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../../core/models/auth_models.dart';
import '../../core/repositories/repository_providers.dart';
import '../../core/navigation/navigation_controller.dart';
import '../../core/providers/provider_reset.dart';
import 'workspace_state_provider.dart';

/// 현재 로그인한 유저 정보 관리
///
/// AsyncNotifier를 사용하여 로딩/에러 상태를 자동으로 처리합니다.
/// - AsyncLoading: 로그인 중, 로그아웃 중
/// - `AsyncData<UserInfo?>`: 로그인 완료 (null = 로그아웃 상태)
/// - AsyncError: 로그인/로그아웃 실패
class CurrentUserNotifier extends AsyncNotifier<UserInfo?> {
  @override
  Future<UserInfo?> build() async {
    // 앱 시작 시 자동 로그인 시도
    final authRepository = ref.read(authRepositoryProvider);
    return await authRepository.tryAutoLogin();
  }

  /// Google OAuth 로그인
  ///
  /// Parameters:
  /// - idToken: Google ID Token (선택)
  /// - accessToken: Google Access Token (선택)
  ///
  /// Returns: LoginResponse (호환성 유지)
  Future<LoginResponse> loginWithGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    state = const AsyncLoading();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.login(
        idToken: idToken,
        accessToken: accessToken,
      );

      state = AsyncData(user);

      // LoginResponse 생성 (하위 호환성)
      // 실제 토큰은 Repository에서 저장되므로 여기서는 더미 값
      return LoginResponse(
        accessToken: 'stored_in_repository',
        tokenType: 'Bearer',
        expiresIn: 3600,
        user: user,
        firstLogin: false,
      );
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  /// 테스트 계정 로그인
  Future<LoginResponse> loginWithTestAccount() async {
    return loginWithGoogle(idToken: 'mock_google_token_for_castlekong1019');
  }

  /// Mock 토큰 로그인 (하위 호환용)
  Future<LoginResponse> loginWithMockToken(String mockToken) async {
    return loginWithGoogle(idToken: mockToken);
  }

  /// 로그아웃
  Future<void> logout() async {
    // ✅ 로그아웃 전 읽음 위치 저장 (선택적, 에러 무시)
    await _saveReadPositionBeforeLogoutIfNeeded();

    state = const AsyncLoading();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.logout();

      // ✅ 상태를 null로 먼저 설정 (로그아웃 완료)
      state = const AsyncData(null);

      // ✅ Provider 초기화 (순환 참조 에러 무시)
      // myGroupsProvider가 ref.watch(currentUserProvider)를 사용하므로
      // invalidate 시 순환 참조가 발생할 수 있지만, 반응형 재평가로 자동 해결됨
      try {
        await resetAllUserDataProviders(ref);
      } catch (e) {
        // 순환 참조 에러 무시 (로그아웃은 이미 완료, 재로그인 시 자동 재평가)
        if (kDebugMode) {
          developer.log(
            '⚠️ Provider reset warning (ignored): $e',
            name: 'CurrentUserNotifier',
          );
        }
      }

      // ✅ 네비게이션 리셋
      final navigationController = ref.read(
        navigationControllerProvider.notifier,
      );
      navigationController.resetToHome();
    } catch (e, stack) {
      // ✅ 에러 발생 시 AsyncError로 자동 설정
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  /// 유저 정보 업데이트
  Future<void> updateUser(UserInfo updatedUser) async {
    state = const AsyncLoading();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updateUser(updatedUser);
      state = AsyncData(updatedUser);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  /// 로그아웃 전 읽음 위치 저장 (선택적, 에러 무시)
  Future<void> _saveReadPositionBeforeLogoutIfNeeded() async {
    try {
      final workspaceState = ref.read(workspaceStateProvider);
      final channelId = workspaceState.selectedChannelId;
      final postId = workspaceState.currentVisiblePostId;

      if (channelId != null && postId != null) {
        final channelIdInt = int.tryParse(channelId);
        if (channelIdInt != null) {
          await ref
              .read(workspaceStateProvider.notifier)
              .saveReadPosition(channelIdInt, postId);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('⚠️ 로그아웃 전 저장 실패 (무시) - $e', name: 'CurrentUserNotifier');
      }
      // 에러 무시 (로그아웃은 계속 진행)
    }
  }

  /// 에러 클리어 (하위 호환용)
  void clearError() {
    // AsyncNotifier에서는 state를 다시 로드하여 에러를 클리어
    if (state.hasError) {
      ref.invalidateSelf();
    }
  }

  /// 유저 클리어 (하위 호환용)
  void clearUser() {
    state = const AsyncData(null);
  }
}

/// 현재 로그인한 유저 정보 Provider
///
/// AsyncValue를 사용하여 로딩/에러 상태를 자동으로 관리합니다.
final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserInfo?>(
      CurrentUserNotifier.new,
    );

/// 편의 Provider: 로그인 여부
final isLoggedInProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(data: (user) => user != null, orElse: () => false);
});

/// 편의 Provider: 로딩 여부
final isAuthLoadingProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.isLoading;
});

/// 편의 Provider: 에러 메시지
final authErrorProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    error: (error, _) => error.toString(),
    orElse: () => null,
  );
});

/// 편의 Provider: 로그아웃 중 여부
///
/// AsyncNotifier에서는 isLoading이 로그아웃 중도 포함하므로
/// 로그아웃 중 판단은 isLoading && user == null로 처리
final isLoggingOutProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    loading: () {
      // 로딩 중이면서 이전 데이터가 null이 아니면 로그아웃 중으로 간주
      final previousData = userAsync.valueOrNull;
      return previousData != null;
    },
    orElse: () => false,
  );
});

// ===== 하위 호환성을 위한 Legacy Provider =====
// 기존 코드가 authProvider를 사용하는 경우를 위해 유지
// 점진적으로 currentUserProvider로 마이그레이션 필요

/// Legacy `AuthState` (하위 호환용)
@Deprecated('Use currentUserProvider with AsyncValue instead')
class AuthState {
  final UserInfo? user;
  final bool isLoading;
  final String? error;
  final bool isLoggingOut;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isLoggingOut = false,
  });

  bool get isLoggedIn => user != null;
}

/// Legacy authProvider (하위 호환용)
///
/// 내부적으로 currentUserProvider를 watch하여 AuthState로 변환
@Deprecated('Use currentUserProvider instead')
final authProvider = Provider<AuthState>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) => AuthState(
      user: user,
      isLoading: false,
      error: null,
      isLoggingOut: false,
    ),
    loading: () {
      final previousUser = userAsync.valueOrNull;
      return AuthState(
        user: previousUser,
        isLoading: true,
        error: null,
        isLoggingOut: previousUser != null, // 로그인된 상태에서 로딩이면 로그아웃 중
      );
    },
    error: (error, _) => AuthState(
      user: null,
      isLoading: false,
      error: error.toString(),
      isLoggingOut: false,
    ),
  );
});
