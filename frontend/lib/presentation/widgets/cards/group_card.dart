import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

/// 그룹 정보를 보여주는 가로 스크롤 카드 위젯
///
/// 토스 디자인 철학 적용:
/// - 단순함: 필수 정보만 표시 (이름, 멤버 수, 상태)
/// - 위계: 아바타 → 그룹명 → 멤버수 → 상태 배지
/// - 여백: 일관된 spacing으로 구조 명확화
/// - 피드백: 터치 시 InkWell 효과
///
/// Usage:
/// ```dart
/// GroupCard(
///   groupName: '컴퓨터공학과',
///   memberCount: 45,
///   isActive: true,
///   avatarText: '컴공',
///   onTap: () => navigateToGroup(groupId),
/// )
/// ```
class GroupCard extends StatelessWidget {
  final String groupName;
  final int memberCount;
  final bool isActive;
  final String avatarText;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  const GroupCard({
    super.key,
    required this.groupName,
    required this.memberCount,
    required this.isActive,
    required this.avatarText,
    this.onTap,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? '$groupName. 멤버 $memberCount명. ${isActive ? '활성 상태' : '비활성 상태'}',
      child: Container(
        width: AppComponents.groupCardWidth,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: AppComponents.avatarSmall,
                        backgroundColor: AppColors.brand,
                        child: Text(
                          avatarText,
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          groupName,
                          style: AppTheme.titleMediumTheme(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '멤버 $memberCount명',
                    style: AppTheme.bodySmallTheme(context).copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs,
                      vertical: AppSpacing.xxs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.brandLight
                          : AppColors.neutral200,
                      borderRadius: BorderRadius.circular(AppComponents.badgeRadius),
                    ),
                    child: Text(
                      isActive ? '활성' : '비활성',
                      style: AppTheme.labelSmallTheme(context).copyWith(
                        color: isActive ? AppColors.brand : AppColors.neutral600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}