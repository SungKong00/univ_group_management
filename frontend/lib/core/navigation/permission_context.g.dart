// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PermissionContextImpl _$$PermissionContextImplFromJson(
  Map<String, dynamic> json,
) => _$PermissionContextImpl(
  groupId: (json['groupId'] as num).toInt(),
  permissions: (json['permissions'] as List<dynamic>)
      .map((e) => e as String)
      .toSet(),
  isAdmin: json['isAdmin'] as bool,
  isLoading: json['isLoading'] as bool? ?? false,
);

Map<String, dynamic> _$$PermissionContextImplToJson(
  _$PermissionContextImpl instance,
) => <String, dynamic>{
  'groupId': instance.groupId,
  'permissions': instance.permissions.toList(),
  'isAdmin': instance.isAdmin,
  'isLoading': instance.isLoading,
};
