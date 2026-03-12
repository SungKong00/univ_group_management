import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/error_state_colors.dart';
import '../theme/enums.dart';
import '../theme/responsive_tokens.dart';
import 'app_button.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppErrorStateType;

/// 에러 상태를 표시하는 ErrorState 컴포넌트
///
/// **용도**: 네트워크 에러, 서버 에러, 권한 없음 등 에러 상황 표시
/// **접근성**: 스크린 리더에 에러 상태 설명 제공
///
/// ```dart
/// // 일반 에러
/// AppErrorState(
///   title: '오류가 발생했습니다',
///   description: '잠시 후 다시 시도해 주세요.',
///   onRetry: () => _reload(),
/// )
///
/// // 네트워크 에러
/// AppErrorState.network(
///   onRetry: () => _reload(),
/// )
///
/// // 권한 없음 에러
/// AppErrorState.unauthorized(
///   onGoBack: () => Navigator.pop(context),
/// )
/// ```
class AppErrorState extends StatelessWidget {
  /// 제목
  final String title;

  /// 설명 (선택)
  final String? description;

  /// 에러 코드 (선택, 개발자용)
  final String? errorCode;

  /// 아이콘
  final IconData? icon;

  /// 커스텀 일러스트레이션 위젯
  final Widget? illustration;

  /// 재시도 버튼 라벨
  final String retryLabel;

  /// 재시도 콜백
  final VoidCallback? onRetry;

  /// 보조 액션 라벨 (뒤로가기, 홈으로 등)
  final String? secondaryActionLabel;

  /// 보조 액션 콜백
  final VoidCallback? onSecondaryAction;

  /// 에러 타입
  final AppErrorStateType type;

  /// 컴팩트 모드 (패딩 축소)
  final bool isCompact;

  /// 에러 코드 표시 여부
  final bool showErrorCode;

  const AppErrorState({
    super.key,
    required this.title,
    this.description,
    this.errorCode,
    this.icon,
    this.illustration,
    this.retryLabel = '다시 시도',
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.type = AppErrorStateType.general,
    this.isCompact = false,
    this.showErrorCode = false,
  });

  /// 네트워크 에러 팩토리
  factory AppErrorState.network({
    Key? key,
    VoidCallback? onRetry,
    String? errorCode,
    bool isCompact = false,
    bool showErrorCode = false,
  }) {
    return AppErrorState(
      key: key,
      title: '네트워크 연결 오류',
      description: '인터넷 연결을 확인하고 다시 시도해 주세요.',
      icon: Icons.wifi_off_outlined,
      type: AppErrorStateType.network,
      onRetry: onRetry,
      errorCode: errorCode,
      isCompact: isCompact,
      showErrorCode: showErrorCode,
    );
  }

  /// 서버 에러 팩토리
  factory AppErrorState.server({
    Key? key,
    VoidCallback? onRetry,
    String? errorCode,
    bool isCompact = false,
    bool showErrorCode = false,
  }) {
    return AppErrorState(
      key: key,
      title: '서버 오류',
      description: '서버에 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.',
      icon: Icons.cloud_off_outlined,
      type: AppErrorStateType.server,
      onRetry: onRetry,
      errorCode: errorCode,
      isCompact: isCompact,
      showErrorCode: showErrorCode,
    );
  }

  /// 권한 없음 에러 팩토리
  factory AppErrorState.unauthorized({
    Key? key,
    VoidCallback? onGoBack,
    VoidCallback? onLogin,
    bool isCompact = false,
  }) {
    return AppErrorState(
      key: key,
      title: '접근 권한이 없습니다',
      description: '이 페이지에 접근할 권한이 없습니다.',
      icon: Icons.lock_outline,
      type: AppErrorStateType.unauthorized,
      retryLabel: onLogin != null ? '로그인' : '다시 시도',
      onRetry: onLogin,
      secondaryActionLabel: onGoBack != null ? '돌아가기' : null,
      onSecondaryAction: onGoBack,
      isCompact: isCompact,
    );
  }

