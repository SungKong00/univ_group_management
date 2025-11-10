// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WorkspaceRoute _$WorkspaceRouteFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'home':
      return HomeRoute.fromJson(json);
    case 'channel':
      return ChannelRoute.fromJson(json);
    case 'calendar':
      return CalendarRoute.fromJson(json);
    case 'admin':
      return AdminRoute.fromJson(json);
    case 'memberManagement':
      return MemberManagementRoute.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'runtimeType',
        'WorkspaceRoute',
        'Invalid union type "${json['runtimeType']}"!',
      );
  }
}

/// @nodoc
mixin _$WorkspaceRoute {
  int get groupId => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int groupId) home,
    required TResult Function(int groupId, int channelId) channel,
    required TResult Function(int groupId) calendar,
    required TResult Function(int groupId) admin,
    required TResult Function(int groupId) memberManagement,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int groupId)? home,
    TResult? Function(int groupId, int channelId)? channel,
    TResult? Function(int groupId)? calendar,
    TResult? Function(int groupId)? admin,
    TResult? Function(int groupId)? memberManagement,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int groupId)? home,
    TResult Function(int groupId, int channelId)? channel,
    TResult Function(int groupId)? calendar,
    TResult Function(int groupId)? admin,
    TResult Function(int groupId)? memberManagement,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HomeRoute value) home,
    required TResult Function(ChannelRoute value) channel,
    required TResult Function(CalendarRoute value) calendar,
    required TResult Function(AdminRoute value) admin,
    required TResult Function(MemberManagementRoute value) memberManagement,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HomeRoute value)? home,
    TResult? Function(ChannelRoute value)? channel,
    TResult? Function(CalendarRoute value)? calendar,
    TResult? Function(AdminRoute value)? admin,
    TResult? Function(MemberManagementRoute value)? memberManagement,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HomeRoute value)? home,
    TResult Function(ChannelRoute value)? channel,
    TResult Function(CalendarRoute value)? calendar,
    TResult Function(AdminRoute value)? admin,
    TResult Function(MemberManagementRoute value)? memberManagement,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this WorkspaceRoute to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkspaceRouteCopyWith<WorkspaceRoute> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkspaceRouteCopyWith<$Res> {
  factory $WorkspaceRouteCopyWith(
    WorkspaceRoute value,
    $Res Function(WorkspaceRoute) then,
  ) = _$WorkspaceRouteCopyWithImpl<$Res, WorkspaceRoute>;
  @useResult
  $Res call({int groupId});
}

