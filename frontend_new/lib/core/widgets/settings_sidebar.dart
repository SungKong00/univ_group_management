import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/sidebar_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

// Export sidebar style for convenience
export '../theme/colors/sidebar_colors.dart' show SidebarStyle;

/// 설정 사이드바 아이템 모델
class SettingItem {
  final String label;
  final String description;
  final Widget control; // Toggle, Switch, etc.
  final IconData icon;

  const SettingItem({
    required this.label,
    required this.description,
    required this.control,
    required this.icon,
  });
}

/// 설정 사이드바 (Settings Sidebar)
///
/// **기능**:
/// - 설정 항목 표시 (토글, 드롭다운 등)
/// - 아이콘 지원
/// - 설명 텍스트
/// - 토글/스위치 컨트롤 통합
///
/// **사용 예시**:
/// ```dart
/// SettingsSidebar(
///   style: SidebarStyle.default_,
///   settings: [
///     SettingItem(
///       label: 'Notifications',
///       description: 'Receive notifications',
///       icon: Icons.notifications,
///       control: Switch(value: true, onChanged: (_) {}),
///     ),
///   ],
/// )
/// ```
class SettingsSidebar extends StatelessWidget {
  /// 사이드바 스타일
  final SidebarStyle style;

  /// 설정 아이템 리스트
  final List<SettingItem> settings;

  /// 섹션 제목
  final String? sectionTitle;

  /// 최대 높이 (스크롤 활성화, 옵션)
  final double? maxHeight;

  const SettingsSidebar({
    super.key,
    required this.style,
    required this.settings,
    this.sectionTitle,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
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
    final borderRadius = ResponsiveTokens.componentBorderRadius(width);

    // ========================================================
    // Step 2: 설정 아이템 빌드
    // ========================================================
    final content = SingleChildScrollView(
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

          // 설정 항목 리스트
          ...settings.asMap().entries.map((entry) {
            final index = entry.key;
            final setting = entry.value;
            final isLast = index == settings.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 설정 아이템
                Container(
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(borderRadius / 2),
                      onTap: null, // 컨트롤로 상호작용
                      child: Padding(
                        padding: EdgeInsets.all(itemSpacing),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 아이콘
                            Icon(
                              setting.icon,
                              color: sidebarColors.icon,
                              size: ComponentSizeTokens.iconSmall,
                            ),

                            SizedBox(width: ComponentSizeTokens.avatarInfoGap),

                            // 텍스트 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    setting.label,
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          color: sidebarColors.value,
                                          fontWeight: FontWeight.w500,
                                        ) ??
                                        TextStyle(
                                          color: sidebarColors.value,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    setting.description,
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.labelSmall?.copyWith(
                                          color: sidebarColors.label,
                                        ) ??
                                        TextStyle(color: sidebarColors.label),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12.0),

                            // 컨트롤 (Toggle, Switch, etc.)
                            setting.control,
                          ],
                        ),
                      ),
                    ),
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

    // ========================================================
    // Step 3: 컨테이너로 래핑
    // ========================================================
    return Container(
      width: sidebarWidth,
      constraints: maxHeight != null
          ? BoxConstraints(maxHeight: maxHeight!)
          : const BoxConstraints(),
      decoration: BoxDecoration(
        color: sidebarColors.background,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: sidebarColors.divider,
          width: BorderTokens.widthThin,
        ),
      ),
      child: content,
    );
  }
}
