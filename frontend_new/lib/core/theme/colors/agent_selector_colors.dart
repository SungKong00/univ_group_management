import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Agent Selector 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class AgentSelectorColors {
  /// 비활성 에이전트 배경
  final Color background;

  /// 활성 에이전트 배경
  final Color backgroundActive;

  /// 호버 시 배경
  final Color backgroundHover;

  /// 테두리
  final Color border;

  /// 활성 에이전트 테두리
  final Color borderActive;

  /// 에이전트 이름 텍스트
  final Color name;

  /// 활성 에이전트 이름 텍스트
  final Color nameActive;

  /// 에이전트 설명 텍스트
  final Color description;

  /// 에이전트 아이콘
  final Color icon;

  /// 활성 에이전트 아이콘
  final Color iconActive;

  const AgentSelectorColors({
    required this.background,
    required this.backgroundActive,
    required this.backgroundHover,
    required this.border,
    required this.borderActive,
    required this.name,
    required this.nameActive,
    required this.description,
    required this.icon,
    required this.iconActive,
  });

  /// 기본 Agent Selector 스타일
  factory AgentSelectorColors.standard(AppColorExtension c) {
    return AgentSelectorColors(
      background: c.surfaceSecondary,
      backgroundActive: c.brandPrimary,
      backgroundHover: c.surfaceHover,
      border: c.borderPrimary,
      borderActive: c.brandPrimary,
      name: c.textPrimary,
      nameActive: c.textOnBrand,
      description: c.textTertiary,
      icon: c.textSecondary,
      iconActive: c.textOnBrand,
    );
  }

  /// Compact Agent Selector 스타일 (작은 크기)
  factory AgentSelectorColors.compact(AppColorExtension c) {
    return AgentSelectorColors(
      background: Colors.transparent,
      backgroundActive: c.overlayMedium,
      backgroundHover: c.overlayLight,
      border: c.borderTertiary,
      borderActive: c.brandPrimary,
      name: c.textSecondary,
      nameActive: c.textPrimary,
      description: c.textQuaternary,
      icon: c.textTertiary,
      iconActive: c.brandPrimary,
    );
  }
}
