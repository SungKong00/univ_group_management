# 📋 채널 동작 메커니즘 MEMO

> **목적**: 워크스페이스 채널의 전체 동작 흐름을 논리적으로 이해하기 위한 문서
> **대상 독자**: 아키텍처 재설계를 준비하는 개발자
> **작성일**: 2025-11-18
> **상태**: 현재 구현 기반 (v2.0 AsyncNotifier 패턴)

---

## 🎯 핵심 요약

현재 아키텍처는 **6가지 메커니즘**으로 구성됨:

1. **채널 진입** → 권한 + 읽음 위치 로드
2. **게시글 로딩** → Flat List 변환 + 무한 스크롤
3. **읽음 위치 계산** → 스크롤 복원 + Sticky Header
4. **읽음 처리** → VisibilityDetector + Debounce
5. **Sticky Header** → RenderBox 좌표 계산
6. **무한 스크롤** → 스크롤 위치 보존

⚠️ **주요 문제**: Feature Flag로 구/신 방식이 병존하며, 여러 Race Condition이 존재

---

## 📊 전체 상태 흐름 (시각화)

```
┌─────────────────────────────────────────────────────────────────┐
│                      [사용자 채널 선택]                          │
└────────────────────────┬──────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│         WorkspaceStateNotifier.selectChannel(groupId, channelId) │
│  - 이전 채널 읽음 위치 저장 (Best-Effort)                       │
│  - 새 채널 권한 로드 (API)                                      │
│  - 새 채널 읽음 위치 로드 (API)                                 │
│  - await Future.wait([...]) → 동시 실행                         │
│  - await Future.delayed(Duration.zero) → 상태 반영 보장          │
│  - WorkspaceState 업데이트                                      │
└────────────────────────┬──────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│               [PostList Widget 초기화]                           │
│  - Feature Flag: useAsyncNotifierPattern 체크                    │
│  - 구 방식 (false): Future.microtask → _loadPostsAndScrollToUnread()
│  - 신 방식 (true):  WidgetsBinding.addPostFrameCallback         │
└────────────────────────┬──────────────────────────────────────────┘
                         │
            ┌────────────┴────────────┐
            │                         │
            ▼                         ▼
    ┌──────────────────┐    ┌──────────────────────┐
    │  [구 방식]       │    │  [신 방식]           │
    │ StateNotifier    │    │ AsyncNotifier.build()│
    │ 패턴             │    │ 패턴 (현재)          │
    └────────┬─────────┘    └──────────┬───────────┘
             │                         │
             ▼                         ▼
    ┌──────────────────────────────────────────┐
    │  [게시글 데이터 로딩]                    │
    │  1. getPostsUseCase(channelId)           │
    │  2. Flat List 생성 (_buildFlatList)      │
    │     - DateMarker + Post 교대로 배치      │
    └────────────────┬─────────────────────────┘
                     │
                     ▼
    ┌──────────────────────────────────────────┐
    │  [읽음 위치 데이터 대기]                  │
    │  1. _waitForReadPositionData()           │
    │  2. lastReadPostIdMap에서 조회 (100ms × 3)|
    │  3. timeout → fallback                   │
    └────────────────┬─────────────────────────┘
                     │
                     ▼
    ┌──────────────────────────────────────────┐
    │  [첫 읽지 않은 글 찾기]                   │
    │  _findFirstUnreadPostIndexInFlatList()   │
    │  → _firstUnreadPostIndex 설정            │
    └────────────────┬─────────────────────────┘
                     │
                     ▼
    ┌──────────────────────────────────────────┐
    │  [스크롤 복원]                           │
    │  1. AutoScrollController.scrollToIndex() │
    │  2. Sticky header 높이 보정 (-24px)      │
    │  3. _hasScrolledToUnread = true          │
    └────────────────┬─────────────────────────┘
                     │
                     ▼
    ┌──────────────────────────────────────────┐
    │  [VisibilityDetector 활성화]             │
    │  각 PostItem이 visibility 이벤트 구독    │
    └────────────────┬─────────────────────────┘
                     │
            ┌────────┴────────┐
            │                 │
            ▼                 ▼
    ┌────────────────┐  ┌────────────────┐
    │ [스크롤 이벤트] │  │ [읽음 처리]    │
    │ 무한 스크롤    │  │ Debounce +    │
    │ Sticky header │  │ JS 캐시 동기화 │
    └────────────────┘  └────────────────┘
                     │
                     ▼
    ┌──────────────────────────────────────────┐
    │  [채널 이탈 시]                          │
    │  saveReadPosition(channelId, maxId)      │
    │  → API에 읽음 위치 저장                  │
    └──────────────────────────────────────────┘
```

---

## 🔍 메커니즘 상세 분석

### 1️⃣ 채널 진입 (Channel Entry)

#### 📍 트리거 조건
```
사용자가 WorkspaceView에서 채널을 선택
  → WorkspaceStateNotifier.selectChannel(groupId, channelId)
```

