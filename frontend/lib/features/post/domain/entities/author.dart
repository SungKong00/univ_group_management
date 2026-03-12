import 'package:freezed_annotation/freezed_annotation.dart';

part 'author.freezed.dart';
part 'author.g.dart';

/// 작성자 정보를 나타내는 불변 Entity
///
/// 게시글, 댓글, 반응 등 다양한 곳에서 재사용 가능합니다.
@freezed
class Author with _$Author {
  const factory Author({
    /// 사용자 고유 ID
    required int id,

    /// 사용자 이름
    required String name,

    /// 프로필 이미지 URL (선택)
    String? profileImageUrl,
  }) = _Author;

  /// JSON에서 Author 객체 생성
  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);
}
