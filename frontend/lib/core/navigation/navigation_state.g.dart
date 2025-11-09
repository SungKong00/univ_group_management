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
);

Map<String, dynamic> _$$NavigationStateImplToJson(
  _$NavigationStateImpl instance,
) => <String, dynamic>{
  'stack': _stackToJson(instance.stack),
  'currentIndex': instance.currentIndex,
};
