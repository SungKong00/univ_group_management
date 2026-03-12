import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/channel.dart';

part 'channel_dto.freezed.dart';
part 'channel_dto.g.dart';

/// Channel DTO (Data Transfer Object)
///
/// API 응답에서 받은 채널 데이터를 Domain Entity로 변환하기 위한 중간 객체입니다.
@freezed
class ChannelDto with _$ChannelDto {
  const ChannelDto._();

  const factory ChannelDto({
    /// 채널 고유 ID
    required int id,

    /// 채널 이름
    required String name,

    /// 채널 타입 (e.g., 'ANNOUNCEMENT', 'TEXT')
    required String type,

    /// 채널 설명 (선택적)
    String? description,

    /// 생성 시각
    DateTime? createdAt,
  }) = _ChannelDto;

  /// JSON에서 ChannelDto 객체 생성
  factory ChannelDto.fromJson(Map<String, dynamic> json) =>
      _$ChannelDtoFromJson(json);

  /// DTO를 Domain Entity로 변환
  Channel toEntity() {
    return Channel(
      id: id,
      name: name,
      type: type,
      description: description,
      createdAt: createdAt,
    );
  }
}
