import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';

/// Step Header
///
/// 다단계 플로우의 각 단계 제목과 뒤로가기 버튼을 표시하는 헤더 컴포넌트.
///
/// **디자인 원칙:**
/// - Title + Description 패턴: 명확한 단계 제목 + 선택적 부제목
/// - 뒤로가기 버튼: 왼쪽 상단 배치 (선택적)
/// - AppTypography 활용: headlineSmall (제목), bodyMedium (부제목)
///
/// **사용 예시:**
/// ```dart
/// StepHeader(
///   title: '일정 유형 선택',
///   subtitle: '생성할 일정의 종류를 선택해주세요',
///   onBack: () => Navigator.pop(context),
/// )
/// ```
class StepHeader extends StatelessWidget {
  /// 단계 제목 (필수)
  final String title;

  /// 부제목 (선택적)
  final String? subtitle;

  /// 뒤로가기 콜백 (선택적, 없으면 뒤로가기 버튼 미표시)
  final VoidCallback? onBack;

  /// 제목 텍스트 스타일 (기본값: AppTheme.headlineSmall)
  final TextStyle? titleStyle;

  /// 부제목 텍스트 스타일 (기본값: AppTheme.bodyMedium)
  final TextStyle? subtitleStyle;

  const StepHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 뒤로가기 버튼 (있을 경우에만)
        if (onBack != null) ...[
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                tooltip: '뒤로 가기',
                color: AppColors.neutral700,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],
        // 제목
        Text(
          title,
          style: titleStyle ??
              AppTheme.headlineSmall.copyWith(
                color: AppColors.neutral900,
              ),
        ),
        // 부제목 (있을 경우에만)
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: subtitleStyle ??
                AppTheme.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
          ),
        ],
      ],
    );
  }
}
