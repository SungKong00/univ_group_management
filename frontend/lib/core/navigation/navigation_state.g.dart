// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NavigationStateImpl _$$NavigationStateImplFromJson(
  Map<String, dynamic> json,
) => _$NavigationStateImpl(
  stack: json['stack'] == null
      ? const []
      : _stackFromJson(json['stack'] as List),
  currentIndex: (json['currentIndex'] as num?)?.toInt() ?? -1,
  isLoading: json['isLoading'] as bool? ?? false,
  loadingMessage: json['loadingMessage'] as String?,
  lastError: json['lastError'] as String?,
  isOffline: json['isOffline'] as bool? ?? false,
);

Map<String, dynamic> _$$NavigationStateImplToJson(
  _$NavigationStateImpl instance,
) => <String, dynamic>{
  'stack': _stackToJson(instance.stack),
  'currentIndex': instance.currentIndex,
  'isLoading': instance.isLoading,
  'loadingMessage': instance.loadingMessage,
  'lastError': instance.lastError,
  'isOffline': instance.isOffline,
};
