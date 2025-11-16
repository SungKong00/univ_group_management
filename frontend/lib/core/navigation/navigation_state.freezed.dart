// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'navigation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

NavigationState _$NavigationStateFromJson(Map<String, dynamic> json) {
  return _NavigationState.fromJson(json);
}

/// @nodoc
mixin _$NavigationState {
  @JsonKey(toJson: _stackToJson, fromJson: _stackFromJson)
  List<WorkspaceRoute> get stack => throw _privateConstructorUsedError;
  int get currentIndex => throw _privateConstructorUsedError;

  /// T105: Loading indicator for slow navigation operations (>2s)
  bool get isLoading => throw _privateConstructorUsedError;

  /// T105: Optional message to display during loading
  String? get loadingMessage => throw _privateConstructorUsedError;

  /// T107: Last error message for API failures
  String? get lastError => throw _privateConstructorUsedError;

  /// T108: Offline detection flag
  bool get isOffline => throw _privateConstructorUsedError;

  /// T111: Scroll positions for each route (key: route hash, value: scroll offset)
  /// Stores up to 5 most recent positions
  Map<int, double> get scrollPositions => throw _privateConstructorUsedError;

  /// T112: Form data for each route (key: route hash, value: form data)
  /// Stores up to 5 most recent form states
  Map<int, Map<String, dynamic>> get formData =>
      throw _privateConstructorUsedError;

  /// Serializes this NavigationState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NavigationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NavigationStateCopyWith<NavigationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NavigationStateCopyWith<$Res> {
  factory $NavigationStateCopyWith(
    NavigationState value,
    $Res Function(NavigationState) then,
  ) = _$NavigationStateCopyWithImpl<$Res, NavigationState>;
  @useResult
  $Res call({
    @JsonKey(toJson: _stackToJson, fromJson: _stackFromJson)
    List<WorkspaceRoute> stack,
    int currentIndex,
    bool isLoading,
    String? loadingMessage,
    String? lastError,
    bool isOffline,
    Map<int, double> scrollPositions,
    Map<int, Map<String, dynamic>> formData,
  });
}

