import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/author.dart';

part 'author_dto.freezed.dart';
part 'author_dto.g.dart';

/// 작성자 정보 DTO (Data Transfer Object)
///
/// API 응답에서 받은 데이터를 Domain Entity로 변환하기 위한 중간 객체입니다.
@freezed
class AuthorDto with _$AuthorDto {
  const AuthorDto._();

  const factory AuthorDto({
    /// 사용자 고유 ID
    required int id,

    /// 사용자 이름
    required String name,

    /// 프로필 이미지 URL (선택)
    String? profileImageUrl,
  }) = _AuthorDto;

  /// JSON에서 AuthorDto 객체 생성
  factory AuthorDto.fromJson(Map<String, dynamic> json) =>
      _$AuthorDtoFromJson(json);

  /// DTO를 Domain Entity로 변환
  Author toEntity() {
    return Author(id: id, name: name, profileImageUrl: profileImageUrl);
  }
}
