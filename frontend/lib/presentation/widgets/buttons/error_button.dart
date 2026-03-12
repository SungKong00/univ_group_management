import 'package:flutter/material.dart';

import '../../../core/theme/app_button_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'button_loading_child.dart';

/// 위험한 액션을 위한 에러 톤 버튼 (주로 삭제, 로그아웃 등)
///
/// 토스 디자인 철학 적용:
/// - 명확성: #EF4444 빨간색으로 위험한 액션임을 명확히 표현
/// - 피드백: hover → 진한 빨강(#DC2626), pressed → 더 진한 빨강
/// - 접근성: 포커스 링(보라색), semanticsLabel, 키보드 네비게이션
class ErrorButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? semanticsLabel;
  final double? width;

  const ErrorButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.semanticsLabel,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null && !isLoading;

    final button = Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticsLabel ?? text,
      child: FilledButton(
        style: AppButtonStyles.error(colorScheme),
        onPressed: isEnabled ? onPressed : null,
        child: ButtonLoadingChild(
          text: text,
          isLoading: isLoading,
          textStyle: AppTheme.bodyLargeTheme(
            context,
          ).copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w600),
          indicatorColor: AppColors.onPrimary,
        ),
      ),
    );

    // width가 지정된 경우만 SizedBox로 감싸기
    // Row 내에서 너비 제약 없이 사용 가능하도록 조건부 처리
    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }
}
