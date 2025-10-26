# 멤버 선택 구현 가이드 (Frontend)

> **문서 예외**: 코드 구현 참조 가이드 (100줄 제한 예외)

하이브리드 대상 선택 플로우(Step 1-3)의 프론트엔드 구현 가이드입니다.

## 개요

**목적**: DYNAMIC/STATIC 방식을 선택할 수 있는 3단계 멤버 선택 UI 구현

**핵심 컴포넌트**:
- Step 1: `MemberFilterPage` - 필터 선택
- Step 2: `SelectionMethodPage` - DYNAMIC/STATIC 카드 선택
- Step 3: `MemberEditPage` - 명단 편집

## Phase 1: 공통 Provider (2시간)

### MemberSelectionNotifier
**파일**: `frontend/lib/core/providers/member/member_selection_provider.dart`

```dart
class MemberSelectionState {
  final Set<int> selectedMemberIds;  // 선택된 멤버 ID

  MemberSelectionState({this.selectedMemberIds = const {}});

  MemberSelectionState copyWith({Set<int>? selectedMemberIds}) {
    return MemberSelectionState(
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
    );
  }
}

class MemberSelectionNotifier extends StateNotifier<MemberSelectionState> {
  MemberSelectionNotifier() : super(MemberSelectionState());

  void toggleMember(int memberId) {
    final updated = Set<int>.from(state.selectedMemberIds);
    if (updated.contains(memberId)) {
      updated.remove(memberId);
    } else {
      updated.add(memberId);
    }
    state = state.copyWith(selectedMemberIds: updated);
  }

  void selectAll(List<int> memberIds) {
    final updated = Set<int>.from(state.selectedMemberIds);
    updated.addAll(memberIds);
    state = state.copyWith(selectedMemberIds: updated);
  }

  void deselectDisplayed(List<int> displayedIds) {
    final updated = Set<int>.from(state.selectedMemberIds);
    updated.removeAll(displayedIds);
    state = state.copyWith(selectedMemberIds: updated);
  }

  void initialize(List<int> memberIds) {
    state = state.copyWith(selectedMemberIds: Set.from(memberIds));
  }

  void clear() {
    state = state.copyWith(selectedMemberIds: {});
  }
}

final memberSelectionProvider = StateNotifierProvider.family
    .autoDispose<MemberSelectionNotifier, MemberSelectionState, int>(
  (ref, groupId) => MemberSelectionNotifier(),
);
```

### Preview API Provider
**파일**: `frontend/lib/core/providers/member/member_preview_provider.dart`

```dart
final memberPreviewProvider = FutureProvider.family
    .autoDispose<MemberPreviewResponse, (int, MemberFilter)>(
  (ref, params) async {
    final (groupId, filter) = params;
    final queryParams = filter.toQueryParameters();

    final response = await ref.read(apiServiceProvider).get(
      '/api/groups/$groupId/members/preview',
      queryParameters: queryParams,
    );

    return MemberPreviewResponse.fromJson(response.data);
  },
);
```

## Phase 2: Step 1 - 필터 선택 (1시간)

### MemberFilterPage
**파일**: `frontend/lib/presentation/pages/member_management/member_filter_page.dart`

```dart
class MemberFilterPage extends ConsumerWidget {
  final int groupId;

  const MemberFilterPage({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(memberFilterStateProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: Text('참여자 선택')),
      body: Column(
        children: [
          // 필터 드롭다운 영역
          MultiSelectFilterBar(groupId: groupId),

          // 선택된 필터 요약
          AppliedFilterSummary(filter: filter),

          Spacer(),

          // 다음 버튼
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: ElevatedButton(
              onPressed: filter.isActive
                  ? () => _navigateToStep2(context, ref)
                  : null,
              child: Text('다음'),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToStep2(BuildContext context, WidgetRef ref) {
    final filter = ref.read(memberFilterStateProvider(groupId).notifier).state;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionMethodPage(
          groupId: groupId,
          filter: filter,
        ),
      ),
    );
  }
}
```

