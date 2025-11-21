# 명시적 상태 머신 (Explicit State Machine)

## 목적
화면의 현재 상태를 명시적 enum으로 정의하여 어떤 상태인지 불명확한 상황을 제거. "로딩 중"의 의미가 초기 로드인지, 그룹 전환인지, 로그아웃인지 명확히.

## 현재 문제
- isLoading이 여러 의미 (초기 로드? 그룹 전환? 로그아웃?)
- 상태 조합이 불가능 (로딩 중이면서 에러? 동시에 있을 수 있나?)
- Race Condition 발생 가능 (그룹 전환 중 로그아웃?)
- 어떤 상태인지 파악하려면 여러 플래그를 확인해야 함

## 원칙
### 1. 상태를 명시적 enum으로 정의
```dart
// 📌 모든 화면/기능의 상태를 enum으로 명시

// ❌ 현재 (불명확)
class WorkspaceState {
  bool isLoading;
  bool isError;
  String? errorMessage;
  String? currentGroupId;
  // → 동시에 여러 상태? 로딩 중 에러? 혼동 가능
}

// ✅ 개선 (명확)
enum WorkspaceViewState {
  uninitialized,      // 시작 (그룹 선택 전)
  loading,            // 초기 로드 중
  ready,              // 준비 완료 (그룹 선택됨)
  groupSwitching,     // 그룹 전환 중 (잠시 로딩)
  channelSwitching,   // 채널 전환 중 (잠시 로딩)
  loggingOut,         // 로그아웃 진행 중
  error,              // 에러 발생
}

// 상태 데이터
class WorkspaceViewStateModel {
  final WorkspaceViewState state;
  final String? currentGroupId;
  final String? currentChannelId;
  final String? errorMessage;
  final StackTrace? errorStack;

  WorkspaceViewStateModel({
    required this.state,
    this.currentGroupId,
    this.currentChannelId,
    this.errorMessage,
    this.errorStack,
  });

  // 상태 쿼리 메서드
  bool get isLoading =>
      state == WorkspaceViewState.loading ||
      state == WorkspaceViewState.groupSwitching ||
      state == WorkspaceViewState.channelSwitching;

  bool get isReady => state == WorkspaceViewState.ready;
  bool get isError => state == WorkspaceViewState.error;
  bool get isTransitioning =>
      state == WorkspaceViewState.groupSwitching ||
      state == WorkspaceViewState.channelSwitching;
}
```

### 2. 상태 전환 규칙 명시
```dart
// 📌 어떤 상태에서 어떤 상태로 전환 가능한지 명시

// ✅ 상태 전환 다이어그램
/*
uninitialized
    ↓
  loading
    ↓
  ready ←→ groupSwitching
    ↓       (그룹 변경)
  channelSwitching
    ↓
  ready

  모든 상태 → loggingOut (로그아웃)
  모든 상태 → error (에러)
*/

@immutable
class WorkspaceNotifier extends StateNotifier<WorkspaceViewStateModel> {
  // 상태 전환 메서드 (명시적)

  /// 초기화
  Future<void> initialize() async {
    state = WorkspaceViewStateModel(state: WorkspaceViewState.loading);
    try {
      // ...
      state = WorkspaceViewStateModel(
        state: WorkspaceViewState.ready,
        currentGroupId: groupId,
        currentChannelId: channelId,
      );
    } catch (e, st) {
      state = WorkspaceViewStateModel(
        state: WorkspaceViewState.error,
        errorMessage: e.toString(),
        errorStack: st,
      );
    }
  }

  /// 그룹 전환
  Future<void> switchGroup(String groupId) async {
    // ✅ 현재 상태가 ready인지 확인 (전환 규칙)
    if (state.state != WorkspaceViewState.ready) {
      throw InvalidStateTransitionException(
        'Cannot switch group from ${state.state}',
      );
    }

    // ✅ 새로운 상태로 전환
    state = WorkspaceViewStateModel(
      state: WorkspaceViewState.groupSwitching,
      currentGroupId: state.currentGroupId,  // 이전 그룹
    );

    try {
      // 그룹 정보 로드
      await loadGroupData(groupId);

      // ✅ 전환 완료
      state = WorkspaceViewStateModel(
        state: WorkspaceViewState.ready,
        currentGroupId: groupId,  // 새 그룹
      );
    } catch (e, st) {
      // ✅ 에러는 이전 상태로 복원
      state = WorkspaceViewStateModel(
        state: WorkspaceViewState.error,
        errorMessage: e.toString(),
        errorStack: st,
      );
    }
  }

  /// 로그아웃
  void logout() {
    // ✅ 모든 상태에서 로그아웃 가능
    state = WorkspaceViewStateModel(
      state: WorkspaceViewState.loggingOut,
    );
    // 실제 로그아웃 처리는 AuthNotifier가 담당
  }
}
```

