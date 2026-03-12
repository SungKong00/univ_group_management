/// Step 1: 멤버 필터 선택 페이지
///
/// 역할, 소속 그룹, 학년, 학번 필터를 선택하는 첫 번째 단계
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../../core/providers/member/member_filter_provider.dart';
import '../../../core/providers/member/member_filter_options_provider.dart';
import '../../../core/models/member_filter.dart';
import '../../../core/models/member_models.dart';
import '../../../core/models/group_models.dart';
import 'providers/role_management_provider.dart';
import '../../components/chips/expandable_chip_section.dart';
import 'selection_method_page.dart';

/// Step 1: 멤버 필터 선택 페이지
class MemberFilterPage extends ConsumerWidget {
  final int groupId;

  const MemberFilterPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // state를 직접 감시하여 변경 시 UI 리빌드
    final currentFilter = ref.watch(memberFilterStateProvider(groupId));
    final filterNotifier = ref.read(
      memberFilterStateProvider(groupId).notifier,
    );
    final rolesAsync = ref.watch(roleListProvider(groupId));
    final subGroupsAsync = ref.watch(subGroupsProvider(groupId));
    final availableYears = ref.watch(availableYearsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('참여자 선택'),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 안내 텍스트
            Text(
              '멤버를 필터링할 조건을 선택하세요',
              style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral700),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 역할 필터
            _buildRoleFilter(
              context,
              ref,
              rolesAsync,
              currentFilter,
              filterNotifier,
            ),
            const SizedBox(height: AppSpacing.md),

            // 소속 그룹 필터
            _buildGroupFilter(
              context,
              ref,
              subGroupsAsync,
              currentFilter,
              filterNotifier,
            ),
            const SizedBox(height: AppSpacing.md),

            // 학년/학번 필터
            _buildGradeYearFilter(
              context,
              ref,
              currentFilter,
              filterNotifier,
              availableYears,
            ),
            const SizedBox(height: AppSpacing.lg),

            // 선택된 필터 요약 또는 전체 선택 안내
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            currentFilter.isActive
                ? _buildFilterSummary(
                    context,
                    currentFilter,
                    rolesAsync,
                    subGroupsAsync,
                    availableYears,
                  )
                : _buildEmptyFilterNotice(context),
            const SizedBox(height: AppSpacing.lg),

            // 다음 버튼 (항상 활성화)
            ElevatedButton(
              onPressed: () => _navigateToStep2(context, ref, currentFilter),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.action,
                minimumSize: const Size.fromHeight(AppComponents.buttonHeight),
              ),
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilter(
    BuildContext context,
    WidgetRef ref,
    AsyncValue rolesAsync,
    MemberFilter currentFilter,
    MemberFilterNotifier filterNotifier,
  ) {
    final isEnabled =
        !currentFilter.isGroupFilterActive &&
        !currentFilter.isGradeFilterActive &&
        !currentFilter.isYearFilterActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '역할',
              style: AppTheme.titleMedium.copyWith(
                color: isEnabled ? AppColors.neutral800 : AppColors.neutral400,
              ),
            ),
            if (!isEnabled) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: '다른 필터 사용 중에는 역할 필터를 사용할 수 없습니다',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.neutral400,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        rolesAsync.when(
          data: (roles) => isEnabled
              ? ExpandableChipSection<GroupRole>(
                  items: roles,
                  selectedItems: roles
                      .where(
                        (r) => currentFilter.roleIds?.contains(r.id) ?? false,
                      )
                      .toList(),
                  itemLabel: (role) => role.name,
                  onSelectionChanged: (selectedRoles) {
                    final selectedIds = selectedRoles.map((r) => r.id).toList();
                    // setFilter로 즉시 적용
                    ref
                        .read(memberFilterStateProvider(groupId).notifier)
                        .setFilter(
                          currentFilter.copyWith(
                            roleIds: selectedIds.isEmpty ? null : selectedIds,
                            groupIds: null,
                            grades: null,
                            years: null,
                          ),
                        );
                  },
                  enabled: true,
                  initialDisplayCount: 6,
                )
              : Text(
                  '다른 필터를 해제하면 역할 필터를 사용할 수 있습니다',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Text('역할을 불러올 수 없습니다', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }

  Widget _buildGroupFilter(
    BuildContext context,
    WidgetRef ref,
    AsyncValue subGroupsAsync,
    MemberFilter currentFilter,
    MemberFilterNotifier filterNotifier,
  ) {
    return subGroupsAsync.when(
      data: (subGroups) {
        if (subGroups.isEmpty) return const SizedBox.shrink();

        final isEnabled = !currentFilter.isRoleFilterActive;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '소속 그룹',
                  style: AppTheme.titleMedium.copyWith(
                    color: isEnabled
                        ? AppColors.neutral800
                        : AppColors.neutral400,
                  ),
                ),
                if (!isEnabled) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: '역할 필터 사용 중에는 그룹 필터를 사용할 수 없습니다',
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.neutral400,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            isEnabled
                ? ExpandableChipSection<GroupSummaryResponse>(
                    items: subGroups,
                    selectedItems: subGroups
                        .where(
                          (g) =>
                              currentFilter.groupIds?.contains(g.id) ?? false,
                        )
                        .toList(),
                    itemLabel: (group) => group.name,
                    onSelectionChanged: (selectedGroups) {
                      final selectedIds = selectedGroups
                          .map((g) => g.id)
                          .toList();
                      // setFilter로 즉시 적용
                      ref
                          .read(memberFilterStateProvider(groupId).notifier)
                          .setFilter(
                            currentFilter.copyWith(
                              roleIds: null,
                              groupIds: selectedIds.isEmpty
                                  ? null
                                  : selectedIds,
                            ),
                          );
                    },
                    enabled: true,
                    initialDisplayCount: 6,
                  )
                : Text(
                    '역할 필터를 해제하면 그룹 필터를 사용할 수 있습니다',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.neutral500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildGradeYearFilter(
    BuildContext context,
    WidgetRef ref,
    MemberFilter currentFilter,
    MemberFilterNotifier filterNotifier,
    List<int> availableYears,
  ) {
    final isEnabled = !currentFilter.isRoleFilterActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '학년 또는 학번',
              style: AppTheme.titleMedium.copyWith(
                color: isEnabled ? AppColors.neutral800 : AppColors.neutral400,
              ),
            ),
            if (!isEnabled) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: '역할 필터 사용 중에는 학년/학번 필터를 사용할 수 없습니다',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.neutral400,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '학년과 학번은 함께 선택 가능합니다 (OR 관계)',
          style: AppTheme.bodySmall.copyWith(
            color: isEnabled ? AppColors.neutral600 : AppColors.neutral400,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isEnabled) ...[
          // 학년
          Text(
            '학년',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.neutral700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ExpandableChipSection<int>(
            items: availableGrades,
            selectedItems: currentFilter.grades ?? [],
            itemLabel: (grade) => gradeLabels[grade] ?? '$grade학년',
            onSelectionChanged: (selectedGrades) {
              // setFilter로 즉시 적용
              ref
                  .read(memberFilterStateProvider(groupId).notifier)
                  .setFilter(
                    currentFilter.copyWith(
                      roleIds: null,
                      grades: selectedGrades.isEmpty ? null : selectedGrades,
                    ),
                  );
            },
            enabled: true,
            initialDisplayCount: 5,
          ),
          const SizedBox(height: AppSpacing.md),
          // 학번
          Text(
            '학번 (입학년도)',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.neutral700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ExpandableChipSection<int>(
            items: availableYears,
            selectedItems: currentFilter.years ?? [],
            itemLabel: (year) => '$year년',
            onSelectionChanged: (selectedYears) {
              // setFilter로 즉시 적용
              ref
                  .read(memberFilterStateProvider(groupId).notifier)
                  .setFilter(
                    currentFilter.copyWith(
                      roleIds: null,
                      years: selectedYears.isEmpty ? null : selectedYears,
                    ),
                  );
            },
            enabled: true,
            initialDisplayCount: 5,
          ),
        ] else
          Text(
            '역할 필터를 해제하면 학년/학번 필터를 사용할 수 있습니다',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.neutral500,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyFilterNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.neutral300, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, size: 20, color: AppColors.neutral700),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '전체 멤버 선택',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppColors.neutral800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '필터를 선택하지 않으면 모든 멤버가 대상에 포함됩니다',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSummary(
    BuildContext context,
    MemberFilter filter,
    AsyncValue rolesAsync,
    AsyncValue subGroupsAsync,
    List<int> availableYears,
  ) {
    final summaries = <String>[];

    // 역할
    if (filter.roleIds?.isNotEmpty ?? false) {
      final roles = rolesAsync.asData?.value ?? [];
      final roleNames = filter.roleIds!
          .map((id) {
            try {
              return roles.firstWhere((r) => r.id == id).name;
            } catch (e) {
              return null;
            }
          })
          .whereType<String>()
          .toList();
      if (roleNames.isNotEmpty) {
        summaries.add('역할: ${roleNames.join(", ")}');
      }
    }

    // 소속 그룹
    if (filter.groupIds?.isNotEmpty ?? false) {
      final subGroups = subGroupsAsync.asData?.value ?? [];
      final groupNames = filter.groupIds!
          .map((id) {
            try {
              return subGroups.firstWhere((g) => g.id == id).name;
            } catch (e) {
              return null;
            }
          })
          .whereType<String>()
          .toList();
      if (groupNames.isNotEmpty) {
        summaries.add('소속: ${groupNames.join(", ")}');
      }
    }

    // 학년
    if (filter.grades?.isNotEmpty ?? false) {
      final gradeText = filter.grades!
          .map((g) => gradeLabels[g] ?? '$g학년')
          .join(', ');
      summaries.add('학년: $gradeText');
    }

    // 학번
    if (filter.years?.isNotEmpty ?? false) {
      final yearText = filter.years!.map((y) => '$y년').join(', ');
      summaries.add('학번: $yearText');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선택된 필터',
          style: AppTheme.titleMedium.copyWith(color: AppColors.neutral800),
        ),
        const SizedBox(height: AppSpacing.xs),
        ...summaries.map(
          (summary) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToStep2(
    BuildContext context,
    WidgetRef ref,
    MemberFilter filter,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionMethodPage(groupId: groupId, filter: filter),
      ),
    );
  }
}

// 학년 레이블 매핑
const gradeLabels = {1: '1학년', 2: '2학년', 3: '3학년', 4: '4학년', 5: '졸업생'};

// 학년 옵션
const availableGrades = [1, 2, 3, 4, 5];