#### 📋 실행 순서
```
Step 1: 채널 선택 요청
  └─ 현재 groupId와 같은지 확인 (isSameGroup 플래그)

Step 2: 이전 채널 읽음 위치 저장 (Best-Effort)
  └─ _highestEverVisibleId가 있으면 saveReadPosition() 호출
  └─ 로그아웃 중이면 저장 안 함

Step 3: 새 채널 데이터 로드 (병렬 실행)
  ├─ loadChannelPermissions(channelId) → API
  │   └─ 권한 정보 조회 (canReadPost, canWritePost, canUploadFile)
  │
  └─ loadReadPosition(channelId) → API
      └─ 마지막 읽은 게시글 ID 조회
      └─ workspaceStateProvider.lastReadPostIdMap에 저장

Step 4: 상태 반영 보장
  └─ await Future.delayed(Duration.zero)
  └─ 이유: Provider 업데이트가 Widget rebuild 전에 완료되도록

Step 5: WorkspaceState 업데이트
  └─ selectedChannelId = channelId
  └─ isLoadingPermissions = false
  └─ selectedPostId = null (댓글 창 닫기)

Step 6: PostList Widget 생성/재생성
  └─ key: ValueKey('post_list_${selectedChannelId}_${postReloadTick}')
  └─ 새 channelId에 대한 Provider 구독 시작
```

#### 🔗 의존성
- `WorkspaceStateProvider`: 상태 저장소
- `ChannelService`: API 호출
- `workspaceStateProvider.lastReadPostIdMap`: 읽음 위치 맵

#### ⚠️ 타이밍 이슈
```
Race Condition #1: 읽음 위치 로딩 vs 게시글 로딩
  ├─ 시간대: channelContentView의 FutureBuilder (3초 timeout)
  ├─ 문제: 읽음 위치 데이터가 없으면 FutureBuilder waiting 상태
  ├─ 타이밍: 3초 후 fallback PostList 재생성
  └─ 결과: 기존 PostList state 손실 → 다시 초기화 됨

Best-Effort 저장:
  ├─ 이전 채널 읽음 위치 저장이 실패해도 무시
  ├─ 사용자 경험 저하 (읽은 위치가 초기화)
  └─ 에러 로깅만 함 (사용자 피드백 없음)
```

---

### 2️⃣ 게시글 데이터 로딩 (Post Loading)

#### 📍 트리거 조건
```
PostList Widget 초기화 시
  또는 무한 스크롤 (상단 200px 도달)
```

#### 📋 실행 순서

**구 방식 (StateNotifier, feature_flags.useAsyncNotifierPattern = false)**
```
Step 1: PostList.initState()
  └─ Future.microtask(() => _loadPostsAndScrollToUnread())

Step 2: _loadPostsAndScrollToUnread()
  ├─ _loadPosts(refresh: true)
  │   └─ postListNotifierProvider(channelId).notifier.loadPosts()
  │   └─ GetPostsUseCase(channelId, page: 0) 호출
  │   └─ 결과: PostListState에 posts 저장
  │
  ├─ _waitForReadPositionData() → 최대 300ms 대기
  │
  ├─ _firstUnreadPostIndex 계산
  │
  └─ _scrollToUnreadPost() 실행

Step 3: PostList.build()
  └─ postListNotifierProvider 감시
  └─ PostListState.posts 업데이트 시 rebuild
```

**신 방식 (AsyncNotifier, feature_flags.useAsyncNotifierPattern = true)**
```
Step 1: PostList.initState()
  └─ WidgetsBinding.addPostFrameCallback(() => _restoreScrollPosition())

Step 2: postListAsyncNotifierProvider 자동 실행
  ├─ Provider.watch() 시점에 build() 메서드 실행
  ├─ PostListAsyncNotifier.build(channelId)
  │   └─ _loadInitialPosts(channelId) 실행
  │   └─ GetPostsUseCase(channelId, page: 0) 호출
  │
  └─ AsyncValue<PostListState> 상태 변경
      ├─ loading → data 전환
      └─ PostList.build()에서 AsyncValue.when() 감시

Step 3: _restoreScrollPosition() 실행 (PostFrameCallback)
  ├─ 100ms 지연
  ├─ _waitForReadPositionData()
  ├─ ref.read(postListAsyncNotifierProvider) → valueOrNull 확인
  ├─ Flat List 생성 (_flatItems = _buildFlatList())
  │
  ⚠️ 문제점:
  │  - _firstUnreadPostIndex 계산 누락
  │  - 데이터 로딩 전에 valueOrNull이 null일 수 있음
  │
  └─ _scrollToUnreadPost() 호출
```

#### 📋 Flat List 생성 로직
```
입력: List<Post> posts (oldest → newest 순서)

변환 과정:
Step 1: DateMarker 추가 시점 결정
  ├─ 이전 날짜와 다르면 DateMarker 추가
  └─ _dates[index] = 해당 날짜 저장

Step 2: Post 추가
  ├─ PostWrapper(post) 객체 생성
  └─ _keys[index] = GlobalKey() 저장

출력: List<PostListItem> _flatItems
  ├─ DateMarkerWrapper, PostWrapper, DateMarkerWrapper, ...
  ├─ sequential index로 접근 가능
  └─ 각 항목에 대해 RenderBox 측정 가능 (GlobalKey 사용)
```

