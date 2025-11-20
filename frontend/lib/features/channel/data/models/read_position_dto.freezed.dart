// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'read_position_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReadPositionDto _$ReadPositionDtoFromJson(Map<String, dynamic> json) {
  return _ReadPositionDto.fromJson(json);
}

/// @nodoc
mixin _$ReadPositionDto {
  /// 채널 ID
  int get channelId => throw _privateConstructorUsedError;

  /// 마지막으로 읽은 게시글 ID
  int get lastReadPostId => throw _privateConstructorUsedError;

  /// 업데이트 시각 (ISO8601 형식)
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ReadPositionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReadPositionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReadPositionDtoCopyWith<ReadPositionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReadPositionDtoCopyWith<$Res> {
  factory $ReadPositionDtoCopyWith(
    ReadPositionDto value,
    $Res Function(ReadPositionDto) then,
  ) = _$ReadPositionDtoCopyWithImpl<$Res, ReadPositionDto>;
  @useResult
  $Res call({int channelId, int lastReadPostId, DateTime updatedAt});
}

/// @nodoc
class _$ReadPositionDtoCopyWithImpl<$Res, $Val extends ReadPositionDto>
    implements $ReadPositionDtoCopyWith<$Res> {
  _$ReadPositionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReadPositionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channelId = null,
    Object? lastReadPostId = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            channelId: null == channelId
                ? _value.channelId
                : channelId // ignore: cast_nullable_to_non_nullable
                      as int,
            lastReadPostId: null == lastReadPostId
                ? _value.lastReadPostId
                : lastReadPostId // ignore: cast_nullable_to_non_nullable
                      as int,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReadPositionDtoImplCopyWith<$Res>
    implements $ReadPositionDtoCopyWith<$Res> {
  factory _$$ReadPositionDtoImplCopyWith(
    _$ReadPositionDtoImpl value,
    $Res Function(_$ReadPositionDtoImpl) then,
  ) = __$$ReadPositionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int channelId, int lastReadPostId, DateTime updatedAt});
}

/// @nodoc
class __$$ReadPositionDtoImplCopyWithImpl<$Res>
    extends _$ReadPositionDtoCopyWithImpl<$Res, _$ReadPositionDtoImpl>
    implements _$$ReadPositionDtoImplCopyWith<$Res> {
  __$$ReadPositionDtoImplCopyWithImpl(
    _$ReadPositionDtoImpl _value,
    $Res Function(_$ReadPositionDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReadPositionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channelId = null,
    Object? lastReadPostId = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ReadPositionDtoImpl(
        channelId: null == channelId
            ? _value.channelId
            : channelId // ignore: cast_nullable_to_non_nullable
                  as int,
        lastReadPostId: null == lastReadPostId
            ? _value.lastReadPostId
            : lastReadPostId // ignore: cast_nullable_to_non_nullable
                  as int,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReadPositionDtoImpl extends _ReadPositionDto {
  const _$ReadPositionDtoImpl({
    required this.channelId,
    required this.lastReadPostId,
    required this.updatedAt,
  }) : super._();

  factory _$ReadPositionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReadPositionDtoImplFromJson(json);

  /// 채널 ID
  @override
  final int channelId;

  /// 마지막으로 읽은 게시글 ID
  @override
  final int lastReadPostId;

  /// 업데이트 시각 (ISO8601 형식)
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ReadPositionDto(channelId: $channelId, lastReadPostId: $lastReadPostId, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadPositionDtoImpl &&
            (identical(other.channelId, channelId) ||
                other.channelId == channelId) &&
            (identical(other.lastReadPostId, lastReadPostId) ||
                other.lastReadPostId == lastReadPostId) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, channelId, lastReadPostId, updatedAt);

  /// Create a copy of ReadPositionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadPositionDtoImplCopyWith<_$ReadPositionDtoImpl> get copyWith =>
      __$$ReadPositionDtoImplCopyWithImpl<_$ReadPositionDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReadPositionDtoImplToJson(this);
  }
}

abstract class _ReadPositionDto extends ReadPositionDto {
  const factory _ReadPositionDto({
    required final int channelId,
    required final int lastReadPostId,
    required final DateTime updatedAt,
  }) = _$ReadPositionDtoImpl;
  const _ReadPositionDto._() : super._();

  factory _ReadPositionDto.fromJson(Map<String, dynamic> json) =
      _$ReadPositionDtoImpl.fromJson;

  /// 채널 ID
  @override
  int get channelId;

  /// 마지막으로 읽은 게시글 ID
  @override
  int get lastReadPostId;

  /// 업데이트 시각 (ISO8601 형식)
  @override
  DateTime get updatedAt;

  /// Create a copy of ReadPositionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReadPositionDtoImplCopyWith<_$ReadPositionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