  /// 찾을 수 없음 에러 팩토리
  factory AppErrorState.notFound({
    Key? key,
    VoidCallback? onGoHome,
    VoidCallback? onGoBack,
    bool isCompact = false,
  }) {
    return AppErrorState(
      key: key,
      title: '페이지를 찾을 수 없습니다',
      description: '요청하신 페이지가 존재하지 않거나 삭제되었습니다.',
      icon: Icons.search_off_outlined,
      type: AppErrorStateType.notFound,
      retryLabel: '홈으로 이동',
      onRetry: onGoHome,
      secondaryActionLabel: onGoBack != null ? '이전 페이지' : null,
      onSecondaryAction: onGoBack,
      isCompact: isCompact,
    );
  }

  /// 시간 초과 에러 팩토리
  factory AppErrorState.timeout({
    Key? key,
    VoidCallback? onRetry,
    String? errorCode,
    bool isCompact = false,
    bool showErrorCode = false,
  }) {
    return AppErrorState(
      key: key,
      title: '요청 시간 초과',
      description: '응답 시간이 초과되었습니다. 다시 시도해 주세요.',
      icon: Icons.timer_off_outlined,
      type: AppErrorStateType.timeout,
      onRetry: onRetry,
      errorCode: errorCode,
      isCompact: isCompact,
      showErrorCode: showErrorCode,
    );
  }

  /// 일반 에러 팩토리
  factory AppErrorState.general({
    Key? key,
    String title = '오류가 발생했습니다',
    String? description,
    VoidCallback? onRetry,
    String? errorCode,
    bool isCompact = false,
    bool showErrorCode = false,
  }) {
    return AppErrorState(
      key: key,
      title: title,
      description: description ?? '잠시 후 다시 시도해 주세요.',
      icon: Icons.error_outline,
      type: AppErrorStateType.general,
      onRetry: onRetry,
      errorCode: errorCode,
      isCompact: isCompact,
      showErrorCode: showErrorCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final colors = ErrorStateColors.from(colorExt, type);

    final verticalPadding = isCompact ? spacingExt.large : spacingExt.xxl;
    final horizontalPadding = isCompact ? spacingExt.medium : spacingExt.xl;
    final iconSize = isCompact ? 48.0 : 64.0;

    return Semantics(
      label: '에러: $title. ${description ?? ""}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 일러스트레이션 또는 아이콘
            if (illustration != null)
              illustration!
            else if (icon != null)
              Icon(icon, size: iconSize, color: colors.icon),

            if (illustration != null || icon != null)
              SizedBox(
                height: isCompact ? spacingExt.medium : spacingExt.large,
              ),

            // 제목
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: colors.title,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            // 설명
            if (description != null) ...[
              SizedBox(height: spacingExt.small),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: switch (ResponsiveTokens.getScreenSize(width)) {
                    ScreenSize.xs => width - spacingExt.xl,
                    ScreenSize.sm => 320.0,
                    ScreenSize.md => 360.0,
                    ScreenSize.lg => 400.0,
                    ScreenSize.xl => 440.0,
                  },
                ),
                child: Text(
                  description!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.description,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // 에러 코드
            if (showErrorCode && errorCode != null) ...[
              SizedBox(height: spacingExt.small),
              Text(
                '에러 코드: $errorCode',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.errorCode,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // 재시도 버튼
            if (onRetry != null) ...[
              SizedBox(
                height: isCompact ? spacingExt.medium : spacingExt.large,
              ),
              AppButton(
                text: retryLabel,
                variant: AppButtonVariant.primary,
                size: isCompact ? AppButtonSize.small : AppButtonSize.medium,
                onPressed: onRetry,
              ),
            ],

            // 보조 액션 버튼
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              SizedBox(height: spacingExt.small),
              AppButton(
                text: secondaryActionLabel!,
                variant: AppButtonVariant.ghost,
                size: isCompact ? AppButtonSize.small : AppButtonSize.medium,
                onPressed: onSecondaryAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