#### 📍 무한 스크롤 (Infinite Scroll)
```
트리거:
  └─ scrollPixels <= 200px (상단)

동작:
Step 1: _onScroll() 콜백
  └─ _scrollController.addListener(_onScroll)

Step 2: _loadPosts(refresh: false)
  ├─ currentPage를 1 증가
  ├─ GetPostsUseCase(channelId, page: currentPage) 호출
  └─ 새 페이지 데이터 받음

Step 3: Flat List 재생성
  └─ _flatItems = _buildFlatList(newState.posts)
  └─ 스크롤 위치 보존 계산 (아래 별도 섹션)
```

#### 🔗 의존성
- `GetPostsUseCase`: 게시글 조회
- `postListNotifierProvider` 또는 `postListAsyncNotifierProvider`
- Pagination 정보 (hasMore, currentPage)

#### ⚠️ 타이밍 이슈
```
AsyncNotifier 적응 불완전:
  ├─ 100ms 지연 후 ref.read(provider).valueOrNull 호출
  ├─ AsyncNotifier가 build() 실행 중이면 null 반환
  └─ _flatItems가 빈 상태로 설정 → 스크롤할 데이터 없음

Feature Flag 병존:
  ├─ 구/신 방식 이중 관리
  ├─ 테스트 커버리지 증가
  └─ 유지보수 복잡도 증가
```

---

### 3️⃣ 읽음 위치 계산 및 스크롤 복원 (Read Position & Scroll Restore)

#### 📍 트리거 조건
```
PostList Widget 초기화 시
  → _loadPostsAndScrollToUnread() 또는 _restoreScrollPosition()
```

#### 📋 실행 순서

**단계 1: 읽음 위치 데이터 대기**
```
_waitForReadPositionData(channelId)
  ├─ 초기 지연: 100ms
  │   └─ 이유: WorkspaceStateNotifier.loadReadPosition() API 호출 완료 대기
  │
  ├─ 최대 3회 재시도:
  │   ├─ 재시도 간격: 100ms
  │   ├─ 각 시도: workspaceState.lastReadPostIdMap.containsKey(channelId) 확인
  │   │
  │   └─ 성공 조건: lastReadPostIdMap에 channelId 키 존재
  │       └─ 확인되면 즉시 반환 (최대 300ms 대기)
  │
  └─ 최대 재시도 횟수 초과:
      └─ 포기하고 진행 (다음 단계)
      └─ 결과: _firstUnreadPostIndex 계산 시 lastReadPostId = null
```

**단계 2: 첫 읽지 않은 글 인덱스 계산**
```
_findFirstUnreadPostIndexInFlatList(lastReadPostId)

Case 1: lastReadPostId == null (읽음 이력 없음)
  ├─ _flatItems를 순회
  ├─ 첫 번째 PostWrapper를 찾음 (DateMarker는 스킵)
  └─ 해당 sequential index 반환

Case 2: lastReadPostId == -1 (신규 채널)
  ├─ 위와 동일
  └─ 첫 번째 글로 스크롤

Case 3: lastReadPostId > 0 (읽음 이력 있음)
  ├─ _flatItems를 순회
  ├─ lastReadPostId와 일치하는 Post를 찾음 (이진 탐색 아님, 선형 탐색)
  │
  ├─ 찾은 후 다음 글 찾기:
  │   └─ 그 다음 PostWrapper를 찾음
  │
  └─ 찾은 index 반환

Case 4: 모두 읽음 (읽지 않은 글 없음)
  └─ null 반환
     └─ → 최하단 스크롤로 폴백
```

**단계 3: 스크롤 실행**
```
_scrollToUnreadPost()

조건 검사:
  ├─ _firstUnreadPostIndex == null? → 반환 (진행 안 함)
  ├─ _hasScrolledToUnread == true? → 반환 (이미 스크롤함)
  └─ 통과: 스크롤 진행

Step 1: ScrollController 준비 확인
  ├─ !_scrollController.hasClients?
  │   └─ 300ms 대기 (PostFrameCallback 완료 대기)
  │
  └─ 여전히 hasClients가 false?
      └─ 최하단 스크롤로 폴백
      └─ _isInitialLoading = false로 로딩 상태 종료

Step 2: AutoScrollController 사용
  └─ _scrollController.scrollToIndex(
       _firstUnreadPostIndex!,
       preferPosition: AutoScrollPosition.begin,
       duration: const Duration(milliseconds: 1)
     )
     └─ 이유: scroll_to_index 패키지 사용
     └─ Duration.zero는 허용 안 됨 (최소 1ms)

Step 3: Sticky Header 높이 보정
  ├─ 문제: scrollToIndex() 후 DateMarker (높이 24px) 겹침
  │
  └─ 해결:
      ├─ currentOffset = scrollController.offset
      ├─ adjustedOffset = currentOffset - 24px
      └─ scrollController.jumpTo(adjustedOffset)

Step 4: 상태 업데이트
  └─ _hasScrolledToUnread = true
  └─ _isInitialLoading = false
  └─ setState() 호출
  └─ _updateSticky() PostFrameCallback 등록
```

#### 🔗 의존성
- `workspaceStateProvider.lastReadPostIdMap`: 읽음 위치 정보
- `_flatItems`: Flat List
- `AutoScrollController`: 스크롤 제어
- `scroll_to_index` 패키지

