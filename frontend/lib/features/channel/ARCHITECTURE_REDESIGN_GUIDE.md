# 📐 채널 메커니즘 아키텍처 재설계 가이드

> **목적**: 현재 문제가 많은 채널 메커니즘을 Clean Architecture + MVVM 패턴으로 재설계
> **작성일**: 2025-11-18
> **버전**: v1.0
> **상태**: 설계 단계

---

## 📋 목차

1. [현재 상태 분석](#1-현재-상태-분석)
2. [핵심 문제점 요약](#2-핵심-문제점-요약)
3. [아키텍처 재설계 원칙](#3-아키텍처-재설계-원칙)
4. [핵심 동작별 재설계](#4-핵심-동작별-재설계)
5. [레이어별 재설계 구조](#5-레이어별-재설계-구조)
6. [의존성 주입 구조](#6-의존성-주입-구조)
7. [에러 처리 전략](#7-에러-처리-전략)
8. [마이그레이션 로드맵](#8-마이그레이션-로드맵)
9. [성공 지표](#9-성공-지표)

---

## 1. 현재 상태 분석

### 1.1 아키텍처 원칙 위반 현황

| 파일 | 현재 줄 수 | 문제점 | 위반 원칙 |
|------|-----------|--------|----------|
| **workspace_state_provider.dart** | 1920줄 | 10개+ 책임 혼재 (God Object) | SRP, 100줄 원칙 |
| **post_list.dart** | 836줄 | View + 비즈니스 로직 혼재 | MVVM, DIP, 100줄 |
| **channel_content_view.dart** | 190줄 | Race Condition 로직 포함 | 관심사 분리 |

### 1.2 기존 구조의 책임 분산 실패

```
WorkspaceStateNotifier (1920줄)의 책임들:
├─ 채널 진입/전환 로직
├─ 읽음 위치 API 호출
├─ 읽음 위치 로컬 상태 관리
├─ 배지 카운트 관리
├─ 권한 로딩 및 캐싱
├─ 스냅샷 저장/복원
├─ 네비게이션 히스토리
├─ 그룹 전환 로직
├─ 모바일/웹 뷰 분기
├─ 로그아웃 처리
└─ JS 캐시 동기화

PostList (836줄)의 책임들:
├─ 게시글 데이터 로딩
├─ 무한 스크롤 처리
├─ Flat List 빌드
├─ Sticky Header 계산
├─ Visibility 추적
├─ 읽음 위치 계산
├─ 스크롤 복원
└─ 에러 처리
```

---

## 2. 핵심 문제점 요약

### 2.1 🔴 치명적 버그: _firstUnreadPostIndex 계산 누락

```dart
// ❌ 현재 코드 (AsyncNotifier 패턴)
_restoreScrollPosition() async {
  await _waitForReadPositionData(channelIdInt);
  final flatItems = _buildFlatList(postListState.posts);
  setState(() {
    _flatItems = flatItems;
    _isInitialLoading = false;
  });

  // ⚠️ 버그: _firstUnreadPostIndex가 null이므로 스크롤 안 됨!
  _scrollToUnreadPost();
}
```

**문제**: AsyncNotifier 패턴에서 `_firstUnreadPostIndex` 계산이 완전히 누락되어 스크롤이 작동하지 않음

### 2.2 Race Condition (2가지)

#### Race Condition #1: 읽음 위치 로딩 vs 게시글 로딩

```
Timeline:
t=0: selectChannel() 호출
  ├─ loadChannelPermissions() 시작 (비동기)
  └─ loadReadPosition() 시작 (비동기)

t=?: ChannelContentView 체크
  ├─ lastReadPostIdMap.containsKey(channelId)?
  └─ NO → 3초 timeout FutureBuilder

t=3000ms: Timeout 발생
  └─ PostList 생성 (읽음 위치 없이)
```

#### Race Condition #2: AsyncNotifier 데이터 로딩

```
초기화: PostList.initState()
  └─ PostFrameCallback → _restoreScrollPosition()

동시 실행:
  ├─ AsyncNotifier.build() → API 호출
  └─ _restoreScrollPosition() → 100ms 후 ref.read()
      └─ valueOrNull == null (아직 로딩 중)
```

### 2.3 Feature Flag 복잡도

```dart
if (!FeatureFlags.useAsyncNotifierPattern) {
  // 구 방식 (StateNotifier)
  Future.microtask(() => _loadPostsAndScrollToUnread());
} else {
  // 신 방식 (AsyncNotifier) - 버그 있음
  WidgetsBinding.instance.addPostFrameCallback((_) =>
    _restoreScrollPosition());
}
```

- 두 가지 경로 유지 → 테스트 부담 2배
- 신 방식에 치명적 버그 존재

---

## 3. 아키텍처 재설계 원칙

### 3.1 Clean Architecture 3-Layer 강제

```
Presentation Layer (UI + ViewModel)
    ↓ (UseCase만 호출)
Domain Layer (비즈니스 로직)
    ↓ (Repository 인터페이스)
Data Layer (API, 캐시, 로컬 DB)
```

**강제 규칙**:
- ❌ Presentation → Data 직접 호출 금지
- ✅ Presentation → Domain (UseCases)만 허용
- ✅ Domain은 Presentation, Data를 모름

### 3.2 MVVM 패턴 엄격 적용

```
View (Widget)
  ↓ (watch/read Provider)
ViewModel (AsyncNotifier)
  ↓ (call UseCases)
Model (Domain Entities)
```

**View 규칙**:
- ❌ 비즈니스 로직 금지
- ❌ API 호출 금지
- ✅ ViewModel 상태만 렌더링
- ✅ 사용자 이벤트를 ViewModel로 위임

**ViewModel 규칙**:
- ❌ Flutter 위젯 의존성 금지
- ✅ UseCases로 비즈니스 로직 실행
- ✅ 순수 Dart 상태 관리

### 3.3 단일 책임 원칙 (SRP)

**파일 크기 제한**:
- ✅ 최대 100줄 (헌법 원칙)
- ✅ 1개 클래스 = 1개 책임

**Notifier 분리 전략**:
```
❌ WorkspaceStateNotifier (1920줄)
    ↓ 분리
✅ ChannelEntryNotifier (50줄)
✅ ReadPositionNotifier (80줄)
✅ UnreadBadgeNotifier (60줄)
✅ ChannelNavigationNotifier (70줄)
✅ PermissionCacheNotifier (50줄)
```

### 3.4 AsyncNotifier 일원화

- ❌ StateNotifier (구 방식) 완전 제거
- ✅ AsyncNotifier만 사용
- ✅ Provider.build()가 데이터 로딩 보장

---

## 4. 핵심 동작별 재설계

### 4.1 채널 진입 (Channel Entry) 재설계

#### 현재 흐름 (복잡, Race Condition)

```dart
// ❌ 현재: 여러 비동기 작업이 독립적으로 실행
selectChannel(channelId) {
  await Future.wait([
    loadChannelPermissions(channelId),  // 독립 비동기
    loadReadPosition(channelIdInt),      // 독립 비동기
  ]);
  await Future.delayed(Duration.zero);   // ⚠️ 타이밍 보장 불가
  state = state.copyWith(selectedChannelId);
}

// PostList에서 별도로 데이터 로딩
_loadPostsAndScrollToUnread() {
  await _loadPosts();                    // 또 다른 비동기
  await _waitForReadPositionData();      // 재시도 로직
  _scrollToUnreadPost();
}
```

#### 재설계 흐름 (원자적, Race Condition 없음)

```dart
// ✅ 재설계: 1개 UseCase가 모든 데이터 원자적 준비
class EnterChannelUseCase {
  Future<ChannelEntryResult> call(int channelId) async {
    // 병렬 로딩 (하나의 트랜잭션)
    final results = await Future.wait([
      _getChannelPermissions(channelId),
      _getReadPosition(channelId),
      _getPosts(channelId),
    ]);

    // 읽음 위치 계산 (순수 함수)
    final unreadPosition = _calculateUnreadPosition(
      posts: results[2],
      lastReadPostId: results[1]?.lastReadPostId,
    );

    return ChannelEntryResult(
      permissions: results[0],
      readPosition: results[1],
      posts: results[2],
      unreadPosition: unreadPosition,  // ✅ 계산 완료
    );
  }
}

// ✅ ViewModel: 단순히 UseCase 호출
class ChannelEntryNotifier extends AsyncNotifier<ChannelEntryResult> {
  @override
  Future<ChannelEntryResult> build(int channelId) async {
    return await enterChannelUseCase(channelId);
  }
}

// ✅ View: 준비된 데이터만 렌더링
class ChannelView extends ConsumerWidget {
  Widget build(context, ref) {
    final entryAsync = ref.watch(channelEntryProvider(channelId));

    return entryAsync.when(
      loading: () => ChannelSkeleton(),
      data: (result) => PostListView(result),  // 모든 데이터 준비됨
      error: (e, _) => ErrorView(e),
    );
  }
}
```

### 4.2 읽음 위치 계산 재설계

#### 현재 문제 (계산 누락)

```dart
// ❌ 현재: _firstUnreadPostIndex 계산 누락
_restoreScrollPosition() async {
  final flatItems = _buildFlatList(posts);
  setState(() => _flatItems = flatItems);

  // ⚠️ _firstUnreadPostIndex가 null!
  _scrollToUnreadPost();
}
```

#### 재설계 (Domain에서 순수 함수로 계산)

```dart
// ✅ 재설계: UseCase가 항상 계산
class CalculateUnreadPositionUseCase {
  UnreadPositionResult call(
    List<Post> posts,
    int? lastReadPostId,
  ) {
    // 순수 함수 (테스트 가능)
    final flatItems = _buildFlatList(posts);
    final firstUnreadIndex = _findFirstUnreadIndex(
      flatItems,
      lastReadPostId,
    );

    return UnreadPositionResult(
      flatItems: flatItems,
      firstUnreadIndex: firstUnreadIndex,  // ✅ 계산 보장
      hasUnread: firstUnreadIndex != null,
    );
  }

  // Private 순수 함수들
  List<PostListItem> _buildFlatList(List<Post> posts) {
    // DateMarker + Post 교대 배치
  }

  int? _findFirstUnreadIndex(items, lastReadId) {
    // 첫 읽지 않은 글 인덱스 찾기
  }
}
```

### 4.3 읽음 처리 (Visibility Tracking) 재설계

#### 현재 문제 (관심사 혼재)

```dart
// ❌ 현재: PostList가 모든 것 처리
class PostList extends StatefulWidget {
  Set<int> _visiblePostIds = {};
  Timer? _debounceTimer;

  void _onPostVisible(int postId) {
    _visiblePostIds.add(postId);
    _scheduleUpdateMaxVisibleId();
  }

  void _updateMaxVisibleId() {
    final maxId = _visiblePostIds.max;
    ref.read(workspaceStateProvider.notifier)
       .updateCurrentVisiblePost(maxId);
  }
}
```

#### 재설계 (책임 분리)

```dart
// ✅ View: Visibility 감지만
class PostItemWithTracking extends ConsumerWidget {
  final Post post;

  Widget build(context, ref) {
    return VisibilityDetector(
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          // ViewModel에 위임
          ref.read(readPositionNotifier.notifier)
             .markAsRead(post.id);
        }
      },
      child: PostItem(post: post),
    );
  }
}

// ✅ ViewModel: 읽음 위치 로직
class ReadPositionNotifier extends AsyncNotifier<ReadPositionState> {
  Timer? _debouncer;

  void markAsRead(int postId) {
    // 디바운싱 + 최댓값 계산 + API 저장
    _debouncer?.cancel();
    _debouncer = Timer(Duration(milliseconds: 200), () {
      _updateReadPosition(postId);
    });
  }

  Future<void> _updateReadPosition(int postId) async {
    final maxId = _calculateMaxVisibleId(postId);
    await updateReadPositionUseCase(channelId, maxId);
    state = AsyncValue.data(
      state.value!.copyWith(lastReadPostId: maxId),
    );
  }
}
```

---

## 5. 레이어별 재설계 구조

### 5.1 Domain Layer (새로 생성)

```
features/channel/domain/
├── entities/
│   ├── channel_entry_result.dart      # 채널 진입 결과
│   ├── read_position.dart             # 읽음 위치 엔티티
│   └── unread_position_result.dart    # 읽지 않은 위치 결과
├── repositories/
│   ├── channel_repository.dart        # 인터페이스
│   └── read_position_repository.dart  # 인터페이스
└── usecases/
    ├── enter_channel_usecase.dart     # 원자적 채널 진입
    ├── calculate_unread_position_usecase.dart  # 순수 함수
    ├── get_read_position_usecase.dart
    ├── update_read_position_usecase.dart
    └── get_unread_count_usecase.dart
```

#### 핵심 UseCase 예시

```dart
// 채널 진입 시 모든 데이터 원자적 로딩
class EnterChannelUseCase {
  final GetChannelPermissionsUseCase _getPermissions;
  final GetReadPositionUseCase _getReadPosition;
  final GetPostsUseCase _getPosts;
  final CalculateUnreadPositionUseCase _calculateUnread;

  Future<ChannelEntryResult> call(int channelId) async {
    // 1. 병렬 로딩
    final results = await Future.wait([
      _getPermissions(channelId),
      _getReadPosition(channelId),
      _getPosts(channelId.toString()),
    ]);

    // 2. 읽음 위치 계산
    final unreadPosition = _calculateUnread(
      results[2].posts,
      results[1]?.lastReadPostId,
    );

    // 3. 결과 반환
    return ChannelEntryResult(
      permissions: results[0],
      readPosition: results[1],
      posts: results[2],
      unreadPosition: unreadPosition,
    );
  }
}
```

### 5.2 Data Layer

```
features/channel/data/
├── datasources/
│   ├── channel_remote_datasource.dart
│   └── read_position_remote_datasource.dart
├── models/
│   ├── channel_dto.dart
│   └── read_position_dto.dart
└── repositories/
    ├── channel_repository_impl.dart
    └── read_position_repository_impl.dart
```

### 5.3 Presentation Layer (리팩터링)

```
features/channel/presentation/
├── providers/
│   ├── channel_entry_provider.dart      # 50줄 (채널 진입)
│   ├── read_position_provider.dart      # 80줄 (읽음 위치)
│   ├── unread_badge_provider.dart       # 60줄 (배지)
│   ├── post_list_provider.dart          # 100줄 (게시글)
│   └── channel_navigation_provider.dart # 70줄 (채널 전환)
└── widgets/
    ├── channel_view.dart                 # 50줄 (진입점)
    ├── post_list_view.dart               # 100줄 (리스트)
    ├── post_item_with_tracking.dart     # 30줄 (추적)
    └── sticky_header_list_view.dart     # 80줄 (Sticky)
```

#### Provider 분리 예시

```dart
// ✅ 채널 진입 Provider (50줄)
class ChannelEntryNotifier
    extends AutoDisposeFamilyAsyncNotifier<ChannelEntryResult, int> {

  @override
  Future<ChannelEntryResult> build(int channelId) async {
    final useCase = ref.watch(enterChannelUseCaseProvider);
    return await useCase(channelId);
  }
}

// ✅ 읽음 위치 Provider (80줄)
class ReadPositionNotifier
    extends AutoDisposeFamilyAsyncNotifier<ReadPositionState, int> {
  Timer? _debouncer;

  @override
  Future<ReadPositionState> build(int channelId) async {
    final useCase = ref.watch(getReadPositionUseCaseProvider);
    final position = await useCase(channelId);
    return ReadPositionState(
      channelId: channelId,
      lastReadPostId: position?.lastReadPostId ?? -1,
    );
  }

  void markAsRead(int postId) {
    _debouncer?.cancel();
    _debouncer = Timer(Duration(milliseconds: 200), () {
      _updateReadPosition(postId);
    });
  }
}

// ✅ 배지 Provider (60줄)
class UnreadBadgeNotifier
    extends AutoDisposeFamilyAsyncNotifier<int, int> {

  @override
  Future<int> build(int channelId) async {
    final useCase = ref.watch(getUnreadCountUseCaseProvider);
    return await useCase(channelId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.watch(getUnreadCountUseCaseProvider);
      return await useCase(arg);
    });
  }
}
```

---

## 6. 의존성 주입 구조

### 6.1 Provider 의존성 그래프

```
ChannelView
  └─ channelEntryProvider(channelId)
      └─ EnterChannelUseCase
          ├─ GetChannelPermissionsUseCase
          ├─ GetReadPositionUseCase
          ├─ GetPostsUseCase
          └─ CalculateUnreadPositionUseCase

PostItemWithTracking
  └─ readPositionNotifier(channelId)
      └─ UpdateReadPositionUseCase
          └─ ReadPositionRepository
              └─ ReadPositionRemoteDataSource

UnreadBadge
  └─ unreadBadgeProvider(channelId)
      └─ GetUnreadCountUseCase
          └─ ReadPositionRepository
```

### 6.2 Provider 정의

```dart
// UseCase Providers
final enterChannelUseCaseProvider = Provider<EnterChannelUseCase>((ref) {
  return EnterChannelUseCase(
    getPermissions: ref.watch(getChannelPermissionsUseCaseProvider),
    getReadPosition: ref.watch(getReadPositionUseCaseProvider),
    getPosts: ref.watch(getPostsUseCaseProvider),
    calculateUnread: ref.watch(calculateUnreadPositionUseCaseProvider),
  );
});

// Repository Providers
final readPositionRepositoryProvider = Provider<ReadPositionRepository>((ref) {
  final dataSource = ref.watch(readPositionRemoteDataSourceProvider);
  return ReadPositionRepositoryImpl(dataSource);
});

// DataSource Providers
final readPositionRemoteDataSourceProvider = Provider<ReadPositionRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ReadPositionRemoteDataSource(dio);
});
```

---

## 7. 에러 처리 전략

### 7.1 레이어별 에러 변환

```dart
// Domain Layer: 비즈니스 에러
class EnterChannelUseCase {
  Future<ChannelEntryResult> call(int channelId) async {
    if (channelId <= 0) {
      throw ArgumentError('유효하지 않은 채널 ID');
    }

    try {
      return await _fetchData(channelId);
    } on PermissionDeniedException {
      throw ChannelAccessDeniedException(channelId);
    }
  }
}

// Data Layer: 기술적 에러 → 도메인 에러
class ReadPositionRepositoryImpl {
  Future<ReadPosition?> getReadPosition(int channelId) async {
    try {
      return await _dataSource.fetch(channelId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;  // 읽음 이력 없음
      }
      throw NetworkException('읽음 위치 조회 실패');
    }
  }
}

// Presentation Layer: UI 에러
class ChannelEntryNotifier {
  Future<ChannelEntryResult> build(int channelId) async {
    try {
      return await _useCase(channelId);
    } on ChannelAccessDeniedException {
      throw Exception('이 채널에 접근할 권한이 없습니다');
    } on NetworkException {
      throw Exception('네트워크 오류가 발생했습니다');
    }
  }
}
```

### 7.2 Best-Effort 개선 (재시도 큐)

```dart
class ReadPositionNotifier extends AsyncNotifier {
  final _retryQueue = <ReadPositionUpdate>[];

  void markAsRead(int postId) {
    // 1. 낙관적 업데이트
    state = AsyncValue.data(
      state.value!.copyWith(lastReadPostId: postId),
    );

    // 2. 백그라운드 저장
    _saveWithRetry(postId);
  }

  Future<void> _saveWithRetry(int postId) async {
    try {
      await _updateReadPositionUseCase(channelId, postId);
    } catch (e) {
      // 3. 재시도 큐
      _retryQueue.add(ReadPositionUpdate(channelId, postId));
      _scheduleRetry();
    }
  }
}
```

---

## 8. 마이그레이션 로드맵

### Phase 1: Domain Layer 구축 (3일)
- [ ] Entity 정의 (ChannelEntryResult, ReadPosition, UnreadPositionResult)
- [ ] Repository 인터페이스 정의
- [ ] UseCase 구현 (EnterChannelUseCase, CalculateUnreadPositionUseCase)
- [ ] 단위 테스트 작성

### Phase 2: Data Layer 구축 (2일)
- [ ] DataSource 구현 (ReadPositionRemoteDataSource)
- [ ] Repository 구현 (ReadPositionRepositoryImpl)
- [ ] DTO ↔ Entity 매핑
- [ ] 통합 테스트 작성

### Phase 3: Presentation Layer 리팩터링 (5일)
- [ ] Provider 분리 (ChannelEntryNotifier, ReadPositionNotifier 등)
- [ ] Widget 단순화 (ChannelView, PostListView)
- [ ] Visibility Tracking 분리 (PostItemWithTracking)
- [ ] Widget 테스트 작성

### Phase 4: Feature Flag 제거 (2일)
- [ ] StateNotifier 제거
- [ ] AsyncNotifier 일원화
- [ ] _firstUnreadPostIndex 버그 수정
- [ ] E2E 테스트 통과

### Phase 5: 최적화 및 문서화 (3일)
- [ ] 성능 프로파일링
- [ ] 메모리 누수 확인
- [ ] 아키텍처 문서 업데이트
- [ ] 코드 리뷰 및 병합

**총 예상 기간**: 15일 (3주)

---

## 9. 성공 지표

### 9.1 정량적 지표

| 지표 | 현재 | 목표 | 개선율 |
|------|------|------|--------|
| **최대 파일 크기** | 1920줄 | 100줄 | -95% |
| **WorkspaceStateNotifier 책임** | 10+ | 0 (분리) | -100% |
| **Feature Flag 분기** | 2개 | 0개 | -100% |
| **Race Condition** | 2개 | 0개 | -100% |
| **테스트 커버리지** | 60% | 90% | +50% |

### 9.2 정성적 지표

- ✅ **_firstUnreadPostIndex 버그 해결**: 스크롤이 정상 작동
- ✅ **Race Condition 제거**: 타이밍 보장된 데이터 로딩
- ✅ **유지보수성 향상**: 파일당 100줄 이하
- ✅ **테스트 용이성**: 순수 함수와 UseCase 분리
- ✅ **확장성**: Clean Architecture로 새 기능 추가 용이

---

## 📌 핵심 체크리스트

### 개발 전
- [ ] 각 UseCase는 1개 책임만 갖는가?
- [ ] View는 ViewModel 메서드만 호출하는가?
- [ ] ViewModel은 Flutter 의존성이 없는가?

### 개발 중
- [ ] 파일 크기 100줄 이하인가?
- [ ] Race Condition이 없는가?
- [ ] 순수 함수는 테스트 가능한가?

### 개발 후
- [ ] 모든 테스트 통과
- [ ] Feature Flag 제거 완료
- [ ] 문서 업데이트 완료

---

**참고 문서**:
- [CHANNEL_MECHANISM_MEMO.md](../post/CHANNEL_MECHANISM_MEMO.md) - 현재 동작 메커니즘
- [architecture-guide.md](../../../../docs/frontend/architecture-guide.md) - 프론트엔드 아키텍처 가이드
- [CLAUDE.md](../../../../../../../../CLAUDE.md) - 프로젝트 헌법