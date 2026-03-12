import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'post_list_state.dart';
import 'post_usecase_providers.dart';

/// 게시글 목록 AsyncNotifier (MVVM 패턴)
class PostListAsyncNotifier
    extends AutoDisposeFamilyAsyncNotifier<PostListState, String> {
  @override
  Future<PostListState> build(String channelId) async {
    return await _loadInitialPosts(channelId);
  }

  Future<PostListState> _loadInitialPosts(String channelId) async {
    final useCase = ref.watch(getPostsUseCaseProvider);

    try {
      final (posts, pagination) = await useCase(channelId, page: 0);

      return PostListState(
        posts: posts,
        flatItems: [],
        isLoading: false,
        hasMore: pagination.hasMore,
        currentPage: pagination.currentPage + 1,
      );
    } catch (e) {
      throw Exception('게시글을 불러오는데 실패했습니다 ($e)');
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    if (currentState.isLoading || !currentState.hasMore) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final useCase = ref.watch(getPostsUseCaseProvider);
      final channelId = arg;
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
      state = AsyncValue.data(currentState.copyWith(isLoading: false));
    }
  }

  void addPost(dynamic newPost) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(posts: [newPost, ...currentState.posts]),
    );
  }

  void updatePost(int postId, String newContent) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedPosts = currentState.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(content: newContent, updatedAt: DateTime.now());
      }
      return post;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(posts: updatedPosts));
  }

  void removePost(int postId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedPosts = currentState.posts
        .where((post) => post.id != postId)
        .toList();

    state = AsyncValue.data(currentState.copyWith(posts: updatedPosts));
  }
}

final postListAsyncNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<PostListAsyncNotifier, PostListState, String>(
      PostListAsyncNotifier.new,
    );
