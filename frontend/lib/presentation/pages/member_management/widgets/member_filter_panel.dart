import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/providers/member/member_filter_provider.dart';
import '../../../../core/providers/member/member_filter_options_provider.dart';
import '../../../../core/providers/member/member_count_provider.dart';
import '../../../../core/models/member_filter.dart';
import '../providers/role_management_provider.dart';
import '../../../components/chips/input_chip.dart';
import '../../../components/chips/app_chip.dart';
import '../../../widgets/common/section_card.dart';

/// 멤버 필터 패널
///
/// 데스크톱: 사이드바로 고정 표시
/// 모바일: 바텀 시트로 표시
class MemberFilterPanel extends ConsumerWidget {
  final int groupId;
  final VoidCallback? onClose; // 모바일 바텀 시트에서 사용

  const MemberFilterPanel({
    super.key,
    required this.groupId,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(roleListProvider(groupId));
    final filter = ref.watch(memberFilterStateProvider(groupId));
    final filterNotifier = ref.watch(memberFilterStateProvider(groupId).notifier);
    final subGroupsAsync = ref.watch(subGroupsProvider(groupId));
    final availableYears = ref.watch(availableYearsProvider);

    // 드래프트 필터 (UI 표시용)
    final draftFilter = filterNotifier.draftFilter;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더: 제목
          Text(
            '필터',
            style: AppTheme.headlineSmall.copyWith(
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 적용된 필터 칩 (있을 때만 표시) - state 기반
          if (filter.isActive) ...[
            _AppliedFilters(
              groupId: groupId,
              filter: filter,
              filterNotifier: filterNotifier,
              rolesAsync: rolesAsync,
              subGroupsAsync: subGroupsAsync,
              availableYears: availableYears,
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
          ],

          // 역할 필터 - draftFilter 기반
          rolesAsync.when(
            data: (roles) => _RoleFilter(
              groupId: groupId,
              roles: roles,
              filter: draftFilter,
              filterNotifier: filterNotifier,
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '역할을 불러올 수 없습니다',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // 소속 그룹 필터 - draftFilter 기반
          subGroupsAsync.when(
            data: (subGroups) => subGroups.isEmpty
                ? const SizedBox.shrink()
                : _GroupFilter(
                    groupId: groupId,
                    subGroups: subGroups,
                    filter: draftFilter,
                    filterNotifier: filterNotifier,
                  ),
            loading: () => const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
          ),

          if (subGroupsAsync.asData?.value.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
          ],

          // 학년/학번 필터 - draftFilter 기반
          _GradeYearFilter(
            groupId: groupId,
            filter: draftFilter,
            filterNotifier: filterNotifier,
            availableYears: availableYears,
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),

          // 하단 액션 영역 (Phase 1 추가)
          _ActionSection(
            groupId: groupId,
            filterNotifier: filterNotifier,
            draftFilter: draftFilter,
          ),
        ],
      ),
    );
  }
}

/// 적용된 필터 칩 표시
class _AppliedFilters extends StatelessWidget {
  final int groupId;
  final dynamic filter;
  final dynamic filterNotifier;
  final AsyncValue rolesAsync;
  final AsyncValue subGroupsAsync;
  final List<int> availableYears;

  const _AppliedFilters({
    required this.groupId,
    required this.filter,
    required this.filterNotifier,
    required this.rolesAsync,
    required this.subGroupsAsync,
    required this.availableYears,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    // 역할 필터 칩
    if (filter.roleIds?.isNotEmpty ?? false) {
      final roles = rolesAsync.asData?.value ?? [];
      for (final roleId in filter.roleIds!) {
        try {
          final role = roles.firstWhere(
            (r) => r.id == roleId,
          );
          chips.add(
            AppInputChip(
              label: '역할: ${role.name}',
              leadingIcon: Icons.person,
              variant: AppChipVariant.primary,
              onDeleted: () => filterNotifier.toggleRole(roleId),
            ),
          );
        } catch (e) {
          // 역할을 찾지 못한 경우 무시
        }
      }
    }

    // 소속 그룹 필터 칩
    if (filter.groupIds?.isNotEmpty ?? false) {
      final subGroups = subGroupsAsync.asData?.value ?? [];
      for (final groupId in filter.groupIds!) {
        try {
          final group = subGroups.firstWhere(
            (g) => g.id == groupId,
          );
          chips.add(
            AppInputChip(
              label: '그룹: ${group.name}',
              leadingIcon: Icons.group,
              onDeleted: () => filterNotifier.toggleGroup(groupId),
            ),
          );
        } catch (e) {
          // 그룹을 찾지 못한 경우 무시
        }
      }
    }

    // 학년 필터 칩
    if (filter.grades?.isNotEmpty ?? false) {
      for (final grade in filter.grades!) {
        final label = gradeLabels[grade] ?? '$grade학년';
        chips.add(
          AppInputChip(
            label: '학년: $label',
            leadingIcon: Icons.school,
            variant: AppChipVariant.success,
            onDeleted: () => filterNotifier.toggleGrade(grade),
          ),
        );
      }
    }

    // 학번 필터 칩
    if (filter.years?.isNotEmpty ?? false) {
      for (final year in filter.years!) {
        chips.add(
          AppInputChip(
            label: '학번: $year년',
            leadingIcon: Icons.calendar_today,
            variant: AppChipVariant.success,
            onDeleted: () => filterNotifier.toggleYear(year),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '적용된 필터',
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.neutral800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => filterNotifier.reset(MemberFilter()),
              child: const Text('모두 지우기'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < chips.length; i++) ...[
                chips[i],
                if (i < chips.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 역할 필터 섹션
class _RoleFilter extends StatelessWidget {
  final int groupId;
  final List roles;
  final dynamic filter;
  final dynamic filterNotifier;

  const _RoleFilter({
    required this.groupId,
    required this.roles,
    required this.filter,
    required this.filterNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // 역할 필터 활성화 여부
    final isEnabled = !filter.isGroupFilterActive &&
        !filter.isGradeFilterActive &&
        !filter.isYearFilterActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '역할',
                style: AppTheme.titleMedium.copyWith(
                  color: isEnabled ? AppColors.neutral800 : AppColors.neutral400,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (!isEnabled)
              Semantics(
                label: '다른 필터 사용 중에는 역할 필터를 사용할 수 없습니다',
                child: Tooltip(
                  message: '다른 필터 사용 중에는 역할 필터를 사용할 수 없습니다',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.neutral400,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles.map((role) {
            final isSelected = filter.roleIds?.contains(role.id) ?? false;
            return Semantics(
              label: '역할 필터: ${role.name}',
              selected: isSelected,
              button: true,
              child: AppChip(
                label: role.name,
                selected: isSelected,
                onSelected: isEnabled ? (_) => filterNotifier.toggleRole(role.id) : null,
                variant: AppChipVariant.primary,
                enabled: isEnabled,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 소속 그룹 필터 섹션
class _GroupFilter extends StatelessWidget {
  final int groupId;
  final List subGroups;
  final dynamic filter;
  final dynamic filterNotifier;

  const _GroupFilter({
    required this.groupId,
    required this.subGroups,
    required this.filter,
    required this.filterNotifier,
  });

  @override
  Widget build(BuildContext context) {
    // 그룹 필터 활성화 여부
    final isEnabled = !filter.isRoleFilterActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '소속 그룹',
                style: AppTheme.titleMedium.copyWith(
                  color: isEnabled ? AppColors.neutral800 : AppColors.neutral400,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (!isEnabled)
              Semantics(
                label: '역할 필터 사용 중에는 그룹 필터를 사용할 수 없습니다',
                child: Tooltip(
                  message: '역할 필터 사용 중에는 그룹 필터를 사용할 수 없습니다',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.neutral400,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subGroups.map((group) {
            final isSelected = filter.groupIds?.contains(group.id) ?? false;
            return Semantics(
              label: '소속 그룹 필터: ${group.name}',
              selected: isSelected,
              button: true,
              child: AppChip(
                label: group.name,
                leadingIcon: Icons.group,
                selected: isSelected,
                onSelected: isEnabled ? (_) => filterNotifier.toggleGroup(group.id) : null,
                enabled: isEnabled,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 학년/학번 필터 섹션
class _GradeYearFilter extends StatelessWidget {
  final int groupId;
  final dynamic filter;
  final dynamic filterNotifier;
  final List<int> availableYears;

  const _GradeYearFilter({
    required this.groupId,
    required this.filter,
    required this.filterNotifier,
    required this.availableYears,
  });

  @override
  Widget build(BuildContext context) {
    // 학년/학번 필터 활성화 여부
    final isEnabled = !filter.isRoleFilterActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '학년 또는 학번',
                style: AppTheme.titleMedium.copyWith(
                  color: isEnabled ? AppColors.neutral800 : AppColors.neutral400,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (!isEnabled)
              Semantics(
                label: '역할 필터 사용 중에는 학년/학번 필터를 사용할 수 없습니다',
                child: Tooltip(
                  message: '역할 필터 사용 중에는 학년/학번 필터를 사용할 수 없습니다',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.neutral400,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '학년과 학번은 함께 선택 가능합니다 (OR 관계)',
          style: AppTheme.bodySmall.copyWith(
            color: isEnabled ? AppColors.neutral600 : AppColors.neutral400,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 학년 필터
        Text(
          '학년',
          style: AppTheme.bodySmall.copyWith(
            color: isEnabled ? AppColors.neutral700 : AppColors.neutral400,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableGrades.map((grade) {
            final isSelected = filter.grades?.contains(grade) ?? false;
            final label = gradeLabels[grade] ?? '$grade학년';
            return AppChip(
              label: label,
              selected: isSelected,
              onSelected: isEnabled ? (_) => filterNotifier.toggleGrade(grade) : null,
              variant: AppChipVariant.success,
              enabled: isEnabled,
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.md),

        // 학번 필터
        Text(
          '학번 (입학년도)',
          style: AppTheme.bodySmall.copyWith(
            color: isEnabled ? AppColors.neutral700 : AppColors.neutral400,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableYears.map((year) {
            final isSelected = filter.years?.contains(year) ?? false;
            return AppChip(
              label: '$year년',
              selected: isSelected,
              onSelected: isEnabled ? (_) => filterNotifier.toggleYear(year) : null,
              variant: AppChipVariant.success,
              size: AppChipSize.small,
              enabled: isEnabled,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 하단 액션 영역 (Phase 1 + Phase 3)
///
/// 변경 사항 칩 + 예상 결과 개수 + 적용/취소/초기화 버튼
class _ActionSection extends ConsumerWidget {
  final int groupId;
  final MemberFilterNotifier filterNotifier;
  final dynamic draftFilter;

  const _ActionSection({
    required this.groupId,
    required this.filterNotifier,
    required this.draftFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDraftDirty = filterNotifier.isDraftDirty;
    final memberCountAsync = ref.watch(draftMemberCountProvider(groupId));

    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phase 3: 예상 결과 개수 미리보기
          if (draftFilter.isActive) ...[
            _buildPreviewSection(memberCountAsync),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Phase 1: 상태 칩 (변경 있을 때만 표시)
          if (isDraftDirty) ...[
            _buildStatusChip(),
            const SizedBox(height: AppSpacing.sm),
          ],

          // 버튼 영역
          Row(
            children: [
              // 초기화 버튼 (드래프트 필터 있을 때만)
              if (draftFilter.isActive)
                TextButton.icon(
                  onPressed: () => filterNotifier.reset(MemberFilter()),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('초기화'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.neutral600,
                  ),
                ),

              const Spacer(),

              // 취소 버튼 (변경 있을 때만)
              if (isDraftDirty)
                TextButton(
                  onPressed: () => filterNotifier.cancel(),
                  child: const Text('취소'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.neutral600,
                  ),
                ),

              if (isDraftDirty) const SizedBox(width: AppSpacing.sm),

              // 적용 버튼
              ElevatedButton(
                onPressed: isDraftDirty ? () => filterNotifier.apply() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  disabledBackgroundColor: AppColors.neutral200,
                  minimumSize: const Size(120, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: const Text('필터 적용'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Phase 3: 예상 결과 개수 미리보기
  Widget _buildPreviewSection(AsyncValue<int> memberCountAsync) {
    return memberCountAsync.when(
      data: (count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.actionTonalBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.action.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.action),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '예상 결과: $count명',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.action,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.neutral600),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '결과 개수 확인 중...',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '결과 개수를 불러올 수 없습니다',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit, size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            '변경 사항 있음',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
