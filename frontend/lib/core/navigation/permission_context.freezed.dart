// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'permission_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PermissionContext _$PermissionContextFromJson(Map<String, dynamic> json) {
  return _PermissionContext.fromJson(json);
}

/// @nodoc
mixin _$PermissionContext {
  int get groupId => throw _privateConstructorUsedError;
  Set<String> get permissions => throw _privateConstructorUsedError;
  bool get isAdmin => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Serializes this PermissionContext to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PermissionContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PermissionContextCopyWith<PermissionContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PermissionContextCopyWith<$Res> {
  factory $PermissionContextCopyWith(
    PermissionContext value,
    $Res Function(PermissionContext) then,
  ) = _$PermissionContextCopyWithImpl<$Res, PermissionContext>;
  @useResult
  $Res call({
    int groupId,
    Set<String> permissions,
    bool isAdmin,
    bool isLoading,
  });
}

/// @nodoc
class _$PermissionContextCopyWithImpl<$Res, $Val extends PermissionContext>
    implements $PermissionContextCopyWith<$Res> {
  _$PermissionContextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PermissionContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? permissions = null,
    Object? isAdmin = null,
    Object? isLoading = null,
  }) {
    return _then(
      _value.copyWith(
            groupId: null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as int,
            permissions: null == permissions
                ? _value.permissions
                : permissions // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
            isAdmin: null == isAdmin
                ? _value.isAdmin
                : isAdmin // ignore: cast_nullable_to_non_nullable
                      as bool,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PermissionContextImplCopyWith<$Res>
    implements $PermissionContextCopyWith<$Res> {
  factory _$$PermissionContextImplCopyWith(
    _$PermissionContextImpl value,
    $Res Function(_$PermissionContextImpl) then,
  ) = __$$PermissionContextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int groupId,
    Set<String> permissions,
    bool isAdmin,
    bool isLoading,
  });
}

/// @nodoc
class __$$PermissionContextImplCopyWithImpl<$Res>
    extends _$PermissionContextCopyWithImpl<$Res, _$PermissionContextImpl>
    implements _$$PermissionContextImplCopyWith<$Res> {
  __$$PermissionContextImplCopyWithImpl(
    _$PermissionContextImpl _value,
    $Res Function(_$PermissionContextImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PermissionContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? permissions = null,
    Object? isAdmin = null,
    Object? isLoading = null,
  }) {
    return _then(
      _$PermissionContextImpl(
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as int,
        permissions: null == permissions
            ? _value._permissions
            : permissions // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        isAdmin: null == isAdmin
            ? _value.isAdmin
            : isAdmin // ignore: cast_nullable_to_non_nullable
                  as bool,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PermissionContextImpl extends _PermissionContext {
  const _$PermissionContextImpl({
    required this.groupId,
    required final Set<String> permissions,
    required this.isAdmin,
    this.isLoading = false,
  }) : _permissions = permissions,
       super._();

  factory _$PermissionContextImpl.fromJson(Map<String, dynamic> json) =>
      _$$PermissionContextImplFromJson(json);

  @override
  final int groupId;
  final Set<String> _permissions;
  @override
  Set<String> get permissions {
    if (_permissions is EqualUnmodifiableSetView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_permissions);
  }

  @override
  final bool isAdmin;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'PermissionContext(groupId: $groupId, permissions: $permissions, isAdmin: $isAdmin, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PermissionContextImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            const DeepCollectionEquality().equals(
              other._permissions,
              _permissions,
            ) &&
            (identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    groupId,
    const DeepCollectionEquality().hash(_permissions),
    isAdmin,
    isLoading,
  );

  /// Create a copy of PermissionContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PermissionContextImplCopyWith<_$PermissionContextImpl> get copyWith =>
      __$$PermissionContextImplCopyWithImpl<_$PermissionContextImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PermissionContextImplToJson(this);
  }
}

abstract class _PermissionContext extends PermissionContext {
  const factory _PermissionContext({
    required final int groupId,
    required final Set<String> permissions,
    required final bool isAdmin,
    final bool isLoading,
  }) = _$PermissionContextImpl;
  const _PermissionContext._() : super._();

  factory _PermissionContext.fromJson(Map<String, dynamic> json) =
      _$PermissionContextImpl.fromJson;

  @override
  int get groupId;
  @override
  Set<String> get permissions;
  @override
  bool get isAdmin;
  @override
  bool get isLoading;

  /// Create a copy of PermissionContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PermissionContextImplCopyWith<_$PermissionContextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
