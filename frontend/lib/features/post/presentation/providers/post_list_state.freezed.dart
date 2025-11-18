// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PostListState {
  /// 게시글 목록 (원본 데이터)
  List<Post> get posts => throw _privateConstructorUsedError;

  /// 평탄화된 목록 (DateMarker + Post)
  ///
  /// UI 렌더링용 플랫 리스트
  /// [DateMarker, Post, Post, DateMarker, Post, ...]
  List<Object> get flatItems => throw _privateConstructorUsedError;

  /// 로딩 중 여부
  bool get isLoading => throw _privateConstructorUsedError;

  /// 다음 페이지 존재 여부
  bool get hasMore => throw _privateConstructorUsedError;

  /// 현재 페이지 번호 (다음 로드할 페이지)
  int get currentPage => throw _privateConstructorUsedError;

  /// 에러 메시지 (에러 발생 시)
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of PostListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostListStateCopyWith<PostListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostListStateCopyWith<$Res> {
  factory $PostListStateCopyWith(
    PostListState value,
    $Res Function(PostListState) then,
  ) = _$PostListStateCopyWithImpl<$Res, PostListState>;
  @useResult
  $Res call({
    List<Post> posts,
    List<Object> flatItems,
    bool isLoading,
    bool hasMore,
    int currentPage,
    String? errorMessage,
  });
}

/// @nodoc
class _$PostListStateCopyWithImpl<$Res, $Val extends PostListState>
    implements $PostListStateCopyWith<$Res> {
  _$PostListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? posts = null,
    Object? flatItems = null,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? currentPage = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            posts: null == posts
                ? _value.posts
                : posts // ignore: cast_nullable_to_non_nullable
                      as List<Post>,
            flatItems: null == flatItems
                ? _value.flatItems
                : flatItems // ignore: cast_nullable_to_non_nullable
                      as List<Object>,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasMore: null == hasMore
                ? _value.hasMore
                : hasMore // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentPage: null == currentPage
                ? _value.currentPage
                : currentPage // ignore: cast_nullable_to_non_nullable
                      as int,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PostListStateImplCopyWith<$Res>
    implements $PostListStateCopyWith<$Res> {
  factory _$$PostListStateImplCopyWith(
    _$PostListStateImpl value,
    $Res Function(_$PostListStateImpl) then,
  ) = __$$PostListStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Post> posts,
    List<Object> flatItems,
    bool isLoading,
    bool hasMore,
    int currentPage,
    String? errorMessage,
  });
}

/// @nodoc
class __$$PostListStateImplCopyWithImpl<$Res>
    extends _$PostListStateCopyWithImpl<$Res, _$PostListStateImpl>
    implements _$$PostListStateImplCopyWith<$Res> {
  __$$PostListStateImplCopyWithImpl(
    _$PostListStateImpl _value,
    $Res Function(_$PostListStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PostListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? posts = null,
    Object? flatItems = null,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? currentPage = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$PostListStateImpl(
        posts: null == posts
            ? _value._posts
            : posts // ignore: cast_nullable_to_non_nullable
                  as List<Post>,
        flatItems: null == flatItems
            ? _value._flatItems
            : flatItems // ignore: cast_nullable_to_non_nullable
                  as List<Object>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasMore: null == hasMore
            ? _value.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentPage: null == currentPage
            ? _value.currentPage
            : currentPage // ignore: cast_nullable_to_non_nullable
                  as int,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$PostListStateImpl implements _PostListState {
  const _$PostListStateImpl({
    final List<Post> posts = const [],
    final List<Object> flatItems = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.currentPage = 0,
    this.errorMessage,
  }) : _posts = posts,
       _flatItems = flatItems;

  /// 게시글 목록 (원본 데이터)
  final List<Post> _posts;

  /// 게시글 목록 (원본 데이터)
  @override
  @JsonKey()
  List<Post> get posts {
    if (_posts is EqualUnmodifiableListView) return _posts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_posts);
  }

  /// 평탄화된 목록 (DateMarker + Post)
  ///
  /// UI 렌더링용 플랫 리스트
  /// [DateMarker, Post, Post, DateMarker, Post, ...]
  final List<Object> _flatItems;

  /// 평탄화된 목록 (DateMarker + Post)
  ///
  /// UI 렌더링용 플랫 리스트
  /// [DateMarker, Post, Post, DateMarker, Post, ...]
  @override
  @JsonKey()
  List<Object> get flatItems {
    if (_flatItems is EqualUnmodifiableListView) return _flatItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_flatItems);
  }

  /// 로딩 중 여부
  @override
  @JsonKey()
  final bool isLoading;

  /// 다음 페이지 존재 여부
  @override
  @JsonKey()
  final bool hasMore;

  /// 현재 페이지 번호 (다음 로드할 페이지)
  @override
  @JsonKey()
  final int currentPage;

  /// 에러 메시지 (에러 발생 시)
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'PostListState(posts: $posts, flatItems: $flatItems, isLoading: $isLoading, hasMore: $hasMore, currentPage: $currentPage, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostListStateImpl &&
            const DeepCollectionEquality().equals(other._posts, _posts) &&
            const DeepCollectionEquality().equals(
              other._flatItems,
              _flatItems,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_posts),
    const DeepCollectionEquality().hash(_flatItems),
    isLoading,
    hasMore,
    currentPage,
    errorMessage,
  );

  /// Create a copy of PostListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostListStateImplCopyWith<_$PostListStateImpl> get copyWith =>
      __$$PostListStateImplCopyWithImpl<_$PostListStateImpl>(this, _$identity);
}

abstract class _PostListState implements PostListState {
  const factory _PostListState({
    final List<Post> posts,
    final List<Object> flatItems,
    final bool isLoading,
    final bool hasMore,
    final int currentPage,
    final String? errorMessage,
  }) = _$PostListStateImpl;

  /// 게시글 목록 (원본 데이터)
  @override
  List<Post> get posts;

  /// 평탄화된 목록 (DateMarker + Post)
  ///
  /// UI 렌더링용 플랫 리스트
  /// [DateMarker, Post, Post, DateMarker, Post, ...]
  @override
  List<Object> get flatItems;

  /// 로딩 중 여부
  @override
  bool get isLoading;

  /// 다음 페이지 존재 여부
  @override
  bool get hasMore;

  /// 현재 페이지 번호 (다음 로드할 페이지)
  @override
  int get currentPage;

  /// 에러 메시지 (에러 발생 시)
  @override
  String? get errorMessage;

  /// Create a copy of PostListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostListStateImplCopyWith<_$PostListStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