/// @nodoc
class _$WorkspaceRouteCopyWithImpl<$Res, $Val extends WorkspaceRoute>
    implements $WorkspaceRouteCopyWith<$Res> {
  _$WorkspaceRouteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? groupId = null}) {
    return _then(
      _value.copyWith(
            groupId: null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HomeRouteImplCopyWith<$Res>
    implements $WorkspaceRouteCopyWith<$Res> {
  factory _$$HomeRouteImplCopyWith(
    _$HomeRouteImpl value,
    $Res Function(_$HomeRouteImpl) then,
  ) = __$$HomeRouteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int groupId});
}

/// @nodoc
class __$$HomeRouteImplCopyWithImpl<$Res>
    extends _$WorkspaceRouteCopyWithImpl<$Res, _$HomeRouteImpl>
    implements _$$HomeRouteImplCopyWith<$Res> {
  __$$HomeRouteImplCopyWithImpl(
    _$HomeRouteImpl _value,
    $Res Function(_$HomeRouteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? groupId = null}) {
    return _then(
      _$HomeRouteImpl(
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HomeRouteImpl implements HomeRoute {
  const _$HomeRouteImpl({required this.groupId, final String? $type})
    : $type = $type ?? 'home';

  factory _$HomeRouteImpl.fromJson(Map<String, dynamic> json) =>
      _$$HomeRouteImplFromJson(json);

  @override
  final int groupId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'WorkspaceRoute.home(groupId: $groupId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeRouteImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, groupId);

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeRouteImplCopyWith<_$HomeRouteImpl> get copyWith =>
      __$$HomeRouteImplCopyWithImpl<_$HomeRouteImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int groupId) home,
    required TResult Function(int groupId, int channelId) channel,
    required TResult Function(int groupId) calendar,
    required TResult Function(int groupId) admin,
    required TResult Function(int groupId) memberManagement,
  }) {
    return home(groupId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int groupId)? home,
    TResult? Function(int groupId, int channelId)? channel,
    TResult? Function(int groupId)? calendar,
    TResult? Function(int groupId)? admin,
    TResult? Function(int groupId)? memberManagement,
  }) {
    return home?.call(groupId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int groupId)? home,
    TResult Function(int groupId, int channelId)? channel,
    TResult Function(int groupId)? calendar,
    TResult Function(int groupId)? admin,
    TResult Function(int groupId)? memberManagement,
    required TResult orElse(),
  }) {
    if (home != null) {
      return home(groupId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HomeRoute value) home,
    required TResult Function(ChannelRoute value) channel,
    required TResult Function(CalendarRoute value) calendar,
    required TResult Function(AdminRoute value) admin,
    required TResult Function(MemberManagementRoute value) memberManagement,
  }) {
    return home(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HomeRoute value)? home,
    TResult? Function(ChannelRoute value)? channel,
    TResult? Function(CalendarRoute value)? calendar,
    TResult? Function(AdminRoute value)? admin,
    TResult? Function(MemberManagementRoute value)? memberManagement,
  }) {
    return home?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HomeRoute value)? home,
    TResult Function(ChannelRoute value)? channel,
    TResult Function(CalendarRoute value)? calendar,
    TResult Function(AdminRoute value)? admin,
    TResult Function(MemberManagementRoute value)? memberManagement,
    required TResult orElse(),
  }) {
    if (home != null) {
      return home(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$HomeRouteImplToJson(this);
  }
}

abstract class HomeRoute implements WorkspaceRoute {
  const factory HomeRoute({required final int groupId}) = _$HomeRouteImpl;

  factory HomeRoute.fromJson(Map<String, dynamic> json) =
      _$HomeRouteImpl.fromJson;

  @override
  int get groupId;

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeRouteImplCopyWith<_$HomeRouteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChannelRouteImplCopyWith<$Res>
    implements $WorkspaceRouteCopyWith<$Res> {
  factory _$$ChannelRouteImplCopyWith(
    _$ChannelRouteImpl value,
    $Res Function(_$ChannelRouteImpl) then,
  ) = __$$ChannelRouteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int groupId, int channelId});
}

