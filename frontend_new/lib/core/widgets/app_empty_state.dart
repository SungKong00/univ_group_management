import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/empty_state_colors.dart';
import '../theme/enums.dart';
import '../theme/responsive_tokens.dart';
import 'app_button.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppEmptyStateType;

/// 데이터 없음 상태를 표시하는 EmptyState 컴포넌트
///
/// **용도**: 검색 결과 없음, 데이터 없음, 필터 결과 없음 등
/// **접근성**: 스크린 리더에 상태 설명 제공
///
/// ```dart
/// // 기본 빈 상태
/// AppEmptyState(
///   title: '데이터가 없습니다',
///   description: '새 항목을 추가해 보세요.',
///   icon: Icons.inbox_outlined,
/// )
///
/// // 검색 결과 없음
/// AppEmptyState.search(
///   searchQuery: '플러터',
///   onClearSearch: () => _clearSearch(),
/// )
///
/// // 액션 버튼 포함
/// AppEmptyState(
///   title: '그룹이 없습니다',
///   description: '첫 번째 그룹을 만들어 보세요.',
///   icon: Icons.group_add_outlined,
///   actionLabel: '그룹 만들기',
///   onAction: () => _createGroup(),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  /// 제목
  final String title;

  /// 설명 (선택)
  final String? description;

  /// 아이콘 (illustration 없을 때 사용)
  final IconData? icon;

  /// 커스텀 일러스트레이션 위젯
  final Widget? illustration;

  /// 액션 버튼 라벨
  final String? actionLabel;

  /// 액션 버튼 콜백
  final VoidCallback? onAction;

  /// 보조 액션 라벨
  final String? secondaryActionLabel;

  /// 보조 액션 콜백
  final VoidCallback? onSecondaryAction;

  /// 빈 상태 타입
  final AppEmptyStateType type;

  /// 컴팩트 모드 (패딩 축소)
  final bool isCompact;

  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.illustration,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.type = AppEmptyStateType.general,
    this.isCompact = false,
  });

  /// 검색 결과 없음 팩토리
  factory AppEmptyState.search({
    Key? key,
    required String searchQuery,
    VoidCallback? onClearSearch,
    bool isCompact = false,
  }) {
    return AppEmptyState(
      key: key,
      title: '"$searchQuery"에 대한 검색 결과가 없습니다',
      description: '다른 검색어로 시도해 보세요.',
      icon: Icons.search_off_outlined,
      type: AppEmptyStateType.search,
      actionLabel: onClearSearch != null ? '검색 초기화' : null,
      onAction: onClearSearch,
      isCompact: isCompact,
    );
  }

  /// 필터 결과 없음 팩토리
  factory AppEmptyState.filter({
    Key? key,
    VoidCallback? onClearFilter,
    bool isCompact = false,
  }) {
    return AppEmptyState(
      key: key,
      title: '필터 결과가 없습니다',
      description: '필터 조건을 변경해 보세요.',
      icon: Icons.filter_alt_off_outlined,
      type: AppEmptyStateType.filter,
      actionLabel: onClearFilter != null ? '필터 초기화' : null,
      onAction: onClearFilter,
      isCompact: isCompact,
    );
  }

  /// 데이터 없음 팩토리
  factory AppEmptyState.noData({
    Key? key,
    String title = '데이터가 없습니다',
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
    bool isCompact = false,
  }) {
    return AppEmptyState(
      key: key,
      title: title,
      description: description ?? '새 항목을 추가해 보세요.',
      icon: Icons.inbox_outlined,
      type: AppEmptyStateType.noData,
      actionLabel: actionLabel,
      onAction: onAction,
      isCompact: isCompact,
    );
  }

  /// 즐겨찾기 없음 팩토리
  factory AppEmptyState.noFavorites({
    Key? key,
    VoidCallback? onBrowse,
    bool isCompact = false,
  }) {
    return AppEmptyState(
      key: key,
      title: '즐겨찾기가 없습니다',
      description: '관심 있는 항목을 즐겨찾기에 추가해 보세요.',
      icon: Icons.star_outline,
      type: AppEmptyStateType.noFavorites,
      actionLabel: onBrowse != null ? '둘러보기' : null,
      onAction: onBrowse,
      isCompact: isCompact,
    );
  }

  /// 알림 없음 팩토리
  factory AppEmptyState.noNotifications({Key? key, bool isCompact = false}) {
    return AppEmptyState(
      key: key,
      title: '알림이 없습니다',
      description: '새로운 알림이 도착하면 여기에 표시됩니다.',
      icon: Icons.notifications_none_outlined,
      type: AppEmptyStateType.noNotifications,
      isCompact: isCompact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final colors = EmptyStateColors.from(colorExt, type);

    final verticalPadding = isCompact ? spacingExt.large : spacingExt.xxl;
    final horizontalPadding = isCompact ? spacingExt.medium : spacingExt.xl;
    final iconSize = isCompact ? 48.0 : 64.0;

    return Semantics(
      label: '$title. ${description ?? ""}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 일러스트레이션 또는 아이콘
            if (illustration != null)
              illustration!
            else if (icon != null)
              Icon(icon, size: iconSize, color: colors.icon),

            if (illustration != null || icon != null)
              SizedBox(
                height: isCompact ? spacingExt.medium : spacingExt.large,
              ),

            // 제목
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: colors.title,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            // 설명
            if (description != null) ...[
              SizedBox(height: spacingExt.small),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: switch (ResponsiveTokens.getScreenSize(width)) {
                    ScreenSize.xs => width - spacingExt.xl,
                    ScreenSize.sm => 320.0,
                    ScreenSize.md => 360.0,
                    ScreenSize.lg => 400.0,
                    ScreenSize.xl => 440.0,
                  },
                ),
                child: Text(
                  description!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.description,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // 액션 버튼
            if (actionLabel != null && onAction != null) ...[
              SizedBox(
                height: isCompact ? spacingExt.medium : spacingExt.large,
              ),
              AppButton(
                text: actionLabel!,
                variant: AppButtonVariant.primary,
                size: isCompact ? AppButtonSize.small : AppButtonSize.medium,
                onPressed: onAction,
              ),
            ],

            // 보조 액션 버튼
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              SizedBox(height: spacingExt.small),
              AppButton(
                text: secondaryActionLabel!,
                variant: AppButtonVariant.ghost,
                size: isCompact ? AppButtonSize.small : AppButtonSize.medium,
                onPressed: onSecondaryAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
