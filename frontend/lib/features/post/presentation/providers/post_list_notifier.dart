import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_posts_usecase.dart';
import 'post_list_state.dart';
import 'post_usecase_providers.dart';

// ============================================================
// Old Implementation (StateNotifier)
// ============================================================

/// 게시글 목록 상태 관리 Notifier (구 방식)
///
/// 무한 스크롤, 새로고침, 에러 처리를 담당합니다.
class PostListNotifier extends StateNotifier<PostListState> {
  final GetPostsUseCase _getPostsUseCase;

  PostListNotifier(this._getPostsUseCase) : super(const PostListState());

  /// 게시글 목록 로드
  ///
  /// [channelId]: 채널 ID
  /// [refresh]: true면 목록 초기화 후 첫 페이지부터 로드
  Future<void> loadPosts(String channelId, {bool refresh = false}) async {
    // 이미 로딩 중이면 무시
    if (state.isLoading) return;

    // 새로고침이면 상태 초기화
    if (refresh) {
      state = const PostListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final (posts, pagination) = await _getPostsUseCase(
        channelId,
        page: refresh ? 0 : state.currentPage,
      );

      state = state.copyWith(
        posts: refresh ? posts : [...state.posts, ...posts],
        isLoading: false,
        hasMore: pagination.hasMore,
        currentPage: pagination.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '게시글을 불러오는데 실패했습니다 ($e)',
      );
    }
  }

  /// 특정 게시글 업데이트 (로컬 상태만)
  ///
  /// Create/Update 성공 후 호출하여 목록 갱신
  void updatePost(int postId, String newContent) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          content: newContent,
          updatedAt: DateTime.now(),
        );
      }
      return post;
    }).toList();

    state = state.copyWith(posts: updatedPosts);
  }

  /// 게시글 삭제 (로컬 상태만)
  ///
  /// Delete 성공 후 호출하여 목록에서 제거
  void removePost(int postId) {
    final updatedPosts = state.posts.where((post) => post.id != postId).toList();
    state = state.copyWith(posts: updatedPosts);
  }

  /// 게시글 추가 (로컬 상태만)
  ///
  /// Create 성공 후 목록 맨 앞에 추가
  void addPost(dynamic newPost) {
    state = state.copyWith(posts: [newPost, ...state.posts]);
  }
}

// ============================================================
// New Implementation (AsyncNotifier)
// ============================================================

/// 게시글 목록 상태 관리 AsyncNotifier (신 방식)
///
/// Provider 생성 시 자동으로 데이터 로딩 (build 메서드)
/// Clean Architecture 준수: ViewModel이 데이터 로딩 제어
class PostListAsyncNotifier
    extends AutoDisposeFamilyAsyncNotifier<PostListState, String> {
  @override
  Future<PostListState> build(String channelId) async {
    // ✅ Provider 생성 시 자동 실행 (Widget initState 불필요)
    return await _loadInitialPosts(channelId);
  }

  /// 초기 데이터 로딩
  Future<PostListState> _loadInitialPosts(String channelId) async {
    final useCase = ref.watch(getPostsUseCaseProvider);

    try {
      final (posts, pagination) = await useCase(channelId, page: 0);

      return PostListState(
        posts: posts,
        isLoading: false,
        hasMore: pagination.hasMore,
        currentPage: pagination.currentPage + 1,
      );
    } catch (e) {
      throw Exception('게시글을 불러오는데 실패했습니다 ($e)');
    }
  }

  /// 무한 스크롤: 다음 페이지 로드
  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    if (currentState.isLoading || !currentState.hasMore) return;

    // 낙관적 업데이트 (로딩 상태)
    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final useCase = ref.watch(getPostsUseCaseProvider);
      final channelId = arg; // family parameter
      final (posts, pagination) = await useCase(
        channelId,
        page: currentState.currentPage,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          posts: [...currentState.posts, ...posts],
          isLoading: false,
          hasMore: pagination.hasMore,
          currentPage: pagination.currentPage + 1,
        ),
      );
    } catch (e) {
      // 에러 시 로딩 상태만 되돌림 (기존 posts 유지)
      state = AsyncValue.data(currentState.copyWith(isLoading: false));
    }
  }

  /// 게시글 추가 (로컬 상태만)
  void addPost(dynamic newPost) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(posts: [newPost, ...currentState.posts]),
    );
  }

  /// 게시글 업데이트 (로컬 상태만)
  void updatePost(int postId, String newContent) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedPosts = currentState.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          content: newContent,
          updatedAt: DateTime.now(),
        );
      }
      return post;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(posts: updatedPosts));
  }

  /// 게시글 삭제 (로컬 상태만)
  void removePost(int postId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedPosts =
        currentState.posts.where((post) => post.id != postId).toList();

    state = AsyncValue.data(currentState.copyWith(posts: updatedPosts));
  }
}

// ============================================================
// Provider Definitions (Feature Flag 기반)
// ============================================================

/// PostListNotifier Provider (구 방식)
///
/// channelId별로 독립적인 Notifier 인스턴스 생성
final postListNotifierProvider = StateNotifierProvider.autoDispose
    .family<PostListNotifier, PostListState, String>((ref, channelId) {
  final useCase = ref.watch(getPostsUseCaseProvider);
  return PostListNotifier(useCase);
});

/// PostListAsyncNotifier Provider (신 방식)
///
/// channelId별로 독립적인 AsyncNotifier 인스턴스 생성
/// build() 메서드가 자동으로 데이터 로딩
final postListAsyncNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<PostListAsyncNotifier, PostListState, String>(
  PostListAsyncNotifier.new,
);
