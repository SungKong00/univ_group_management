# Provider 의존성 맵 (Provider Dependency Map)

## 목적
각 화면(Page)이 어떤 Provider를 필요로 하는지 중앙에서 관리하여 AI agent가 화면을 수정할 때 필요한 모든 Provider를 즉시 파악할 수 있게 함.

## 현재 문제
- 화면을 수정할 때 "이 화면은 뭘 필요로 하지?" 확인하려면 코드를 읽어야 함
- 새로운 Provider를 추가해도 문서가 동기화되지 않음
- 화면 간 Provider 공유 관계가 불명확
- 불필요한 Provider를 watch하는 경우를 찾기 어려움

## 원칙
### 1. 중앙 집중식 ScreenProviderMap
```dart
// 📌 lib/core/documentation/screen_provider_map.dart
// 모든 화면과 그들의 Provider 의존성을 한 곳에서 정의

class ScreenProviderMap {
  /// 모든 화면과 그들이 사용하는 Provider를 중앙에서 관리
  static const Map<String, ScreenDependencies> screens = {
    // =========== Post 화면 ===========
    'PostListPage': ScreenDependencies(
      name: 'Post List Screen',
      description: '채널 내 게시글 목록 표시 및 관리',

      // 📊 데이터 Provider (화면 렌더링용)
      dataProviders: [
        'postListProvider(channelId)',
        'currentGroupProvider',
        'currentChannelProvider',
      ],

      // 🔐 권한 Provider (버튼 활성화 여부)
      permissionProviders: [
        'groupPermissionProvider(groupId)',
      ],

      // ⚙️ 설정 Provider (UI 옵션)
      configProviders: [
        'localFilterProvider',
        'scrollPositionProvider(channelId)',
      ],

      // 🔌 액션 Provider (비동기 작업)
      actionProviders: [
        'createPostUseCaseProvider',
        'deletePostUseCaseProvider',
      ],

      dataFlow: '''
        Post API → PostDto → PostListState → PostListPage
      ''',

      relatedScreens: ['PostDetailPage', 'CommentPage'],
    ),

    'PostDetailPage': ScreenDependencies(
      name: 'Post Detail Screen',
      description: '게시글 상세 보기 및 댓글 조회',

      dataProviders: [
        'postDetailProvider(postId)',
        'commentListProvider(postId)',
      ],

      permissionProviders: [
        'groupPermissionProvider(groupId)',
        'postPermissionProvider(postId)',
      ],

      configProviders: [
        'scrollPositionProvider(postId)',
      ],

      actionProviders: [
        'updatePostUseCaseProvider',
        'deletePostUseCaseProvider',
        'createCommentUseCaseProvider',
      ],

      relatedScreens: ['PostListPage', 'CommentEditPage'],
    ),

    // =========== Comment 화면 ===========
    'CommentPage': ScreenDependencies(
      name: 'Comment Screen',
      description: '게시글 내 댓글 조회 및 관리',

      dataProviders: [
        'commentListProvider(postId)',
      ],

      permissionProviders: [
        'commentPermissionProvider(commentId)',
      ],

      configProviders: [],

      actionProviders: [
        'createCommentUseCaseProvider',
        'deleteCommentUseCaseProvider',
      ],

      relatedScreens: ['PostDetailPage'],
    ),

    // ... 더 많은 화면
  };
}

/// 화면의 Provider 의존성 정의
@immutable
class ScreenDependencies {
  final String name;
  final String description;
  final List<String> dataProviders;
  final List<String> permissionProviders;
  final List<String> configProviders;
  final List<String> actionProviders;
  final String dataFlow;
  final List<String> relatedScreens;

  const ScreenDependencies({
    required this.name,
    required this.description,
    required this.dataProviders,
    required this.permissionProviders,
    required this.configProviders,
    required this.actionProviders,
    required this.dataFlow,
    required this.relatedScreens,
  });

  /// 이 화면이 필요로 하는 모든 Provider
  List<String> get allProviders => [
    ...dataProviders,
    ...permissionProviders,
    ...configProviders,
    ...actionProviders,
  ];

  /// 데이터 Provider만 (로딩 표시할 때)
  List<String> get loadingProviders => dataProviders;

  /// 액션 Provider만 (API 호출할 때)
  List<String> get actionProvidersList => actionProviders;
}
```

### 2. 화면 파일 상단에 주석으로 Provider 명시
```dart
/// Post List Page Provider Dependencies
///
/// 이 페이지가 필요로 하는 모든 Provider:
///
/// 📊 데이터 Provider (화면 렌더링용)
/// - postListProvider(channelId) → AsyncValue<List<Post>>
/// - currentChannelProvider → String (어느 채널?)
/// - currentGroupProvider → String (어느 그룹?)
///
/// 🔐 권한 Provider (버튼 활성화 여부)
/// - groupPermissionProvider(groupId) → GroupPermission (삭제 버튼 표시?)
///
/// ⚙️ 설정 Provider (UI 옵션)
/// - localFilterProvider → FilterModel (정렬?)
/// - scrollPositionProvider(channelId) → int (스크롤 위치 복원)
///
/// 🔌 액션 Provider (비동기 작업)
/// - createPostUseCaseProvider → (params) → Future<Post>
/// - deletePostUseCaseProvider → (postId) → Future<void>
///
/// ❌ 사용하지 않음 (주의!)
/// - personalCalendarProvider (캘린더 없음)
/// - placesProvider (장소 없음)
///
/// 📖 ScreenProviderMap: lib/core/documentation/screen_provider_map.dart

class PostListPage extends ConsumerStatefulWidget {
  const PostListPage({required this.channelId});
  final String channelId;

  @override
  ConsumerState<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends ConsumerState<PostListPage> {
  @override
  Widget build(BuildContext context) {
    // ✅ 정의된 Provider만 사용 가능
    final postList = ref.watch(postListProvider(widget.channelId));
    final canDelete = ref.watch(groupPermissionProvider(groupId)).canDeletePost;
    final filterModel = ref.watch(localFilterProvider);

    return postList.when(
      data: (posts) => _buildList(posts),
      loading: () => const Skeleton(),
      error: (err, stack) => ErrorWidget(error: err),
    );
  }

  // ... 나머지 구현
}
```

