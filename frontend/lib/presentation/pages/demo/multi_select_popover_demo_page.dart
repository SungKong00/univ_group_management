import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../components/chips/compact_chip.dart';
import '../../components/popovers/multi_select_popover.dart';

/// MultiSelectPopover 데모 페이지
///
/// **목적**: CompactChip 및 MultiSelectPopover 컴포넌트 테스트
///
/// **테스트 시나리오**:
/// 1. CompactChip 단독 테스트 (선택/미선택/비활성화)
/// 2. MultiSelectPopover 기본 동작 (역할/그룹/학년)
/// 3. 모바일 반응형 (900px 미만 BottomSheet)
/// 4. 선택 개수 표시 및 Draft-Commit 패턴
class MultiSelectPopoverDemoPage extends StatefulWidget {
  const MultiSelectPopoverDemoPage({super.key});

  @override
  State<MultiSelectPopoverDemoPage> createState() =>
      _MultiSelectPopoverDemoPageState();
}

class _MultiSelectPopoverDemoPageState
    extends State<MultiSelectPopoverDemoPage> {
  // Sample data
  final List<String> roles = ['그룹장', '교수', '멤버', '조교', '게스트'];
  final List<String> groups = [
    'AI학회',
    '알고리즘 스터디',
    'UX디자인',
    '데이터 분석',
    '웹 개발',
    '모바일 앱',
  ];
  final List<String> grades = ['1학년', '2학년', '3학년', '4학년'];

  // Selected items
  List<String> selectedRoles = [];
  List<String> selectedGroups = [];
  List<String> selectedGrades = [];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버 필터 데모'),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 실제 사용 시나리오 (멤버 필터)
            _buildSectionTitle('멤버 필터 (실제 사용 시나리오)'),
            const SizedBox(height: AppSpacing.sm),
            _buildMemberFilterSection(),
            const SizedBox(height: AppSpacing.lg),

            // 선택 요약
            _buildSelectionSummary(),
            const SizedBox(height: AppSpacing.lg),

            // 컴포넌트 테스트
            ExpansionTile(
              title: Text(
                '컴포넌트 단독 테스트 (개발자용)',
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              initiallyExpanded: false,
              children: [
                const SizedBox(height: AppSpacing.sm),
                _buildCompactChipDemo(),
                const SizedBox(height: AppSpacing.md),
                _buildMultiSelectDemo(),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 섹션 타이틀
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.headlineSmall.copyWith(
        color: AppColors.brand,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 멤버 필터 섹션 (실제 사용 시나리오)
  Widget _buildMemberFilterSection() {
    final hasSelection =
        selectedRoles.isNotEmpty ||
        selectedGroups.isNotEmpty ||
        selectedGrades.isNotEmpty;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.filter_list, size: 20, color: AppColors.brand),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '멤버 필터링',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (hasSelection)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedRoles.clear();
                        selectedGroups.clear();
                        selectedGrades.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('초기화'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // 필터 버튼들 (Wrap)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                MultiSelectPopover<String>(
                  label: '역할',
                  items: roles,
                  selectedItems: selectedRoles,
                  itemLabel: (role) => role,
                  onChanged: (selected) {
                    setState(() {
                      selectedRoles = selected;
                    });
                  },
                ),
                MultiSelectPopover<String>(
                  label: '그룹',
                  items: groups,
                  selectedItems: selectedGroups,
                  itemLabel: (group) => group,
                  onChanged: (selected) {
                    setState(() {
                      selectedGroups = selected;
                    });
                  },
                ),
                MultiSelectPopover<String>(
                  label: '학년',
                  items: grades,
                  selectedItems: selectedGrades,
                  itemLabel: (grade) => grade,
                  onChanged: (selected) {
                    setState(() {
                      selectedGrades = selected;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// CompactChip 단독 테스트
  Widget _buildCompactChipDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CompactChip 상태별 예시',
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 미선택 상태
            _buildChipRow('미선택', [
              CompactChip(label: '그룹장', selected: false, onTap: () {}),
              CompactChip(label: '교수', selected: false, onTap: () {}),
              CompactChip(label: '멤버', selected: false, onTap: () {}),
            ]),

            const SizedBox(height: AppSpacing.sm),

            // 선택 상태
            _buildChipRow('선택', [
              CompactChip(label: '그룹장', selected: true, onTap: () {}),
              CompactChip(label: '교수', selected: true, onTap: () {}),
              CompactChip(label: '멤버', selected: false, onTap: () {}),
            ]),

            const SizedBox(height: AppSpacing.sm),

            // 비활성화 상태
            _buildChipRow('비활성화', [
              CompactChip(
                label: '그룹장',
                selected: false,
                onTap: () {},
                enabled: false,
              ),
              CompactChip(
                label: '교수',
                selected: true,
                onTap: () {},
                enabled: false,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  /// 칩 행 (라벨 + 칩들)
  Widget _buildChipRow(String label, List<Widget> chips) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: chips,
          ),
        ),
      ],
    );
  }

  /// MultiSelectPopover 테스트
  Widget _buildMultiSelectDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MultiSelectPopover 필터 바',
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 필터 바
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                MultiSelectPopover<String>(
                  label: '역할',
                  items: roles,
                  selectedItems: selectedRoles,
                  itemLabel: (role) => role,
                  onChanged: (selected) {
                    setState(() {
                      selectedRoles = selected;
                    });
                  },
                ),
                MultiSelectPopover<String>(
                  label: '그룹',
                  items: groups,
                  selectedItems: selectedGroups,
                  itemLabel: (group) => group,
                  onChanged: (selected) {
                    setState(() {
                      selectedGroups = selected;
                    });
                  },
                ),
                MultiSelectPopover<String>(
                  label: '학년',
                  items: grades,
                  selectedItems: selectedGrades,
                  itemLabel: (grade) => grade,
                  onChanged: (selected) {
                    setState(() {
                      selectedGrades = selected;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 선택 요약
  Widget _buildSelectionSummary() {
    final hasSelection =
        selectedRoles.isNotEmpty ||
        selectedGroups.isNotEmpty ||
        selectedGrades.isNotEmpty;

    return Card(
      color: hasSelection ? AppColors.brandLight.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasSelection ? Icons.check_circle : Icons.info_outline,
                  size: 20,
                  color: hasSelection ? AppColors.brand : AppColors.neutral600,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  hasSelection ? '선택된 필터' : '필터를 선택하세요',
                  style: AppTheme.titleMedium.copyWith(
                    color: hasSelection
                        ? AppColors.brand
                        : AppColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (hasSelection)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedRoles.clear();
                        selectedGroups.clear();
                        selectedGrades.clear();
                      });
                    },
                    child: const Text('모두 지우기'),
                  ),
              ],
            ),

            if (hasSelection) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              if (selectedRoles.isNotEmpty)
                _buildSelectionItem('역할', selectedRoles),
              if (selectedGroups.isNotEmpty)
                _buildSelectionItem('그룹', selectedGroups),
              if (selectedGrades.isNotEmpty)
                _buildSelectionItem('학년', selectedGrades),
            ],
          ],
        ),
      ),
    );
  }

  /// 선택 항목 표시
  Widget _buildSelectionItem(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item,
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