### 3. 상태별 UI 분기
```dart
// ✅ switch/when으로 모든 상태 처리

@override
Widget build(BuildContext context, WidgetRef ref) {
  final workspaceState = ref.watch(workspaceStateProvider);

  return switch (workspaceState.state) {
    // 초기화 전
    WorkspaceViewState.uninitialized => SizedBox.shrink(),

    // 초기 로드 중
    WorkspaceViewState.loading => FullScreenLoader(),

    // 준비 완료 (정상 상태)
    WorkspaceViewState.ready => WorkspaceView(
      groupId: workspaceState.currentGroupId!,
      channelId: workspaceState.currentChannelId!,
    ),

    // 그룹 전환 중 (로딩 표시)
    WorkspaceViewState.groupSwitching => WorkspaceView(
      groupId: workspaceState.currentGroupId!,
      channelId: workspaceState.currentChannelId!,
      isLoading: true,  // 로딩 오버레이 표시
    ),

    // 채널 전환 중
    WorkspaceViewState.channelSwitching => WorkspaceView(
      groupId: workspaceState.currentGroupId!,
      channelId: workspaceState.currentChannelId!,
      isLoading: true,
    ),

    // 로그아웃 진행 중
    WorkspaceViewState.loggingOut => AuthView(),

    // 에러 상태
    WorkspaceViewState.error => ErrorView(
      message: workspaceState.errorMessage,
      onRetry: () => ref.read(workspaceStateProvider.notifier).initialize(),
    ),
  };
}
```

## 구현 패턴

### Before (현재 - 상태 불명확)
```dart
// ❌ 문제: 상태가 명확하지 않음

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  bool isLoading = false;
  bool isError = false;
  String? errorMessage;
  String? currentGroupId;

  Future<void> switchGroup(String groupId) async {
    isLoading = true;  // 무엇이 로딩? 초기화? 전환?

    try {
      await loadGroupData(groupId);
      currentGroupId = groupId;
      isLoading = false;
      isError = false;
    } catch (e) {
      isError = true;
      errorMessage = e.toString();
      // isLoading은? true? false? (둘 다 true일 수도?)
    }
  }
}

// UI에서 어떤 상태인지 파악 어려움
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(workspaceStateProvider);

  if (state.isError) {
    return ErrorView(message: state.errorMessage);
  } else if (state.isLoading) {
    // 초기 로드? 그룹 전환? 로그아웃? 뭔지 모름
    return FullScreenLoader();
  } else if (state.currentGroupId != null) {
    return WorkspaceView(groupId: state.currentGroupId!);
  } else {
    return SizedBox.shrink();
  }
}
```

### After (개선 - 상태 명확)
```dart
// ✅ 해결: 상태가 명확함

enum WorkspaceViewState {
  uninitialized,
  loading,
  ready,
  groupSwitching,
  channelSwitching,
  loggingOut,
  error,
}

class WorkspaceNotifier extends StateNotifier<WorkspaceViewStateModel> {
  Future<void> switchGroup(String groupId) async {
    // ✅ 상태 전환이 명확함
    state = state.copyWith(state: WorkspaceViewState.groupSwitching);

    try {
      await loadGroupData(groupId);
      // ✅ 성공하면 ready로 전환
      state = state.copyWith(
        state: WorkspaceViewState.ready,
        currentGroupId: groupId,
      );
    } catch (e, st) {
      // ✅ 에러는 error로 전환 (로딩과 분리)
      state = state.copyWith(
        state: WorkspaceViewState.error,
        errorMessage: e.toString(),
        errorStack: st,
      );
    }
  }
}

// UI에서 상태 처리 명확함
@override
Widget build(BuildContext context, WidgetRef ref) {
  final workspaceState = ref.watch(workspaceStateProvider);

  return switch (workspaceState.state) {
    WorkspaceViewState.uninitialized => SizedBox.shrink(),
    WorkspaceViewState.loading => FullScreenLoader(),
    WorkspaceViewState.ready => WorkspaceView(
      groupId: workspaceState.currentGroupId!,
      channelId: workspaceState.currentChannelId!,
    ),
    WorkspaceViewState.groupSwitching => WorkspaceView(
      groupId: workspaceState.currentGroupId!,
      isLoading: true,
    ),
    WorkspaceViewState.channelSwitching => WorkspaceView(
      groupId: workspaceState.currentGroupId!,
      isLoading: true,
    ),
    WorkspaceViewState.loggingOut => AuthView(),
    WorkspaceViewState.error => ErrorView(
      message: workspaceState.errorMessage,
    ),
  };
}
```

## 검증 방법

### 체크리스트
- [ ] 모든 화면/기능이 상태 enum을 정의했는가?
- [ ] 상태가 mutually exclusive인가? (동시에 여러 상태 불가)
- [ ] 상태 전환 규칙이 명시되어 있는가?
- [ ] UI가 switch/when으로 모든 상태를 처리하는가?
- [ ] 상태별 UI가 다르게 렌더링되는가?

### 구체적 검증
```bash
# 1. enum 상태 확인
grep -r "enum.*State\|sealed class.*State" lib/features/*/presentation/providers/
# → 모든 주요 Provider의 상태가 정의되어 있어야 함

# 2. switch/when 사용 확인
grep -r "switch.*state\|state.when" lib/features/*/presentation/pages/
# → 상태별 UI 분기가 명확해야 함

# 3. 상태 동시 설정 검사 (금지)
grep -r "isLoading = true.*isError = true" lib/features/*/presentation/
# → 0개 (상태가 mutually exclusive여야 함)
```

## 관련 문서
- [상태 생명주기](state-lifecycle.md) - Provider 생명주기
- [API 응답 매핑](api-response-mapping.md) - AsyncValue와의 연계
- [화면 구조 템플릿](screen-structure.md) - 화면별 상태 정의
