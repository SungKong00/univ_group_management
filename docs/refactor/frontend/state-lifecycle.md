# 상태 생명주기 (State Lifecycle Management)

## 목적
Provider가 언제까지 메모리에 살아있을지를 명시적으로 정의하여 로그아웃 시 자동 정리 되도록 함. "이 상태는 어디까지 유지되어야 하는가?"를 미리 결정.

## 현재 문제
- 로그아웃 시 어떤 Provider를 정리해야 하는지 불명확
- 새로운 Provider 추가할 때마다 provider_reset.dart에 수동으로 추가해야 함
- 로그아웃 후 이전 계정 데이터가 메모리에 남음
- "이 Provider는 언제까지 유지되어야 하는가?"에 대한 규칙이 없음

## 원칙
### 1. StateScope 명시적 정의
```dart
// 📌 모든 상태는 생명주기를 먼저 정의

enum StateScope {
  // APP: 앱 전체 수명 (로그아웃해도 유지)
  // 예: 테마, 로컬 설정, 광고 ID
  APP,

  // SESSION: 로그인 세션 동안만 (로그아웃 시 즉시 정리)
  // 예: 그룹 목록, 현재 사용자, 멤버 목록
  SESSION,

  // VIEW: 화면 진입 시 ~ 화면 퇴출 시 (자동 dispose)
  // 예: 게시글 목록, 댓글 목록, 필터
  VIEW,

  // TEMPORARY: 상태 변경하면 즉시 정리
  // 예: 폼 입력, 모달 상태, 로딩 플래그
  TEMPORARY,
}

// ✅ StateScope를 먼저 정의 (매우 중요!)
class ProviderRegistry {
  static const Map<String, StateScope> scopes = {
    // SESSION 스코프 (로그아웃 시 정리)
    'myGroupsProvider': StateScope.SESSION,
    'currentUserProvider': StateScope.SESSION,
    'groupMembersProvider': StateScope.SESSION,
    'userPermissionsProvider': StateScope.SESSION,

    // VIEW 스코프 (화면 퇴출 시 정리)
    'postListProvider': StateScope.VIEW,
    'commentListProvider': StateScope.VIEW,
    'localFilterProvider': StateScope.VIEW,

    // APP 스코프 (로그아웃해도 유지)
    'themeProvider': StateScope.APP,
    'settingsProvider': StateScope.APP,

    // TEMPORARY 스코프 (상태 변경 시 정리)
    'formInputProvider': StateScope.TEMPORARY,
    'isLoadingProvider': StateScope.TEMPORARY,
  };
}
```

### 2. StateScope별 구현 패턴
```dart
// 📌 각 StateScope에 따른 구현 방식

// 1️⃣ APP 스코프 (로그아웃해도 유지)
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  // 특별한 초기화 필요 없음
  return ThemeNotifier();
  // 로그아웃 시에도 provider_reset에 등록 안 함
});

// 2️⃣ SESSION 스코프 (로그아웃 시 정리)
final myGroupsProvider =
    FutureProvider.autoDispose<List<Group>>((ref) async {
  // keepAlive: 탭 전환 시 dispose 방지 (세션 스코프 유지)
  ref.keepAlive();

  // 세션이 유효한지 확인
  final auth = ref.watch(authProvider);
  if (auth.user == null) {
    throw SessionExpiredException();
  }

  // API 호출
  return await groupService.getMyGroups();
});

// 3️⃣ VIEW 스코프 (화면별 상태)
final postListProvider = FutureProvider.autoDispose.family<
  List<Post>,
  String  // channelId
>((ref, channelId) async {
  // autoDispose: 화면 퇴출 시 자동 정리
  // keepAlive 호출 금지 (VIEW 스코프는 짧아야 함)

  return await postService.getPosts(channelId);
});

// 4️⃣ TEMPORARY 스코프 (단기 상태)
final formInputProvider =
    StateNotifierProvider.autoDispose<FormInputNotifier, FormInputState>((ref) {
  // autoDispose: 사용 중단 시 정리
  return FormInputNotifier();
});
```

### 3. 로그아웃 시 자동 정리 규칙
```dart
// 📌 로그아웃 시 동작

void resetAllUserDataProviders(Ref ref) {
  // 1단계: 메모리 정리 콜백 실행
  for (final callback in _customLogoutCallbacks) {
    callback(ref);
  }

  // 2단계: StateScope.SESSION 스코프 자동 invalidate
  // (provider_reset.dart가 알아서 처리)

  // 📌 규칙:
  // - SESSION: 자동 invalidate
  // - VIEW: 화면 전환으로 자동 dispose (수동 invalidate 불필요)
  // - TEMPORARY: 상태 변경으로 자동 정리 (수동 invalidate 불필요)
  // - APP: invalidate 금지 (로그인 상태 상관없이 유지)
}
```

## 구현 패턴

