# 멤버 필터 구현 가이드 (Member Filter Implementation)

멤버 필터링 시스템의 프론트엔드 구현 가이드입니다.

## 파일 구조

```
lib/
├── core/
│   ├── models/
│   │   └── member_filter.dart (필터 모델)
│   └── providers/
│       └── member/
│           ├── member_list_provider.dart
│           └── member_filter_provider.dart
├── presentation/
│   └── widgets/
│       └── member/
│           ├── member_avatar.dart (기존)
│           ├── role_badge.dart (신규)
│           ├── member_info_row.dart (신규)
│           ├── member_card.dart (신규 - public)
│           ├── member_table_row.dart (신규 - public)
│           └── filters/
│               ├── role_filter.dart
│               ├── group_filter.dart
│               └── grade_year_filter.dart
```

## 데이터 모델

### MemberFilter

```dart
// lib/core/models/member_filter.dart
class MemberFilter {
  final List<int>? roleIds;        // 역할 ID 목록
  final List<int>? groupIds;       // 소속 그룹 ID 목록
  final List<int>? grades;         // 학년 목록
  final List<int>? years;          // 학번(입학년도) 목록

  MemberFilter({
    this.roleIds,
    this.groupIds,
    this.grades,
    this.years,
  });

  // API 쿼리 파라미터로 변환
  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (roleIds != null && roleIds!.isNotEmpty) {
      params['roleIds'] = roleIds!.join(',');
    }
    if (groupIds != null && groupIds!.isNotEmpty) {
      params['groupIds'] = groupIds!.join(',');
    }
    if (grades != null && grades!.isNotEmpty) {
      params['grades'] = grades!.join(',');
    }
    if (years != null && years!.isNotEmpty) {
      params['years'] = years!.join(',');
    }
    return params;
  }

  // 필터 활성 여부
  bool get isActive =>
      (roleIds?.isNotEmpty ?? false) ||
      (groupIds?.isNotEmpty ?? false) ||
      (grades?.isNotEmpty ?? false) ||
      (years?.isNotEmpty ?? false);

  // 역할 필터 사용 중
  bool get isRoleFilterActive => roleIds?.isNotEmpty ?? false;
}
```

## Provider 설계

### MemberFilterProvider

```dart
// lib/core/providers/member/member_filter_provider.dart
@riverpod
class MemberFilterState extends _$MemberFilterState {
  @override
  MemberFilter build(int groupId) {
    return MemberFilter(); // 초기값: 필터 없음
  }

  // 역할 필터 토글
  void toggleRole(int roleId) {
    final current = state.roleIds ?? [];
    final updated = current.contains(roleId)
        ? current.where((id) => id != roleId).toList()
        : [...current, roleId];

    state = state.copyWith(
      roleIds: updated.isEmpty ? null : updated,
      // 역할 선택 시 다른 필터 초기화
      groupIds: null,
      grades: null,
      years: null,
    );
  }

  // 소속 그룹 필터 토글
  void toggleGroup(int groupId) {
    // 그룹 선택 시 역할 필터 초기화
    state = state.copyWith(roleIds: null);

    final current = state.groupIds ?? [];
    final updated = current.contains(groupId)
        ? current.where((id) => id != groupId).toList()
        : [...current, groupId];

    state = state.copyWith(
      groupIds: updated.isEmpty ? null : updated,
    );
  }

  // 학년 필터 토글 (학번과 OR 관계)
  void toggleGrade(int grade) {
    // 학년 선택 시 역할 필터 초기화
    state = state.copyWith(roleIds: null);

    final current = state.grades ?? [];
    final updated = current.contains(grade)
        ? current.where((g) => g != grade).toList()
        : [...current, grade];

    state = state.copyWith(
      grades: updated.isEmpty ? null : updated,
    );
  }

  // 학번 필터 토글 (학년과 OR 관계)
  void toggleYear(int year) {
    // 학번 선택 시 역할 필터 초기화
    state = state.copyWith(roleIds: null);

    final current = state.years ?? [];
    final updated = current.contains(year)
        ? current.where((y) => y != year).toList()
        : [...current, year];

    state = state.copyWith(
      years: updated.isEmpty ? null : updated,
    );
  }

  // 모든 필터 초기화
  void reset() {
    state = MemberFilter();
  }
}
```

