import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/animation_tokens.dart';
import '../theme/enums.dart';

/// 알림 배지 컴포넌트
///
/// **용도**: 아이콘이나 버튼에 알림 개수 또는 상태 표시
/// **접근성**: Semantics 지원
///
/// ```dart
/// // 숫자 배지
/// AppNotificationBadge(
///   count: 5,
///   child: Icon(Icons.notifications),
/// )
///
/// // 점 배지 (개수 없이)
/// AppNotificationBadge(
///   showDot: true,
///   child: Icon(Icons.mail),
/// )
///
/// // 최대 표시값 설정
/// AppNotificationBadge(
///   count: 150,
///   maxCount: 99,  // "99+" 표시
///   child: Icon(Icons.inbox),
/// )
///
/// // 색상 커스터마이징
/// AppNotificationBadge(
///   count: 3,
///   badgeColor: AppBadgeColor.warning,
///   child: Icon(Icons.warning),
/// )
/// ```
class AppNotificationBadge extends StatelessWidget {
  /// 자식 위젯 (아이콘, 버튼 등)
  final Widget child;

  /// 배지에 표시할 숫자
  final int? count;

  /// 최대 표시 숫자 (초과 시 "99+" 형태)
  final int maxCount;

  /// 점으로만 표시 (숫자 없이)
  final bool showDot;

  /// 배지 표시 여부
  final bool show;

  /// 배지 색상
  final AppBadgeColor badgeColor;

  /// 배지 위치 - 상단
  final double top;

  /// 배지 위치 - 우측
  final double right;

  /// 커스텀 배지 색상
  final Color? customBadgeColor;

  /// 커스텀 텍스트 색상
  final Color? customTextColor;

  const AppNotificationBadge({
    super.key,
    required this.child,
    this.count,
    this.maxCount = 99,
    this.showDot = false,
    this.show = true,
    this.badgeColor = AppBadgeColor.error,
    this.top = -4,
    this.right = -4,
    this.customBadgeColor,
    this.customTextColor,
  });

  bool get _shouldShow {
    if (!show) return false;
    if (showDot) return true;
    return count != null && count! > 0;
  }

  String get _displayText {
    if (showDot || count == null) return '';
    if (count! > maxCount) return '$maxCount+';
    return count.toString();
  }

  Color _getBadgeColor(AppColorExtension colors) {
    if (customBadgeColor != null) return customBadgeColor!;
    return switch (badgeColor) {
      AppBadgeColor.success => colors.stateSuccessBg,
      AppBadgeColor.warning => colors.stateWarningBg,
      AppBadgeColor.error => colors.stateErrorBg,
      AppBadgeColor.info => colors.stateInfoBg,
      AppBadgeColor.neutral => colors.surfaceTertiary,
      AppBadgeColor.brand => colors.brandPrimary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (_shouldShow)
          Positioned(
            top: top,
            right: right,
            child: _Badge(
              text: _displayText,
              showDot: showDot,
              backgroundColor: _getBadgeColor(colorExt),
              textColor: customTextColor ?? Colors.white,
            ),
          ),
      ],
    );
  }
}

/// 배지 위젯
class _Badge extends StatelessWidget {
  final String text;
  final bool showDot;
  final Color backgroundColor;
  final Color textColor;

  const _Badge({
    required this.text,
    required this.showDot,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // 점 배지
    if (showDot) {
      return AnimatedContainer(
        duration: AnimationTokens.durationQuick,
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: 1.5,
          ),
        ),
      );
    }

    // 숫자 배지
    final isShort = text.length <= 2;
    return AnimatedContainer(
      duration: AnimationTokens.durationQuick,
      constraints: BoxConstraints(minWidth: isShort ? 18 : 24, minHeight: 18),
      padding: EdgeInsets.symmetric(horizontal: isShort ? 4 : 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