### 3. Provider 카테고리별 명시
```dart
// 📌 Provider 4가지 카테고리

// 1️⃣ 데이터 Provider (AsyncValue - 로딩/데이터/에러)
// 화면을 렌더링하기 위한 데이터
final postListProvider = FutureProvider.autoDispose.family<
  List<Post>,
  String
>((ref, channelId) async {
  // 데이터 조회
  return await postService.getPosts(channelId);
});

// 2️⃣ 권한 Provider (동기 - 즉시 반환)
// 버튼/필드 활성화 여부 결정
final groupPermissionProvider = Provider.family<
  GroupPermission,
  String
>((ref, groupId) {
  // 권한 정보 반환
  return permissionService.getGroupPermission(groupId);
});

// 3️⃣ 설정 Provider (동기 - UI 옵션)
// 필터, 정렬, 레이아웃 옵션
final localFilterProvider = StateNotifierProvider<
  FilterNotifier,
  FilterModel
>((ref) {
  return FilterNotifier();
});

// 4️⃣ 액션 Provider (Future - 비동기 작업)
// 게시글 생성, 삭제, 수정 등
final createPostUseCaseProvider = FutureProvider.family<
  Post,
  CreatePostRequest
>((ref, request) async {
  return await postService.createPost(request);
});
```

## 구현 패턴

### Example: PostListPage 의존성 파악
```dart
// ❌ 현재 (어떤 Provider를 사용하는지 파악 어려움)
@override
Widget build(BuildContext context, WidgetRef ref) {
  final posts = ref.watch(postListProvider(channelId));
  final groups = ref.watch(myGroupsProvider);
  final members = ref.watch(groupMembersProvider(groupId));
  final isAdmin = ref.watch(isAdminProvider(groupId));
  final theme = ref.watch(themeProvider);
  final filter = ref.watch(localFilterProvider);

  // ... 이 Provider들이 왜 필요? 모두 사용되나?
}

// ✅ 개선 (의존성이 명확함)
///
/// 📊 데이터 Provider
/// - postListProvider(channelId)
///
/// 🔐 권한 Provider
/// - isAdminProvider(groupId)
///
/// ⚙️ 설정 Provider
/// - localFilterProvider
/// - themeProvider
///

@override
Widget build(BuildContext context, WidgetRef ref) {
  // 필요한 것만 명확하게
  final posts = ref.watch(postListProvider(channelId));
  final isAdmin = ref.watch(isAdminProvider(groupId));
  final filter = ref.watch(localFilterProvider);

  // 불필요한 것 제거: myGroupsProvider, groupMembersProvider, themeProvider
}
```

### Example: ScreenProviderMap 사용
```dart
// AI agent가 PostListPage를 수정하려면:
// 1. ScreenProviderMap에서 PostListPage 찾기
// 2. dataProviders, permissionProviders, configProviders, actionProviders 확인
// 3. 필요한 Provider만 ref.watch()

void modifyPostListPage(WidgetRef ref) {
  // 1단계: ScreenProviderMap 확인
  final deps = ScreenProviderMap.screens['PostListPage']!;

  // 2단계: 데이터 Provider 확인
  // - postListProvider(channelId)
  final posts = ref.watch(postListProvider(channelId));

  // 3단계: 권한 Provider 확인
  // - groupPermissionProvider(groupId)
  final canCreate = ref.watch(groupPermissionProvider(groupId)).canCreatePost;

  // 4단계: 새 기능 추가 시 ScreenProviderMap도 업데이트
  // deps.dataProviders.add('newProvider');
}
```

## 검증 방법

### 체크리스트
- [ ] 모든 화면이 ScreenProviderMap에 등록되어 있는가?
- [ ] ScreenProviderMap과 실제 코드의 Provider가 일치하는가?
- [ ] 각 화면 파일 상단에 주석으로 Provider가 명시되어 있는가?
- [ ] Provider가 4가지 카테고리로 분류되는가?
- [ ] 불필요한 Provider를 watch하지 않는가?

### 구체적 검증
```bash
# 1. ScreenProviderMap 동기화 확인
grep -r "ref.watch" lib/features/*/presentation/pages/*.dart | \
  sed 's/.*ref.watch(//' | sed 's/[)].*//' | sort -u > /tmp/actual.txt

grep "Provider\|provider" lib/core/documentation/screen_provider_map.dart | \
  grep -oE "'[^']+'" | sort -u > /tmp/map.txt

comm -23 /tmp/actual.txt /tmp/map.txt
# → 차이가 많으면 ScreenProviderMap 업데이트 필요

# 2. 화면별 주석 확인
grep -r "Provider Dependencies" lib/features/*/presentation/pages/
# → 모든 주요 페이지에서 발견되어야 함

# 3. Provider 카테고리 분류 확인
grep -r "FutureProvider\|Provider\|StateNotifierProvider" \
  lib/features/*/presentation/providers/ | wc -l
# → 모두 4가지 카테고리 중 하나에 속해야 함
```

## 관련 문서
- [화면 구조 템플릿](screen-structure.md) - Feature 폴더 구조
- [상태 생명주기](state-lifecycle.md) - Provider 생명주기 관리
- [상태 머신](state-machine.md) - 화면 상태 정의
