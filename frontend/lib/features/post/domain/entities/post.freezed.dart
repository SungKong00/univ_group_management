// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Post _$PostFromJson(Map<String, dynamic> json) {
  return _Post.fromJson(json);
}

/// @nodoc
mixin _$Post {
  /// 게시글 고유 ID
  int get id => throw _privateConstructorUsedError;

  /// 게시글 내용 (제목 없음)
  String get content => throw _privateConstructorUsedError;

  /// 작성자 정보
  Author get author => throw _privateConstructorUsedError;

  /// 작성 시각
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// 수정 시각 (수정되지 않았으면 null)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// 댓글 수
  int get commentCount => throw _privateConstructorUsedError;

  /// 마지막 댓글 작성 시각 (댓글이 없으면 null)
  DateTime? get lastCommentedAt => throw _privateConstructorUsedError;

  /// Serializes this Post to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostCopyWith<Post> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostCopyWith<$Res> {
  factory $PostCopyWith(Post value, $Res Function(Post) then) =
      _$PostCopyWithImpl<$Res, Post>;
  @useResult
  $Res call({
    int id,
    String content,
    Author author,
    DateTime createdAt,
    DateTime? updatedAt,
    int commentCount,
    DateTime? lastCommentedAt,
  });

  $AuthorCopyWith<$Res> get author;
}

/// @nodoc
class _$PostCopyWithImpl<$Res, $Val extends Post>
    implements $PostCopyWith<$Res> {
  _$PostCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? author = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? commentCount = null,
    Object? lastCommentedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
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
            commentCount: null == commentCount
                ? _value.commentCount
                : commentCount // ignore: cast_nullable_to_non_nullable
                      as int,
            lastCommentedAt: freezed == lastCommentedAt
                ? _value.lastCommentedAt
                : lastCommentedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of Post
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
abstract class _$$PostImplCopyWith<$Res> implements $PostCopyWith<$Res> {
  factory _$$PostImplCopyWith(
    _$PostImpl value,
    $Res Function(_$PostImpl) then,
  ) = __$$PostImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String content,
    Author author,
    DateTime createdAt,
    DateTime? updatedAt,
    int commentCount,
    DateTime? lastCommentedAt,
  });

  @override
  $AuthorCopyWith<$Res> get author;
}

/// @nodoc
class __$$PostImplCopyWithImpl<$Res>
    extends _$PostCopyWithImpl<$Res, _$PostImpl>
    implements _$$PostImplCopyWith<$Res> {
  __$$PostImplCopyWithImpl(_$PostImpl _value, $Res Function(_$PostImpl) _then)
    : super(_value, _then);

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? author = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? commentCount = null,
    Object? lastCommentedAt = freezed,
  }) {
    return _then(
      _$PostImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
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
        commentCount: null == commentCount
            ? _value.commentCount
            : commentCount // ignore: cast_nullable_to_non_nullable
                  as int,
        lastCommentedAt: freezed == lastCommentedAt
            ? _value.lastCommentedAt
            : lastCommentedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PostImpl implements _Post {
  const _$PostImpl({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    this.updatedAt,
    this.commentCount = 0,
    this.lastCommentedAt,
  });

  factory _$PostImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostImplFromJson(json);

  /// 게시글 고유 ID
  @override
  final int id;

  /// 게시글 내용 (제목 없음)
  @override
  final String content;

  /// 작성자 정보
  @override
  final Author author;

  /// 작성 시각
  @override
  final DateTime createdAt;

  /// 수정 시각 (수정되지 않았으면 null)
  @override
  final DateTime? updatedAt;

  /// 댓글 수
  @override
  @JsonKey()
  final int commentCount;

  /// 마지막 댓글 작성 시각 (댓글이 없으면 null)
  @override
  final DateTime? lastCommentedAt;

  @override
  String toString() {
    return 'Post(id: $id, content: $content, author: $author, createdAt: $createdAt, updatedAt: $updatedAt, commentCount: $commentCount, lastCommentedAt: $lastCommentedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.lastCommentedAt, lastCommentedAt) ||
                other.lastCommentedAt == lastCommentedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    content,
    author,
    createdAt,
    updatedAt,
    commentCount,
    lastCommentedAt,
  );

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostImplCopyWith<_$PostImpl> get copyWith =>
      __$$PostImplCopyWithImpl<_$PostImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostImplToJson(this);
  }
}

abstract class _Post implements Post {
  const factory _Post({
    required final int id,
    required final String content,
    required final Author author,
    required final DateTime createdAt,
    final DateTime? updatedAt,
    final int commentCount,
    final DateTime? lastCommentedAt,
  }) = _$PostImpl;

  factory _Post.fromJson(Map<String, dynamic> json) = _$PostImpl.fromJson;

  /// 게시글 고유 ID
  @override
  int get id;

  /// 게시글 내용 (제목 없음)
  @override
  String get content;

  /// 작성자 정보
  @override
  Author get author;

  /// 작성 시각
  @override
  DateTime get createdAt;

  /// 수정 시각 (수정되지 않았으면 null)
  @override
  DateTime? get updatedAt;

  /// 댓글 수
  @override
  int get commentCount;

  /// 마지막 댓글 작성 시각 (댓글이 없으면 null)
  @override
  DateTime? get lastCommentedAt;

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostImplCopyWith<_$PostImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
