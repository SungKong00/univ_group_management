import '../../../../core/models/comment_models.dart' as old_comment;
import '../../domain/entities/comment.dart';

/// Clean Architecture Comment → Old Comment Model 변환 유틸리티
///
/// CommentItem 위젯은 Old Comment Model을 사용하므로,
/// Clean Architecture의 새 Comment Entity를 변환합니다.
///
/// 변환 내용:
/// - New Comment: `Author author` (중첩 객체)
/// - Old Comment: `authorId`, `authorName`, `authorProfileUrl` (플랫 구조)
class CommentConverter {
  /// Clean Architecture Comment → Old Comment Model 변환
  static old_comment.Comment toOldComment(Comment comment) {
    return old_comment.Comment(
      id: comment.id,
      postId: comment.postId,
      content: comment.content,
      authorId: comment.author.id,
      authorName: comment.author.name,
      authorProfileUrl: comment.author.profileImageUrl,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
      depth: comment.depth,
      parentCommentId: comment.parentCommentId,
    );
  }

  /// 댓글 목록 변환
  static List<old_comment.Comment> toOldCommentList(List<Comment> comments) {
    return comments.map(toOldComment).toList();
  }
}