#### ⚠️ 타이밍 이슈
```
Race Condition #1: 데이터 vs 읽음 위치
  ├─ 신 방식에서 100ms 후 ref.read() 호출
  ├─ AsyncNotifier가 여전히 로딩 중이면 null 반환
  └─ _flatItems가 비어있음 → _firstUnreadPostIndex 찾기 불가

Race Condition #2: 스크롤 컨트롤러 준비
  ├─ PostFrameCallback 실행 시점에 hasClients 미결정
  ├─ 최대 300ms 지연 필요
  └─ 타이밍이 맞지 않으면 fallback (최하단 스크롤)

선형 탐색 성능:
  ├─ _flatItems를 매번 전체 순회
  ├─ 큰 리스트에서 O(n) 성능
  └─ 이진 탐색으로 개선 가능 (O(log n))
```

---

### 4️⃣ 읽음 처리 (Visibility Tracking)

#### 📍 트리거 조건
```
1. VisibilityDetector가 PostItem의 가시성 변화 감지
2. 사용자가 스크롤
```

#### 📋 실행 순서

**단계 1: 가시성 감지**
```
각 PostItem 위젯:
  └─ VisibilityDetector(
       key: ValueKey(post.id),
       child: PostItem(),
       onVisibilityChanged: (VisibilityInfo info) {
         if (info.visibleFraction >= 0.5) {
           _onPostVisible(post.id)  // 50% 이상 보임
         } else {
           _onPostInvisible(post.id)  // 50% 미만
         }
       }
     )
```

**단계 2: 보이는 게시글 추적**
```
_onPostVisible(postId)
  ├─ _visiblePostIds.add(postId)
  └─ _scheduleUpdateMaxVisibleId() 호출

_onPostInvisible(postId)
  ├─ _visiblePostIds.remove(postId)
  └─ _scheduleUpdateMaxVisibleId() 호출
```

**단계 3: 읽음 위치 업데이트 (Debouncing)**
```
_scheduleUpdateMaxVisibleId()
  ├─ 이전 Timer 취소: _debounceTimer?.cancel()
  │   └─ 이유: 빠른 스크롤 시 너무 많은 업데이트 방지
  │
  └─ 새 Timer 등록:
      └─ _debounceTimer = Timer(200ms, () => _updateMaxVisibleId())
         └─ 200ms 지연 후 최댓값 한 번 업데이트

_updateMaxVisibleId()
  ├─ 현재 보이는 게시글 중 최댓값 찾기:
  │   └─ maxId = _visiblePostIds.reduce((a, b) => a > b ? a : b)
  │
  ├─ 지금까지 본 것 중 최댓값과 비교:
  │   ├─ maxId > _highestEverVisibleId?
  │   │   ├─ _highestEverVisibleId = maxId
  │   │   └─ 업데이트 진행
  │   │
  │   └─ 아니면: 반환 (업데이트 안 함)
  │       └─ 이유: 읽음 위치는 절대 감소하지 않음
  │
  └─ WorkspaceStateNotifier에 업데이트 알림:
      └─ ref.read(workspaceStateProvider.notifier)
           .updateCurrentVisiblePost(maxId)
```

**단계 4: 상태 업데이트 및 캐싱**
```
WorkspaceStateNotifier.updateCurrentVisiblePost(maxId)
  ├─ state.currentVisiblePostId = maxId
  │   └─ UI에 즉시 반영 (Riverpod state 업데이트)
  │
  └─ JS 캐시 동기화 (웹):
      └─ web_utils.updateJSCache(
           groupId: state.selectedGroupId,
           channelId: state.selectedChannelId,
           maxReadPostId: maxId
         )
      └─ localStorage 또는 sessionStorage에 저장
      └─ 브라우저 새로고침 시에도 유지
```

**단계 5: 채널 이탈 시 API 저장**
```
selectChannel() 호출 시 (다른 채널로 변경):

Step 1: 이전 채널의 읽음 위치 저장
  └─ saveReadPosition(
       channelId: 이전 채널,
       postId: _highestEverVisibleId
     )

Step 2: API 호출
  └─ ChannelService.updateReadPosition(channelId, postId)
  └─ 서버에 최종 읽음 위치 저장

Step 3: 로그아웃 안전장치
  ├─ 로그아웃 중이면 저장 안 함
  └─ isLoggingOutProvider 확인
```

#### 🔗 의존성
- `VisibilityDetector`: 가시성 감지 (visibility_detector 패키지)
- `workspaceStateProvider`: 상태 저장소
- `ChannelService`: API 호출
- `web_utils`: JS 캐시 동기화 (웹)

#### ⚠️ 타이밍 이슈
```
Debouncing 지연 (200ms):
  ├─ 빠른 스크롤 시 최종 위치에서 최대 200ms 지연
  ├─ 장점: CPU/메모리 사용 감소
  └─ 단점: 브라우저 뒤로 가기 시 미저장된 위치 사용 가능

JS 캐시 vs API 저장:
  ├─ JS 캐시: 실시간 동기화 (빠름)
  ├─ API 저장: 채널 이탈 시만 호출 (지연 가능)
  │   └─ 문제: 네트워크 오류 시 저장 실패 가능
  │
  └─ 개선 안: API 저장도 실시간으로 진행

VisibilityDetector 정확도:
  ├─ 50% 이상 조건 (이전에는 30%)
  ├─ 지속 시간 조건 없음 (이전에는 500ms)
  └─ 빠른 스크롤 시 부정확 가능성
```

---

