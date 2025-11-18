import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:frontend/features/post/domain/entities/author.dart';
import '../../domain/entities/comment.dart';

part 'comment_dto.freezed.dart';
part 'comment_dto.g.dart';

/// Comment DTO (Data Transfer Object)
///
/// API 응답에서 받은 댓글 데이터를 Domain Entity로 변환하기 위한 중간 객체입니다.
@freezed
class CommentDto with _$CommentDto {
  const CommentDto._();

  const factory CommentDto({
    /// 댓글 고유 ID
    required int id,

    /// 게시글 ID
    required int postId,

    /// 댓글 내용
    required String content,

    /// 작성자 정보 (중첩된 객체)
    required Author author,

    /// 작성 시각
    required DateTime createdAt,

    /// 수정 시각 (선택적)
    DateTime? updatedAt,

    /// 댓글 깊이 (0=최상위, 1=대댓글)
    @Default(0) int depth,

    /// 부모 댓글 ID (선택적)
    int? parentCommentId,
  }) = _CommentDto;

  /// JSON에서 CommentDto 객체 생성
  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);

  /// DTO를 Domain Entity로 변환
  Comment toEntity() {
    return Comment(
      id: id,
      postId: postId,
      content: content,
      author: author,
      createdAt: createdAt,
      updatedAt: updatedAt,
      depth: depth,
      parentCommentId: parentCommentId,
    );
  }
}
