import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';

/// 빠른 실행 기능을 위한 액션 카드 위젯
///
/// 토스 디자인 철학 적용:
/// - 단순함: 아이콘, 제목, 설명으로 구성된 명확한 구조
/// - 위계: 아이콘 → 제목 → 설명의 시각적 계층
/// - 여백: 일관된 spacing으로 가독성 향상
/// - 피드백: 터치 시 InkWell 효과
///
/// Usage:
/// ```dart
/// ActionCard(
///   icon: Icons.add,
///   title: '그룹 생성',
///   description: '새로운 그룹을 만들어보세요',
///   onTap: () => navigateToCreateGroup(),
/// )
/// ```
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? '$title. $description',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: AppComponents.actionCardIconSize,
                  color: AppColors.action, // 하이라이트 블루 #1E6FFF
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  style: AppTheme.titleLargeTheme(context),
                ),
                const SizedBox(height: AppSpacing.xxs / 2),
                Text(
                  description,
                  style: AppTheme.bodySmallTheme(context).copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}