### 5️⃣ Sticky Header 업데이트 (Sticky Date Divider)

#### 📍 트리거 조건
```
1. 스크롤 이벤트 발생
2. 데이터 로드 완료 후
3. PostFrameCallback 실행
```

#### 📋 실행 순서

**단계 1: 스크롤 리스너 등록**
```
PostList.initState()
  └─ _scrollController.addListener(_onScroll)

_onScroll()
  ├─ 무한 스크롤 체크 (상단 200px)
  │   └─ _loadPosts() 호출
  │
  └─ Sticky header 업데이트 예약:
      └─ WidgetsBinding.instance.addPostFrameCallback((_) {
           _updateSticky()
         })
      └─ 이유: 렌더링 완료 후 RenderBox 측정
```

**단계 2: 첫 보이는 날짜 찾기**
```
_updateSticky()

전제 조건:
  ├─ _scrollController.hasClients == true
  ├─ _flatItems.isNotEmpty
  └─ _keys (GlobalKey 맵) 준비됨

Step 1: 모든 DateMarker의 RenderBox 측정
  ├─ _keys.entries 순회
  ├─ key.currentContext?.findRenderObject() as RenderBox?
  │   └─ null 체크 (렌더링 안 된 항목 스킵)
  │
  └─ box.hasSize 확인
      └─ false면 continue (아직 측정 안 됨)

Step 2: 화면 절대 좌표 계산
  ├─ pos = box.localToGlobal(Offset.zero)
  │   └─ 로컬 좌표를 화면 전체 좌표계로 변환
  │
  └─ 조건:
      └─ pos.dy + box.size.height > 87px?
         └─ TopNavigation (48px) + ChannelHeader (39px) 아래에서 보이는가?
         └─ 조건 만족 = 사용자 눈에 보이는 첫 번째 항목

Step 3: 첫 보이는 항목의 날짜 추출
  ├─ firstVisibleIndex 기록
  └─ _dates[firstVisibleIndex] 조회 → newDate

Step 4: Sticky date 업데이트
  ├─ newDate != _stickyDate?
  │   └─ setState(() => _stickyDate = newDate)
  │   └─ UI 업데이트 (DateDivider 변경)
  │
  └─ 아니면: 변경 없음 (불필요한 rebuild 방지)
```

**단계 3: Sticky Header 렌더링**
```
Stack(
  children: [
    // 게시글 리스트 (스크롤)
    CustomScrollView(...),

    // Sticky Header (고정)
    if (_stickyDate != null)
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: _buildSticky(),  // DateDivider with _stickyDate
      )
  ]
)
```

#### 📊 좌표 계산 상세

```
화면 좌표계:
┌─────────────────────────────────────────┐
│                                         │
│  0 ─────────────────────────── (top)    │
│  │                                      │
│  48px ◀───── TopNavigation              │
│  │                                      │
│  48px ─────────────────────             │
│  │                                      │
│  39px ◀───── ChannelHeader               │
│  │                                      │
│  87px ─────────────────────── (threshold)│
│  │                                      │
│        ↑ Sticky header 표시 기준         │
│        ↑ 이 선 아래에서 보이는 항목이    │
│        ↑ Sticky로 고정됨                │
│  │                                      │
│        PostList 시작 (CustomScrollView) │
│  │                                      │
│        DateMarker 1 (2025-11-18)        │
│        ├─ localToGlobal() = pos.dy      │
│        ├─ pos.dy 값 < 87px?             │
│        └─ YES → Sticky (아직 화면 상단)  │
│  │                                      │
│        DateMarker 2 (2025-11-17)        │
│        ├─ pos.dy >= 87px?               │
│        └─ YES → Sticky 대상 (가장 가까움) │
│  │                                      │
│        DateMarker 3 (2025-11-16)        │
│        ├─ pos.dy >> 87px                │
│        └─ NO → 아직 화면 밖              │
│  │                                      │
└─────────────────────────────────────────┘
```

#### 🔗 의존성
- `GlobalKey`: DateMarker 위치 측정
- `RenderBox.localToGlobal()`: 좌표 변환
- `WidgetsBinding.addPostFrameCallback()`: 렌더링 타이밍

#### ⚠️ 타이밍 이슈
```
RenderBox 측정 타이밍:
  ├─ localToGlobal() 호출 전 box.hasSize 확인 필수
  ├─ PostFrameCallback으로 렌더링 완료 보장
  └─ 하지만 마우스 휠 스크롤 시 아직 렌더링 중일 수 있음
      └─ → null check와 exception handling 필요

좌표 계산 오류:
  ├─ 87px 임계값이 하드코딩됨
  ├─ TopNavigation 또는 ChannelHeader 높이 변경 시 영향
  └─ 개선: 동적으로 계산하거나 상수 중앙화

성능:
  ├─ 모든 DateMarker를 순회 (O(n))
  ├─ 이미 찾은 후도 계속 순회
  └─ 개선: 첫 항목 찾은 후 break
```

---

### 6️⃣ 무한 스크롤 (Infinite Scroll)

#### 📍 트리거 조건
```
scrollController.position.pixels <= 200px
  (상단으로부터 200px 이내 스크롤)
```

#### 📋 실행 순서

