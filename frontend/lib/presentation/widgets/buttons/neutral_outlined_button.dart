import 'package:flutter/material.dart';

import '../../../core/theme/app_button_styles.dart';
import '../../../core/theme/app_colors.dart';

/// 중립적인 회색 톤의 아웃라인 버튼 (주로 취소 액션에 사용)
///
/// 토스 디자인 철학 적용:
/// - 단순함: 불필요한 장식 제거, 명확한 시각적 위계
/// - 가독성: #E5E7EB 아웃라인, hover 시 시각적 피드백
/// - 접근성: semanticsLabel, 포커스 링, 키보드 네비게이션
class NeutralOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? semanticsLabel;
  final double? width;

  const NeutralOutlinedButton({
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
        child: OutlinedButton(
          style: AppButtonStyles.neutralOutlined(colorScheme),
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
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.neutral600),
        ),
      );
    }

    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }
}
