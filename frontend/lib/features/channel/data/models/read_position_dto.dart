import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/read_position.dart';

part 'read_position_dto.freezed.dart';
part 'read_position_dto.g.dart';

/// ReadPosition DTO (Data Transfer Object)
///
/// API 응답에서 받은 읽음 위치 데이터를 Domain Entity로 변환하기 위한 중간 객체입니다.
@freezed
class ReadPositionDto with _$ReadPositionDto {
  const ReadPositionDto._();

  const factory ReadPositionDto({
    /// 채널 ID
    required int channelId,

    /// 마지막으로 읽은 게시글 ID
    required int lastReadPostId,

    /// 업데이트 시각 (ISO8601 형식)
    required DateTime updatedAt,
  }) = _ReadPositionDto;

  /// JSON에서 ReadPositionDto 객체 생성
  factory ReadPositionDto.fromJson(Map<String, dynamic> json) =>
      _$ReadPositionDtoFromJson(json);

  /// DTO를 Domain Entity로 변환
  ReadPosition toEntity() {
    return ReadPosition(
      channelId: channelId,
      lastReadPostId: lastReadPostId,
      updatedAt: updatedAt,
    );
  }
}
