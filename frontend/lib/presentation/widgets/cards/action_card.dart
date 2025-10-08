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
///
/// ActionCard(
///   icon: Icons.delete,
///   title: '그룹 삭제',
///   description: '그룹을 영구적으로 삭제합니다',
///   isDestructive: true,
///   onTap: () => confirmDelete(),
/// )
/// ```
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final bool isDestructive;
  final bool showChevron;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.semanticsLabel,
    this.isDestructive = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDestructive
        ? AppColors.error.withValues(alpha: 0.05)
        : AppColors.neutral100;
    final iconColor = isDestructive ? AppColors.error : AppColors.action;
    final titleColor = isDestructive ? AppColors.error : AppColors.neutral900;

    return Semantics(
      button: true,
      label: semanticsLabel ?? '$title. $description',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isDestructive
                  ? AppColors.error.withValues(alpha: 0.2)
                  : AppColors.neutral300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.titleLargeTheme(context).copyWith(
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTheme.bodySmallTheme(context).copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.neutral400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}