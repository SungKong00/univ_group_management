import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/post.dart';
import 'author_dto.dart';

part 'post_dto.freezed.dart';
part 'post_dto.g.dart';

/// 게시글 DTO (Data Transfer Object)
///
/// API 응답에서 받은 데이터를 Domain Entity로 변환하기 위한 중간 객체입니다.
@freezed
class PostDto with _$PostDto {
  const PostDto._();

  const factory PostDto({
    /// 게시글 고유 ID
    required int id,

    /// 게시글 내용
    required String content,

    /// 작성자 정보 (중첩 객체)
    required AuthorDto author,

    /// 작성 시각
    required DateTime createdAt,

    /// 수정 시각 (수정되지 않았으면 null)
    DateTime? updatedAt,

    /// 댓글 수
    @Default(0) int commentCount,

    /// 마지막 댓글 작성 시각 (댓글이 없으면 null)
    DateTime? lastCommentedAt,
  }) = _PostDto;

  /// JSON에서 PostDto 객체 생성
  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);

  /// DTO를 Domain Entity로 변환
  Post toEntity() {
    return Post(
      id: id,
      content: content,
      author: author.toEntity(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      commentCount: commentCount,
      lastCommentedAt: lastCommentedAt,
    );
  }
}
