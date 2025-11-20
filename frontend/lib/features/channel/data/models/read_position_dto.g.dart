// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_position_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReadPositionDtoImpl _$$ReadPositionDtoImplFromJson(
  Map<String, dynamic> json,
) => _$ReadPositionDtoImpl(
  channelId: (json['channelId'] as num).toInt(),
  lastReadPostId: (json['lastReadPostId'] as num).toInt(),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$ReadPositionDtoImplToJson(
  _$ReadPositionDtoImpl instance,
) => <String, dynamic>{
  'channelId': instance.channelId,
  'lastReadPostId': instance.lastReadPostId,
  'updatedAt': instance.updatedAt.toIso8601String(),
};
