import '../entities/comment.dart';
import '../repositories/comment_repository.dart';

/// UseCase for retrieving comments for a post
///
/// This UseCase encapsulates the business logic for fetching
/// all comments associated with a specific post.
class GetCommentsUseCase {
  final CommentRepository _repository;

  const GetCommentsUseCase(this._repository);

  /// Executes the use case
  ///
  /// [postId] The unique identifier of the post
  /// Returns a list of [Comment] entities sorted by creation time
  /// Throws [ArgumentError] if postId is invalid
  /// Throws an exception if the repository operation fails
  Future<List<Comment>> call(int postId) async {
    if (postId <= 0) {
      throw ArgumentError('Post ID must be positive', 'postId');
    }

    return await _repository.getComments(postId);
  }
}
