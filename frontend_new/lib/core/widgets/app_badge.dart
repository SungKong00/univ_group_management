import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_typography_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/badge_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/responsive_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppBadgeVariant, AppBadgeColor, AppBadgeSize;

/// 상태, 카운트, 라벨을 표시하는 작은 UI 요소
///
/// **용도**: 알림 개수, 상태 태그, 라벨 표시
/// **접근성**: 최소 높이 보장, Semantics 레이블 제공
///
/// ```dart
/// // 기본 사용
/// AppBadge(label: 'New')
///
/// // 숫자 카운트 (99+ 자동 처리)
/// AppBadge.count(count: 150) // "99+"로 표시
///
/// // 상태 배지
/// AppBadge(
///   label: '완료',
///   color: AppBadgeColor.success,
///   variant: AppBadgeVariant.prominent,
/// )
///
/// // 아이콘 포함
/// AppBadge(
///   label: 'Error',
///   color: AppBadgeColor.error,
///   icon: Icons.error_outline,
/// )
/// ```
class AppBadge extends StatelessWidget {
  /// 배지 텍스트
  final String label;

  /// 배지 스타일 (subtle: 투명 배경, prominent: 색상 배경)
  final AppBadgeVariant variant;

  /// 배지 색상 (success, warning, error, info, neutral, brand)
  final AppBadgeColor color;

  /// 배지 크기 (small, medium)
  final AppBadgeSize size;

  /// 선행 아이콘 (선택)
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.prominent,
    this.color = AppBadgeColor.neutral,
    this.size = AppBadgeSize.medium,
    this.icon,
  });

  /// 숫자 카운트 배지 (99+ 자동 처리)
  ///
  /// ```dart
  /// AppBadge.count(count: 5)   // "5"
  /// AppBadge.count(count: 100) // "99+"
  /// ```
  factory AppBadge.count({
    Key? key,
    required int count,
    AppBadgeVariant variant = AppBadgeVariant.prominent,
    AppBadgeColor color = AppBadgeColor.error,
    AppBadgeSize size = AppBadgeSize.small,
    int maxCount = 99,
  }) {
    final displayCount = count > maxCount ? '$maxCount+' : '$count';
    return AppBadge(
      key: key,
      label: displayCount,
      variant: variant,
      color: color,
      size: size,
    );
  }

  /// 도트 배지 (알림 표시용 작은 점)
  ///
  /// ```dart
  /// AppBadge.dot(color: AppBadgeColor.error)
  /// ```
  factory AppBadge.dot({Key? key, AppBadgeColor color = AppBadgeColor.error}) {
    return _DotBadge(key: key, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final typographyExt = context.appTypography;
    final spacingExt = context.appSpacing;
    final width = MediaQuery.sizeOf(context).width;

    // 색상 팩토리
    final colors = BadgeColors.from(colorExt, variant, color);

    // 사이즈별 스타일
    final (paddingH, paddingV, iconSize) = switch (size) {
      AppBadgeSize.small => (
        spacingExt.small, // 6px의 소수점은 medium(12px)이 맞으니 small(8px) 사용
        spacingExt.xs, // 2px는 없으므로 xs(4px) 사용
        ResponsiveTokens.iconSize(width) - 4, // 기본 아이콘 크기에서 축소
      ),
      AppBadgeSize.medium => (
        spacingExt.medium, // 12px = medium(12px)
        spacingExt.xs, // 4px = xs(4px)
        ResponsiveTokens.iconSize(width), // 기본 아이콘 크기
      ),
    };

    final textStyle = typographyExt.textMicro.copyWith(
      color: colors.text,
      fontWeight: FontWeight.w500,
    );

    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        decoration: BoxDecoration(
          color: colors.background,
          border: variant == AppBadgeVariant.subtle
              ? Border.all(color: colors.border, width: BorderTokens.widthThin)
              : null,
          borderRadius: BorderTokens.smallRadius(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: colors.text),
              SizedBox(width: spacingExt.componentIconGap / 2),
            ],
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }
}

/// 내부 전용: 도트 배지 위젯
class _DotBadge extends AppBadge {
  const _DotBadge({super.key, required super.color})
    : super(
        label: '',
        variant: AppBadgeVariant.prominent,
        size: AppBadgeSize.small,
      );

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = BadgeColors.from(colorExt, variant, color);
    final spacingExt = context.appSpacing;

    // 도트 배지 크기: xs(4px) + xs(4px) = 8px
    final dotSize = spacingExt.small; // 8px

    return Semantics(
      label: '알림',
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: colors.text, // dot은 text 색상 사용 (더 진함)
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