/// @nodoc
class _$NavigationStateCopyWithImpl<$Res, $Val extends NavigationState>
    implements $NavigationStateCopyWith<$Res> {
  _$NavigationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NavigationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stack = null,
    Object? currentIndex = null,
    Object? isLoading = null,
    Object? loadingMessage = freezed,
    Object? lastError = freezed,
    Object? isOffline = null,
    Object? scrollPositions = null,
    Object? formData = null,
  }) {
    return _then(
      _value.copyWith(
            stack: null == stack
                ? _value.stack
                : stack // ignore: cast_nullable_to_non_nullable
                      as List<WorkspaceRoute>,
            currentIndex: null == currentIndex
                ? _value.currentIndex
                : currentIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            loadingMessage: freezed == loadingMessage
                ? _value.loadingMessage
                : loadingMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastError: freezed == lastError
                ? _value.lastError
                : lastError // ignore: cast_nullable_to_non_nullable
                      as String?,
            isOffline: null == isOffline
                ? _value.isOffline
                : isOffline // ignore: cast_nullable_to_non_nullable
                      as bool,
            scrollPositions: null == scrollPositions
                ? _value.scrollPositions
                : scrollPositions // ignore: cast_nullable_to_non_nullable
                      as Map<int, double>,
            formData: null == formData
                ? _value.formData
                : formData // ignore: cast_nullable_to_non_nullable
                      as Map<int, Map<String, dynamic>>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NavigationStateImplCopyWith<$Res>
    implements $NavigationStateCopyWith<$Res> {
  factory _$$NavigationStateImplCopyWith(
    _$NavigationStateImpl value,
    $Res Function(_$NavigationStateImpl) then,
  ) = __$$NavigationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(toJson: _stackToJson, fromJson: _stackFromJson)
    List<WorkspaceRoute> stack,
    int currentIndex,
    bool isLoading,
    String? loadingMessage,
    String? lastError,
    bool isOffline,
    Map<int, double> scrollPositions,
    Map<int, Map<String, dynamic>> formData,
  });
}

/// @nodoc
class __$$NavigationStateImplCopyWithImpl<$Res>
    extends _$NavigationStateCopyWithImpl<$Res, _$NavigationStateImpl>
    implements _$$NavigationStateImplCopyWith<$Res> {
  __$$NavigationStateImplCopyWithImpl(
    _$NavigationStateImpl _value,
    $Res Function(_$NavigationStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NavigationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stack = null,
    Object? currentIndex = null,
    Object? isLoading = null,
    Object? loadingMessage = freezed,
    Object? lastError = freezed,
    Object? isOffline = null,
    Object? scrollPositions = null,
    Object? formData = null,
  }) {
    return _then(
      _$NavigationStateImpl(
        stack: null == stack
            ? _value._stack
            : stack // ignore: cast_nullable_to_non_nullable
                  as List<WorkspaceRoute>,
        currentIndex: null == currentIndex
            ? _value.currentIndex
            : currentIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadingMessage: freezed == loadingMessage
            ? _value.loadingMessage
            : loadingMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastError: freezed == lastError
            ? _value.lastError
            : lastError // ignore: cast_nullable_to_non_nullable
                  as String?,
        isOffline: null == isOffline
            ? _value.isOffline
            : isOffline // ignore: cast_nullable_to_non_nullable
                  as bool,
        scrollPositions: null == scrollPositions
            ? _value._scrollPositions
            : scrollPositions // ignore: cast_nullable_to_non_nullable
                  as Map<int, double>,
        formData: null == formData
            ? _value._formData
            : formData // ignore: cast_nullable_to_non_nullable
                  as Map<int, Map<String, dynamic>>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NavigationStateImpl extends _NavigationState {
  const _$NavigationStateImpl({
    @JsonKey(toJson: _stackToJson, fromJson: _stackFromJson)
    final List<WorkspaceRoute> stack = const [],
    this.currentIndex = -1,
    this.isLoading = false,
    this.loadingMessage,
    this.lastError,
    this.isOffline = false,
    final Map<int, double> scrollPositions = const {},
    final Map<int, Map<String, dynamic>> formData = const {},
  }) : _stack = stack,
       _scrollPositions = scrollPositions,
       _formData = formData,
       super._();

  factory _$NavigationStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$NavigationStateImplFromJson(json);

  final List<WorkspaceRoute> _stack;
  @override
  @JsonKey(toJson: _stackToJson, fromJson: _stackFromJson)
  List<WorkspaceRoute> get stack {
    if (_stack is EqualUnmodifiableListView) return _stack;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stack);
  }

  @override
  @JsonKey()
  final int currentIndex;

  /// T105: Loading indicator for slow navigation operations (>2s)
  @override
  @JsonKey()
  final bool isLoading;

  /// T105: Optional message to display during loading
  @override
  final String? loadingMessage;

  /// T107: Last error message for API failures
  @override
  final String? lastError;

  /// T108: Offline detection flag
  @override
  @JsonKey()
  final bool isOffline;

  /// T111: Scroll positions for each route (key: route hash, value: scroll offset)
  /// Stores up to 5 most recent positions
  final Map<int, double> _scrollPositions;

  /// T111: Scroll positions for each route (key: route hash, value: scroll offset)
  /// Stores up to 5 most recent positions
  @override
  @JsonKey()
  Map<int, double> get scrollPositions {
    if (_scrollPositions is EqualUnmodifiableMapView) return _scrollPositions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_scrollPositions);
  }

  /// T112: Form data for each route (key: route hash, value: form data)
  /// Stores up to 5 most recent form states
  final Map<int, Map<String, dynamic>> _formData;

  /// T112: Form data for each route (key: route hash, value: form data)
  /// Stores up to 5 most recent form states
  @override
  @JsonKey()
  Map<int, Map<String, dynamic>> get formData {
    if (_formData is EqualUnmodifiableMapView) return _formData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_formData);
  }

  @override
  String toString() {
    return 'NavigationState(stack: $stack, currentIndex: $currentIndex, isLoading: $isLoading, loadingMessage: $loadingMessage, lastError: $lastError, isOffline: $isOffline, scrollPositions: $scrollPositions, formData: $formData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NavigationStateImpl &&
            const DeepCollectionEquality().equals(other._stack, _stack) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.loadingMessage, loadingMessage) ||
                other.loadingMessage == loadingMessage) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError) &&
            (identical(other.isOffline, isOffline) ||
                other.isOffline == isOffline) &&
            const DeepCollectionEquality().equals(
              other._scrollPositions,
              _scrollPositions,
            ) &&
            const DeepCollectionEquality().equals(other._formData, _formData));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_stack),
    currentIndex,
    isLoading,
    loadingMessage,
    lastError,
    isOffline,
    const DeepCollectionEquality().hash(_scrollPositions),
    const DeepCollectionEquality().hash(_formData),
  );

  /// Create a copy of NavigationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NavigationStateImplCopyWith<_$NavigationStateImpl> get copyWith =>
      __$$NavigationStateImplCopyWithImpl<_$NavigationStateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NavigationStateImplToJson(this);
  }
}

abstract class _NavigationState extends NavigationState {
  const factory _NavigationState({
    @JsonKey(toJson: _stackToJson, fromJson: _stackFromJson)
    final List<WorkspaceRoute> stack,
    final int currentIndex,
    final bool isLoading,
    final String? loadingMessage,
    final String? lastError,
    final bool isOffline,
    final Map<int, double> scrollPositions,
    final Map<int, Map<String, dynamic>> formData,
  }) = _$NavigationStateImpl;
  const _NavigationState._() : super._();

  factory _NavigationState.fromJson(Map<String, dynamic> json) =
      _$NavigationStateImpl.fromJson;

  @override
  @JsonKey(toJson: _stackToJson, fromJson: _stackFromJson)
  List<WorkspaceRoute> get stack;
  @override
  int get currentIndex;

  /// T105: Loading indicator for slow navigation operations (>2s)
  @override
  bool get isLoading;

  /// T105: Optional message to display during loading
  @override
  String? get loadingMessage;

  /// T107: Last error message for API failures
  @override
  String? get lastError;

  /// T108: Offline detection flag
  @override
  bool get isOffline;

  /// T111: Scroll positions for each route (key: route hash, value: scroll offset)
  /// Stores up to 5 most recent positions
  @override
  Map<int, double> get scrollPositions;

  /// T112: Form data for each route (key: route hash, value: form data)
  /// Stores up to 5 most recent form states
  @override
  Map<int, Map<String, dynamic>> get formData;

  /// Create a copy of NavigationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NavigationStateImplCopyWith<_$NavigationStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
