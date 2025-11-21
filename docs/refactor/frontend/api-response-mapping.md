# API 응답 매핑 (API Response to State Mapping)

## 목적
API 응답 파싱 규칙을 통일하여 모든 Provider가 동일한 방식으로 AsyncValue를 반환하도록 함. UI에서 단 하나의 패턴으로 처리 가능하게.

## 현재 문제
- 게시글: AsyncValue.data
- 댓글: response.data
- 그룹: List<Group> 직접 반환
- 멤버: FutureProvider로 List 반환
- 각 Provider마다 다르게 처리해야 함
- UI에서 예측 불가능한 응답 형식

## 원칙
### 1. API 응답 파싱 통일 규칙
```dart
// 📌 모든 API 호출은 동일한 방식으로 처리

/// API 응답을 AsyncValue로 변환하는 표준 패턴
/// - ApiResponse<T> → AsyncValue<T>
/// - success=true → AsyncValue.data(T)
/// - success=false → AsyncValue.error(ApiException)
/// - 네트워크 에러 → AsyncValue.error(NetworkException)
abstract class ApiDataSource {
  /// API 호출 후 결과를 AsyncValue로 변환
  /// 모든 Provider가 이 메서드를 통해서만 API 호출
  Future<AsyncValue<T>> fetch<T>(
    Future<ApiResponse<T>> Function() apiCall,
  );
}

// 구현
class ApiDataSourceImpl implements ApiDataSource {
  final Dio _httpClient;

  @override
  Future<AsyncValue<T>> fetch<T>(
    Future<ApiResponse<T>> Function() apiCall,
  ) async {
    try {
      // 1단계: API 호출
      final response = await apiCall();

      // 2단계: ApiResponse → T 변환
      if (response.success && response.data != null) {
        return AsyncValue.data(response.data as T);
      } else {
        // 성공 응답이지만 데이터 없음
        throw ApiException(
          code: response.error?.code ?? 'UNKNOWN',
          message: response.error?.message ?? 'Unknown error',
        );
      }
    } on ApiException catch (e) {
      // 3단계: API 에러 처리
      return AsyncValue.error(e, StackTrace.current);
    } on NetworkException catch (e) {
      // 4단계: 네트워크 에러 처리
      return AsyncValue.error(e, StackTrace.current);
    } catch (e, st) {
      // 5단계: 예상치 못한 에러
      return AsyncValue.error(
        UnknownException('Unknown error: $e'),
        st,
      );
    }
  }
}
```

### 2. Provider는 ApiDataSource만 사용
```dart
// ✅ 모든 Provider가 동일한 방식으로 API 호출

final postListProvider = FutureProvider.autoDispose.family<
  List<Post>,
  String  // channelId
>((ref, channelId) async {
  ref.keepAlive();

  // API 호출 (통일된 방식)
  final dataSource = ref.watch(apiDataSourceProvider);
  final result = await dataSource.fetch(
    () => api.getPosts(channelId),  // ApiResponse<List<Post>> 반환
  );

  // result가 이미 AsyncValue이므로 그대로 반환
  return result.whenData((posts) => posts);
});

final groupMembersProvider = FutureProvider.autoDispose.family<
  List<Member>,
  String  // groupId
>((ref, groupId) async {
  final dataSource = ref.watch(apiDataSourceProvider);

  // 같은 방식
  return await dataSource.fetch(
    () => api.getGroupMembers(groupId),
  );
});

// ✅ 모든 Provider의 응답 형식
// FutureProvider -> AsyncValue.data(T) 또는 AsyncValue.error(Exception)
```

### 3. UI는 단 하나의 패턴으로 처리
```dart
// ✅ 모든 데이터를 동일하게 처리

@override
Widget build(BuildContext context, WidgetRef ref) {
  // 모든 Provider의 응답이 AsyncValue<T>
  final postsAsync = ref.watch(postListProvider(channelId));

  // 단 하나의 패턴으로 처리
  return postsAsync.when(
    data: (posts) => PostListView(posts: posts),
    loading: () => SkeletonLoader(),
    error: (error, stack) => ErrorView(
      error: error,
      onRetry: () => ref.refresh(postListProvider(channelId)),
    ),
  );
}
```

### 4. 에러 타입 통일
```dart
// 📌 모든 에러를 분류

abstract class ApiException implements Exception {
  final String code;
  final String message;

  ApiException({required this.code, required this.message});

  @override
  String toString() => 'ApiException: [$code] $message';
}

class NetworkException extends ApiException {
  NetworkException({required String message})
      : super(code: 'NETWORK_ERROR', message: message);
}

class ServerException extends ApiException {
  final int statusCode;

  ServerException({
    required this.statusCode,
    required String code,
    required String message,
  }) : super(code: code, message: message);
}

class ParseException extends ApiException {
  ParseException({required String message})
      : super(code: 'PARSE_ERROR', message: message);
}

class UnknownException extends ApiException {
  UnknownException(String message)
      : super(code: 'UNKNOWN_ERROR', message: message);
}

// UI에서 에러 타입별 처리
error: (error, stack) {
  if (error is NetworkException) {
    return ErrorView(message: '네트워크 연결을 확인하세요');
  } else if (error is ServerException) {
    if (error.code == 'PERMISSION_DENIED') {
      return ErrorView(message: '접근 권한이 없습니다');
    }
  }
  return ErrorView(message: '알 수 없는 오류가 발생했습니다');
}
```

## 구현 패턴

