import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/activity_item_colors.dart';
import '../theme/enums.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

// Export activity type for convenience
export '../theme/enums.dart' show ActivityType;

/// 활동 아이템 모델
class ActivityItem {
  final ActivityType type;
  final String title;
  final String description;
  final String time;
  final String author;
  final IconData icon;

  const ActivityItem({
    required this.type,
    required this.title,
    required this.description,
    required this.time,
    required this.author,
    required this.icon,
  });
}

/// 활동 섹션 (Activity Log)
///
/// **기능**:
/// - 활동 로그 표시 (댓글, 상태 변경, 담당자 변경, 시스템 이벤트)
/// - 타임라인 스타일 표시
/// - 활동별 색상 구분
/// - 스크롤 가능
///
/// **사용 예시**:
/// ```dart
/// ActivitySection(
///   activities: [
///     ActivityItem(
///       type: ActivityType.comment,
///       title: 'John added a comment',
///       description: 'This issue is now fixed',
///       time: '2 hours ago',
///       author: 'John Doe',
///       icon: Icons.comment,
///     ),
///   ],
/// )
/// ```
class ActivitySection extends StatelessWidget {
  /// 활동 리스트
  final List<ActivityItem> activities;

  /// 섹션 제목
  final String? sectionTitle;

  /// 최대 높이 (스크롤 활성화)
  final double? maxHeight;

  const ActivitySection({
    super.key,
    required this.activities,
    this.sectionTitle,
    this.maxHeight = 400,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacing = context.appSpacing;
    final width = MediaQuery.sizeOf(context).width;

    final itemSpacing = ResponsiveTokens.cardPadding(width);
    final borderRadius = ResponsiveTokens.componentBorderRadius(width);

    // ========================================================
    // Step 1: 활동 리스트 빌드
    // ========================================================
    final content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 섹션 제목
          if (sectionTitle != null)
            Padding(
              padding: EdgeInsets.all(itemSpacing),
              child: Text(
                sectionTitle!,
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorExt.textPrimary,
                    ) ??
                    TextStyle(color: colorExt.textPrimary),
              ),
            ),

          // 활동 타임라인
          Padding(
            padding: EdgeInsets.symmetric(horizontal: itemSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: activities.asMap().entries.map((entry) {
                final activity = entry.value;

                // 활동 타입에 따른 색상
                final activityColors = switch (activity.type) {
                  ActivityType.comment => ActivityItemColors.comment(colorExt),
                  ActivityType.statusChanged => ActivityItemColors.statusChange(
                    colorExt,
                  ),
                  ActivityType.assigned => ActivityItemColors.assigneeChange(
                    colorExt,
                  ),
                  ActivityType.priorityChanged =>
                    ActivityItemColors.priorityChange(colorExt),
                  _ => ActivityItemColors.comment(colorExt),
                };

                return Container(
                  margin: EdgeInsets.only(bottom: itemSpacing),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 타임라인 원형 표시
                      Container(
                        width: ComponentSizeTokens.avatarSmall,
                        height: ComponentSizeTokens.avatarSmall,
                        decoration: BoxDecoration(
                          color: activityColors.iconBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activityColors.timelineColor,
                            width: BorderTokens.widthFocus,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          activity.icon,
                          size: ComponentSizeTokens.iconXSmall,
                          color: activityColors.timelineColor,
                        ),
                      ),

                      SizedBox(width: ComponentSizeTokens.avatarInfoGap),

                      // 활동 내용
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목 + 시간
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    activity.title,
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          color: activityColors.text,
                                          fontWeight: FontWeight.w500,
                                        ) ??
                                        TextStyle(
                                          color: activityColors.text,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: ResponsiveTokens.space8),
                                Text(
                                  activity.time,
                                  style:
                                      Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.copyWith(
                                        color: activityColors.metaText,
                                      ) ??
                                      TextStyle(color: activityColors.metaText),
                                ),
                              ],
                            ),

                            SizedBox(height: spacing.xs),

                            // 설명
                            Text(
                              activity.description,
                              style:
                                  Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: activityColors.text) ??
                                  TextStyle(color: activityColors.text),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(height: spacing.xs),

                            // 작성자
                            Text(
                              activity.author,
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(
                                    color: activityColors.metaText,
                                  ) ??
                                  TextStyle(color: activityColors.metaText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );

    // ========================================================
    // Step 2: 최대 높이 적용
    // ========================================================
    if (maxHeight != null) {
      return Container(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: colorExt.borderSecondary,
            width: BorderTokens.widthThin,
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}