/// @nodoc
class __$$ChannelRouteImplCopyWithImpl<$Res>
    extends _$WorkspaceRouteCopyWithImpl<$Res, _$ChannelRouteImpl>
    implements _$$ChannelRouteImplCopyWith<$Res> {
  __$$ChannelRouteImplCopyWithImpl(
    _$ChannelRouteImpl _value,
    $Res Function(_$ChannelRouteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? groupId = null, Object? channelId = null}) {
    return _then(
      _$ChannelRouteImpl(
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as int,
        channelId: null == channelId
            ? _value.channelId
            : channelId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChannelRouteImpl implements ChannelRoute {
  const _$ChannelRouteImpl({
    required this.groupId,
    required this.channelId,
    final String? $type,
  }) : $type = $type ?? 'channel';

  factory _$ChannelRouteImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChannelRouteImplFromJson(json);

  @override
  final int groupId;
  @override
  final int channelId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'WorkspaceRoute.channel(groupId: $groupId, channelId: $channelId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelRouteImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.channelId, channelId) ||
                other.channelId == channelId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, groupId, channelId);

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelRouteImplCopyWith<_$ChannelRouteImpl> get copyWith =>
      __$$ChannelRouteImplCopyWithImpl<_$ChannelRouteImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int groupId) home,
    required TResult Function(int groupId, int channelId) channel,
    required TResult Function(int groupId) calendar,
    required TResult Function(int groupId) admin,
    required TResult Function(int groupId) memberManagement,
  }) {
    return channel(groupId, channelId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int groupId)? home,
    TResult? Function(int groupId, int channelId)? channel,
    TResult? Function(int groupId)? calendar,
    TResult? Function(int groupId)? admin,
    TResult? Function(int groupId)? memberManagement,
  }) {
    return channel?.call(groupId, channelId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int groupId)? home,
    TResult Function(int groupId, int channelId)? channel,
    TResult Function(int groupId)? calendar,
    TResult Function(int groupId)? admin,
    TResult Function(int groupId)? memberManagement,
    required TResult orElse(),
  }) {
    if (channel != null) {
      return channel(groupId, channelId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HomeRoute value) home,
    required TResult Function(ChannelRoute value) channel,
    required TResult Function(CalendarRoute value) calendar,
    required TResult Function(AdminRoute value) admin,
    required TResult Function(MemberManagementRoute value) memberManagement,
  }) {
    return channel(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HomeRoute value)? home,
    TResult? Function(ChannelRoute value)? channel,
    TResult? Function(CalendarRoute value)? calendar,
    TResult? Function(AdminRoute value)? admin,
    TResult? Function(MemberManagementRoute value)? memberManagement,
  }) {
    return channel?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HomeRoute value)? home,
    TResult Function(ChannelRoute value)? channel,
    TResult Function(CalendarRoute value)? calendar,
    TResult Function(AdminRoute value)? admin,
    TResult Function(MemberManagementRoute value)? memberManagement,
    required TResult orElse(),
  }) {
    if (channel != null) {
      return channel(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ChannelRouteImplToJson(this);
  }
}

abstract class ChannelRoute implements WorkspaceRoute {
  const factory ChannelRoute({
    required final int groupId,
    required final int channelId,
  }) = _$ChannelRouteImpl;

  factory ChannelRoute.fromJson(Map<String, dynamic> json) =
      _$ChannelRouteImpl.fromJson;

  @override
  int get groupId;
  int get channelId;

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChannelRouteImplCopyWith<_$ChannelRouteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CalendarRouteImplCopyWith<$Res>
    implements $WorkspaceRouteCopyWith<$Res> {
  factory _$$CalendarRouteImplCopyWith(
    _$CalendarRouteImpl value,
    $Res Function(_$CalendarRouteImpl) then,
  ) = __$$CalendarRouteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int groupId});
}

/// @nodoc
class __$$CalendarRouteImplCopyWithImpl<$Res>
    extends _$WorkspaceRouteCopyWithImpl<$Res, _$CalendarRouteImpl>
    implements _$$CalendarRouteImplCopyWith<$Res> {
  __$$CalendarRouteImplCopyWithImpl(
    _$CalendarRouteImpl _value,
    $Res Function(_$CalendarRouteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? groupId = null}) {
    return _then(
      _$CalendarRouteImpl(
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CalendarRouteImpl implements CalendarRoute {
  const _$CalendarRouteImpl({required this.groupId, final String? $type})
    : $type = $type ?? 'calendar';

  factory _$CalendarRouteImpl.fromJson(Map<String, dynamic> json) =>
      _$$CalendarRouteImplFromJson(json);

  @override
  final int groupId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'WorkspaceRoute.calendar(groupId: $groupId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CalendarRouteImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, groupId);

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CalendarRouteImplCopyWith<_$CalendarRouteImpl> get copyWith =>
      __$$CalendarRouteImplCopyWithImpl<_$CalendarRouteImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int groupId) home,
    required TResult Function(int groupId, int channelId) channel,
    required TResult Function(int groupId) calendar,
    required TResult Function(int groupId) admin,
    required TResult Function(int groupId) memberManagement,
  }) {
    return calendar(groupId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int groupId)? home,
    TResult? Function(int groupId, int channelId)? channel,
    TResult? Function(int groupId)? calendar,
    TResult? Function(int groupId)? admin,
    TResult? Function(int groupId)? memberManagement,
  }) {
    return calendar?.call(groupId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int groupId)? home,
    TResult Function(int groupId, int channelId)? channel,
    TResult Function(int groupId)? calendar,
    TResult Function(int groupId)? admin,
    TResult Function(int groupId)? memberManagement,
    required TResult orElse(),
  }) {
    if (calendar != null) {
      return calendar(groupId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HomeRoute value) home,
    required TResult Function(ChannelRoute value) channel,
    required TResult Function(CalendarRoute value) calendar,
    required TResult Function(AdminRoute value) admin,
    required TResult Function(MemberManagementRoute value) memberManagement,
  }) {
    return calendar(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HomeRoute value)? home,
    TResult? Function(ChannelRoute value)? channel,
    TResult? Function(CalendarRoute value)? calendar,
    TResult? Function(AdminRoute value)? admin,
    TResult? Function(MemberManagementRoute value)? memberManagement,
  }) {
    return calendar?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HomeRoute value)? home,
    TResult Function(ChannelRoute value)? channel,
    TResult Function(CalendarRoute value)? calendar,
    TResult Function(AdminRoute value)? admin,
    TResult Function(MemberManagementRoute value)? memberManagement,
    required TResult orElse(),
  }) {
    if (calendar != null) {
      return calendar(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CalendarRouteImplToJson(this);
  }
}

abstract class CalendarRoute implements WorkspaceRoute {
  const factory CalendarRoute({required final int groupId}) =
      _$CalendarRouteImpl;

  factory CalendarRoute.fromJson(Map<String, dynamic> json) =
      _$CalendarRouteImpl.fromJson;

  @override
  int get groupId;

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CalendarRouteImplCopyWith<_$CalendarRouteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AdminRouteImplCopyWith<$Res>
    implements $WorkspaceRouteCopyWith<$Res> {
  factory _$$AdminRouteImplCopyWith(
    _$AdminRouteImpl value,
    $Res Function(_$AdminRouteImpl) then,
  ) = __$$AdminRouteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int groupId});
}

