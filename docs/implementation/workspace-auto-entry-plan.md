# 워크스페이스 자동 진입 시스템 구현 계획

> **생성일**: 2025-10-04
> **상태**: Phase 1 백엔드 API 구현 완료 / Phase 2 프론트엔드 개발 대기
> **우선순위**: 중간

## 문제 정의

### 현재 상황
1. **워크스페이스 버튼 클릭 시**: `/workspace` 경로로 이동하지만 `groupId` 파라미터가 없음
2. **WorkspacePage 로직**: `groupId`가 없으면 채널 네비게이션이 표시되지 않고 빈 상태만 보임
3. **사용자 경험 저하**: 워크스페이스에 진입했지만 아무것도 볼 수 없는 상태

### 요구사항
- 워크스페이스 버튼 클릭 시 **사용자가 속한 그룹 중 최상위 그룹**으로 자동 진입
- 다른 페이지(홈, 그룹 탐색 등)에서도 **특정 그룹의 워크스페이스로 유연하게 진입** 가능
- 워크스페이스 진입 시 네비게이션 상태 동기화 (글로벌 네비게이션 축소, 채널 네비게이션 표시)

## 해결 방안

### 1. 백엔드 API 구현 필요 ⚠️

#### 1.1. 사용자 소속 그룹 목록 조회
**엔드포인트**: `GET /api/me/groups`

**응답 구조**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "한신대학교",
      "type": "UNIVERSITY",
      "level": 0,
      "parentId": null,
      "role": "MEMBER",
      "permissions": ["CHANNEL_READ", "POST_READ"]
    },
    {
      "id": 2,
      "name": "AI/SW학부",
      "type": "DEPARTMENT",
      "level": 2,
      "parentId": 1,
      "role": "MEMBER",
      "permissions": ["CHANNEL_READ", "POST_READ", "POST_WRITE"]
    },
    {
      "id": 10,
      "name": "프로그래밍 동아리",
      "type": "CLUB",
      "level": 1,
      "parentId": 1,
      "role": "OWNER",
      "permissions": ["GROUP_MANAGE", "ADMIN_MANAGE", ...]
    }
  ],
  "error": null
}
```

**정렬 기준**:
- `level` 오름차순 (0이 최상위)
- 동일 레벨일 경우 `id` 오름차순

#### 1.2. 최상위 그룹 선택 로직
사용자가 속한 그룹 중 **가장 상위 레벨 그룹** 선택:
1. `level`이 가장 작은 그룹 필터링
2. 여러 개 있을 경우 `id`가 가장 작은 그룹 (가장 먼저 가입한 그룹)
3. 없을 경우: 빈 상태 유지 (그룹 가입 유도)

### 2. 프론트엔드 구현

#### 2.1. 그룹 서비스 (`lib/core/services/group_service.dart`)

```dart
class GroupService {
  final DioClient _client;

  GroupService(this._client);

  /// 사용자가 속한 모든 그룹 조회
  Future<List<GroupMembership>> getMyGroups() async {
    try {
      final response = await _client.get('/me/groups');
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (json) => (json as List)
            .map((item) => GroupMembership.fromJson(item))
            .toList(),
      );
      return apiResponse.data ?? [];
    } catch (e) {
      developer.log('Failed to fetch my groups: $e');
      return [];
    }
  }

  /// 최상위 그룹 선택
  GroupMembership? getTopLevelGroup(List<GroupMembership> groups) {
    if (groups.isEmpty) return null;

    // level이 가장 작은 그룹들 필터링
    final minLevel = groups.map((g) => g.level).reduce((a, b) => a < b ? a : b);
    final topLevelGroups = groups.where((g) => g.level == minLevel).toList();

    // id가 가장 작은 그룹 선택
    topLevelGroups.sort((a, b) => a.id.compareTo(b.id));
    return topLevelGroups.first;
  }
}
```

#### 2.2. 데이터 모델 (`lib/core/models/group_models.dart`)

```dart
class GroupMembership {
  final int id;
  final String name;
  final String type; // UNIVERSITY, COLLEGE, DEPARTMENT, CLUB, etc.
  final int level; // 0 = 최상위
  final int? parentId;
  final String role; // OWNER, ADVISOR, MEMBER
  final List<String> permissions;

  GroupMembership({
    required this.id,
    required this.name,
    required this.type,
    required this.level,
    this.parentId,
    required this.role,
    required this.permissions,
  });