**단계 1: 스크롤 위치 검사**
```
_onScroll() 콜백 (매 스크롤 이벤트마다 호출)
  ├─ _isInitialLoading 체크
  │   └─ true면 반환 (초기 로딩 중에는 무한 스크롤 안 함)
  │
  └─ 스크롤 위치 확인:
      ├─ _scrollController.position.pixels <= 200.0?
      │   └─ YES → _loadPosts(refresh: false) 호출
      │
      └─ NO → 스크롤 계속 (로드 안 함)
```

**단계 2: 다음 페이지 로드**
```
_loadPosts(refresh: false)

Step 1: 상태 확인
  ├─ state.isLoading == true? → 반환 (이미 로드 중)
  ├─ state.hasMore == false? → 반환 (더 이상 데이터 없음)
  └─ 통과: 로드 진행

Step 2: 스크롤 위치 저장 (무한 스크롤 시에만)
  ├─ refresh == false (무한 스크롤)이고
  ├─ currentPage > 0 (첫 페이지 아님)이고
  ├─ _scrollController.hasClients이면:
  │
  └─ 저장:
      ├─ savedScrollOffset = _scrollController.offset
      └─ savedMaxScrollExtent = _scrollController.position.maxScrollExtent

Step 3: API 호출
  └─ GetPostsUseCase(
       channelId,
       page: state.currentPage  // 0 → 1 → 2 ...
     )

Step 4: Flat List 재생성
  ├─ setState():
  │   └─ _flatItems = _buildFlatList(newState.posts)
  │
  └─ newState.currentPage 증가 (1씩)
```

**단계 3: 스크롤 위치 복원**
```
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (savedScrollOffset != null) {
    // 새 데이터로 인한 스크롤 위치 변화 계산
    final delta = _scrollController.position.maxScrollExtent
                 - (savedMaxScrollExtent ?? 0);

    // 새 위치로 이동
    _scrollController.jumpTo(savedScrollOffset! + delta);

    // Sticky header 업데이트
    _updateSticky();
  }
})
```

#### 📊 스크롤 위치 계산

```
무한 스크롤 전:
  maxScrollExtent = 3000px (기존 데이터)
  currentOffset = 150px (사용자 스크롤 위치)

API에서 새 데이터 로드 (다음 페이지 20개 게시글):
  새로운 렌더링:
    ├─ 기존 아이템 + 새 아이템 함께 렌더링
    └─ maxScrollExtent = 3000 + 800 = 3800px

스크롤 복원:
  delta = 3800 - 3000 = 800px (새로 추가된 높이)
  newOffset = 150 + 800 = 950px

  결과:
    └─ 사용자 관점: 스크롤 위치 유지 (상대적으로 동일)
    └─ 기술적으로: 절대 위치 증가 (새 아이템만큼)

목적:
  ├─ UX: 사용자가 읽던 위치에서 계속 읽도록
  ├─ 구현: 스크롤 점프 없음 (부자연스러움 방지)
  └─ 성능: 새 아이템 데이터만 로드 (모든 아이템 재로드 X)
```

#### 🔗 의존성
- `GetPostsUseCase`: 다음 페이지 조회
- `postListNotifierProvider` 상태: currentPage, hasMore
- `AutoScrollController`: 스크롤 위치 제어

#### ⚠️ 타이밍 이슈
```
빠른 무한 스크롤:
  ├─ 사용자가 빠르게 스크롤할 때
  ├─ 첫 번째 API 호출 전에 다시 200px 도달
  ├─ state.isLoading 체크로 방지
  └─ 하지만 여전히 race condition 가능

스크롤 위치 계산 오류:
  ├─ maxScrollExtent 측정 타이밍
  ├─ 아이템 높이 예측 불가 (가변)
  ├─ Sticky header로 인한 오프셋
  └─ 부정확하면 스크롤 점프 발생

성능:
  ├─ 매 스크롤 이벤트마다 _onScroll() 호출 (100+ 번/초)
  ├─ 조건 검사는 빠르지만 누적 비용 있음
  └─ 스크롤 이벤트 throttling 고려
```

---

## 🔴 현재 문제점 요약

### 1. Race Condition (2가지)

**RC #1: 읽음 위치 로딩 vs 게시글 로딩**
```
Timeline:
  t=0ms: selectChannel() 호출
    ├─ API 1: loadChannelPermissions() 시작
    └─ API 2: loadReadPosition() 시작

  t=100ms: 먼저 완료된 API 반영
    └─ workspaceState 업데이트

  t=200ms: ChannelContentView FutureBuilder 체크
    ├─ lastReadPostIdMap.containsKey(channelId)?
    └─ NO → FutureBuilder waiting 상태

  t=3000ms: 3초 timeout!
    ├─ fallback PostList 재생성
    └─ 기존 PostList state 손실 → 초기화

  t=3100ms: API 완료 (지연이 있었을 경우)
    └─ 이미 fallback된 후 → 무시됨
```

