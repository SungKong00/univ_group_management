import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/theme.dart';

/// 정보 배너 타입
enum AppInfoBannerType {
  /// 일반 정보 (파란색 - AppColors.action)
  info,

  /// 경고 (노란색 - AppColors.warning)
  warning,

  /// 오류 (빨간색 - AppColors.error)
  error,

  /// 성공 (초록색 - AppColors.success)
  success,
}

/// 통합 정보 배너 컴포넌트
///
/// 사용자에게 정보, 경고, 에러, 성공 메시지를 일관된 스타일로 전달합니다.
/// 타입별 factory constructor를 제공하여 편리하게 사용할 수 있습니다.
///
/// 사용 예시:
/// ```dart
/// // 기본 정보 배너
/// AppInfoBanner(message: '이 작업은 되돌릴 수 없습니다.')
///
/// // 경고 배너
/// AppInfoBanner.warning(message: '주의가 필요합니다.')
///
/// // 에러 배너
/// AppInfoBanner.error(message: '오류가 발생했습니다.')
///
/// // 성공 배너
/// AppInfoBanner.success(message: '성공적으로 완료되었습니다.')
/// ```
class AppInfoBanner extends StatelessWidget {
  /// 표시할 메시지 (필수)
  final String message;

  /// 배너 타입 (기본값: info)
  final AppInfoBannerType type;

  /// 커스텀 아이콘 (null이면 타입별 기본 아이콘 사용)
  final IconData? icon;

  /// 액션 버튼 (선택 사항)
  final Widget? action;

  /// 닫기 버튼 표시 여부
  final bool showCloseButton;

  /// 닫기 버튼 클릭 콜백
  final VoidCallback? onClose;

  const AppInfoBanner({
    super.key,
    required this.message,
    this.type = AppInfoBannerType.info,
    this.icon,
    this.action,
    this.showCloseButton = false,
    this.onClose,
  });

  /// 경고 배너 생성자
  factory AppInfoBanner.warning({
    required String message,
    IconData? icon,
    Widget? action,
    bool showCloseButton = false,
    VoidCallback? onClose,
  }) {
    return AppInfoBanner(
      message: message,
      type: AppInfoBannerType.warning,
      icon: icon,
      action: action,
      showCloseButton: showCloseButton,
      onClose: onClose,
    );
  }

  /// 에러 배너 생성자
  factory AppInfoBanner.error({
    required String message,
    IconData? icon,
    Widget? action,
    bool showCloseButton = false,
    VoidCallback? onClose,
  }) {
    return AppInfoBanner(
      message: message,
      type: AppInfoBannerType.error,
      icon: icon,
      action: action,
      showCloseButton: showCloseButton,
      onClose: onClose,
    );
  }

  /// 성공 배너 생성자
  factory AppInfoBanner.success({
    required String message,
    IconData? icon,
    Widget? action,
    bool showCloseButton = false,
    VoidCallback? onClose,
  }) {
    return AppInfoBanner(
      message: message,
      type: AppInfoBannerType.success,
      icon: icon,
      action: action,
      showCloseButton: showCloseButton,
      onClose: onClose,
    );
  }

  /// 타입별 배경색
  Color get _backgroundColor {
    switch (type) {
      case AppInfoBannerType.info:
        return AppColors.action.withValues(alpha: 0.05);
      case AppInfoBannerType.warning:
        return AppColors.warning.withValues(alpha: 0.05);
      case AppInfoBannerType.error:
        return AppColors.error.withValues(alpha: 0.05);
      case AppInfoBannerType.success:
        return AppColors.success.withValues(alpha: 0.05);
    }
  }

  /// 타입별 경계선 색상
  Color get _borderColor {
    switch (type) {
      case AppInfoBannerType.info:
        return AppColors.action.withValues(alpha: 0.2);
      case AppInfoBannerType.warning:
        return AppColors.warning.withValues(alpha: 0.2);
      case AppInfoBannerType.error:
        return AppColors.error.withValues(alpha: 0.2);
      case AppInfoBannerType.success:
        return AppColors.success.withValues(alpha: 0.2);
    }
  }

  /// 타입별 아이콘/텍스트 색상
  Color get _foregroundColor {
    switch (type) {
      case AppInfoBannerType.info:
        return AppColors.action;
      case AppInfoBannerType.warning:
        return AppColors.warning;
      case AppInfoBannerType.error:
        return AppColors.error;
      case AppInfoBannerType.success:
        return AppColors.success;
    }
  }

  /// 타입별 기본 아이콘
  IconData get _defaultIcon {
    switch (type) {
      case AppInfoBannerType.info:
        return Icons.info_outline;
      case AppInfoBannerType.warning:
        return Icons.warning_amber_outlined;
      case AppInfoBannerType.error:
        return Icons.error_outline;
      case AppInfoBannerType.success:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘
          Icon(icon ?? _defaultIcon, color: _foregroundColor, size: 20),
          const SizedBox(width: AppSpacing.xs),

          // 메시지
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: isDark
                    ? AppColors.darkSecondary
                    : AppColors.lightSecondary,
              ),
            ),
          ),

          // 액션 버튼
          if (action != null) ...[
            const SizedBox(width: AppSpacing.xs),
            action!,
          ],

          // 닫기 버튼
          if (showCloseButton) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: _foregroundColor,
              tooltip: '닫기',
            ),
          ],
        ],
      ),
    );
  }
}
