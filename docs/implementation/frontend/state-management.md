# 상태 관리 (State Management)

## Riverpod 개요

**왜 Riverpod인가?**:
- 의존성 주입 패턴 자동화
- 테스트 가능한 구조 (Provider 재정의 가능)
- 메모리 효율성 (autoDispose 지원)
- 강력한 타입 안전성

## Provider 초기화 시스템

### 문제점

로그아웃 시 이전 계정의 데이터가 메모리에 남아있어, 계정 전환 시 잘못된 데이터 표시

### 해결책

**파일**: lib/core/providers/provider_reset.dart

중앙 집중식 Provider 관리 시스템:

```dart
// 로그아웃 시 초기화할 Provider 목록
final _providersToInvalidateOnLogout = <ProviderOrFamily>[
  myGroupsProvider,
  homeStateProvider,
  calendarEventsProvider,
  // ... 사용자 데이터 관련 Provider
];

// 메모리 정리 필요한 콜백
final _customLogoutCallbacks = <LogoutResetCallback>[
  (ref) => ref.read(workspaceStateProvider.notifier).forceClearForLogout(),
  (ref) => ref.read(homeStateProvider.notifier).clearSnapshots(),
];

void resetAllUserDataProviders(Ref ref) {
  // 1. 메모리 상태 정리
  for (final callback in _customLogoutCallbacks) {
    callback(ref);
  }

  // 2. Riverpod 캐시 무효화
  for (final provider in _providersToInvalidateOnLogout) {
    ref.invalidate(provider);
  }
}
```

### autoDispose 패턴

사용하지 않을 때 자동으로 메모리에서 해제:

```dart
// ❌ 메모리에 계속 유지됨
final myGroupsProvider = FutureProvider<List<GroupMembership>>((ref) async {
  return await groupService.getMyGroups();
});

// ✅ 자동 메모리 해제
final myGroupsProvider = FutureProvider.autoDispose<List<GroupMembership>>((ref) async {
  return await groupService.getMyGroups();
});
```

## 액션/Mutation 패턴

비동기 작업 (게시글 작성, 댓글 추가 등) 처리:

1. **파라미터 모델**: @freezed 클래스로 정의
2. **FutureProvider.family**: 파라미터를 받는 Provider 생성
3. **UI 호출**: ref.read(provider(params).future) 사용

## AuthService 패턴

```dart
class AuthService {
  Future<LoginResponse> loginWithGoogle({
    String? idToken,
    String? accessToken,
  });

  Future<void> tryAutoLogin();
  Future<void> logout();
}
```

**로그아웃 통합**:

```dart
Future<void> logout() async {
  await _authService.logout();
  resetAllUserDataProviders(_ref);  // Provider 초기화
  _navigationController.resetToHome();  // 네비게이션 초기화
  state = AuthState(user: null, isLoading: false);
}
```

## keepAlive + 로그아웃 가드를 이용한 세션 스코프 캐싱

탭 전환/네비게이션 중에는 캐시를 유지하되, 로그아웃 중 Race Condition을 차단하는 패턴:

```dart
// ✅ 권장: keepAlive로 세션 캐시 유지
final myGroupsProvider = FutureProvider<List<GroupMembership>>((ref) async {
  // keepAlive: 탭 전환 시 provider dispose 방지 (세션 스코프 유지)
  ref.keepAlive();

  final groupService = GroupService();
  return await groupService.getMyGroups();
});
```

**로그아웃 시 처리** (`provider_reset.dart`):
```dart
void resetAllUserDataProviders(Ref ref) {
  // 모든 사용자 데이터 Provider 일괄 invalidate
  for (final provider in _providersToInvalidateOnLogout) {
    ref.invalidate(provider);  // myGroupsProvider도 포함
  }
}
```

**Race Condition 차단** (`workspace_state_provider.dart`):
```dart
Future<GroupMembership?> _resolveGroupMembership(String groupId) async {
  // ⭐ 로그아웃 중 워크스페이스 진입 시도 차단
  if (_ref.read(authProvider).isLoggingOut) {
    throw LogoutInProgressException();
  }

  // 일반 그룹 조회
  final memberships = await _ref.read(myGroupsProvider.future);
  return memberships.firstWhere((group) => group.id.toString() == groupId);
}
```

**동작 원리**:
1. **keepAlive()**: 탭 전환 시 provider dispose 방지 (세션 스코프 유지)
2. **로그아웃 시 invalidate()**: 캐시 표시
3. **workspace_state_provider의 isLoggingOut 가드**: 로그아웃 중 myGroupsProvider 접근 차단
4. **새 로그인 시**: 다음 read에서 새 API 호출로 새 데이터 로드

## 새 Provider 추가 시

1. `_providersToInvalidateOnLogout`에 등록 (invalidate 보장)
2. 특별한 정리 필요 시 `_customLogoutCallbacks`에 콜백 등록
3. keepAlive가 필요한 경우만 `ref.keepAlive()` 사용

## 관련 문서

- [고급 상태 패턴](advanced-state-patterns.md) - Unified Provider, LocalFilterNotifier
- [컴포넌트 구현](components.md) - 상태 기반 UI 컴포넌트
- [아키텍처](architecture.md) - 전체 아키텍처 구조
