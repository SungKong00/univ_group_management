// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_permissions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChannelPermissions {
  /// List of permission strings
  /// Examples: 'POST_READ', 'POST_WRITE', 'COMMENT_WRITE', 'CHANNEL_MANAGE'
  List<String> get permissions => throw _privateConstructorUsedError;

  /// Create a copy of ChannelPermissions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChannelPermissionsCopyWith<ChannelPermissions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChannelPermissionsCopyWith<$Res> {
  factory $ChannelPermissionsCopyWith(
    ChannelPermissions value,
    $Res Function(ChannelPermissions) then,
  ) = _$ChannelPermissionsCopyWithImpl<$Res, ChannelPermissions>;
  @useResult
  $Res call({List<String> permissions});
}

/// @nodoc
class _$ChannelPermissionsCopyWithImpl<$Res, $Val extends ChannelPermissions>
    implements $ChannelPermissionsCopyWith<$Res> {
  _$ChannelPermissionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChannelPermissions
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
abstract class _$$ChannelPermissionsImplCopyWith<$Res>
    implements $ChannelPermissionsCopyWith<$Res> {
  factory _$$ChannelPermissionsImplCopyWith(
    _$ChannelPermissionsImpl value,
    $Res Function(_$ChannelPermissionsImpl) then,
  ) = __$$ChannelPermissionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> permissions});
}

/// @nodoc
class __$$ChannelPermissionsImplCopyWithImpl<$Res>
    extends _$ChannelPermissionsCopyWithImpl<$Res, _$ChannelPermissionsImpl>
    implements _$$ChannelPermissionsImplCopyWith<$Res> {
  __$$ChannelPermissionsImplCopyWithImpl(
    _$ChannelPermissionsImpl _value,
    $Res Function(_$ChannelPermissionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChannelPermissions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? permissions = null}) {
    return _then(
      _$ChannelPermissionsImpl(
        permissions: null == permissions
            ? _value._permissions
            : permissions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$ChannelPermissionsImpl extends _ChannelPermissions {
  const _$ChannelPermissionsImpl({required final List<String> permissions})
    : _permissions = permissions,
      super._();

  /// List of permission strings
  /// Examples: 'POST_READ', 'POST_WRITE', 'COMMENT_WRITE', 'CHANNEL_MANAGE'
  final List<String> _permissions;

  /// List of permission strings
  /// Examples: 'POST_READ', 'POST_WRITE', 'COMMENT_WRITE', 'CHANNEL_MANAGE'
  @override
  List<String> get permissions {
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_permissions);
  }

  @override
  String toString() {
    return 'ChannelPermissions(permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelPermissionsImpl &&
            const DeepCollectionEquality().equals(
              other._permissions,
              _permissions,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_permissions),
  );

  /// Create a copy of ChannelPermissions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelPermissionsImplCopyWith<_$ChannelPermissionsImpl> get copyWith =>
      __$$ChannelPermissionsImplCopyWithImpl<_$ChannelPermissionsImpl>(
        this,
        _$identity,
      );
}

abstract class _ChannelPermissions extends ChannelPermissions {
  const factory _ChannelPermissions({required final List<String> permissions}) =
      _$ChannelPermissionsImpl;
  const _ChannelPermissions._() : super._();

  /// List of permission strings
  /// Examples: 'POST_READ', 'POST_WRITE', 'COMMENT_WRITE', 'CHANNEL_MANAGE'
  @override
  List<String> get permissions;

  /// Create a copy of ChannelPermissions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChannelPermissionsImplCopyWith<_$ChannelPermissionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
