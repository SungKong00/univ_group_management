import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:frontend/features/post/domain/entities/author.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

/// 댓글을 나타내는 불변 Entity
///
/// 게시글에 달린 댓글을 표현합니다.
/// depth: 0=최상위 댓글, 1=대댓글 (최대 2단계)
@freezed
class Comment with _$Comment {
  const factory Comment({
    /// 댓글 고유 ID
    required int id,

    /// 게시글 ID
    required int postId,

    /// 댓글 내용
    required String content,

    /// 작성자 정보
    required Author author,

    /// 작성 시각
    required DateTime createdAt,

    /// 수정 시각 (수정되지 않았으면 null)
    DateTime? updatedAt,

    /// 댓글 깊이 (0=최상위, 1=대댓글)
    @Default(0) int depth,

    /// 부모 댓글 ID (최상위 댓글이면 null)
    int? parentCommentId,
  }) = _Comment;

  /// JSON에서 Comment 객체 생성
  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);
}
