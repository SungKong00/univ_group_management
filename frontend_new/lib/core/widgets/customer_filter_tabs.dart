import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../../features/component_showcase/data/models/filter_tab_model.dart';

/// Customer Filter Tabs - 카테고리 필터 탭
class CustomerFilterTabs extends StatelessWidget {
  final List<FilterTab> tabs;
  final String selectedTab;
  final ValueChanged<String> onTabSelected;

  const CustomerFilterTabs({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gap = ResponsiveTokens.cardGap(width);

    // Wrap 레이아웃: 가로로 배치, 넘치면 다음 줄로
    return Wrap(
      spacing: ResponsiveTokens.space12,
      runSpacing: gap * 0.5,
      children: tabs.map((tab) {
        final isSelected = tab.filter == selectedTab;
        return _buildTab(
          context: context,
          label: tab.label,
          isSelected: isSelected,
          onTap: () => onTabSelected(tab.filter),
        );
      }).toList(),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AnimationTokens.durationStandard,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveTokens.cardGap(width),
          vertical: ResponsiveTokens.cardGap(width) * 0.5,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorExt.brandPrimary.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? colorExt.brandPrimary
                : colorExt.borderSecondary,
            width: BorderTokens.widthThin,
          ),
          borderRadius: BorderTokens.roundRadius(),
        ),
        child: Text(
          label,
          style: textTheme.bodyMedium!.copyWith(
            color: isSelected ? colorExt.brandPrimary : colorExt.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