## Phase 3: Step 2 - DYNAMIC/STATIC 선택 (2시간)

### SelectionMethodPage
**파일**: `frontend/lib/presentation/pages/member_management/selection_method_page.dart`

```dart
class SelectionMethodPage extends ConsumerWidget {
  final int groupId;
  final MemberFilter filter;

  const SelectionMethodPage({
    required this.groupId,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(
      memberPreviewProvider((groupId, filter))
    );

    return Scaffold(
      appBar: AppBar(title: Text('저장 방식 선택')),
      body: previewAsync.when(
        data: (preview) => Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              // DYNAMIC 카드
              _buildDynamicCard(context, preview),
              SizedBox(height: AppSpacing.md),
              // STATIC 카드
              _buildStaticCard(context, preview),
            ],
          ),
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, st) => ErrorView(error: e),
      ),
    );
  }

  Widget _buildDynamicCard(BuildContext context, MemberPreviewResponse preview) {
    return Card(
      child: InkWell(
        onTap: () => _selectDynamic(context),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔄 조건으로 저장 (DYNAMIC)', style: AppTheme.titleMedium),
              SizedBox(height: AppSpacing.sm),
              Text('총 ${preview.totalCount}명', style: AppTheme.bodyLarge),
              SizedBox(height: AppSpacing.xs),
              Text(
                preview.samples.map((s) => s.name).join(', ') + ' ...',
                style: AppTheme.bodySmall,
              ),
              SizedBox(height: AppSpacing.sm),
              Text('✓ 신규 멤버 자동 포함', style: AppTheme.bodySmall),
              Text('✓ 조건 변경 시 자동 업데이트', style: AppTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticCard(BuildContext context, MemberPreviewResponse preview) {
    return Card(
      child: InkWell(
        onTap: () => _selectStatic(context, preview),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📋 명단으로 저장 (STATIC)', style: AppTheme.titleMedium),
              SizedBox(height: AppSpacing.sm),
              Text('총 ${preview.totalCount}명', style: AppTheme.bodyLarge),
              SizedBox(height: AppSpacing.xs),
              Text(
                preview.samples.map((s) => s.name).join(', ') + ' ...',
                style: AppTheme.bodySmall,
              ),
              SizedBox(height: AppSpacing.sm),
              Text('⚠ 고정 명단 (수동 관리)', style: AppTheme.bodySmall),
              Text('→ 다음 단계에서 편집 가능', style: AppTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDynamic(BuildContext context) {
    // DYNAMIC 선택 시 즉시 저장 (Step 3 건너뛰기)
    Navigator.pop(context, MemberSelectionResult.dynamic(filter));
  }

  void _selectStatic(BuildContext context, MemberPreviewResponse preview) {
    // STATIC 선택 시 Step 3으로 이동
    final memberIds = preview.samples.map((s) => s.id).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberEditPage(
          groupId: groupId,
          initialFilter: filter,
          initialSelectedIds: memberIds,
        ),
      ),
    ).then((result) {
      if (result != null) {
        Navigator.pop(context, result);
      }
    });
  }
}
```

## Phase 4: Step 3 - 명단 편집 (3시간)

### MemberEditPage
**파일**: `frontend/lib/presentation/pages/member_management/member_edit_page.dart`

