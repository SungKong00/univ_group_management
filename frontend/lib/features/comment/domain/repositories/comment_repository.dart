import '../entities/comment.dart';

/// Comment repository interface
///
/// Defines the contract for comment data access operations.
/// This interface follows Clean Architecture principles by keeping
/// the domain layer independent of data sources and implementation details.
abstract class CommentRepository {
  /// Retrieves all comments for a given post
  ///
  /// [postId] The unique identifier of the post
  /// Returns a list of [Comment] entities sorted by creation time
  /// Throws an exception if the operation fails
  Future<List<Comment>> getComments(int postId);

  /// Creates a new comment on the specified post
  ///
  /// [postId] The unique identifier of the post
  /// [content] The text content of the comment
  /// [parentCommentId] Optional ID of parent comment (for replies)
  /// Returns the newly created [Comment] entity
  /// Throws an exception if the operation fails or user lacks permissions
  Future<Comment> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  });

  /// Deletes an existing comment
  ///
  /// [commentId] The unique identifier of the comment to delete
  /// Throws an exception if the operation fails or user lacks permissions
  Future<void> deleteComment(int commentId);
}