/// @nodoc
class __$$AdminRouteImplCopyWithImpl<$Res>
    extends _$WorkspaceRouteCopyWithImpl<$Res, _$AdminRouteImpl>
    implements _$$AdminRouteImplCopyWith<$Res> {
  __$$AdminRouteImplCopyWithImpl(
    _$AdminRouteImpl _value,
    $Res Function(_$AdminRouteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? groupId = null}) {
    return _then(
      _$AdminRouteImpl(
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AdminRouteImpl implements AdminRoute {
  const _$AdminRouteImpl({required this.groupId, final String? $type})
    : $type = $type ?? 'admin';

  factory _$AdminRouteImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdminRouteImplFromJson(json);

  @override
  final int groupId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'WorkspaceRoute.admin(groupId: $groupId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminRouteImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, groupId);

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminRouteImplCopyWith<_$AdminRouteImpl> get copyWith =>
      __$$AdminRouteImplCopyWithImpl<_$AdminRouteImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int groupId) home,
    required TResult Function(int groupId, int channelId) channel,
    required TResult Function(int groupId) calendar,
    required TResult Function(int groupId) admin,
    required TResult Function(int groupId) memberManagement,
  }) {
    return admin(groupId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int groupId)? home,
    TResult? Function(int groupId, int channelId)? channel,
    TResult? Function(int groupId)? calendar,
    TResult? Function(int groupId)? admin,
    TResult? Function(int groupId)? memberManagement,
  }) {
    return admin?.call(groupId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int groupId)? home,
    TResult Function(int groupId, int channelId)? channel,
    TResult Function(int groupId)? calendar,
    TResult Function(int groupId)? admin,
    TResult Function(int groupId)? memberManagement,
    required TResult orElse(),
  }) {
    if (admin != null) {
      return admin(groupId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HomeRoute value) home,
    required TResult Function(ChannelRoute value) channel,
    required TResult Function(CalendarRoute value) calendar,
    required TResult Function(AdminRoute value) admin,
    required TResult Function(MemberManagementRoute value) memberManagement,
  }) {
    return admin(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HomeRoute value)? home,
    TResult? Function(ChannelRoute value)? channel,
    TResult? Function(CalendarRoute value)? calendar,
    TResult? Function(AdminRoute value)? admin,
    TResult? Function(MemberManagementRoute value)? memberManagement,
  }) {
    return admin?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HomeRoute value)? home,
    TResult Function(ChannelRoute value)? channel,
    TResult Function(CalendarRoute value)? calendar,
    TResult Function(AdminRoute value)? admin,
    TResult Function(MemberManagementRoute value)? memberManagement,
    required TResult orElse(),
  }) {
    if (admin != null) {
      return admin(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AdminRouteImplToJson(this);
  }
}

abstract class AdminRoute implements WorkspaceRoute {
  const factory AdminRoute({required final int groupId}) = _$AdminRouteImpl;

  factory AdminRoute.fromJson(Map<String, dynamic> json) =
      _$AdminRouteImpl.fromJson;

  @override
  int get groupId;

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminRouteImplCopyWith<_$AdminRouteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MemberManagementRouteImplCopyWith<$Res>
    implements $WorkspaceRouteCopyWith<$Res> {
  factory _$$MemberManagementRouteImplCopyWith(
    _$MemberManagementRouteImpl value,
    $Res Function(_$MemberManagementRouteImpl) then,
  ) = __$$MemberManagementRouteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int groupId});
}

