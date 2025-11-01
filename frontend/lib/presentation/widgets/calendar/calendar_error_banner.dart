import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../buttons/neutral_outlined_button.dart';

/// 캘린더 에러 배너 (공통 컴포넌트)
///
/// 캘린더 페이지에서 에러 발생 시 표시되는 배너
/// - 에러 메시지와 재시도 버튼 제공
/// - 에러 아이콘과 함께 명확한 시각적 피드백
class CalendarErrorBanner extends StatelessWidget {
  const CalendarErrorBanner({
    required this.message,
    required this.onRetry,
    super.key,
  });

  /// 에러 메시지
  final String message;

  /// 재시도 버튼 핸들러
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: NeutralOutlinedButton(text: '다시 시도', onPressed: onRetry),
          ),
        ],
      ),
    );
  }
}
