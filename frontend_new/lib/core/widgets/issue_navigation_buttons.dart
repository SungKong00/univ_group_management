import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_typography_extension.dart';
import '../theme/responsive_tokens.dart';
import 'app_button.dart';

/// 이슈 네비게이션 버튼 컴포넌트 (이전/다음)
///
/// **기능**:
/// - 이전/다음 이슈로 이동
/// - 끝 도달 시 자동 비활성화
/// - 터치 친화적 버튼 크기
///
/// **사용 예시**:
/// ```dart
/// IssueNavigationButtons(
///   hasPrevious: true,
///   hasNext: true,
///   onPrevious: () => print('Previous'),
///   onNext: () => print('Next'),
/// )
/// ```
class IssueNavigationButtons extends StatelessWidget {
  /// 이전 버튼 활성화 여부
  final bool hasPrevious;

  /// 다음 버튼 활성화 여부
  final bool hasNext;

  /// 이전 버튼 클릭 콜백
  final VoidCallback? onPrevious;

  /// 다음 버튼 클릭 콜백
  final VoidCallback? onNext;

  const IssueNavigationButtons({
    super.key,
    required this.hasPrevious,
    required this.hasNext,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final spacing = ResponsiveTokens.cardGap(width);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ========================================================
        // 이전 버튼
        // ========================================================
        Opacity(
          opacity: hasPrevious ? 1.0 : 0.5,
          child: AppButton(
            text: 'Previous',
            onPressed: hasPrevious ? onPrevious : null,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.medium,
            icon: Icons.arrow_back_ios,
          ),
        ),

        // ========================================================
        // 간격
        // ========================================================
        SizedBox(width: spacing),

        // ========================================================
        // 다음 버튼
        // ========================================================
        Opacity(
          opacity: hasNext ? 1.0 : 0.5,
          child: AppButton(
            text: 'Next',
            onPressed: hasNext ? onNext : null,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.medium,
            icon: Icons.arrow_forward_ios,
          ),
        ),
      ],
    );
  }
}
