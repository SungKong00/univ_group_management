import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/comment_remote_data_source.dart';

/// Comment repository implementation
///
/// Implements the [CommentRepository] interface by delegating to
/// [CommentRemoteDataSource] and converting DTOs to domain entities.
/// Error handling is already done at the data source level.
class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource _remoteDataSource;

  CommentRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Comment>> getComments(int postId) async {
    final dtos = await _remoteDataSource.getComments(postId);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<Comment> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    final dto = await _remoteDataSource.createComment(
      postId: postId,
      content: content,
      parentCommentId: parentCommentId,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deleteComment(int commentId) async {
    await _remoteDataSource.deleteComment(commentId);
  }
}