```dart
class MemberEditPage extends ConsumerStatefulWidget {
  final int groupId;
  final MemberFilter initialFilter;
  final List<int> initialSelectedIds;

  const MemberEditPage({
    required this.groupId,
    required this.initialFilter,
    required this.initialSelectedIds,
  });

  @override
  ConsumerState<MemberEditPage> createState() => _MemberEditPageState();
}

class _MemberEditPageState extends ConsumerState<MemberEditPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 초기 필터 설정
      ref.read(memberFilterStateProvider(widget.groupId).notifier)
          .setDraft(widget.initialFilter);
      ref.read(memberFilterStateProvider(widget.groupId).notifier).apply();

      // 초기 선택 상태 설정
      ref.read(memberSelectionProvider(widget.groupId).notifier)
          .initialize(widget.initialSelectedIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedState = ref.watch(memberSelectionProvider(widget.groupId));
    final membersAsync = ref.watch(filteredMembersProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: Text('명단 편집'),
        actions: [
          TextButton(
            onPressed: () => _confirmSelection(context),
            child: Text('확정'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 드롭다운
          MultiSelectFilterBar(groupId: widget.groupId),

          // 선택 통계 + 일괄 액션
          _buildActionBar(context, selectedState, membersAsync),

          // 멤버 리스트 (체크박스)
          Expanded(
            child: membersAsync.when(
              data: (members) => _buildMemberList(members, selectedState),
              loading: () => SkeletonLoader(),
              error: (e, st) => ErrorView(error: e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    MemberSelectionState selectedState,
    AsyncValue<List<Member>> membersAsync,
  ) {
    final displayedMembers = membersAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Text('선택됨: ${selectedState.selectedMemberIds.length}명'),
          Spacer(),
          TextButton(
            onPressed: () {
              ref.read(memberSelectionProvider(widget.groupId).notifier)
                  .selectAll(displayedMembers.map((m) => m.id).toList());
            },
            child: Text('전체 선택'),
          ),
          TextButton(
            onPressed: () {
              ref.read(memberSelectionProvider(widget.groupId).notifier)
                  .deselectDisplayed(displayedMembers.map((m) => m.id).toList());
            },
            child: Text('표시된 멤버 해제'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(List<Member> members, MemberSelectionState selectedState) {
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isSelected = selectedState.selectedMemberIds.contains(member.id);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (_) {
            ref.read(memberSelectionProvider(widget.groupId).notifier)
                .toggleMember(member.id);
          },
          title: Text(member.name),
          subtitle: Text('${member.grade}학년 · ${member.year}학번 · ${member.roleName}'),
        );
      },
    );
  }

  void _confirmSelection(BuildContext context) {
    final selectedIds = ref.read(memberSelectionProvider(widget.groupId))
        .selectedMemberIds.toList();
    Navigator.pop(
      context,
      MemberSelectionResult.static(selectedIds),
    );
  }
}
```

## Phase 5: 결과 모델 (30분)

### MemberSelectionResult
**파일**: `frontend/lib/core/models/member_selection_result.dart`

```dart
enum SelectionType { dynamic, static }

class MemberSelectionResult {
  final SelectionType type;
  final MemberFilter? filter;       // DYNAMIC 선택 시
  final List<int>? memberIds;       // STATIC 선택 시

  MemberSelectionResult._({
    required this.type,
    this.filter,
    this.memberIds,
  });

  factory MemberSelectionResult.dynamic(MemberFilter filter) {
    return MemberSelectionResult._(
      type: SelectionType.dynamic,
      filter: filter,
    );
  }

  factory MemberSelectionResult.static(List<int> memberIds) {
    return MemberSelectionResult._(
      type: SelectionType.static,
      memberIds: memberIds,
    );
  }
}
```

## 사용 예시

### 일정 생성 페이지에서 호출
```dart
ElevatedButton(
  onPressed: () async {
    final result = await Navigator.push<MemberSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MemberFilterPage(groupId: groupId),
      ),
    );

    if (result != null) {
      if (result.type == SelectionType.dynamic) {
        // DYNAMIC 방식으로 일정 생성
        await createEventWithFilter(result.filter!);
      } else {
        // STATIC 방식으로 일정 생성
        await createEventWithMembers(result.memberIds!);
      }
    }
  },
  child: Text('참여자 선택'),
)
```

## 관련 문서

- [멤버 선택 플로우](../../features/member-selection-flow.md) - 전체 흐름
- [Preview API 명세](../../features/member-selection-preview-api.md) - API 설계
- [멤버 필터링 시스템](../../concepts/member-list-system.md) - 필터 조합 로직
- [상태 관리](state-management.md) - Riverpod 패턴
