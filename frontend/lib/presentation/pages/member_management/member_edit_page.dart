/// Step 3: 멤버 명단 편집 페이지
///
/// STATIC 방식 선택 시 멤버 목록을 편집하는 세 번째 단계
library;

import 'package:flutter/material.dart';
import '../../../core/utils/snack_bar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../../core/models/member_filter.dart';
import '../../../core/models/member_selection_result.dart';
import '../../../core/providers/member/member_filter_provider.dart';
import '../../../core/providers/member/member_filter_options_provider.dart';
import '../../../core/providers/member/member_list_provider.dart';
import '../../../core/providers/member/member_selection_provider.dart';
import '../../../core/models/member_models.dart';
import '../../../core/models/group_models.dart';
import 'providers/role_management_provider.dart';
import '../../components/popovers/multi_select_popover.dart';

/// Step 3: 멤버 명단 편집 페이지
class MemberEditPage extends ConsumerStatefulWidget {
  final int groupId;
  final MemberFilter initialFilter;
  final List<int> initialSelectedIds;

  const MemberEditPage({
    super.key,
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
      // 초기 필터 설정 (setFilter로 즉시 적용)
      ref
          .read(memberFilterStateProvider(widget.groupId).notifier)
          .setFilter(widget.initialFilter);

      // 초기 선택 상태 설정
      ref
          .read(memberSelectionProvider(widget.groupId).notifier)
          .initialize(widget.initialSelectedIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedState = ref.watch(memberSelectionProvider(widget.groupId));
    final membersAsync = ref.watch(filteredGroupMembersProvider(widget.groupId));
    // state를 직접 감시 (notifier 감시 시 무한 리빌드 발생)
    final currentFilter = ref.watch(memberFilterStateProvider(widget.groupId));
    final filterNotifier = ref.read(memberFilterStateProvider(widget.groupId).notifier);
    final rolesAsync = ref.watch(roleListProvider(widget.groupId));
    final subGroupsAsync = ref.watch(subGroupsProvider(widget.groupId));
    final availableYears = ref.watch(availableYearsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('명단 편집'),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => _confirmSelection(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('확정'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 섹션
          Container(
            color: AppColors.neutral100,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '필터 조건',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppColors.neutral800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildCompactFilters(
                  currentFilter,
                  filterNotifier,
                  rolesAsync,
                  subGroupsAsync,
                  availableYears,
                ),
              ],
            ),
          ),

          // 선택 통계 + 일괄 액션
          _buildActionBar(context, selectedState, membersAsync),

          // 멤버 리스트 (체크박스)
          Expanded(
            child: membersAsync.when(
              data: (members) => members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.neutral400,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '조건에 해당하는 멤버가 없습니다',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildMemberList(members, selectedState),
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.md),
                    Text('멤버 목록을 불러오는 중...'),
                  ],
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '데이터를 불러올 수 없습니다',
                        style: AppTheme.titleMedium.copyWith(color: AppColors.error),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        error.toString(),
                        style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(filteredGroupMembersProvider(widget.groupId)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilters(
    MemberFilter currentFilter,
    dynamic filterNotifier,
    AsyncValue rolesAsync,
    AsyncValue subGroupsAsync,
    List<int> availableYears,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 역할 필터
        if (!currentFilter.isGroupFilterActive &&
            !currentFilter.isGradeFilterActive &&
            !currentFilter.isYearFilterActive)
          rolesAsync.maybeWhen(
            data: (roles) => SizedBox(
              width: 150,
              child: MultiSelectPopover<GroupRole>(
                label: '역할',
                items: roles,
                selectedItems: roles
                    .where((r) => currentFilter.roleIds?.contains(r.id) ?? false)
                    .toList(),
                itemLabel: (role) => role.name,
                onChanged: (selectedRoles) {
                  final selectedIds = selectedRoles.map((r) => r.id).toList();
                  filterNotifier.setFilter(
                    currentFilter.copyWith(
                      roleIds: selectedIds.isEmpty ? null : selectedIds,
                      groupIds: null,
                      grades: null,
                      years: null,
                    ),
                  );
                },
                emptyLabel: '전체',
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),

        // 소속 그룹 필터
        if (!currentFilter.isRoleFilterActive)
          subGroupsAsync.maybeWhen(
            data: (subGroups) => subGroups.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                    width: 150,
                    child: MultiSelectPopover<GroupSummaryResponse>(
                      label: '그룹',
                      items: subGroups,
                      selectedItems: subGroups
                          .where((g) => currentFilter.groupIds?.contains(g.id) ?? false)
                          .toList(),
                      itemLabel: (group) => group.name,
                      onChanged: (selectedGroups) {
                        final selectedIds = selectedGroups.map((g) => g.id).toList();
                        filterNotifier.setFilter(
                          currentFilter.copyWith(
                            roleIds: null,
                            groupIds: selectedIds.isEmpty ? null : selectedIds,
                          ),
                        );
                      },
                      emptyLabel: '전체',
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),

        // 학년 필터
        if (!currentFilter.isRoleFilterActive)
          SizedBox(
            width: 150,
            child: MultiSelectPopover<int>(
              label: '학년',
              items: const [1, 2, 3, 4, 5],
              selectedItems: currentFilter.grades ?? [],
              itemLabel: (grade) {
                const gradeLabels = {
                  1: '1학년',
                  2: '2학년',
                  3: '3학년',
                  4: '4학년',
                  5: '졸업생',
                };
                return gradeLabels[grade] ?? '$grade학년';
              },
              onChanged: (selectedGrades) {
                filterNotifier.setFilter(
                  currentFilter.copyWith(
                    roleIds: null,
                    grades: selectedGrades.isEmpty ? null : selectedGrades,
                  ),
                );
              },
              emptyLabel: '전체',
            ),
          ),

        // 학번 필터
        if (!currentFilter.isRoleFilterActive)
          SizedBox(
            width: 150,
            child: MultiSelectPopover<int>(
              label: '학번',
              items: availableYears,
              selectedItems: currentFilter.years ?? [],
              itemLabel: (year) => '$year년',
              onChanged: (selectedYears) {
                filterNotifier.setFilter(
                  currentFilter.copyWith(
                    roleIds: null,
                    years: selectedYears.isEmpty ? null : selectedYears,
                  ),
                );
              },
              emptyLabel: '전체',
            ),
          ),
      ],
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    MemberSelectionState selectedState,
    AsyncValue membersAsync,
  ) {
    final displayedMembers = membersAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.people, size: 20, color: AppColors.brand),
          const SizedBox(width: 8),
          Text(
            '선택됨: ${selectedState.selectedMemberIds.length}명',
            style: AppTheme.titleMedium.copyWith(
              color: AppColors.brand,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: displayedMembers.isEmpty
                ? null
                : () {
                    ref
                        .read(memberSelectionProvider(widget.groupId).notifier)
                        .selectAll(displayedMembers.map((m) => m.id).toList());
                  },
            icon: const Icon(Icons.select_all, size: 16),
            label: const Text('전체 선택'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.action,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: displayedMembers.isEmpty
                ? null
                : () {
                    ref
                        .read(memberSelectionProvider(widget.groupId).notifier)
                        .deselectDisplayed(
                            displayedMembers.map((m) => m.id).toList());
                  },
            icon: const Icon(Icons.deselect, size: 16),
            label: const Text('표시 해제'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.neutral600,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(members, MemberSelectionState selectedState) {
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isSelected = selectedState.selectedMemberIds.contains(member.id);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (_) {
            ref
                .read(memberSelectionProvider(widget.groupId).notifier)
                .toggleMember(member.id);
          },
          title: Text(
            member.userName,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${member.academicYear != null ? "${member.academicYear}학년" : "학년 정보 없음"} · '
            '${member.studentNo?.substring(0, 4) ?? "학번 정보 없음"}학번 · '
            '${member.roleName}',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          activeColor: AppColors.brand,
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }

  void _confirmSelection(BuildContext context) {
    final selectedIds = ref
        .read(memberSelectionProvider(widget.groupId))
        .selectedMemberIds
        .toList();

    if (selectedIds.isEmpty) {
      AppSnackBar.error(context, '최소 1명 이상 선택해주세요');
      return;
    }

    Navigator.pop(
      context,
      MemberSelectionResult.static(selectedIds),
    );
  }
}
