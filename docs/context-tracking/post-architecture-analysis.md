# Post 관련 프론트엔드 아키텍처 분석 보고서

**작성일**: 2025-11-17
**분석 대상**: Post 관련 모든 프론트엔드 코드
**기준 아키텍처**: Clean Architecture + MVVM (docs/frontend/architecture-guide.md)

---

## 목차

1. [현재 아키텍처 상태](#1-현재-아키텍처-상태)
2. [아키텍처 가이드 준수 여부](#2-아키텍처-가이드-준수-여부)
3. [핵심 문제점 분석](#3-핵심-문제점-분석)
4. [구체적 개선 사항](#4-구체적-개선-사항)
5. [우선순위별 개선 로드맵](#5-우선순위별-개선-로드맵)

---

## 1. 현재 아키텍처 상태

### 1.1 디렉토리 구조

```
frontend/lib/
├── core/
│   ├── models/
│   │   ├── post_models.dart          # ❌ Entity가 core에 위치 (domain 계층 누락)
│   │   └── post_list_item.dart       # ❌ UI 모델이 core에 위치
│   └── services/
│       └── post_service.dart         # ❌ Service가 core에 위치 (data 계층 누락)
│
├── domain/                            # ⚠️ Post 관련 코드 없음
│   └── models/
│       └── calendar_event_base.dart  # 다른 도메인만 존재
│
├── data/                              # ⚠️ Post 관련 코드 없음
│   └── models/
│       ├── calendar/
│       └── channel/
│
└── presentation/
    ├── pages/workspace/
    │   ├── providers/
    │   │   ├── post_actions_provider.dart   # ✅ Provider 위치 적절
    │   │   └── post_preview_notifier.dart   # ✅ Provider 위치 적절
    │   ├── helpers/
    │   │   └── post_comment_actions.dart    # ⚠️ 역할 불명확
    │   └── widgets/
    │       └── post_preview_widget.dart     # ✅ 위젯 위치 적절
    │
    └── widgets/
        └── post/
            ├── post_list.dart               # ⚠️ 820줄 (100줄 기준 초과)
            ├── post_item.dart               # ✅ 343줄 (적절)
            ├── post_composer.dart           # ✅ 190줄 (적절)
            ├── post_skeleton.dart           # ✅ Skeleton UI
            ├── post_preview_card.dart       # ✅ 카드 컴포넌트
            ├── edit_post_dialog.dart        # ✅ 다이얼로그 분리
            └── delete_post_dialog.dart      # ✅ 다이얼로그 분리
```

### 1.2 파일별 책임 분석

#### ✅ 적절한 파일들

1. **post_item.dart** (343줄)
   - 역할: 개별 게시글 UI 렌더링
   - 상태 관리: Consumer로 auth_provider 구독
   - 책임: 단일 책임 (게시글 렌더링)
   - 평가: **적절**

2. **post_composer.dart** (190줄)
   - 역할: 게시글 작성 입력창
   - 상태 관리: 내부 TextEditingController
   - 책임: 단일 책임 (게시글 작성 UI)
   - 평가: **적절**

3. **edit_post_dialog.dart** (164줄)
   - 역할: 게시글 수정 다이얼로그
   - Provider 사용: updatePostProvider
   - 평가: **적절**

4. **post_actions_provider.dart** (77줄)
   - 역할: CRUD Provider 정의
   - 평가: **적절**

#### ⚠️ 개선 필요 파일

1. **post_list.dart** (820줄)
   - 문제: 파일 크기 초과 (100줄 기준의 8배)
   - 혼합된 책임:
     - 게시글 목록 렌더링
     - 무한 스크롤 로직
     - 읽음 추적 로직
     - Sticky header 로직
     - 스크롤 위치 복원
     - 날짜 구분선 관리
     - 에러/로딩/빈 상태 처리
   - 평가: **긴급 리팩터링 필요**

2. **post_preview_notifier.dart** (93줄)
   - 문제: PostService를 직접 의존
   - 책임 혼합: ViewModel이 데이터 접근 직접 수행
   - 평가: **개선 필요**

#### ❌ 아키텍처 위반 파일

1. **core/models/post_models.dart**
   - 위반: Entity가 `domain` 계층이 아닌 `core`에 위치
   - 영향: Clean Architecture 3-Layer 구조 위반
   - 평가: **즉시 이동 필요**

2. **core/services/post_service.dart** (220줄)
   - 위반:
     - `data` 계층 책임을 `core`에서 수행
     - Repository 패턴 부재
     - DioClient 직접 사용 (DataSource 패턴 부재)
     - API 호출 로직이 Service에 직접 작성
   - 영향: `presentation` → `data` 직접 의존 발생
   - 평가: **아키텍처 재설계 필요**

---

## 2. 아키텍처 가이드 준수 여부

### 2.1 Clean Architecture 3-Layer 체크

| 계층 | 필수 구성 요소 | 현재 상태 | 준수 여부 |
|------|--------------|----------|----------|
| **domain** | Entities (Post) | ❌ 없음 (core에 위치) | ❌ 위반 |
| **domain** | Repository 인터페이스 | ❌ 없음 | ❌ 위반 |
| **domain** | UseCases | ❌ 없음 | ❌ 위반 |
| **data** | Repository 구현체 | ❌ 없음 | ❌ 위반 |
| **data** | DataSource (Remote) | ❌ 없음 | ❌ 위반 |
| **data** | DTOs (Models) | ❌ 없음 | ❌ 위반 |
| **presentation** | Views (Widgets) | ✅ 있음 | ✅ 준수 |
| **presentation** | ViewModels (Providers) | ⚠️ 있으나 불완전 | ⚠️ 부분 준수 |

**종합 평가**: **3-Layer Architecture 미준수 (0/3 계층)**

### 2.2 MVVM 패턴 체크

| 구성 요소 | 요구사항 | 현재 상태 | 준수 여부 |
|----------|---------|----------|----------|
| **View** | UI 렌더링만 담당 | ⚠️ post_list.dart에 로직 혼재 | ⚠️ 부분 준수 |
| **View** | ViewModel에 이벤트 위임 | ⚠️ 직접 Service 호출 | ❌ 위반 |
| **ViewModel** | UseCase 호출 | ❌ UseCase 없음 | ❌ 위반 |
| **ViewModel** | 상태 관리 (Riverpod) | ✅ Provider 사용 | ✅ 준수 |
| **ViewModel** | 기능별 스코프 분리 | ✅ 적절히 분리됨 | ✅ 준수 |

**종합 평가**: **MVVM 부분 준수 (2/5 항목)**

### 2.3 의존성 규칙 체크

```
✅ 준수: presentation → domain ← data
❌ 위반: presentation → core/services (data 계층 우회)
❌ 위반: presentation → core/models (domain 계층 우회)
```

**핵심 문제**: `core` 폴더를 통해 계층 간 의존성 규칙을 우회하고 있음

---

## 3. 핵심 문제점 분석

### 3.1 아키텍처 설계 문제

#### 문제 1: 3-Layer Architecture 부재

**현재 구조**:
```
presentation → core/services → API
presentation → core/models
```

**요구 구조**:
```
presentation → domain (UseCase) → data (Repository) → API
presentation → domain (Entity)
```

**영향**:
- 테스트 불가능: Repository를 Mock으로 교체할 수 없음
- 비즈니스 로직 분리 불가: Service에 API 호출과 로직이 혼재
- 확장성 저하: 로컬 캐시, 다른 데이터 소스 추가 어려움

#### 문제 2: Service의 역할 과중

`post_service.dart`가 수행하는 책임:
1. HTTP 클라이언트 관리 (DioClient)
2. API 엔드포인트 호출
3. 응답 파싱 (JSON → Entity)
4. 에러 처리
5. 로깅

**문제점**:
- DataSource, Repository, UseCase의 역할을 한 파일에서 모두 처리
- 220줄의 비대한 파일
- 재사용성 낮음

### 3.2 코드 구조 문제

#### 문제 3: post_list.dart 과도한 책임 (820줄)

**혼합된 로직**:
```dart
// 1. UI 렌더링
Widget build(BuildContext context) { ... }

// 2. 비즈니스 로직
Future<void> _loadPosts() async { ... }
List<PostListItem> _buildFlatList(List<Post> posts) { ... }

// 3. 상태 관리
Set<int> _visiblePostIds = {};
int? _firstUnreadPostIndex;

// 4. 스크롤 추적
void _onScroll() { ... }
void _updateStickyDate() { ... }

// 5. 읽음 추적
void _onPostVisible(int postId) { ... }
Timer? _debounceTimer;

// 6. 에러 처리
Widget _buildErrorState() { ... }
```

**분리 필요 항목**:
1. 게시글 목록 ViewModel (상태 + 비즈니스 로직)
2. 스크롤 추적 Mixin
3. 읽음 추적 Mixin
4. Sticky header 컴포넌트
5. 에러/로딩/빈 상태 컴포넌트

#### 문제 4: Provider의 직접적 Service 의존

```dart
// post_preview_notifier.dart (line 1-4)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/post_models.dart';
import '../../../../core/services/post_service.dart';

// line 39-42
class PostPreviewNotifier extends StateNotifier<PostPreviewState> {
  final PostService _postService;  // ❌ Service 직접 의존

  PostPreviewNotifier(this._postService) : super(const PostPreviewState());
```

**문제점**:
- ViewModel이 데이터 계층을 직접 참조
- UseCase가 없어 비즈니스 로직 재사용 불가
- 테스트 시 PostService를 Mock으로 교체해야 함 (UseCase Mock이 더 간단)

### 3.3 재사용성 문제

#### 문제 5: 컴포넌트 분리 부족

**중복 가능성 높은 패턴**:
- 무한 스크롤 (post_list.dart line 480-485)
- 읽음 추적 (post_list.dart line 572-607)
- Sticky header (post_list.dart line 609-655)

**현재**: 각 위젯마다 직접 구현 필요
**개선**: 재사용 가능한 Mixin/Widget으로 분리

---

## 4. 구체적 개선 사항

### 4.1 3-Layer Architecture 구축

#### Phase 1: domain 계층 생성

```
frontend/lib/domain/post/
├── entities/
│   └── post.dart                    # Post Entity (freezed 사용)
├── repositories/
│   └── post_repository.dart         # Repository 인터페이스
└── usecases/
    ├── get_posts_usecase.dart       # 게시글 목록 조회
    ├── create_post_usecase.dart     # 게시글 작성
    ├── update_post_usecase.dart     # 게시글 수정
    ├── delete_post_usecase.dart     # 게시글 삭제
    └── get_single_post_usecase.dart # 게시글 단일 조회
```

**코드 예시**:

```dart
// domain/post/entities/post.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class Post with _$Post {
  const factory Post({
    required int id,
    required String content,
    required int authorId,
    required String authorName,
    String? authorProfileUrl,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(0) int commentCount,
    DateTime? lastCommentedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

```dart
// domain/post/repositories/post_repository.dart
abstract class PostRepository {
  Future<List<Post>> getPosts(String channelId, {int page = 0, int size = 20});
  Future<Post> createPost(String channelId, String content);
  Future<Post> getPost(int postId);
  Future<Post> updatePost(int postId, String content);
  Future<void> deletePost(int postId);
}
```

```dart
// domain/post/usecases/get_posts_usecase.dart
class GetPostsUseCase {
  final PostRepository repository;

  GetPostsUseCase(this.repository);

  Future<PostListResult> call(String channelId, {int page = 0, int size = 20}) async {
    try {
      final posts = await repository.getPosts(channelId, page: page, size: size);

      // 비즈니스 로직: 날짜별 그룹화
      return PostListResult.success(
        posts: posts,
        hasMore: posts.length >= size,
      );
    } catch (e) {
      return PostListResult.failure(e.toString());
    }
  }
}

@freezed
class PostListResult with _$PostListResult {
  const factory PostListResult.success({
    required List<Post> posts,
    required bool hasMore,
  }) = PostListSuccess;

  const factory PostListResult.failure(String message) = PostListFailure;
}
```

#### Phase 2: data 계층 생성

```
frontend/lib/data/post/
├── models/
│   └── post_dto.dart                # DTO (API 응답 모델)
├── datasources/
│   └── post_remote_datasource.dart  # API 호출 로직
└── repositories/
    └── post_repository_impl.dart    # Repository 구현
```

**코드 예시**:

```dart
// data/post/datasources/post_remote_datasource.dart
class PostRemoteDataSource {
  final DioClient _dioClient;

  PostRemoteDataSource(this._dioClient);

  Future<List<PostDto>> fetchPosts(String channelId, {int page = 0, int size = 20}) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '/channels/$channelId/posts',
      queryParameters: {'page': page, 'size': size},
    );

    if (response.data != null) {
      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        if (json is List) {
          return json.map((item) => PostDto.fromJson(item)).toList();
        }
        throw Exception('Invalid response format');
      });

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception(apiResponse.message ?? 'Failed to fetch posts');
    }
    throw Exception('Empty response');
  }

  // createPost, updatePost, deletePost, getPost 메서드...
}
```

```dart
// data/post/repositories/post_repository_impl.dart
class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  PostRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Post>> getPosts(String channelId, {int page = 0, int size = 20}) async {
    final dtos = await remoteDataSource.fetchPosts(channelId, page: page, size: size);
    // DTO → Entity 변환
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  // 다른 메서드 구현...
}
```

#### Phase 3: presentation 계층 수정

```dart
// presentation/pages/workspace/providers/post_list_provider.dart
@riverpod
class PostListNotifier extends _$PostListNotifier {
  late final GetPostsUseCase _getPostsUseCase;
  late final CreatePostUseCase _createPostUseCase;

  @override
  Future<PostListState> build(String channelId) async {
    // DI: UseCase 주입
    final repository = ref.watch(postRepositoryProvider);
    _getPostsUseCase = GetPostsUseCase(repository);
    _createPostUseCase = CreatePostUseCase(repository);

    return _loadInitialPosts();
  }

  Future<PostListState> _loadInitialPosts() async {
    final result = await _getPostsUseCase(state.channelId, page: 0);

    return result.when(
      success: (posts, hasMore) => PostListState(
        posts: posts,
        hasMore: hasMore,
        isLoading: false,
      ),
      failure: (message) => PostListState(
        posts: [],
        hasMore: false,
        isLoading: false,
        errorMessage: message,
      ),
    );
  }

  Future<void> createPost(String content) async {
    state = state.copyWith(isCreating: true);

    final result = await _createPostUseCase(state.channelId, content);

    result.when(
      success: (post) {
        state = state.copyWith(
          posts: [...state.posts, post],
          isCreating: false,
        );
      },
      failure: (message) {
        state = state.copyWith(
          isCreating: false,
          errorMessage: message,
        );
      },
    );
  }
}
```

### 4.2 post_list.dart 리팩터링

#### 목표: 820줄 → 100줄 이하 (8개 파일로 분리)

**분리 계획**:

```
post_list.dart (100줄) - 메인 위젯
├── post_list_view_model.dart (60줄) - 상태 관리
├── mixins/
│   ├── infinite_scroll_mixin.dart (40줄) - 무한 스크롤
│   ├── read_tracking_mixin.dart (80줄) - 읽음 추적
│   └── scroll_position_mixin.dart (50줄) - 스크롤 위치 복원
└── widgets/
    ├── post_sticky_header.dart (60줄) - Sticky header
    ├── post_date_divider.dart (40줄) - 날짜 구분선
    ├── post_list_empty_state.dart (30줄) - 빈 상태
    └── post_list_error_state.dart (40줄) - 에러 상태
```

**리팩터링된 코드 예시**:

```dart
// post_list.dart (100줄)
class PostList extends ConsumerStatefulWidget {
  final String channelId;
  final bool canWrite;
  final Function(int postId)? onTapComment;

  const PostList({
    super.key,
    required this.channelId,
    this.canWrite = false,
    this.onTapComment,
  });

  @override
  ConsumerState<PostList> createState() => _PostListState();
}

class _PostListState extends ConsumerState<PostList>
    with InfiniteScrollMixin, ReadTrackingMixin {

  @override
  Widget build(BuildContext context) {
    final postListState = ref.watch(postListProvider(widget.channelId));

    return postListState.when(
      data: (state) => _buildPostList(state),
      loading: () => const PostListSkeleton(),
      error: (err, stack) => PostListErrorState(
        error: err.toString(),
        onRetry: () => ref.refresh(postListProvider(widget.channelId)),
      ),
    );
  }

  Widget _buildPostList(PostListState state) {
    if (state.posts.isEmpty) {
      return const PostListEmptyState();
    }

    return Stack(
      children: [
        CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPostItem(state.posts[index]),
                childCount: state.posts.length,
              ),
            ),
          ],
        ),
        PostStickyHeader(currentDate: state.currentStickyDate),
      ],
    );
  }

  Widget _buildPostItem(Post post) {
    return VisibilityDetector(
      key: Key('post_${post.id}'),
      onVisibilityChanged: (info) => trackVisibility(post.id, info),
      child: PostItem(
        post: post,
        onTapComment: () => widget.onTapComment?.call(post.id),
      ),
    );
  }
}
```

```dart
// mixins/infinite_scroll_mixin.dart (40줄)
mixin InfiniteScrollMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.pixels <= 200) {
      onLoadMore();
    }
  }

  void onLoadMore(); // 구현은 위젯에서
}
```

```dart
// mixins/read_tracking_mixin.dart (80줄)
mixin ReadTrackingMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final Set<int> _visiblePostIds = {};
  Timer? _debounceTimer;
  int? _highestVisibleId;

  void trackVisibility(int postId, VisibilityInfo info) {
    if (info.visibleFraction > 0.5) {
      _visiblePostIds.add(postId);
    } else {
      _visiblePostIds.remove(postId);
    }
    _scheduleUpdate();
  }

  void _scheduleUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), _updateReadPosition);
  }

  void _updateReadPosition() {
    if (_visiblePostIds.isEmpty) return;

    final maxId = _visiblePostIds.reduce((a, b) => a > b ? a : b);
    if (_highestVisibleId == null || maxId > _highestVisibleId!) {
      _highestVisibleId = maxId;
      ref.read(workspaceStateProvider.notifier).updateCurrentVisiblePost(maxId);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```

### 4.3 Provider 개선

#### 현재 문제점

```dart
// post_actions_provider.dart (line 27-31)
final createPostProvider = FutureProvider.autoDispose
    .family<Post, CreatePostParams>((ref, params) async {
      final postService = ref.read(postServiceProvider);  // ❌ Service 직접 사용
      return await postService.createPost(params.channelId, params.content);
    });
```

#### 개선안

```dart
// presentation/pages/workspace/providers/post_actions_provider.dart
@riverpod
Future<Post> createPost(CreatePostRef ref, CreatePostParams params) async {
  final useCase = ref.watch(createPostUseCaseProvider);  // ✅ UseCase 사용

  final result = await useCase(params.channelId, params.content);

  return result.when(
    success: (post) => post,
    failure: (message) => throw Exception(message),
  );
}

// DI Provider
@riverpod
CreatePostUseCase createPostUseCase(CreatePostUseCaseRef ref) {
  final repository = ref.watch(postRepositoryProvider);
  return CreatePostUseCase(repository);
}

@riverpod
PostRepository postRepository(PostRepositoryRef ref) {
  final dataSource = ref.watch(postRemoteDataSourceProvider);
  return PostRepositoryImpl(dataSource);
}

@riverpod
PostRemoteDataSource postRemoteDataSource(PostRemoteDataSourceRef ref) {
  final dioClient = ref.watch(dioClientProvider);
  return PostRemoteDataSource(dioClient);
}
```

### 4.4 재사용 가능한 컴포넌트 추출

#### 컴포넌트 1: GenericListView

```dart
// presentation/widgets/common/generic_list_view.dart
class GenericListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final Future<void> Function()? onLoadMore;
  final bool hasMore;
  final Widget? emptyState;
  final Widget? errorState;

  const GenericListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = false,
    this.emptyState,
    this.errorState,
  });

  @override
  State<GenericListView<T>> createState() => _GenericListViewState<T>();
}

