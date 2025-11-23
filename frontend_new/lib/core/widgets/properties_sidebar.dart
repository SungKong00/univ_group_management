import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/sidebar_colors.dart';
import '../theme/enums.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

// Export sidebar style for convenience
export '../theme/enums.dart' show SidebarStyle;

/// 속성 사이드바 (Properties Sidebar)
///
/// **기능**:
/// - 이슈 속성 표시 (Status, Priority, Assignee, Labels)
/// - 각 속성별 편집 버튼
/// - 섹션 구분선
/// - 반응형 너비 조절
///
/// **사용 예시**:
/// ```dart
/// PropertiesSidebar(
///   style: SidebarStyle.default_,
///   properties: [
///     SidebarProperty(label: 'Status', value: 'In Progress', icon: Icons.check),
///     SidebarProperty(label: 'Priority', value: 'High', icon: Icons.priority_high),
///   ],
///   onEditPressed: (property) => print(property),
/// )
/// ```
class SidebarProperty {
  final String label;
  final String value;
  final IconData? icon;
  final Function()? onEdit;

  const SidebarProperty({
    required this.label,
    required this.value,
    this.icon,
    this.onEdit,
  });
}

class PropertiesSidebar extends StatelessWidget {
  /// 사이드바 스타일
  final SidebarStyle style;

  /// 속성 리스트
  final List<SidebarProperty> properties;

  /// 섹션 제목 (옵션)
  final String? sectionTitle;

  const PropertiesSidebar({
    super.key,
    required this.style,
    required this.properties,
    this.sectionTitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacing = context.appSpacing;
    final width = MediaQuery.sizeOf(context).width;

    // ========================================================
    // Step 1: 스타일에 따른 색상 결정
    // ========================================================
    final sidebarColors = switch (style) {
      SidebarStyle.default_ => SidebarColors.default_(colorExt),
      SidebarStyle.dark => SidebarColors.dark(colorExt),
      SidebarStyle.compact => SidebarColors.compact(colorExt),
    };

    final sidebarWidth = 280.0; // Fixed sidebar width
    final itemSpacing = ResponsiveTokens.cardPadding(width);

    // ========================================================
    // Step 2: 속성 아이템 빌드
    // ========================================================
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: sidebarColors.background,
        borderRadius: BorderRadius.circular(
          ResponsiveTokens.componentBorderRadius(width),
        ),
        border: Border.all(
          color: sidebarColors.divider,
          width: BorderTokens.widthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 섹션 제목
          if (sectionTitle != null)
            Padding(
              padding: EdgeInsets.all(itemSpacing),
              child: Text(
                sectionTitle!,
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: sidebarColors.sectionTitle,
                    ) ??
                    TextStyle(color: sidebarColors.sectionTitle),
              ),
            ),

          // 속성 리스트
          ...properties.asMap().entries.map((entry) {
            final index = entry.key;
            final property = entry.value;
            final isLast = index == properties.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 속성 아이템
                Padding(
                  padding: EdgeInsets.all(itemSpacing),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.label,
                              style:
                                  Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: sidebarColors.label) ??
                                  TextStyle(color: sidebarColors.label),
                            ),
                            SizedBox(height: spacing.xs),
                            Row(
                              children: [
                                if (property.icon != null) ...[
                                  Icon(
                                    property.icon,
                                    size: ComponentSizeTokens.badgeMedium,
                                    color: sidebarColors.icon,
                                  ),
                                  const SizedBox(width: 6.0),
                                ],
                                Expanded(
                                  child: Text(
                                    property.value,
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          color: sidebarColors.value,
                                        ) ??
                                        TextStyle(color: sidebarColors.value),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // 편집 버튼
                      if (property.onEdit != null)
                        Container(
                          decoration: BoxDecoration(
                            color: sidebarColors.editButtonBg,
                            borderRadius: BorderTokens.smallRadius(),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: property.onEdit,
                              borderRadius: BorderTokens.smallRadius(),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.edit,
                                  size: ComponentSizeTokens.iconXSmall,
                                  color: sidebarColors.editButtonText,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 구분선 (마지막이 아닐 경우)
                if (!isLast)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: itemSpacing),
                    child: Divider(color: sidebarColors.divider, height: 1),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
