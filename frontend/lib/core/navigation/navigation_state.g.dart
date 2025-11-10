// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NavigationStateImpl _$$NavigationStateImplFromJson(
  Map<String, dynamic> json,
) => _$NavigationStateImpl(
  stack:
      (json['stack'] as List<dynamic>?)
          ?.map((e) => WorkspaceRoute.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  currentIndex: (json['currentIndex'] as num?)?.toInt() ?? -1,
  isLoading: json['isLoading'] as bool? ?? false,
  loadingMessage: json['loadingMessage'] as String?,
  lastError: json['lastError'] as String?,
  isOffline: json['isOffline'] as bool? ?? false,
  scrollPositions:
      (json['scrollPositions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), (e as num).toDouble()),
      ) ??
      const {},
  formData:
      (json['formData'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), e as Map<String, dynamic>),
      ) ??
      const {},
);

Map<String, dynamic> _$$NavigationStateImplToJson(
  _$NavigationStateImpl instance,
) => <String, dynamic>{
  'stack': instance.stack.map((e) => e.toJson()).toList(),
  'currentIndex': instance.currentIndex,
  'isLoading': instance.isLoading,
  'loadingMessage': instance.loadingMessage,
  'lastError': instance.lastError,
  'isOffline': instance.isOffline,
  'scrollPositions': instance.scrollPositions.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
  'formData': instance.formData.map((k, e) => MapEntry(k.toString(), e)),
};