  factory GroupMembership.fromJson(Map<String, dynamic> json) {
    return GroupMembership(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      level: json['level'] as int,
      parentId: json['parentId'] as int?,
      role: json['role'] as String,
      permissions: (json['permissions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}
```

#### 2.3. 사이드바 네비게이션 로직 수정

**파일**: `lib/presentation/widgets/navigation/sidebar_navigation.dart`

```dart
void _handleItemTap(BuildContext context, WidgetRef ref, NavigationConfig config) async {
  final navigationController = ref.read(navigationControllerProvider.notifier);

  if (config.route == AppConstants.workspaceRoute) {
    // 워크스페이스 클릭 시 최상위 그룹으로 자동 진입
    navigationController.enterWorkspace();

    // 로딩 상태 표시
    // TODO: 로딩 인디케이터 추가

    // 최상위 그룹 조회
    final groupService = GroupService(DioClient());
    final myGroups = await groupService.getMyGroups();
    final topGroup = groupService.getTopLevelGroup(myGroups);

    if (topGroup != null) {
      // 최상위 그룹 워크스페이스로 이동
      if (context.mounted) {
        context.go('/workspace/${topGroup.id}');
      }
    } else {
      // 소속 그룹이 없을 경우 기본 워크스페이스로
      if (context.mounted) {
        context.go(AppConstants.workspaceRoute);
      }
    }
  } else {
    navigationController.exitWorkspace();
    NavigationHelper.navigateWithSync(context, ref, config.route);
  }
}
```

#### 2.4. 유연한 워크스페이스 진입 (홈 페이지 등)

**사용 예시**: 홈 페이지에서 그룹 카드 클릭

```dart
// 홈 페이지 그룹 카드
GestureDetector(
  onTap: () {
    // 특정 그룹의 워크스페이스로 진입
    final navigationController = ref.read(navigationControllerProvider.notifier);
    navigationController.enterWorkspace();
    context.go('/workspace/${group.id}');
  },
  child: GroupCard(group: group),
)
```

#### 2.5. 워크스페이스 Provider 개선

**파일**: `lib/presentation/providers/workspace_state_provider.dart`

```dart
class WorkspaceStateNotifier extends StateNotifier<WorkspaceState> {
  // ... 기존 코드 ...

  /// 워크스페이스 진입 (그룹 ID 자동 감지)
  Future<void> enterWorkspaceAuto() async {
    final groupService = GroupService(DioClient());
    final myGroups = await groupService.getMyGroups();
    final topGroup = groupService.getTopLevelGroup(myGroups);

    if (topGroup != null) {
      await enterWorkspace(topGroup.id.toString());
    }
  }
}
```

### 3. 라우팅 개선

**현재 구조**:
```
/workspace (groupId 없음, 빈 상태)
/workspace/:groupId (특정 그룹 워크스페이스)
/workspace/:groupId/channel/:channelId (특정 채널)
```

**개선 후**:
- `/workspace` 접근 시 자동으로 `/workspace/:topGroupId`로 리다이렉트
- 또는 `/workspace` 자체에서 최상위 그룹을 로드하여 표시

#### 3.1. 라우터 리다이렉트 추가

**파일**: `lib/core/router/app_router.dart`

```dart
GoRoute(
  path: AppConstants.workspaceRoute,
  name: 'workspace',
  redirect: (context, state) async {
    // 워크스페이스 루트 경로 접근 시 최상위 그룹으로 리다이렉트
    final groupService = GroupService(DioClient());
    final myGroups = await groupService.getMyGroups();
    final topGroup = groupService.getTopLevelGroup(myGroups);

    if (topGroup != null) {
      return '/workspace/${topGroup.id}';
    }
    return null; // 소속 그룹 없으면 그대로 진행
  },
  builder: (context, state) => const WorkspacePage(),
  routes: [
    // 하위 라우트...
  ],
),
```

## 구현 순서

### Phase 1: 백엔드 API 구현 ✅ 완료 (2025-10-04)
1. ✅ `GET /api/me/groups` 엔드포인트 구현 (MeController.kt:31-41)
2. ✅ MyGroupResponse DTO 생성 (GroupDto.kt:199-209)
3. ✅ level, parentId 필드 포함
4. ✅ 정렬: level 오름차순 → id 오름차순
5. ✅ JOIN FETCH 최적화 (GroupRepositories.kt:128-136)
6. ✅ 계층 레벨 계산 로직 (GroupMemberService.kt:594-602)
7. ✅ API 문서 업데이트 (api-reference.md:435-487)

### Phase 2: 프론트엔드 데이터 레이어
1. ✅ `GroupMembership` 모델 생성
2. ✅ `GroupService.getMyGroups()` 구현
3. ✅ `GroupService.getTopLevelGroup()` 로직 구현
4. ✅ 에러 처리 및 로깅

### Phase 3: 네비게이션 통합
1. ✅ 사이드바 워크스페이스 버튼 로직 수정
2. ✅ 로딩 상태 UI 추가
3. ✅ 라우터 리다이렉트 설정
4. ✅ 네비게이션 컨트롤러 상태 동기화

### Phase 4: 테스트 및 검증
1. ✅ 소속 그룹이 여러 개인 경우 테스트
2. ✅ 소속 그룹이 없는 경우 처리
3. ✅ 다른 페이지에서 특정 그룹 진입 테스트
4. ✅ 뒤로가기 동작 확인

## 엣지 케이스 처리

### 1. 소속 그룹이 없는 경우
**시나리오**: 신규 사용자, 모든 그룹 탈퇴한 사용자

**처리**:
```dart
// 빈 상태 화면 표시
Widget _buildNoGroupsState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.group_add_outlined, size: 64, color: AppColors.brand),
        SizedBox(height: 16),
        Text('소속된 그룹이 없습니다', style: AppTheme.displaySmall),
        SizedBox(height: 8),
        Text('홈에서 그룹을 탐색하고 가입해보세요',
             style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600)),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go('/home'),
          child: Text('그룹 탐색하기'),
        ),
      ],
    ),
  );
}
```

### 2. API 호출 실패
**처리**:
- 네트워크 에러: 재시도 버튼 제공
- 타임아웃: 기본 워크스페이스 빈 상태 표시
- 권한 에러: 로그인 페이지로 리다이렉트

### 3. 여러 최상위 그룹이 있는 경우
**예시**: 한신대학교 + 연세대학교 동시 소속

**처리**:
- `id`가 가장 작은 그룹 (가장 먼저 가입한 그룹) 선택
- 향후 개선: 사용자 선택 UI 추가

## 성능 최적화

### 1. 그룹 목록 캐싱
```dart
// Riverpod Provider로 캐싱
final myGroupsProvider = FutureProvider<List<GroupMembership>>((ref) async {
  final groupService = GroupService(DioClient());
  return await groupService.getMyGroups();
});

