import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/responsive_tokens.dart';

/// Customer Filter Tabs - 카테고리 필터 탭
class CustomerFilterTabs extends StatelessWidget {
  final List<Map<String, dynamic>> tabs;
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
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveTokens.cardGap(width) * 0.5,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveTokens.pagePadding(width),
        ),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12.0),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final label = tab['label'] as String? ?? '';
          final filter = tab['filter'] as String? ?? '';
          final isSelected = filter == selectedTab;

          return _buildTab(
            context: context,
            label: label,
            isSelected: isSelected,
            onTap: () => onTabSelected(filter),
          );
        },
      ),
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
        duration: const Duration(milliseconds: 200),
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
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
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
