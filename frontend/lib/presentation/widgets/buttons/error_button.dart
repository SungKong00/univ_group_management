import 'package:flutter/material.dart';

import '../../../core/theme/app_button_styles.dart';
import '../../../core/theme/app_colors.dart';

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

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticsLabel ?? text,
      child: SizedBox(
        width: width,
        child: FilledButton(
          style: AppButtonStyles.error(colorScheme),
          onPressed: isEnabled ? onPressed : null,
          child: _buildChild(),
        ),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
        ),
      );
    }

    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }
}
