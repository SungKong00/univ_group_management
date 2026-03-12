import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/channel_permissions.dart';

part 'channel_permissions_dto.freezed.dart';
part 'channel_permissions_dto.g.dart';

/// Channel Permissions DTO (Data Transfer Object)
///
/// API 응답에서 받은 채널 권한 데이터를 Domain Entity로 변환하기 위한 중간 객체입니다.
@freezed
class ChannelPermissionsDto with _$ChannelPermissionsDto {
  const ChannelPermissionsDto._();

  const factory ChannelPermissionsDto({
    /// 권한 목록
    required List<String> permissions,
  }) = _ChannelPermissionsDto;

  /// JSON에서 ChannelPermissionsDto 객체 생성
  factory ChannelPermissionsDto.fromJson(Map<String, dynamic> json) =>
      _$ChannelPermissionsDtoFromJson(json);

  /// DTO를 Domain Entity로 변환
  ChannelPermissions toEntity() {
    return ChannelPermissions(permissions: permissions);
  }
}
