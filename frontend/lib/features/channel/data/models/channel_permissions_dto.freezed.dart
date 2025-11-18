// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_permissions_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChannelPermissionsDto _$ChannelPermissionsDtoFromJson(
  Map<String, dynamic> json,
) {
  return _ChannelPermissionsDto.fromJson(json);
}

/// @nodoc
mixin _$ChannelPermissionsDto {
  /// 권한 목록
  List<String> get permissions => throw _privateConstructorUsedError;

  /// Serializes this ChannelPermissionsDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChannelPermissionsDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChannelPermissionsDtoCopyWith<ChannelPermissionsDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChannelPermissionsDtoCopyWith<$Res> {
  factory $ChannelPermissionsDtoCopyWith(
    ChannelPermissionsDto value,
    $Res Function(ChannelPermissionsDto) then,
  ) = _$ChannelPermissionsDtoCopyWithImpl<$Res, ChannelPermissionsDto>;
  @useResult
  $Res call({List<String> permissions});
}

/// @nodoc
class _$ChannelPermissionsDtoCopyWithImpl<
  $Res,
  $Val extends ChannelPermissionsDto
>
    implements $ChannelPermissionsDtoCopyWith<$Res> {
  _$ChannelPermissionsDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChannelPermissionsDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? permissions = null}) {
    return _then(
      _value.copyWith(
            permissions: null == permissions
                ? _value.permissions
                : permissions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChannelPermissionsDtoImplCopyWith<$Res>
    implements $ChannelPermissionsDtoCopyWith<$Res> {
  factory _$$ChannelPermissionsDtoImplCopyWith(
    _$ChannelPermissionsDtoImpl value,
    $Res Function(_$ChannelPermissionsDtoImpl) then,
  ) = __$$ChannelPermissionsDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> permissions});
}

/// @nodoc
class __$$ChannelPermissionsDtoImplCopyWithImpl<$Res>
    extends
        _$ChannelPermissionsDtoCopyWithImpl<$Res, _$ChannelPermissionsDtoImpl>
    implements _$$ChannelPermissionsDtoImplCopyWith<$Res> {
  __$$ChannelPermissionsDtoImplCopyWithImpl(
    _$ChannelPermissionsDtoImpl _value,
    $Res Function(_$ChannelPermissionsDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChannelPermissionsDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? permissions = null}) {
    return _then(
      _$ChannelPermissionsDtoImpl(
        permissions: null == permissions
            ? _value._permissions
            : permissions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChannelPermissionsDtoImpl extends _ChannelPermissionsDto {
  const _$ChannelPermissionsDtoImpl({required final List<String> permissions})
    : _permissions = permissions,
      super._();

  factory _$ChannelPermissionsDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChannelPermissionsDtoImplFromJson(json);

  /// 권한 목록
  final List<String> _permissions;

  /// 권한 목록
  @override
  List<String> get permissions {
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_permissions);
  }

  @override
  String toString() {
    return 'ChannelPermissionsDto(permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelPermissionsDtoImpl &&
            const DeepCollectionEquality().equals(
              other._permissions,
              _permissions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_permissions),
  );

  /// Create a copy of ChannelPermissionsDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelPermissionsDtoImplCopyWith<_$ChannelPermissionsDtoImpl>
  get copyWith =>
      __$$ChannelPermissionsDtoImplCopyWithImpl<_$ChannelPermissionsDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChannelPermissionsDtoImplToJson(this);
  }
}

abstract class _ChannelPermissionsDto extends ChannelPermissionsDto {
  const factory _ChannelPermissionsDto({
    required final List<String> permissions,
  }) = _$ChannelPermissionsDtoImpl;
  const _ChannelPermissionsDto._() : super._();

  factory _ChannelPermissionsDto.fromJson(Map<String, dynamic> json) =
      _$ChannelPermissionsDtoImpl.fromJson;

  /// 권한 목록
  @override
  List<String> get permissions;

  /// Create a copy of ChannelPermissionsDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChannelPermissionsDtoImplCopyWith<_$ChannelPermissionsDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
