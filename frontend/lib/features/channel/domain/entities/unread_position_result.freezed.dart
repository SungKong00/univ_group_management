// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unread_position_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UnreadPositionResult {
  /// 첫 번째 읽지 않은 게시글의 인덱스
  /// null이면 모든 게시글을 읽은 상태
  int? get unreadIndex => throw _privateConstructorUsedError;

  /// 읽지 않은 게시글 총 개수
  int get totalUnread => throw _privateConstructorUsedError;

  /// 읽지 않은 게시글이 있는지 여부
  bool get hasUnread => throw _privateConstructorUsedError;

  /// Create a copy of UnreadPositionResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnreadPositionResultCopyWith<UnreadPositionResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnreadPositionResultCopyWith<$Res> {
  factory $UnreadPositionResultCopyWith(
    UnreadPositionResult value,
    $Res Function(UnreadPositionResult) then,
  ) = _$UnreadPositionResultCopyWithImpl<$Res, UnreadPositionResult>;
  @useResult
  $Res call({int? unreadIndex, int totalUnread, bool hasUnread});
}

/// @nodoc
class _$UnreadPositionResultCopyWithImpl<
  $Res,
  $Val extends UnreadPositionResult
>
    implements $UnreadPositionResultCopyWith<$Res> {
  _$UnreadPositionResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnreadPositionResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unreadIndex = freezed,
    Object? totalUnread = null,
    Object? hasUnread = null,
  }) {
    return _then(
      _value.copyWith(
            unreadIndex: freezed == unreadIndex
                ? _value.unreadIndex
                : unreadIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
            totalUnread: null == totalUnread
                ? _value.totalUnread
                : totalUnread // ignore: cast_nullable_to_non_nullable
                      as int,
            hasUnread: null == hasUnread
                ? _value.hasUnread
                : hasUnread // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UnreadPositionResultImplCopyWith<$Res>
    implements $UnreadPositionResultCopyWith<$Res> {
  factory _$$UnreadPositionResultImplCopyWith(
    _$UnreadPositionResultImpl value,
    $Res Function(_$UnreadPositionResultImpl) then,
  ) = __$$UnreadPositionResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int? unreadIndex, int totalUnread, bool hasUnread});
}

/// @nodoc
class __$$UnreadPositionResultImplCopyWithImpl<$Res>
    extends _$UnreadPositionResultCopyWithImpl<$Res, _$UnreadPositionResultImpl>
    implements _$$UnreadPositionResultImplCopyWith<$Res> {
  __$$UnreadPositionResultImplCopyWithImpl(
    _$UnreadPositionResultImpl _value,
    $Res Function(_$UnreadPositionResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UnreadPositionResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unreadIndex = freezed,
    Object? totalUnread = null,
    Object? hasUnread = null,
  }) {
    return _then(
      _$UnreadPositionResultImpl(
        unreadIndex: freezed == unreadIndex
            ? _value.unreadIndex
            : unreadIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
        totalUnread: null == totalUnread
            ? _value.totalUnread
            : totalUnread // ignore: cast_nullable_to_non_nullable
                  as int,
        hasUnread: null == hasUnread
            ? _value.hasUnread
            : hasUnread // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$UnreadPositionResultImpl implements _UnreadPositionResult {
  const _$UnreadPositionResultImpl({
    required this.unreadIndex,
    this.totalUnread = 0,
    this.hasUnread = false,
  });

  /// 첫 번째 읽지 않은 게시글의 인덱스
  /// null이면 모든 게시글을 읽은 상태
  @override
  final int? unreadIndex;

  /// 읽지 않은 게시글 총 개수
  @override
  @JsonKey()
  final int totalUnread;

  /// 읽지 않은 게시글이 있는지 여부
  @override
  @JsonKey()
  final bool hasUnread;

  @override
  String toString() {
    return 'UnreadPositionResult(unreadIndex: $unreadIndex, totalUnread: $totalUnread, hasUnread: $hasUnread)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnreadPositionResultImpl &&
            (identical(other.unreadIndex, unreadIndex) ||
                other.unreadIndex == unreadIndex) &&
            (identical(other.totalUnread, totalUnread) ||
                other.totalUnread == totalUnread) &&
            (identical(other.hasUnread, hasUnread) ||
                other.hasUnread == hasUnread));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, unreadIndex, totalUnread, hasUnread);

  /// Create a copy of UnreadPositionResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnreadPositionResultImplCopyWith<_$UnreadPositionResultImpl>
  get copyWith =>
      __$$UnreadPositionResultImplCopyWithImpl<_$UnreadPositionResultImpl>(
        this,
        _$identity,
      );
}

abstract class _UnreadPositionResult implements UnreadPositionResult {
  const factory _UnreadPositionResult({
    required final int? unreadIndex,
    final int totalUnread,
    final bool hasUnread,
  }) = _$UnreadPositionResultImpl;

  /// 첫 번째 읽지 않은 게시글의 인덱스
  /// null이면 모든 게시글을 읽은 상태
  @override
  int? get unreadIndex;

  /// 읽지 않은 게시글 총 개수
  @override
  int get totalUnread;

  /// 읽지 않은 게시글이 있는지 여부
  @override
  bool get hasUnread;

  /// Create a copy of UnreadPositionResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnreadPositionResultImplCopyWith<_$UnreadPositionResultImpl>
  get copyWith => throw _privateConstructorUsedError;
}