// 사용
final myGroupsAsync = ref.watch(myGroupsProvider);
myGroupsAsync.when(
  data: (groups) { /* 그룹 목록 사용 */ },
  loading: () { /* 로딩 */ },
  error: (error, stack) { /* 에러 */ },
);
```

### 2. 최상위 그룹 메모이제이션
```dart
final topGroupProvider = Provider<GroupMembership?>((ref) {
  final myGroupsAsync = ref.watch(myGroupsProvider);
  return myGroupsAsync.maybeWhen(
    data: (groups) {
      final groupService = GroupService(DioClient());
      return groupService.getTopLevelGroup(groups);
    },
    orElse: () => null,
  );
});
```

## 문서 업데이트

### 1. API 참조 문서
**파일**: `docs/implementation/api-reference.md`

**추가 섹션**:
```markdown
## Me API - 내 정보 조회

### GET /api/me/groups
사용자가 속한 모든 그룹 목록을 조회합니다.

**권한**: `isAuthenticated()`

**응답**:
- level 오름차순 (0이 최상위)
- 동일 레벨: id 오름차순

**사용 사례**:
- 워크스페이스 자동 진입 (최상위 그룹 선택)
- 내 그룹 목록 표시
- 권한별 그룹 필터링
```

### 2. 프론트엔드 가이드
**파일**: `docs/implementation/frontend-guide.md`

**추가 섹션**:
```markdown
## 워크스페이스 진입 패턴

### 자동 진입 (글로벌 네비게이션)
워크스페이스 버튼 클릭 시 최상위 그룹으로 자동 진입

### 직접 진입 (다른 페이지)
홈, 그룹 탐색 등에서 특정 그룹 워크스페이스로 바로 진입
```

## 관련 문서
- [워크스페이스 페이지 명세](../ui-ux/pages/workspace-pages.md)
- [네비게이션 플로우](../ui-ux/pages/navigation-and-page-flow.md)
- [API 참조](api-reference.md)
- [그룹 계층 구조](../concepts/group-hierarchy.md)

## 변경 이력
| 날짜 | 내용 |
|------|------|
| 2025-10-04 | 최초 작성 (백엔드 API 미구현으로 보류) |
