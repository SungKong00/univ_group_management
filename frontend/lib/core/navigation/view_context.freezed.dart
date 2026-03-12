// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'view_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ViewContext _$ViewContextFromJson(Map<String, dynamic> json) {
  return _ViewContext.fromJson(json);
}

/// @nodoc
mixin _$ViewContext {
  ViewType get type => throw _privateConstructorUsedError;
  int? get channelId =>
      throw _privateConstructorUsedError; // Only for ViewType.channel
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this ViewContext to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ViewContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ViewContextCopyWith<ViewContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ViewContextCopyWith<$Res> {
  factory $ViewContextCopyWith(
    ViewContext value,
    $Res Function(ViewContext) then,
  ) = _$ViewContextCopyWithImpl<$Res, ViewContext>;
  @useResult
  $Res call({ViewType type, int? channelId, Map<String, dynamic>? metadata});
}

/// @nodoc
class _$ViewContextCopyWithImpl<$Res, $Val extends ViewContext>
    implements $ViewContextCopyWith<$Res> {
  _$ViewContextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ViewContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? channelId = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as ViewType,
            channelId: freezed == channelId
                ? _value.channelId
                : channelId // ignore: cast_nullable_to_non_nullable
                      as int?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ViewContextImplCopyWith<$Res>
    implements $ViewContextCopyWith<$Res> {
  factory _$$ViewContextImplCopyWith(
    _$ViewContextImpl value,
    $Res Function(_$ViewContextImpl) then,
  ) = __$$ViewContextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ViewType type, int? channelId, Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$ViewContextImplCopyWithImpl<$Res>
    extends _$ViewContextCopyWithImpl<$Res, _$ViewContextImpl>
    implements _$$ViewContextImplCopyWith<$Res> {
  __$$ViewContextImplCopyWithImpl(
    _$ViewContextImpl _value,
    $Res Function(_$ViewContextImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ViewContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? channelId = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _$ViewContextImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as ViewType,
        channelId: freezed == channelId
            ? _value.channelId
            : channelId // ignore: cast_nullable_to_non_nullable
                  as int?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ViewContextImpl extends _ViewContext {
  const _$ViewContextImpl({
    required this.type,
    this.channelId,
    final Map<String, dynamic>? metadata,
  }) : _metadata = metadata,
       super._();

  factory _$ViewContextImpl.fromJson(Map<String, dynamic> json) =>
      _$$ViewContextImplFromJson(json);

  @override
  final ViewType type;
  @override
  final int? channelId;
  // Only for ViewType.channel
  final Map<String, dynamic>? _metadata;
  // Only for ViewType.channel
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'ViewContext(type: $type, channelId: $channelId, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ViewContextImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.channelId, channelId) ||
                other.channelId == channelId) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    channelId,
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of ViewContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ViewContextImplCopyWith<_$ViewContextImpl> get copyWith =>
      __$$ViewContextImplCopyWithImpl<_$ViewContextImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ViewContextImplToJson(this);
  }
}

abstract class _ViewContext extends ViewContext {
  const factory _ViewContext({
    required final ViewType type,
    final int? channelId,
    final Map<String, dynamic>? metadata,
  }) = _$ViewContextImpl;
  const _ViewContext._() : super._();

  factory _ViewContext.fromJson(Map<String, dynamic> json) =
      _$ViewContextImpl.fromJson;

  @override
  ViewType get type;
  @override
  int? get channelId; // Only for ViewType.channel
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of ViewContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ViewContextImplCopyWith<_$ViewContextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