### FilteredMembersProvider

```dart
// lib/core/providers/member/member_list_provider.dart
@riverpod
Future<List<GroupMember>> filteredMembers(
  FilteredMembersRef ref,
  int groupId,
) async {
  final filter = ref.watch(memberFilterStateProvider(groupId));
  final apiService = ref.watch(groupApiServiceProvider);

  // 필터가 없으면 전체 조회
  if (!filter.isActive) {
    return apiService.getMembers(groupId: groupId);
  }

  // 필터 적용하여 조회
  return apiService.getMembers(
    groupId: groupId,
    queryParameters: filter.toQueryParameters(),
  );
}
```

## UI 컴포넌트 구현

### RoleFilter (역할 필터)

```dart
// lib/presentation/widgets/member/filters/role_filter.dart
class RoleFilter extends ConsumerWidget {
  final int groupId;
  final List<GroupRole> roles;

  const RoleFilter({
    super.key,
    required this.groupId,
    required this.roles,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(memberFilterStateProvider(groupId));
    final isDisabled = filter.isActive && !filter.isRoleFilterActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('역할 (선택 시 단독 필터)', style: AppTheme.titleMedium),
            const SizedBox(width: 4),
            Tooltip(
              message: '역할 선택 시 다른 필터가 비활성화됩니다',
              child: Icon(Icons.info_outline, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles.map((role) {
            final isSelected = filter.roleIds?.contains(role.id) ?? false;
            return FilterChip(
              label: Text(role.name),
              selected: isSelected,
              onSelected: isDisabled
                  ? null
                  : (_) => ref
                      .read(memberFilterStateProvider(groupId).notifier)
                      .toggleRole(role.id),
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

### GradeYearFilter (학년/학번 필터 - OR 관계)

```dart
// lib/presentation/widgets/member/filters/grade_year_filter.dart
class GradeYearFilter extends ConsumerWidget {
  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(memberFilterStateProvider(groupId));
    final isDisabled = filter.isRoleFilterActive;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('학년 또는 학번', style: AppTheme.titleMedium),
              const SizedBox(width: 4),
              Tooltip(
                message: '학년 또는 학번 중 하나 이상 만족',
                child: Icon(Icons.info_outline, size: 16),
              ),
            ],
          ),
          const Divider(),
          // 학년 필터
          Text('학년', style: AppTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [1, 2, 3, 4].map((grade) {
              final isSelected = filter.grades?.contains(grade) ?? false;
              return FilterChip(
                label: Text('${grade}학년'),
                selected: isSelected,
                onSelected: isDisabled
                    ? null
                    : (_) => ref
                        .read(memberFilterStateProvider(groupId).notifier)
                        .toggleGrade(grade),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // 학번 필터
          Text('학번 (입학년도)', style: AppTheme.bodyMedium),
          // 드롭다운으로 학번 선택 (동적 생성)
        ],
      ),
    );
  }
}
```

## API 통합

### GET 요청 예시

```dart
// 필터가 적용된 멤버 목록 조회
GET /api/groups/1/members?roleIds=1,2&groupIds=10,20&grades=2,3&years=24,25

// 응답
{
  "data": [
    {
      "id": 1,
      "userId": 100,
      "userName": "김철수",
      "roleId": 1,
      "roleName": "그룹장",
      "studentNo": "202400001",
      "academicYear": 2,
      ...
    }
  ],
  "message": "success"
}
```

## 성능 최적화

- **디바운싱**: 필터 변경 시 300ms 디바운스 후 API 호출
- **캐싱**: 동일한 필터 조합은 5분간 캐시
- **페이지네이션**: 기본 20명/페이지

## 관련 문서

- [멤버 필터 개념](../../concepts/member-list-system.md) - 필터링 로직
- [멤버 필터 UI](../../ui-ux/components/member-list-component.md) - UI/UX 설계
- [상태 관리](state-management.md) - Riverpod 패턴