### Before (현재 - StateScope 불명확)
```dart
// ❌ 문제: 어떤 Provider를 정리해야 하는지 불명확
final myGroupsProvider = FutureProvider<List<Group>>((ref) async {
  // 로그아웃 시 정리되어야 함 (언제까지 사는지 불명확)
  return await groupService.getMyGroups();
});

final postListProvider = FutureProvider<List<Post>>((ref) async {
  // 화면 전환 시 정리되어야 함
  return await postService.getPosts();
});

final formInputProvider = StateNotifierProvider<FormNotifier, FormState>((ref) {
  // 폼 제출 시 정리되어야 함
  return FormNotifier();
});

// 로그아웃 시 어떤 것을 정리할지 매번 결정
void logout(Ref ref) {
  // 어? 이것도 정리? 저것도 정리?
  ref.invalidate(myGroupsProvider);  // 맞음
  ref.invalidate(postListProvider);  // 틀림 (화면 전환으로 정리됨)
  ref.invalidate(formInputProvider);  // 틀림 (이미 정리됨)
}
```

### After (개선 - StateScope 명확)
```dart
// ✅ StateScope를 정의 (모든 개발자가 일관됨)

class ProviderRegistry {
  static const Map<String, StateScope> scopes = {
    'myGroupsProvider': StateScope.SESSION,     // 로그아웃 시 정리
    'postListProvider': StateScope.VIEW,        // 화면 전환 시 정리
    'formInputProvider': StateScope.TEMPORARY,  // 상태 변경 시 정리
  };
}

// 각 Provider는 StateScope에 맞게 구현
final myGroupsProvider = FutureProvider.autoDispose<List<Group>>((ref) async {
  ref.keepAlive();  // SESSION: 세션 동안 유지
  return await groupService.getMyGroups();
});

final postListProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  // VIEW: autoDispose (keepAlive 금지)
  return await postService.getPosts();
});

final formInputProvider =
    StateNotifierProvider.autoDispose<FormNotifier, FormState>((ref) {
  // TEMPORARY: autoDispose (keepAlive 금지)
  return FormNotifier();
});

// 로그아웃은 ProviderRegistry를 믿고 실행
void logout(Ref ref) {
  // ProviderRegistry.scopes에 SESSION으로 등록된 Provider만 invalidate
  for (final (name, scope) in ProviderRegistry.scopes.entries) {
    if (scope == StateScope.SESSION) {
      ref.invalidate(getProviderByName(name));
    }
  }
}
```

### StateScope 적용 체크리스트
```dart
// 📋 새 Provider 추가할 때 따라야 할 단계

// Step 1: StateScope 결정
final myNewProvider = FutureProvider.autoDispose<Data>((ref) async {
  // "이 데이터는 언제까지 유지되어야 하는가?"
  // - 로그인 세션 끝까지? → SESSION
  // - 화면 진입 ~ 퇴출? → VIEW
  // - 상태 변경할 때까지? → TEMPORARY
  // - 앱 실행 내내? → APP

  // Step 2: StateScope에 따른 구현
  // - SESSION: ref.keepAlive() 필수
  // - VIEW: autoDispose만 사용 (keepAlive 금지)
  // - TEMPORARY: autoDispose만 사용
  // - APP: 특별한 처리 없음

  ref.keepAlive();  // SESSION이면 필수!

  return await service.getData();
});

// Step 3: ProviderRegistry에 등록
class ProviderRegistry {
  static const Map<String, StateScope> scopes = {
    // ...
    'myNewProvider': StateScope.SESSION,  // ← 추가!
  };
}
```

## 검증 방법

### 체크리스트
- [ ] 모든 Provider가 ProviderRegistry에 등록되어 있는가?
- [ ] SESSION Provider는 ref.keepAlive() 호출하는가?
- [ ] VIEW/TEMPORARY Provider는 autoDispose를 사용하는가?
- [ ] 로그아웃 시 SESSION 범위만 invalidate하는가?
- [ ] 새 Provider 추가 시 ProviderRegistry를 먼저 업데이트하는가?

### 구체적 검증
```bash
# 1. ref.keepAlive() 사용 확인
grep -r "ref.keepAlive()" lib/features/*/presentation/providers/
# → SESSION 스코프 Provider에서만 발견되어야 함

# 2. autoDispose 미사용 Provider 확인
grep -r "FutureProvider\|StateNotifierProvider" lib/features/*/presentation/providers/ \
  | grep -v "autoDispose" | grep -v "keepAlive"
# → SESSION 스코프가 아닌 경우만 발견되어야 함

# 3. ProviderRegistry 동기화 확인
grep -r "FutureProvider\|StateNotifierProvider" lib/features/*/presentation/providers/ \
  | grep "final.*Provider" | wc -l
# → ProviderRegistry 항목 수와 일치해야 함
```

## 관련 문서
- [API 응답 매핑](api-response-mapping.md) - 상태 변환 규칙
- [Provider 의존성 맵](provider-dependency.md) - 화면별 Provider 관리
- [상태 관리](../../docs/implementation/frontend/state-management.md) - Riverpod 상태 관리 기본
