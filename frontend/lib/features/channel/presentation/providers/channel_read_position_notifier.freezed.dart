// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_read_position_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChannelReadPositionState {
  /// 채널별 마지막 읽은 게시글 ID {channelId: lastReadPostId}
  Map<int, int> get lastReadPostIdMap => throw _privateConstructorUsedError;

  /// 채널별 읽지 않은 글 개수 {channelId: unreadCount}
  Map<int, int> get unreadCountMap => throw _privateConstructorUsedError;

  /// 현재 보고 있는 게시글 ID (가시성 추적)
  int? get currentVisiblePostId => throw _privateConstructorUsedError;

  /// 현재 활성 채널 ID
  int? get activeChannelId => throw _privateConstructorUsedError;

  /// Create a copy of ChannelReadPositionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChannelReadPositionStateCopyWith<ChannelReadPositionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChannelReadPositionStateCopyWith<$Res> {
  factory $ChannelReadPositionStateCopyWith(
    ChannelReadPositionState value,
    $Res Function(ChannelReadPositionState) then,
  ) = _$ChannelReadPositionStateCopyWithImpl<$Res, ChannelReadPositionState>;
  @useResult
  $Res call({
    Map<int, int> lastReadPostIdMap,
    Map<int, int> unreadCountMap,
    int? currentVisiblePostId,
    int? activeChannelId,
  });
}

/// @nodoc
class _$ChannelReadPositionStateCopyWithImpl<
  $Res,
  $Val extends ChannelReadPositionState
