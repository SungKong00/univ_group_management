import '../entities/comment.dart';
import '../repositories/comment_repository.dart';

/// UseCase for creating a new comment
///
/// This UseCase encapsulates the business logic for posting
/// a new comment on a post, with optional reply support.
class CreateCommentUseCase {
  final CommentRepository _repository;

  const CreateCommentUseCase(this._repository);

  /// Executes the use case
  ///
  /// [postId] The unique identifier of the post
  /// [content] The text content of the comment (must not be empty)
  /// [parentCommentId] Optional ID for replying to another comment
  /// Returns the newly created [Comment] entity
  /// Throws [ArgumentError] if validation fails
  /// Throws an exception if the repository operation fails
  Future<Comment> call({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    if (postId <= 0) {
      throw ArgumentError('Post ID must be positive', 'postId');
    }

    if (content.trim().isEmpty) {
      throw ArgumentError('Comment content cannot be empty', 'content');
    }

    if (parentCommentId != null && parentCommentId <= 0) {
      throw ArgumentError(
        'Parent comment ID must be positive',
        'parentCommentId',
      );
    }

    return await _repository.createComment(
      postId: postId,
      content: content.trim(),
      parentCommentId: parentCommentId,
    );
  }
}
