// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_permissions_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChannelPermissionsDtoImpl _$$ChannelPermissionsDtoImplFromJson(
  Map<String, dynamic> json,
) => _$ChannelPermissionsDtoImpl(
  permissions: (json['permissions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$$ChannelPermissionsDtoImplToJson(
  _$ChannelPermissionsDtoImpl instance,
) => <String, dynamic>{'permissions': instance.permissions};
