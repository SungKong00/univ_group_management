// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CommentDto _$CommentDtoFromJson(Map<String, dynamic> json) {
  return _CommentDto.fromJson(json);
}

/// @nodoc
mixin _$CommentDto {
  /// 댓글 고유 ID
  int get id => throw _privateConstructorUsedError;

  /// 게시글 ID
  int get postId => throw _privateConstructorUsedError;

  /// 댓글 내용
  String get content => throw _privateConstructorUsedError;

  /// 작성자 정보 (중첩된 객체)
  Author get author => throw _privateConstructorUsedError;

  /// 작성 시각
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// 수정 시각 (선택적)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// 댓글 깊이 (0=최상위, 1=대댓글)
  int get depth => throw _privateConstructorUsedError;

  /// 부모 댓글 ID (선택적)
  int? get parentCommentId => throw _privateConstructorUsedError;

  /// Serializes this CommentDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommentDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommentDtoCopyWith<CommentDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentDtoCopyWith<$Res> {
  factory $CommentDtoCopyWith(
    CommentDto value,
    $Res Function(CommentDto) then,
  ) = _$CommentDtoCopyWithImpl<$Res, CommentDto>;
  @useResult
  $Res call({
    int id,
    int postId,
    String content,
    Author author,
    DateTime createdAt,
    DateTime? updatedAt,
    int depth,
    int? parentCommentId,
  });

  $AuthorCopyWith<$Res> get author;
}

/// @nodoc
class _$CommentDtoCopyWithImpl<$Res, $Val extends CommentDto>
    implements $CommentDtoCopyWith<$Res> {
  _$CommentDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommentDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? postId = null,
    Object? content = null,
    Object? author = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? depth = null,
    Object? parentCommentId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            postId: null == postId
                ? _value.postId
                : postId // ignore: cast_nullable_to_non_nullable
                      as int,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            author: null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as Author,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            depth: null == depth
                ? _value.depth
                : depth // ignore: cast_nullable_to_non_nullable
                      as int,
            parentCommentId: freezed == parentCommentId
                ? _value.parentCommentId
                : parentCommentId // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }

  /// Create a copy of CommentDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthorCopyWith<$Res> get author {
    return $AuthorCopyWith<$Res>(_value.author, (value) {
      return _then(_value.copyWith(author: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CommentDtoImplCopyWith<$Res>
    implements $CommentDtoCopyWith<$Res> {
  factory _$$CommentDtoImplCopyWith(
    _$CommentDtoImpl value,
    $Res Function(_$CommentDtoImpl) then,
  ) = __$$CommentDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int postId,
    String content,
    Author author,
    DateTime createdAt,
    DateTime? updatedAt,
    int depth,
    int? parentCommentId,
  });

  @override
  $AuthorCopyWith<$Res> get author;
}

/// @nodoc
class __$$CommentDtoImplCopyWithImpl<$Res>
    extends _$CommentDtoCopyWithImpl<$Res, _$CommentDtoImpl>
    implements _$$CommentDtoImplCopyWith<$Res> {
  __$$CommentDtoImplCopyWithImpl(
    _$CommentDtoImpl _value,
    $Res Function(_$CommentDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommentDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? postId = null,
    Object? content = null,
    Object? author = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? depth = null,
    Object? parentCommentId = freezed,
  }) {
    return _then(
      _$CommentDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        postId: null == postId
            ? _value.postId
            : postId // ignore: cast_nullable_to_non_nullable
                  as int,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as Author,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        depth: null == depth
            ? _value.depth
            : depth // ignore: cast_nullable_to_non_nullable
                  as int,
        parentCommentId: freezed == parentCommentId
            ? _value.parentCommentId
            : parentCommentId // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentDtoImpl extends _CommentDto {
  const _$CommentDtoImpl({
    required this.id,
    required this.postId,
    required this.content,
    required this.author,
    required this.createdAt,
    this.updatedAt,
    this.depth = 0,
    this.parentCommentId,
  }) : super._();

  factory _$CommentDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentDtoImplFromJson(json);

  /// 댓글 고유 ID
  @override
  final int id;

  /// 게시글 ID
  @override
  final int postId;

  /// 댓글 내용
  @override
  final String content;

  /// 작성자 정보 (중첩된 객체)
  @override
  final Author author;

  /// 작성 시각
  @override
  final DateTime createdAt;

  /// 수정 시각 (선택적)
  @override
  final DateTime? updatedAt;

  /// 댓글 깊이 (0=최상위, 1=대댓글)
  @override
  @JsonKey()
  final int depth;

  /// 부모 댓글 ID (선택적)
  @override
  final int? parentCommentId;

  @override
  String toString() {
    return 'CommentDto(id: $id, postId: $postId, content: $content, author: $author, createdAt: $createdAt, updatedAt: $updatedAt, depth: $depth, parentCommentId: $parentCommentId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.postId, postId) || other.postId == postId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.depth, depth) || other.depth == depth) &&
            (identical(other.parentCommentId, parentCommentId) ||
                other.parentCommentId == parentCommentId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    postId,
    content,
    author,
    createdAt,
    updatedAt,
    depth,
    parentCommentId,
  );

  /// Create a copy of CommentDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentDtoImplCopyWith<_$CommentDtoImpl> get copyWith =>
      __$$CommentDtoImplCopyWithImpl<_$CommentDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentDtoImplToJson(this);
  }
}

abstract class _CommentDto extends CommentDto {
  const factory _CommentDto({
    required final int id,
    required final int postId,
    required final String content,
    required final Author author,
    required final DateTime createdAt,
    final DateTime? updatedAt,
    final int depth,
    final int? parentCommentId,
  }) = _$CommentDtoImpl;
  const _CommentDto._() : super._();

  factory _CommentDto.fromJson(Map<String, dynamic> json) =
      _$CommentDtoImpl.fromJson;

  /// 댓글 고유 ID
  @override
  int get id;

  /// 게시글 ID
  @override
  int get postId;

  /// 댓글 내용
  @override
  String get content;

  /// 작성자 정보 (중첩된 객체)
  @override
  Author get author;

  /// 작성 시각
  @override
  DateTime get createdAt;

  /// 수정 시각 (선택적)
  @override
  DateTime? get updatedAt;

  /// 댓글 깊이 (0=최상위, 1=대댓글)
  @override
  int get depth;

  /// 부모 댓글 ID (선택적)
  @override
  int? get parentCommentId;

  /// Create a copy of CommentDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentDtoImplCopyWith<_$CommentDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
