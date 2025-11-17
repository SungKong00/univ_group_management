import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_posts_usecase.dart';
import 'post_list_state.dart';
import 'post_usecase_providers.dart';

/// 게시글 목록 상태 관리 Notifier
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

/// PostListNotifier Provider
///
/// channelId별로 독립적인 Notifier 인스턴스 생성
final postListNotifierProvider = StateNotifierProvider.autoDispose
    .family<PostListNotifier, PostListState, String>((ref, channelId) {
  final useCase = ref.watch(getPostsUseCaseProvider);
  return PostListNotifier(useCase);
});