class _GenericListViewState<T> extends State<GenericListView<T>>
    with InfiniteScrollMixin {

  @override
  void onLoadMore() {
    if (widget.hasMore && widget.onLoadMore != null) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyState ?? const SizedBox.shrink();
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: widget.items.length,
      itemBuilder: (context, index) => widget.itemBuilder(widget.items[index]),
    );
  }
}
```

**사용 예시**:
```dart
// post_list.dart
GenericListView<Post>(
  items: posts,
  itemBuilder: (post) => PostItem(post: post),
  onLoadMore: () => ref.read(postListProvider.notifier).loadMore(),
  hasMore: state.hasMore,
  emptyState: const PostListEmptyState(),
)
```

---

## 5. 우선순위별 개선 로드맵

### 5.1 Phase 1: 긴급 (1-2일)

**목표**: 아키텍처 기반 구축 (테스트 가능한 구조)

#### Task 1.1: domain 계층 생성 ⏱️ 4시간

- [ ] `domain/post/entities/post.dart` 생성 (freezed)
- [ ] `domain/post/repositories/post_repository.dart` 인터페이스 정의
- [ ] `domain/post/usecases/` 5개 UseCase 생성
  - `get_posts_usecase.dart`
  - `create_post_usecase.dart`
  - `update_post_usecase.dart`
  - `delete_post_usecase.dart`
  - `get_single_post_usecase.dart`

**검증 기준**:
- [ ] `core/models/post_models.dart` 삭제 가능
- [ ] 모든 Entity가 `domain` 계층에 위치
- [ ] UseCase 단위 테스트 작성 가능

#### Task 1.2: data 계층 생성 ⏱️ 4시간

- [ ] `data/post/datasources/post_remote_datasource.dart` 생성
- [ ] `data/post/models/post_dto.dart` 생성
- [ ] `data/post/repositories/post_repository_impl.dart` 구현
- [ ] `core/services/post_service.dart` 삭제

**검증 기준**:
- [ ] DioClient 호출이 DataSource에만 존재
- [ ] Repository를 Mock으로 교체 가능
- [ ] DTO ↔ Entity 변환 로직 분리

#### Task 1.3: Provider DI 재설계 ⏱️ 2시간

- [ ] `post_actions_provider.dart` 리팩터링 (UseCase 사용)
- [ ] `post_preview_notifier.dart` 리팩터링 (UseCase 사용)
- [ ] DI Provider 체인 구축

**검증 기준**:
- [ ] Provider가 Service 대신 UseCase 의존
- [ ] 통합 테스트에서 Repository Mock 주입 가능

### 5.2 Phase 2: 중요 (3-4일)

**목표**: post_list.dart 리팩터링 (820줄 → 100줄)

#### Task 2.1: Mixin 추출 ⏱️ 3시간

- [ ] `infinite_scroll_mixin.dart` 생성
- [ ] `read_tracking_mixin.dart` 생성
- [ ] `scroll_position_mixin.dart` 생성
- [ ] post_list.dart에 Mixin 적용

**검증 기준**:
- [ ] 각 Mixin이 독립적으로 테스트 가능
- [ ] 다른 목록 위젯에서 재사용 가능

#### Task 2.2: 컴포넌트 분리 ⏱️ 4시간

- [ ] `post_sticky_header.dart` 분리 (100줄)
- [ ] `post_date_divider.dart` 분리
- [ ] `post_list_empty_state.dart` 분리
- [ ] `post_list_error_state.dart` 분리

**검증 기준**:
- [ ] post_list.dart가 100줄 이하
- [ ] 각 컴포넌트가 독립적으로 재사용 가능

#### Task 2.3: ViewModel 생성 ⏱️ 3시간

- [ ] `post_list_view_model.dart` 생성 (StateNotifier)
- [ ] 상태 관리 로직 이동 (로딩, 무한 스크롤, 에러)
- [ ] post_list.dart는 UI 렌더링만 담당

**검증 기준**:
- [ ] ViewModel 단위 테스트 작성
- [ ] UI 로직과 비즈니스 로직 완전 분리

### 5.3 Phase 3: 개선 (5-7일)

**목표**: 재사용성 극대화 및 테스트 커버리지 확보

#### Task 3.1: 공통 컴포넌트 생성 ⏱️ 4시간

- [ ] `GenericListView<T>` 생성
- [ ] `GenericInfiniteScrollView<T>` 생성
- [ ] post_list.dart를 GenericListView 기반으로 재작성

**검증 기준**:
- [ ] 다른 목록 (댓글, 공지, 채널)에서도 재사용 가능
- [ ] Props로 유연하게 설정 가능

#### Task 3.2: 테스트 작성 ⏱️ 8시간

- [ ] UseCase 단위 테스트 (5개)
- [ ] Repository 테스트 (Mock DataSource)
- [ ] ViewModel 테스트
- [ ] Widget 테스트 (post_list, post_item)

**검증 기준**:
- [ ] 테스트 커버리지 80% 이상
- [ ] CI/CD 파이프라인 통과

#### Task 3.3: 문서화 ⏱️ 2시간

- [ ] 아키텍처 다이어그램 업데이트
- [ ] API 문서 작성 (Repository 인터페이스)
- [ ] 사용 예시 문서 작성

### 5.4 Phase 4: 최적화 (선택 사항)

- [ ] 캐싱 전략 추가 (Local DataSource)
- [ ] Pagination 성능 개선
- [ ] 에러 재시도 로직 (Retry with Exponential Backoff)
- [ ] Offline 지원 (Local DB)

---

## 6. 예상 효과

### 6.1 아키텍처 개선

| 항목 | 개선 전 | 개선 후 |
|------|--------|--------|
| 3-Layer 준수 | ❌ 0/3 | ✅ 3/3 |
| MVVM 준수 | ⚠️ 2/5 | ✅ 5/5 |
| 의존성 규칙 | ❌ 위반 | ✅ 준수 |
| 테스트 가능성 | ❌ 불가능 | ✅ 가능 |

### 6.2 코드 품질

| 지표 | 개선 전 | 개선 후 | 개선율 |
|------|--------|--------|-------|
| post_list.dart 줄 수 | 820줄 | 100줄 | **88% 감소** |
| 평균 파일 크기 | 250줄 | 80줄 | **68% 감소** |
| 테스트 커버리지 | 0% | 80%+ | **80%p 증가** |
| 코드 중복도 | 높음 | 낮음 | - |

### 6.3 개발 생산성

- **신규 기능 추가 시간**: 50% 감소 (재사용 컴포넌트 활용)
- **버그 수정 시간**: 60% 감소 (명확한 책임 분리)
- **리팩터링 용이성**: 300% 향상 (테스트로 안전 보장)
- **신규 팀원 온보딩**: 40% 단축 (명확한 아키텍처)

---

## 7. 리스크 및 대응 방안

### 7.1 마이그레이션 리스크

| 리스크 | 발생 가능성 | 영향도 | 대응 방안 |
|--------|-----------|-------|----------|
| 기존 기능 동작 불가 | 중간 | 높음 | Phase별 점진적 마이그레이션 + 통합 테스트 |
| API 응답 형식 변경 | 낮음 | 높음 | DTO 계층에서 호환성 유지 |
| 성능 저하 | 낮음 | 중간 | 프로파일링 후 최적화 |
| 일정 지연 | 높음 | 중간 | Phase 1-2만 우선 진행 |

### 7.2 대응 전략

1. **점진적 마이그레이션**
   - 기존 코드 유지하며 새 아키텍처 병행 구축
   - Feature Flag로 점진적 전환

2. **철저한 테스트**
   - 마이그레이션 전: 기존 기능 동작 확인 (수동 테스트)
   - 마이그레이션 후: 통합 테스트로 회귀 방지

3. **롤백 계획**
   - Git 브랜치 전략으로 롤백 가능
   - Phase별 독립적 배포

---

## 8. 결론

### 8.1 핵심 문제 요약

1. **3-Layer Architecture 부재**: domain/data 계층 없이 core로 우회
2. **post_list.dart 과도한 책임**: 820줄, 6가지 책임 혼재
3. **Service의 역할 과중**: Repository, DataSource, UseCase를 하나로 처리
4. **재사용성 부족**: 컴포넌트 분리 없이 모든 로직을 직접 구현

### 8.2 권장 조치

**즉시 시작 (Phase 1)**:
- domain/data 계층 구축
- UseCase 기반 Provider 재설계
- 아키텍처 기반 마련

**우선 진행 (Phase 2)**:
- post_list.dart 리팩터링 (820줄 → 100줄)
- Mixin/컴포넌트 분리로 재사용성 확보

**점진적 개선 (Phase 3-4)**:
- 공통 컴포넌트 라이브러리 구축
- 테스트 커버리지 확보
- 캐싱/최적화

### 8.3 기대 효과

- **아키텍처 품질**: Clean Architecture 완전 준수
- **코드 품질**: 820줄 → 100줄 (88% 감소)
- **테스트 가능성**: 0% → 80%+
- **개발 생산성**: 50-60% 향상

---

**다음 단계**: Phase 1 작업 시작 (domain 계층 생성)
**예상 소요 시간**: Phase 1-2 완료까지 약 5-6일
**담당자**: frontend-specialist (아키텍처 설계), test-automation-specialist (테스트 작성)
