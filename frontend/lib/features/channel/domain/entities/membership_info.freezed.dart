// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'membership_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MembershipInfo {
  /// Group ID the membership belongs to
  int get groupId => throw _privateConstructorUsedError;

  /// Role of the user in the group
  /// Examples: 'OWNER', 'ADMIN', 'MEMBER'
  String get role => throw _privateConstructorUsedError;

  /// List of permission strings the user has in the group
  List<String> get permissions => throw _privateConstructorUsedError;

  /// Create a copy of MembershipInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MembershipInfoCopyWith<MembershipInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MembershipInfoCopyWith<$Res> {
  factory $MembershipInfoCopyWith(
    MembershipInfo value,
    $Res Function(MembershipInfo) then,
  ) = _$MembershipInfoCopyWithImpl<$Res, MembershipInfo>;
  @useResult
  $Res call({int groupId, String role, List<String> permissions});
}

/// @nodoc
class _$MembershipInfoCopyWithImpl<$Res, $Val extends MembershipInfo>
    implements $MembershipInfoCopyWith<$Res> {
  _$MembershipInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MembershipInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? role = null,
    Object? permissions = null,
  }) {
    return _then(
      _value.copyWith(
            groupId: null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as int,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$MembershipInfoImplCopyWith<$Res>
    implements $MembershipInfoCopyWith<$Res> {
  factory _$$MembershipInfoImplCopyWith(
    _$MembershipInfoImpl value,
    $Res Function(_$MembershipInfoImpl) then,
  ) = __$$MembershipInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int groupId, String role, List<String> permissions});
}

/// @nodoc
class __$$MembershipInfoImplCopyWithImpl<$Res>
    extends _$MembershipInfoCopyWithImpl<$Res, _$MembershipInfoImpl>
    implements _$$MembershipInfoImplCopyWith<$Res> {
  __$$MembershipInfoImplCopyWithImpl(
    _$MembershipInfoImpl _value,
    $Res Function(_$MembershipInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MembershipInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? role = null,
    Object? permissions = null,
  }) {
    return _then(
      _$MembershipInfoImpl(
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as int,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        permissions: null == permissions
            ? _value._permissions
            : permissions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$MembershipInfoImpl extends _MembershipInfo {
  const _$MembershipInfoImpl({
    required this.groupId,
    required this.role,
    required final List<String> permissions,
  }) : _permissions = permissions,
       super._();

  /// Group ID the membership belongs to
  @override
  final int groupId;

  /// Role of the user in the group
  /// Examples: 'OWNER', 'ADMIN', 'MEMBER'
  @override
  final String role;

  /// List of permission strings the user has in the group
  final List<String> _permissions;

  /// List of permission strings the user has in the group
  @override
  List<String> get permissions {
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_permissions);
  }

  @override
  String toString() {
    return 'MembershipInfo(groupId: $groupId, role: $role, permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MembershipInfoImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.role, role) || other.role == role) &&
            const DeepCollectionEquality().equals(
              other._permissions,
              _permissions,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    groupId,
    role,
    const DeepCollectionEquality().hash(_permissions),
  );

  /// Create a copy of MembershipInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MembershipInfoImplCopyWith<_$MembershipInfoImpl> get copyWith =>
      __$$MembershipInfoImplCopyWithImpl<_$MembershipInfoImpl>(
        this,
        _$identity,
      );
}

abstract class _MembershipInfo extends MembershipInfo {
  const factory _MembershipInfo({
    required final int groupId,
    required final String role,
    required final List<String> permissions,
  }) = _$MembershipInfoImpl;
  const _MembershipInfo._() : super._();

  /// Group ID the membership belongs to
  @override
  int get groupId;

  /// Role of the user in the group
  /// Examples: 'OWNER', 'ADMIN', 'MEMBER'
  @override
  String get role;

  /// List of permission strings the user has in the group
  @override
  List<String> get permissions;

  /// Create a copy of MembershipInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MembershipInfoImplCopyWith<_$MembershipInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