### Before (현재 - 다양한 응답 형식)
```dart
// ❌ Provider마다 다른 방식

final postListProvider = FutureProvider<List<PostDto>>((ref) async {
  final response = await api.getPosts();
  if (response.success) {
    return response.data!.map((json) => PostDto.fromJson(json)).toList();
  } else {
    throw Exception(response.error?.message);
  }
  // 직접 List 반환 (AsyncValue 아님)
});

final commentListProvider = FutureProvider<List<Comment>>((ref) async {
  try {
    final response = await api.getComments();
    return response.data;  // ApiResponse 파싱 다름
  } catch (e) {
    throw e;
  }
});

final groupMembersProvider = AsyncNotifierProvider.family<
  GroupMemberNotifier,
  List<Member>,
  String
>((ref, groupId) {
  return GroupMemberNotifier(ref, groupId)..init();
  // AsyncNotifier 사용 (다른 방식)
});

// UI에서 매번 다르게 처리
@override
Widget build(BuildContext context, WidgetRef ref) {
  final postsAsync = ref.watch(postListProvider);
  final commentsAsync = ref.watch(commentListProvider);
  final membersAsync = ref.watch(groupMembersProvider(groupId));

  // 각각 다르게 처리해야 함
  return Column(
    children: [
      postsAsync.when(
        data: (posts) => Text('Posts: ${posts.length}'),
        loading: () => CircularProgressIndicator(),
        error: (err, st) => Text('Error: $err'),
      ),
      commentsAsync.when(
        data: (comments) => Text('Comments: ${comments.length}'),
        loading: () => CircularProgressIndicator(),
        error: (err, st) => Text('Error: $err'),
      ),
      membersAsync.when(
        data: (members) => Text('Members: ${members.length}'),
        loading: () => CircularProgressIndicator(),
        error: (err, st) => Text('Error: $err'),
      ),
    ],
  );
}
```

### After (개선 - 통일된 응답 형식)
```dart
// ✅ 모든 Provider가 동일한 방식

// 1단계: API 레이어
class PostApi {
  Future<ApiResponse<List<Post>>> getPosts(String channelId) async {
    final response = await dio.get('/posts?channelId=$channelId');
    // 백엔드가 ApiResponse 형식으로 응답
    return ApiResponse.fromJson(response.data);
  }
}

// 2단계: Provider는 ApiDataSource 사용
final postListProvider = FutureProvider.autoDispose.family<
  List<Post>,
  String
>((ref, channelId) async {
  final dataSource = ref.watch(apiDataSourceProvider);

  // 모든 Provider가 동일한 패턴
  return await dataSource.fetch(
    () => api.getPosts(channelId),
  );
});

final commentListProvider = FutureProvider.autoDispose.family<
  List<Comment>,
  String
>((ref, postId) async {
  final dataSource = ref.watch(apiDataSourceProvider);

  // 같은 패턴
  return await dataSource.fetch(
    () => api.getComments(postId),
  );
});

final groupMembersProvider = FutureProvider.autoDispose.family<
  List<Member>,
  String
>((ref, groupId) async {
  final dataSource = ref.watch(apiDataSourceProvider);

  // 같은 패턴
  return await dataSource.fetch(
    () => api.getGroupMembers(groupId),
  );
});

// UI에서 단 하나의 패턴으로 처리
@override
Widget build(BuildContext context, WidgetRef ref) {
  final postsAsync = ref.watch(postListProvider(channelId));
  final commentsAsync = ref.watch(commentListProvider(postId));
  final membersAsync = ref.watch(groupMembersProvider(groupId));

  // 모두 동일한 처리
  return Column(
    children: [
      _buildAsyncWidget(postsAsync, (posts) => PostListView(posts: posts)),
      _buildAsyncWidget(commentsAsync, (comments) => CommentListView(comments: comments)),
      _buildAsyncWidget(membersAsync, (members) => MemberListView(members: members)),
    ],
  );
}

// 재사용 가능한 헬퍼
Widget _buildAsyncWidget<T>(
  AsyncValue<T> asyncValue,
  Widget Function(T) builder,
) {
  return asyncValue.when(
    data: (data) => builder(data),
    loading: () => SkeletonLoader(),
    error: (error, stack) => ErrorView(error: error),
  );
}
```

## 검증 방법

### 체크리스트
- [ ] 모든 API 호출이 ApiDataSource를 통하는가?
- [ ] 모든 Provider가 FutureProvider.autoDispose를 사용하는가?
- [ ] UI에서 when() 패턴을 사용하는가?
- [ ] 에러 타입이 통일되어 있는가?
- [ ] 직접 List/Object를 반환하는 Provider가 없는가?

### 구체적 검증
```bash
# 1. ApiDataSource 사용 확인
grep -r "apiDataSourceProvider\|dataSource.fetch" lib/features/*/presentation/providers/
# → 모든 API 호출이 여기서 발견되어야 함

# 2. 직접 API 호출 확인 (금지)
grep -r "api\.\|dio\." lib/features/*/presentation/providers/ | grep -v "apiDataSourceProvider"
# → 0개 (모두 ApiDataSource 통해야 함)

# 3. 응답 형식 통일 확인
grep -r "FutureProvider\|AsyncNotifierProvider" lib/features/*/presentation/providers/
# → FutureProvider만 사용 (AsyncNotifierProvider는 상태 변경이 필요할 때만)

# 4. 에러 처리 통일 확인
grep -r "error:" lib/features/*/presentation/ | wc -l
# → UI에서 error 처리가 일관되게 나타나야 함
```

## 관련 문서
- [상태 생명주기](state-lifecycle.md) - Provider 생명주기 관리
- [Provider 의존성 맵](provider-dependency.md) - 화면별 Provider 구성
- [헌법 - 표준 응답 형식](../../.specify/memory/constitution.md#ii-표준-응답-형식-비협상)
