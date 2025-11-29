import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// EmptyState 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class EmptyStateColors {
  /// 아이콘 색상
  final Color icon;

  /// 제목 색상
  final Color title;

  /// 설명 색상
  final Color description;

  /// 배경 색상 (선택적)
  final Color? background;

  const EmptyStateColors({
    required this.icon,
    required this.title,
    required this.description,
    this.background,
  });

  /// 타입별 팩토리 메서드
  factory EmptyStateColors.from(AppColorExtension c, AppEmptyStateType type) {
    return switch (type) {
      AppEmptyStateType.general => EmptyStateColors(
        icon: c.textTertiary,
        title: c.textPrimary,
        description: c.textSecondary,
      ),
      AppEmptyStateType.search => EmptyStateColors(
        icon: c.stateInfoText,
        title: c.textPrimary,
        description: c.textSecondary,
      ),
      AppEmptyStateType.filter => EmptyStateColors(
        icon: c.stateWarningText,
        title: c.textPrimary,
        description: c.textSecondary,
      ),
      AppEmptyStateType.noData => EmptyStateColors(
        icon: c.textTertiary,
        title: c.textPrimary,
        description: c.textSecondary,
      ),
      AppEmptyStateType.noFavorites => EmptyStateColors(
        icon: c.stateWarningText,
        title: c.textPrimary,
        description: c.textSecondary,
      ),
      AppEmptyStateType.noNotifications => EmptyStateColors(
        icon: c.textTertiary,
        title: c.textPrimary,
        description: c.textSecondary,
      ),
    };
  }
}