**RC #2: 데이터 로딩 vs 스크롤 복원**
```
신 방식 (AsyncNotifier):
  t=0ms: PostList.initState()
    └─ WidgetsBinding.addPostFrameCallback()

  t=16ms: Provider watch 시작
    └─ postListAsyncNotifierProvider.build() 실행
    └─ GetPostsUseCase 호출 시작

  t=50ms: PostFrameCallback 실행
    ├─ _restoreScrollPosition() 실행
    ├─ ref.read(provider).valueOrNull
    │   └─ 아직 로딩 중 → AsyncValue.loading → null!
    │
    └─ _flatItems = [] (빈 상태)
         → _firstUnreadPostIndex 계산 불가

  t=100ms: API 응답
    └─ AsyncValue.data 업데이트
    └─ 하지만 _firstUnreadPostIndex는 이미 null로 결정됨
       → 최하단 스크롤로 폴백
```

### 2. 상태 동기화 의존성

```
await Future.delayed(Duration.zero)에 의존:
  ├─ selectChannel()에서 사용
  ├─ 목적: WorkspaceState 업데이트가 Widget rebuild 전에 완료
  └─ 문제: Duration.zero는 보장 불가
      └─ 실제로는 마이크로태스크 스케줄링일 뿐
      └─ 실제 순서는 이벤트 루프 구현에 따라 다름

개선 필요:
  ├─ State 변경 감시: ref.listen()
  ├─ Provider 로딩 완료 감시: AsyncValue.when()
  └─ 명시적 콜백으로 타이밍 제어
```

### 3. Feature Flag 병존

```
현재 상태:
  ├─ useAsyncNotifierPattern = true (신 방식)
  ├─ 하지만 구 방식 코드도 남아있음
  │   ├─ StateNotifier 패턴 유지
  │   ├─ Future.microtask() 사용
  │   └─ 테스트 필요 (기능 안 함?)
  │
  └─ 결과:
      ├─ 코드 복잡도 증가
      ├─ 유지보수 부담
      └─ 버그 발생 시 디버깅 어려움

해결:
  ├─ Phase 1: Feature Flag 완전 제거
  ├─ Phase 2: 한 가지 방식으로 통일
  └─ Phase 3: 구 코드 제거
```

---

## 💡 아키텍처 재설계 시 고려사항

### 개선 방향

#### 1. 데이터 로딩 타이밍 일원화

**현재 문제**:
- 구/신 방식 이중 관리
- 100ms, 300ms, 3초 등 여러 타이밍 상수 산재
- Race Condition 여러 개

**개선 방안**:
```
1. Provider 로딩 완료 신호 명확화
   ├─ AsyncNotifier.build() 이후 widget rebuild 순서 정리
   └─ ref.watch() 감시 → AsyncValue 상태 전환

2. 스크롤 복원 타이밍 개선
   ├─ AsyncValue.data 케이스에서만 스크롤
   ├─ _restoreScrollPosition() 삭제
   └─ build() 메서드 내에서 모든 로직 통합

3. Feature Flag 제거
   ├─ AsyncNotifier 방식만 남기기
   ├─ _loadPostsAndScrollToUnread() 삭제
   └─ 테스트 커버리지 단순화
```

#### 2. 읽음 위치 관리 개선

**현재 문제**:
- 3초 timeout이 race condition 유발
- 재시도 로직 (100ms × 3회) 복잡
- Best-Effort 방식으로 실패 무시

**개선 방안**:
```
1. 읽음 위치 로딩 조건 개선
   ├─ FutureBuilder 제거
   ├─ ref.watch(workspaceStateProvider) 직접 감시
   └─ lastReadPostIdMap 변화 감시 → setState()

2. 재시도 메커니즘 단순화
   ├─ 최대 재시도 횟수 감소 (3 → 1)
   ├─ 재시도 간격 조정 (100ms → 50ms)
   └─ 또는 재시도 제거 (로드 안 되면 그냥 진행)

3. 에러 핸들링 개선
   ├─ 읽음 위치 로드 실패 → 사용자 알림
   ├─ 최하단으로 스크롤 → 명확한 이유 제시
   └─ 수동 새로고침 버튼 제공
```

#### 3. Sticky Header 개선

**현재 문제**:
- 87px 임계값 하드코딩
- 모든 DateMarker 순회 (O(n))
- 마우스 휠 스크롤 시 타이밍 문제

**개선 방안**:
```
1. 임계값 동적 계산
   ├─ AppConstants.topNavigationHeight 사용
   ├─ ChannelHeader 높이 동적 측정
   └─ 좌표 계산 중앙화

2. 검색 알고리즘 최적화
   ├─ 첫 보이는 항목 찾은 후 break
   ├─ 또는 이진 탐색 사용 (정렬된 위치)
   └─ 캐싱 (이전 index 기억)

3. 렌더링 타이밍 개선
   ├─ PostFrameCallback 대신 ScrollNotification 사용
   └─ SchedulerBinding으로 frame 동기화
```

#### 4. 무한 스크롤 개선

**현재 문제**:
- 매 스크롤 이벤트마다 조건 검사 (성능)
- 스크롤 위치 계산 부정확 가능
- 동시 요청 방지 로직만 있음

**개선 방안**:
```
1. 이벤트 throttling
   ├─ 스크롤 이벤트 50ms 간격으로 제한
   └─ 또는 위치 변화 >= 50px일 때만 검사

2. 스크롤 위치 계산 정확도
   ├─ 가변 높이 아이템 대비
   ├─ SliverChildBuilder 사용 (동적 높이)
   └─ 또는 정확한 높이 미리 계산

3. 로딩 상태 관리
   ├─ isLoading + hasMore 외에 상태 추가
   └─ 예: LoadingState { idle, loading, error, allLoaded }
```

