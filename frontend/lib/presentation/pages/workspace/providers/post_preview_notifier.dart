import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/post_models.dart';
import '../../../../core/services/post_service.dart';

/// 게시글 미리보기 상태
class PostPreviewState {
  final Post? post;
  final bool isLoading;
  final String? errorMessage;

  const PostPreviewState({
    this.post,
    this.isLoading = false,
    this.errorMessage,
  });

  PostPreviewState copyWith({
    Post? post,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PostPreviewState(
      post: post ?? this.post,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 빈 상태로 리셋
  PostPreviewState reset() {
    return const PostPreviewState();
  }
}

/// 게시글 미리보기 상태 관리
///
/// 워크스페이스 웹 버전에서 게시글 선택 시 우측 패널에 표시될 게시글 데이터 관리
class PostPreviewNotifier extends StateNotifier<PostPreviewState> {
  final PostService _postService;

  PostPreviewNotifier(this._postService) : super(const PostPreviewState());

  /// 게시글 로드
  Future<void> loadPost(String postId) async {
    // 중복 로드 방지
    if (state.post?.id.toString() == postId && !state.isLoading) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final postIdInt = int.parse(postId);
      final post = await _postService.getPost(postIdInt);

      state = PostPreviewState(
        post: post,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = PostPreviewState(
        post: null,
        isLoading: false,
        errorMessage: '게시글을 불러올 수 없습니다.',
      );
    }
  }

  /// 상태 초기화 (패널 닫을 때)
  void reset() {
    state = state.reset();
  }
}

// ============================================================================
// Providers
// ============================================================================

/// PostService Provider (Singleton)
final postServiceProvider = Provider<PostService>((ref) {
  return PostService();
});

/// 게시글 미리보기 Provider (autoDispose)
final postPreviewProvider =
    StateNotifierProvider.autoDispose<PostPreviewNotifier, PostPreviewState>(
  (ref) {
    final postService = ref.watch(postServiceProvider);
    return PostPreviewNotifier(postService);
  },
);
