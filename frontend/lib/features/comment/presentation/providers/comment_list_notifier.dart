import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/comment.dart';
import 'comment_providers.dart';

/// Comment List AsyncNotifier
///
/// Manages the state of the comment list for a specific post.
/// Uses AsyncNotifier pattern for automatic loading and error handling.
///
/// Features:
/// - Automatic loading on provider creation (build method)
/// - Manual refresh support
/// - Add comment support for optimistic UI updates
/// - Delete comment support for optimistic UI updates
class CommentListNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Comment>, int> {
  @override
  Future<List<Comment>> build(int postId) async {
    // Automatically load comments for the specified post
    return await _loadComments(postId);
  }

  /// Loads comments for the specified post
  Future<List<Comment>> _loadComments(int postId) async {
    final useCase = ref.read(getCommentsUseCaseProvider);

    try {
      return await useCase(postId);
    } catch (e) {
      throw Exception('댓글을 불러오는데 실패했습니다 ($e)');
    }
  }

  /// Refreshes the comment list
  ///
  /// Call this when comments are created, updated, or deleted
  /// to ensure the UI reflects the latest state.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadComments(arg));
  }

  /// Adds a newly created comment to the list
  ///
  /// This is an optimistic update - the comment is added immediately
  /// without waiting for a server response.
  ///
  /// Use this after successfully creating a comment to update the UI instantly.
  void addComment(Comment comment) {
    state.whenData((comments) {
      state = AsyncValue.data([...comments, comment]);
    });
  }

  /// Removes a comment from the list
  ///
  /// This is an optimistic update - the comment is removed immediately
  /// without waiting for a server response.
  ///
  /// Use this after successfully deleting a comment to update the UI instantly.
  void removeComment(int commentId) {
    state.whenData((comments) {
      final updatedComments = comments.where((c) => c.id != commentId).toList();
      state = AsyncValue.data(updatedComments);
    });
  }

  /// Creates a new comment
  ///
  /// Validates input, calls the UseCase, and optimistically updates the list.
  /// Returns the newly created comment.
  Future<Comment> createComment(String content, {int? parentCommentId}) async {
    final useCase = ref.read(createCommentUseCaseProvider);

    try {
      final comment = await useCase(
        postId: arg,
        content: content,
        parentCommentId: parentCommentId,
      );

      // Optimistic update
      addComment(comment);

      return comment;
    } catch (e) {
      throw Exception('댓글 작성에 실패했습니다 ($e)');
    }
  }

  /// Deletes a comment
  ///
  /// Calls the UseCase and optimistically updates the list.
  Future<void> deleteComment(int commentId) async {
    final useCase = ref.read(deleteCommentUseCaseProvider);

    try {
      await useCase(commentId);

      // Optimistic update
      removeComment(commentId);
    } catch (e) {
      throw Exception('댓글 삭제에 실패했습니다 ($e)');
    }
  }
}

/// Comment List Provider
///
/// Provides the comment list for a specific post.
/// Automatically loads comments when the provider is created.
///
/// Usage:
/// ```dart
/// final commentsAsync = ref.watch(commentListProvider(postId));
/// ```
final commentListProvider = AsyncNotifierProvider.autoDispose
    .family<CommentListNotifier, List<Comment>, int>(CommentListNotifier.new);
