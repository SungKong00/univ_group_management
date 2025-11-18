// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_entry_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChannelEntryResult {
  /// 채널 정보
  Channel get channel => throw _privateConstructorUsedError;

  /// 현재 사용자의 채널 권한
  ChannelPermissions get permissions => throw _privateConstructorUsedError;

  /// 채널의 게시글 목록
  List<Post> get posts => throw _privateConstructorUsedError;

  /// 마지막으로 읽은 게시글 ID (없으면 null)
  int? get readPosition => throw _privateConstructorUsedError;

  /// Create a copy of ChannelEntryResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChannelEntryResultCopyWith<ChannelEntryResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChannelEntryResultCopyWith<$Res> {
  factory $ChannelEntryResultCopyWith(
    ChannelEntryResult value,
    $Res Function(ChannelEntryResult) then,
  ) = _$ChannelEntryResultCopyWithImpl<$Res, ChannelEntryResult>;
  @useResult
  $Res call({
    Channel channel,
    ChannelPermissions permissions,
    List<Post> posts,
    int? readPosition,
  });

  $ChannelCopyWith<$Res> get channel;
  $ChannelPermissionsCopyWith<$Res> get permissions;
}

/// @nodoc
class _$ChannelEntryResultCopyWithImpl<$Res, $Val extends ChannelEntryResult>
    implements $ChannelEntryResultCopyWith<$Res> {
  _$ChannelEntryResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChannelEntryResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channel = null,
    Object? permissions = null,
    Object? posts = null,
    Object? readPosition = freezed,
  }) {
    return _then(
      _value.copyWith(
            channel: null == channel
                ? _value.channel
                : channel // ignore: cast_nullable_to_non_nullable
                      as Channel,
            permissions: null == permissions
                ? _value.permissions
                : permissions // ignore: cast_nullable_to_non_nullable
                      as ChannelPermissions,
            posts: null == posts
                ? _value.posts
                : posts // ignore: cast_nullable_to_non_nullable
                      as List<Post>,
            readPosition: freezed == readPosition
                ? _value.readPosition
                : readPosition // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }

  /// Create a copy of ChannelEntryResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChannelCopyWith<$Res> get channel {
    return $ChannelCopyWith<$Res>(_value.channel, (value) {
      return _then(_value.copyWith(channel: value) as $Val);
    });
  }

  /// Create a copy of ChannelEntryResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChannelPermissionsCopyWith<$Res> get permissions {
    return $ChannelPermissionsCopyWith<$Res>(_value.permissions, (value) {
      return _then(_value.copyWith(permissions: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ChannelEntryResultImplCopyWith<$Res>
    implements $ChannelEntryResultCopyWith<$Res> {
  factory _$$ChannelEntryResultImplCopyWith(
    _$ChannelEntryResultImpl value,
    $Res Function(_$ChannelEntryResultImpl) then,
  ) = __$$ChannelEntryResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Channel channel,
    ChannelPermissions permissions,
    List<Post> posts,
    int? readPosition,
  });

  @override
  $ChannelCopyWith<$Res> get channel;
  @override
  $ChannelPermissionsCopyWith<$Res> get permissions;
}

/// @nodoc
class __$$ChannelEntryResultImplCopyWithImpl<$Res>
    extends _$ChannelEntryResultCopyWithImpl<$Res, _$ChannelEntryResultImpl>
    implements _$$ChannelEntryResultImplCopyWith<$Res> {
  __$$ChannelEntryResultImplCopyWithImpl(
    _$ChannelEntryResultImpl _value,
    $Res Function(_$ChannelEntryResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChannelEntryResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channel = null,
    Object? permissions = null,
    Object? posts = null,
    Object? readPosition = freezed,
  }) {
    return _then(
      _$ChannelEntryResultImpl(
        channel: null == channel
            ? _value.channel
            : channel // ignore: cast_nullable_to_non_nullable
                  as Channel,
        permissions: null == permissions
            ? _value.permissions
            : permissions // ignore: cast_nullable_to_non_nullable
                  as ChannelPermissions,
        posts: null == posts
            ? _value._posts
            : posts // ignore: cast_nullable_to_non_nullable
                  as List<Post>,
        readPosition: freezed == readPosition
            ? _value.readPosition
            : readPosition // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$ChannelEntryResultImpl implements _ChannelEntryResult {
  const _$ChannelEntryResultImpl({
    required this.channel,
    required this.permissions,
    required final List<Post> posts,
    this.readPosition,
  }) : _posts = posts;

  /// 채널 정보
  @override
  final Channel channel;

  /// 현재 사용자의 채널 권한
  @override
  final ChannelPermissions permissions;

  /// 채널의 게시글 목록
  final List<Post> _posts;

  /// 채널의 게시글 목록
  @override
  List<Post> get posts {
    if (_posts is EqualUnmodifiableListView) return _posts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_posts);
  }

  /// 마지막으로 읽은 게시글 ID (없으면 null)
  @override
  final int? readPosition;

  @override
  String toString() {
    return 'ChannelEntryResult(channel: $channel, permissions: $permissions, posts: $posts, readPosition: $readPosition)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelEntryResultImpl &&
            (identical(other.channel, channel) || other.channel == channel) &&
            (identical(other.permissions, permissions) ||
                other.permissions == permissions) &&
            const DeepCollectionEquality().equals(other._posts, _posts) &&
            (identical(other.readPosition, readPosition) ||
                other.readPosition == readPosition));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    channel,
    permissions,
    const DeepCollectionEquality().hash(_posts),
    readPosition,
  );

  /// Create a copy of ChannelEntryResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelEntryResultImplCopyWith<_$ChannelEntryResultImpl> get copyWith =>
      __$$ChannelEntryResultImplCopyWithImpl<_$ChannelEntryResultImpl>(
        this,
        _$identity,
      );
}

abstract class _ChannelEntryResult implements ChannelEntryResult {
  const factory _ChannelEntryResult({
    required final Channel channel,
    required final ChannelPermissions permissions,
    required final List<Post> posts,
    final int? readPosition,
  }) = _$ChannelEntryResultImpl;

  /// 채널 정보
  @override
  Channel get channel;

  /// 현재 사용자의 채널 권한
  @override
  ChannelPermissions get permissions;

  /// 채널의 게시글 목록
  @override
  List<Post> get posts;

  /// 마지막으로 읽은 게시글 ID (없으면 null)
  @override
  int? get readPosition;

  /// Create a copy of ChannelEntryResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChannelEntryResultImplCopyWith<_$ChannelEntryResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