/// @nodoc
class __$$MemberManagementRouteImplCopyWithImpl<$Res>
    extends _$WorkspaceRouteCopyWithImpl<$Res, _$MemberManagementRouteImpl>
    implements _$$MemberManagementRouteImplCopyWith<$Res> {
  __$$MemberManagementRouteImplCopyWithImpl(
    _$MemberManagementRouteImpl _value,
    $Res Function(_$MemberManagementRouteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? groupId = null}) {
    return _then(
      _$MemberManagementRouteImpl(
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MemberManagementRouteImpl implements MemberManagementRoute {
  const _$MemberManagementRouteImpl({
    required this.groupId,
    final String? $type,
  }) : $type = $type ?? 'memberManagement';

  factory _$MemberManagementRouteImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemberManagementRouteImplFromJson(json);

  @override
  final int groupId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'WorkspaceRoute.memberManagement(groupId: $groupId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemberManagementRouteImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, groupId);

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemberManagementRouteImplCopyWith<_$MemberManagementRouteImpl>
  get copyWith =>
      __$$MemberManagementRouteImplCopyWithImpl<_$MemberManagementRouteImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int groupId) home,
    required TResult Function(int groupId, int channelId) channel,
    required TResult Function(int groupId) calendar,
    required TResult Function(int groupId) admin,
    required TResult Function(int groupId) memberManagement,
  }) {
    return memberManagement(groupId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int groupId)? home,
    TResult? Function(int groupId, int channelId)? channel,
    TResult? Function(int groupId)? calendar,
    TResult? Function(int groupId)? admin,
    TResult? Function(int groupId)? memberManagement,
  }) {
    return memberManagement?.call(groupId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int groupId)? home,
    TResult Function(int groupId, int channelId)? channel,
    TResult Function(int groupId)? calendar,
    TResult Function(int groupId)? admin,
    TResult Function(int groupId)? memberManagement,
    required TResult orElse(),
  }) {
    if (memberManagement != null) {
      return memberManagement(groupId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(HomeRoute value) home,
    required TResult Function(ChannelRoute value) channel,
    required TResult Function(CalendarRoute value) calendar,
    required TResult Function(AdminRoute value) admin,
    required TResult Function(MemberManagementRoute value) memberManagement,
  }) {
    return memberManagement(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(HomeRoute value)? home,
    TResult? Function(ChannelRoute value)? channel,
    TResult? Function(CalendarRoute value)? calendar,
    TResult? Function(AdminRoute value)? admin,
    TResult? Function(MemberManagementRoute value)? memberManagement,
  }) {
    return memberManagement?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(HomeRoute value)? home,
    TResult Function(ChannelRoute value)? channel,
    TResult Function(CalendarRoute value)? calendar,
    TResult Function(AdminRoute value)? admin,
    TResult Function(MemberManagementRoute value)? memberManagement,
    required TResult orElse(),
  }) {
    if (memberManagement != null) {
      return memberManagement(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$MemberManagementRouteImplToJson(this);
  }
}

abstract class MemberManagementRoute implements WorkspaceRoute {
  const factory MemberManagementRoute({required final int groupId}) =
      _$MemberManagementRouteImpl;

  factory MemberManagementRoute.fromJson(Map<String, dynamic> json) =
      _$MemberManagementRouteImpl.fromJson;

  @override
  int get groupId;

  /// Create a copy of WorkspaceRoute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemberManagementRouteImplCopyWith<_$MemberManagementRouteImpl>
  get copyWith => throw _privateConstructorUsedError;
}