>
    implements $ChannelReadPositionStateCopyWith<$Res> {
  _$ChannelReadPositionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChannelReadPositionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lastReadPostIdMap = null,
    Object? unreadCountMap = null,
    Object? currentVisiblePostId = freezed,
    Object? activeChannelId = freezed,
  }) {
    return _then(
      _value.copyWith(
            lastReadPostIdMap: null == lastReadPostIdMap
                ? _value.lastReadPostIdMap
                : lastReadPostIdMap // ignore: cast_nullable_to_non_nullable
                      as Map<int, int>,
            unreadCountMap: null == unreadCountMap
                ? _value.unreadCountMap
                : unreadCountMap // ignore: cast_nullable_to_non_nullable
                      as Map<int, int>,
            currentVisiblePostId: freezed == currentVisiblePostId
                ? _value.currentVisiblePostId
                : currentVisiblePostId // ignore: cast_nullable_to_non_nullable
                      as int?,
            activeChannelId: freezed == activeChannelId
                ? _value.activeChannelId
                : activeChannelId // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChannelReadPositionStateImplCopyWith<$Res>
    implements $ChannelReadPositionStateCopyWith<$Res> {
  factory _$$ChannelReadPositionStateImplCopyWith(
    _$ChannelReadPositionStateImpl value,
    $Res Function(_$ChannelReadPositionStateImpl) then,
  ) = __$$ChannelReadPositionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Map<int, int> lastReadPostIdMap,
    Map<int, int> unreadCountMap,
    int? currentVisiblePostId,
    int? activeChannelId,
  });
}

/// @nodoc
class __$$ChannelReadPositionStateImplCopyWithImpl<$Res>
    extends
        _$ChannelReadPositionStateCopyWithImpl<
          $Res,
          _$ChannelReadPositionStateImpl
        >
    implements _$$ChannelReadPositionStateImplCopyWith<$Res> {
  __$$ChannelReadPositionStateImplCopyWithImpl(
    _$ChannelReadPositionStateImpl _value,
    $Res Function(_$ChannelReadPositionStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChannelReadPositionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lastReadPostIdMap = null,
    Object? unreadCountMap = null,
    Object? currentVisiblePostId = freezed,
    Object? activeChannelId = freezed,
  }) {
    return _then(
      _$ChannelReadPositionStateImpl(
        lastReadPostIdMap: null == lastReadPostIdMap
            ? _value._lastReadPostIdMap
            : lastReadPostIdMap // ignore: cast_nullable_to_non_nullable
                  as Map<int, int>,
        unreadCountMap: null == unreadCountMap
            ? _value._unreadCountMap
            : unreadCountMap // ignore: cast_nullable_to_non_nullable
                  as Map<int, int>,
        currentVisiblePostId: freezed == currentVisiblePostId
            ? _value.currentVisiblePostId
            : currentVisiblePostId // ignore: cast_nullable_to_non_nullable
                  as int?,
        activeChannelId: freezed == activeChannelId
            ? _value.activeChannelId
            : activeChannelId // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$ChannelReadPositionStateImpl implements _ChannelReadPositionState {
  const _$ChannelReadPositionStateImpl({
    final Map<int, int> lastReadPostIdMap = const {},
    final Map<int, int> unreadCountMap = const {},
    this.currentVisiblePostId,
    this.activeChannelId,
  }) : _lastReadPostIdMap = lastReadPostIdMap,
       _unreadCountMap = unreadCountMap;

  /// 채널별 마지막 읽은 게시글 ID {channelId: lastReadPostId}
  final Map<int, int> _lastReadPostIdMap;

  /// 채널별 마지막 읽은 게시글 ID {channelId: lastReadPostId}
  @override
  @JsonKey()
  Map<int, int> get lastReadPostIdMap {
    if (_lastReadPostIdMap is EqualUnmodifiableMapView)
      return _lastReadPostIdMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_lastReadPostIdMap);
  }

  /// 채널별 읽지 않은 글 개수 {channelId: unreadCount}
  final Map<int, int> _unreadCountMap;

  /// 채널별 읽지 않은 글 개수 {channelId: unreadCount}
  @override
  @JsonKey()
  Map<int, int> get unreadCountMap {
    if (_unreadCountMap is EqualUnmodifiableMapView) return _unreadCountMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_unreadCountMap);
  }

  /// 현재 보고 있는 게시글 ID (가시성 추적)
  @override
  final int? currentVisiblePostId;

  /// 현재 활성 채널 ID
  @override
  final int? activeChannelId;

  @override
  String toString() {
    return 'ChannelReadPositionState(lastReadPostIdMap: $lastReadPostIdMap, unreadCountMap: $unreadCountMap, currentVisiblePostId: $currentVisiblePostId, activeChannelId: $activeChannelId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelReadPositionStateImpl &&
            const DeepCollectionEquality().equals(
              other._lastReadPostIdMap,
              _lastReadPostIdMap,
            ) &&
            const DeepCollectionEquality().equals(
              other._unreadCountMap,
              _unreadCountMap,
            ) &&
            (identical(other.currentVisiblePostId, currentVisiblePostId) ||
                other.currentVisiblePostId == currentVisiblePostId) &&
            (identical(other.activeChannelId, activeChannelId) ||
                other.activeChannelId == activeChannelId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_lastReadPostIdMap),
    const DeepCollectionEquality().hash(_unreadCountMap),
    currentVisiblePostId,
    activeChannelId,
  );

  /// Create a copy of ChannelReadPositionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelReadPositionStateImplCopyWith<_$ChannelReadPositionStateImpl>
  get copyWith =>
      __$$ChannelReadPositionStateImplCopyWithImpl<
        _$ChannelReadPositionStateImpl
      >(this, _$identity);
}

abstract class _ChannelReadPositionState implements ChannelReadPositionState {
  const factory _ChannelReadPositionState({
    final Map<int, int> lastReadPostIdMap,
    final Map<int, int> unreadCountMap,
    final int? currentVisiblePostId,
    final int? activeChannelId,
  }) = _$ChannelReadPositionStateImpl;

  /// 채널별 마지막 읽은 게시글 ID {channelId: lastReadPostId}
  @override
  Map<int, int> get lastReadPostIdMap;

  /// 채널별 읽지 않은 글 개수 {channelId: unreadCount}
  @override
  Map<int, int> get unreadCountMap;

  /// 현재 보고 있는 게시글 ID (가시성 추적)
  @override
  int? get currentVisiblePostId;

  /// 현재 활성 채널 ID
  @override
  int? get activeChannelId;

  /// Create a copy of ChannelReadPositionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChannelReadPositionStateImplCopyWith<_$ChannelReadPositionStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
