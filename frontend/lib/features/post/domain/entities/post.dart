import 'package:freezed_annotation/freezed_annotation.dart';
import 'author.dart';

part 'post.freezed.dart';
part 'post.g.dart';

/// 게시글을 나타내는 불변 Entity
///
/// Slack 스타일로 제목 없이 내용만 포함합니다.
@freezed
class Post with _$Post {
  const factory Post({
    /// 게시글 고유 ID
    required int id,

    /// 게시글 내용 (제목 없음)
    required String content,

    /// 작성자 정보
    required Author author,

    /// 작성 시각
    required DateTime createdAt,

    /// 수정 시각 (수정되지 않았으면 null)
    DateTime? updatedAt,

    /// 댓글 수
    @Default(0) int commentCount,

    /// 마지막 댓글 작성 시각 (댓글이 없으면 null)
    DateTime? lastCommentedAt,
  }) = _Post;

  /// JSON에서 Post 객체 생성
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