#### 5. 에러 처리 강화

**현재 문제**:
- Best-Effort 방식 (실패 무시)
- 사용자에게 에러 정보 없음
- 로그만 출력 (개발자용)

**개선 방안**:
```
1. 에러 상태 추가
   ├─ PostListState에 errorMessage 필드
   ├─ AsyncValue.error 케이스 처리
   └─ 사용자 친화적 메시지

2. 재시도 UI
   ├─ "다시 시도" 버튼 제공
   ├─ 또는 자동 재시도 (지수 백오프)
   └─ 최대 재시도 횟수 표시

3. 부분 실패 처리
   ├─ 권한 로드 실패 ≠ 게시글 로드 실패
   ├─ 각각 다른 처리
   └─ 사용자 경험 최적화
```

---

## 📚 참조 코드 위치

### 핵심 파일
```
1. WorkspaceStateNotifier
   └─ frontend/lib/presentation/providers/workspace_state_provider.dart
      ├─ selectChannel() [약 600줄]
      ├─ loadChannelPermissions() [약 650줄]
      ├─ loadReadPosition() [약 1050줄]
      ├─ saveReadPosition() [약 1130줄]
      └─ updateCurrentVisiblePost() [약 610줄]

2. PostList Widget
   └─ frontend/lib/presentation/widgets/post/post_list.dart
      ├─ initState() [137줄]
      ├─ _restoreScrollPosition() [161줄]
      ├─ _loadPostsAndScrollToUnread() [307줄]
      ├─ _scrollToUnreadPost() [389줄]
      ├─ _updateMaxVisibleId() [601줄]
      ├─ _updateSticky() [551줄]
      ├─ _onScroll() [535줄]
      └─ build() [635줄]

3. PostListNotifier / AsyncNotifier
   └─ frontend/lib/features/post/presentation/providers/post_list_notifier.dart
      ├─ PostListNotifier (구 방식) [13줄]
      └─ PostListAsyncNotifier (신 방식) [94줄]

4. ChannelContentView
   └─ frontend/lib/presentation/pages/workspace/widgets/channel_content_view.dart
      ├─ Race Condition #1 발생 위치 [108줄]
      └─ FutureBuilder timeout [118줄]

5. Constants & Utilities
   └─ frontend/lib/presentation/widgets/post/post_list.dart
      ├─ _PostListConstants [30줄]
      └─ 상수 정의 (200px, 24px, 87px, 300ms, 3s, ...)
```

### 관련 Provider
```
workspaceStateProvider
  ├─ state.lastReadPostIdMap: Map<int, int>
  ├─ state.currentVisiblePostId: int?
  ├─ state.selectedChannelId: String?
  └─ state.channels: List<Channel>

postListNotifierProvider 또는 postListAsyncNotifierProvider
  ├─ posts: List<Post>
  ├─ isLoading: bool
  ├─ hasMore: bool
  ├─ currentPage: int
  └─ errorMessage: String?

workspaceNavigationHistoryProvider
  └─ navigationHistory: List<NavigationEntry>
```

---

## ✅ 검증 항목 (문제 수정 후)

1. **채널 진입**
   - [ ] 채널 클릭 후 권한 로딩 완료
   - [ ] 읽음 위치 데이터 로딩 완료
   - [ ] PostList 스크롤 위치 정확함

2. **최신글/읽지 않은 글 스크롤**
   - [ ] 첫 진입: 최신글으로 스크롤
   - [ ] 읽음 이력: 첫 읽지 않은 글로 스크롤
   - [ ] 1회만 실행 (중복 스크롤 X)

3. **읽음 처리**
   - [ ] 게시글 50% 이상 보임 → _onPostVisible() 호출
   - [ ] 200ms 후 읽음 위치 업데이트
   - [ ] 채널 이탈: API에 최종 읽음 위치 저장

4. **Sticky Header**
   - [ ] 스크롤 시 날짜 구분선 업데이트
   - [ ] 정확한 위치에 고정
   - [ ] 렌더링 오류 없음

5. **무한 스크롤**
   - [ ] 상단 200px: 다음 페이지 로드
   - [ ] 스크롤 위치 유지
   - [ ] 중복 로드 없음

6. **성능 & 안정성**
   - [ ] 메모리 누수 없음 (dispose 확인)
   - [ ] 에러 로깅 (디버깅 용이)
   - [ ] 느린 네트워크에서도 정상 작동

---

## 📝 추가 메모

### 개발 시 주의사항
1. Feature Flag 제거 시 관련 테스트도 함께 정리
2. 상수값 변경 전에 영향 범위 확인 (87px, 200px 등)
3. RenderBox 측정은 항상 hasSize 확인
4. 비동기 작업 후 mounted 확인 (메모리 누수 방지)

### 테스트 시나리오
1. 느린 네트워크 (API 지연 3초)
2. 오프라인 상태 (API 실패)
3. 채널 빠른 전환 (race condition 재현)
4. 무한 스크롤 반복 (메모리 누수 확인)
5. 큰 리스트 (1000+ 게시글)

---

**이 문서는 추후 아키텍처 재설계의 기초 자료입니다.**
**각 섹션의 "개선 방안"을 참고하여 새로운 설계에 반영하세요.**
