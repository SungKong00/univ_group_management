// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChannelDto _$ChannelDtoFromJson(Map<String, dynamic> json) {
  return _ChannelDto.fromJson(json);
}

/// @nodoc
mixin _$ChannelDto {
  /// 채널 고유 ID
  int get id => throw _privateConstructorUsedError;

  /// 채널 이름
  String get name => throw _privateConstructorUsedError;

  /// 채널 타입 (e.g., 'ANNOUNCEMENT', 'TEXT')
  String get type => throw _privateConstructorUsedError;

  /// 채널 설명 (선택적)
  String? get description => throw _privateConstructorUsedError;

  /// 생성 시각
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ChannelDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChannelDtoCopyWith<ChannelDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChannelDtoCopyWith<$Res> {
  factory $ChannelDtoCopyWith(
    ChannelDto value,
    $Res Function(ChannelDto) then,
  ) = _$ChannelDtoCopyWithImpl<$Res, ChannelDto>;
  @useResult
  $Res call({
    int id,
    String name,
    String type,
    String? description,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$ChannelDtoCopyWithImpl<$Res, $Val extends ChannelDto>
    implements $ChannelDtoCopyWith<$Res> {
  _$ChannelDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? description = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChannelDtoImplCopyWith<$Res>
    implements $ChannelDtoCopyWith<$Res> {
  factory _$$ChannelDtoImplCopyWith(
    _$ChannelDtoImpl value,
    $Res Function(_$ChannelDtoImpl) then,
  ) = __$$ChannelDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String type,
    String? description,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$ChannelDtoImplCopyWithImpl<$Res>
    extends _$ChannelDtoCopyWithImpl<$Res, _$ChannelDtoImpl>
    implements _$$ChannelDtoImplCopyWith<$Res> {
  __$$ChannelDtoImplCopyWithImpl(
    _$ChannelDtoImpl _value,
    $Res Function(_$ChannelDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? description = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$ChannelDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChannelDtoImpl extends _ChannelDto {
  const _$ChannelDtoImpl({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.createdAt,
  }) : super._();

  factory _$ChannelDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChannelDtoImplFromJson(json);

  /// 채널 고유 ID
  @override
  final int id;

  /// 채널 이름
  @override
  final String name;

  /// 채널 타입 (e.g., 'ANNOUNCEMENT', 'TEXT')
  @override
  final String type;

  /// 채널 설명 (선택적)
  @override
  final String? description;

  /// 생성 시각
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ChannelDto(id: $id, name: $name, type: $type, description: $description, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, type, description, createdAt);

  /// Create a copy of ChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelDtoImplCopyWith<_$ChannelDtoImpl> get copyWith =>
      __$$ChannelDtoImplCopyWithImpl<_$ChannelDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChannelDtoImplToJson(this);
  }
}

abstract class _ChannelDto extends ChannelDto {
  const factory _ChannelDto({
    required final int id,
    required final String name,
    required final String type,
    final String? description,
    final DateTime? createdAt,
  }) = _$ChannelDtoImpl;
  const _ChannelDto._() : super._();

  factory _ChannelDto.fromJson(Map<String, dynamic> json) =
      _$ChannelDtoImpl.fromJson;

  /// 채널 고유 ID
  @override
  int get id;

  /// 채널 이름
  @override
  String get name;

  /// 채널 타입 (e.g., 'ANNOUNCEMENT', 'TEXT')
  @override
  String get type;

  /// 채널 설명 (선택적)
  @override
  String? get description;

  /// 생성 시각
  @override
  DateTime? get createdAt;

  /// Create a copy of ChannelDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChannelDtoImplCopyWith<_$ChannelDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
