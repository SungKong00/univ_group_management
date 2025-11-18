import '../repositories/comment_repository.dart';

/// UseCase for deleting a comment
///
/// This UseCase encapsulates the business logic for removing
/// an existing comment from a post.
class DeleteCommentUseCase {
  final CommentRepository _repository;

  const DeleteCommentUseCase(this._repository);

  /// Executes the use case
  ///
  /// [commentId] The unique identifier of the comment to delete
  /// Throws [ArgumentError] if commentId is invalid
  /// Throws an exception if the repository operation fails
  /// (e.g., permission denied, comment not found)
  Future<void> call(int commentId) async {
    if (commentId <= 0) {
      throw ArgumentError('Comment ID must be positive', 'commentId');
    }

    await _repository.deleteComment(commentId);
  }
}
