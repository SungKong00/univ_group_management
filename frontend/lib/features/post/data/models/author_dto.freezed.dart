// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'author_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AuthorDto _$AuthorDtoFromJson(Map<String, dynamic> json) {
  return _AuthorDto.fromJson(json);
}

/// @nodoc
mixin _$AuthorDto {
  /// 사용자 고유 ID
  int get id => throw _privateConstructorUsedError;

  /// 사용자 이름
  String get name => throw _privateConstructorUsedError;

  /// 프로필 이미지 URL (선택)
  String? get profileImageUrl => throw _privateConstructorUsedError;

  /// Serializes this AuthorDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthorDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthorDtoCopyWith<AuthorDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthorDtoCopyWith<$Res> {
  factory $AuthorDtoCopyWith(AuthorDto value, $Res Function(AuthorDto) then) =
      _$AuthorDtoCopyWithImpl<$Res, AuthorDto>;
  @useResult
  $Res call({int id, String name, String? profileImageUrl});
}

/// @nodoc
class _$AuthorDtoCopyWithImpl<$Res, $Val extends AuthorDto>
    implements $AuthorDtoCopyWith<$Res> {
  _$AuthorDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthorDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? profileImageUrl = freezed,
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
            profileImageUrl: freezed == profileImageUrl
                ? _value.profileImageUrl
                : profileImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthorDtoImplCopyWith<$Res>
    implements $AuthorDtoCopyWith<$Res> {
  factory _$$AuthorDtoImplCopyWith(
    _$AuthorDtoImpl value,
    $Res Function(_$AuthorDtoImpl) then,
  ) = __$$AuthorDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, String? profileImageUrl});
}

/// @nodoc
class __$$AuthorDtoImplCopyWithImpl<$Res>
    extends _$AuthorDtoCopyWithImpl<$Res, _$AuthorDtoImpl>
    implements _$$AuthorDtoImplCopyWith<$Res> {
  __$$AuthorDtoImplCopyWithImpl(
    _$AuthorDtoImpl _value,
    $Res Function(_$AuthorDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthorDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? profileImageUrl = freezed,
  }) {
    return _then(
      _$AuthorDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        profileImageUrl: freezed == profileImageUrl
            ? _value.profileImageUrl
            : profileImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthorDtoImpl extends _AuthorDto {
  const _$AuthorDtoImpl({
    required this.id,
    required this.name,
    this.profileImageUrl,
  }) : super._();

  factory _$AuthorDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthorDtoImplFromJson(json);

  /// 사용자 고유 ID
  @override
  final int id;

  /// 사용자 이름
  @override
  final String name;

  /// 프로필 이미지 URL (선택)
  @override
  final String? profileImageUrl;

  @override
  String toString() {
    return 'AuthorDto(id: $id, name: $name, profileImageUrl: $profileImageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthorDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.profileImageUrl, profileImageUrl) ||
                other.profileImageUrl == profileImageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, profileImageUrl);

  /// Create a copy of AuthorDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthorDtoImplCopyWith<_$AuthorDtoImpl> get copyWith =>
      __$$AuthorDtoImplCopyWithImpl<_$AuthorDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthorDtoImplToJson(this);
  }
}

abstract class _AuthorDto extends AuthorDto {
  const factory _AuthorDto({
    required final int id,
    required final String name,
    final String? profileImageUrl,
  }) = _$AuthorDtoImpl;
  const _AuthorDto._() : super._();

  factory _AuthorDto.fromJson(Map<String, dynamic> json) =
      _$AuthorDtoImpl.fromJson;

  /// 사용자 고유 ID
  @override
  int get id;

  /// 사용자 이름
  @override
  String get name;

  /// 프로필 이미지 URL (선택)
  @override
  String? get profileImageUrl;

  /// Create a copy of AuthorDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthorDtoImplCopyWith<_$AuthorDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
