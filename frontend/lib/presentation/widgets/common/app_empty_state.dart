import 'package:flutter/material.dart';

/// 범용 EmptyState 컴포넌트
///
/// 데이터가 없거나 검색 결과가 없을 때 표시하는 표준 위젯.
/// 아이콘, 메시지, 서브메시지, 액션 버튼을 일관된 스타일로 제공.
class AppEmptyState extends StatelessWidget {
  /// 표시할 아이콘 (선택)
  final IconData? icon;

  /// 메인 메시지
  final String message;

  /// 서브 메시지 (선택)
  final String? subtitle;

  /// 액션 버튼 (선택)
  final Widget? action;

  /// 아이콘 크기 (기본: 64)
  final double iconSize;

  /// 패딩 (기본: EdgeInsets.all(48))
  final EdgeInsets padding;

  const AppEmptyState({
    super.key,
    this.icon,
    required this.message,
    this.subtitle,
    this.action,
    this.iconSize = 64,
    this.padding = const EdgeInsets.all(48),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: iconSize,
                color: colorScheme.onSurface.withOpacity(0.38),
              ),
            if (icon != null) const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.38),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }

  // Factory constructors for common use cases

  /// 일반 데이터 없음
  factory AppEmptyState.noData({
    String message = '데이터가 없습니다',
    String? subtitle,
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.inbox_outlined,
      message: message,
      subtitle: subtitle,
      action: action,
    );
  }

  /// 검색 결과 없음
  factory AppEmptyState.noResults({
    String message = '검색 결과가 없습니다',
    String? subtitle,
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.search_off_outlined,
      message: message,
      subtitle: subtitle,
      action: action,
    );
  }

  /// 댓글 없음
  factory AppEmptyState.noComments({
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.comment_outlined,
      message: '아직 댓글이 없습니다',
      subtitle: '첫 댓글을 작성해보세요',
      action: action,
    );
  }

  /// 게시글 없음
  factory AppEmptyState.noPosts({
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.article_outlined,
      message: '아직 게시글이 없습니다',
      subtitle: '첫 게시글을 작성해보세요',
      action: action,
    );
  }

  /// 그룹 없음
  factory AppEmptyState.noGroups({
    String? message,
    String? subtitle,
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.groups_outlined,
      message: message ?? '가입한 그룹이 없습니다',
      subtitle: subtitle ?? '그룹을 탐색하여 가입해보세요',
      action: action,
    );
  }

  /// 장소 없음
  factory AppEmptyState.noPlaces({
    String? message,
    String? subtitle,
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.place_outlined,
      message: message ?? '사용 가능한 장소가 없습니다',
      subtitle: subtitle,
      action: action,
    );
  }

  /// 멤버 없음
  factory AppEmptyState.noMembers({
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.people_outline,
      message: '멤버가 없습니다',
      action: action,
    );
  }

  /// 모집공고 없음
  factory AppEmptyState.noRecruitments({
    Widget? action,
  }) {
    return AppEmptyState(
      icon: Icons.campaign_outlined,
      message: '모집공고가 없습니다',
      action: action,
    );
  }
}
