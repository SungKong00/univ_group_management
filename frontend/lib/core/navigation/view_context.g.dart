// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'view_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ViewContextImpl _$$ViewContextImplFromJson(Map<String, dynamic> json) =>
    _$ViewContextImpl(
      type: $enumDecode(_$ViewTypeEnumMap, json['type']),
      channelId: (json['channelId'] as num?)?.toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$ViewContextImplToJson(_$ViewContextImpl instance) =>
    <String, dynamic>{
      'type': _$ViewTypeEnumMap[instance.type]!,
      'channelId': instance.channelId,
      'metadata': instance.metadata,
    };

const _$ViewTypeEnumMap = {
  ViewType.home: 'home',
  ViewType.channel: 'channel',
  ViewType.calendar: 'calendar',
  ViewType.admin: 'admin',
  ViewType.memberManagement: 'memberManagement',
};
