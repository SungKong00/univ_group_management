import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// Avatar 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class AvatarColors {
  /// 기본 배경색 (이미지 없을 때)
  final Color background;

  /// 텍스트/이니셜 색상
  final Color text;

  /// 테두리 색상
  final Color border;

  /// 온라인 상태 표시 색상
  final Color statusIndicator;

  const AvatarColors({
    required this.background,
    required this.text,
    required this.border,
    required this.statusIndicator,
  });

  /// 표준 아바타 색상
  factory AvatarColors.standard(AppColorExtension c) {
    return AvatarColors(
      background: c.surfaceTertiary,
      text: c.textSecondary,
      border: c.borderPrimary,
      statusIndicator: c.stateSuccessText,
    );
  }

  /// 브랜드 강조 아바타 색상
  factory AvatarColors.brand(AppColorExtension c) {
    return AvatarColors(
      background: c.brandPrimary.withValues(alpha: 0.15),
      text: c.brandText,
      border: c.brandPrimary.withValues(alpha: 0.3),
      statusIndicator: c.stateSuccessText,
    );
  }

  /// 상태별 표시 색상
  static Color statusColor(AppColorExtension c, AppAvatarStatus status) {
    return switch (status) {
      AppAvatarStatus.online => c.stateSuccessText,
      AppAvatarStatus.offline => c.textQuaternary,
      AppAvatarStatus.away => c.stateWarningText,
      AppAvatarStatus.busy => c.stateErrorText,
    };
  }

  /// 이니셜 배경색 팔레트 (이름 기반 색상 할당용)
  static List<Color> initialsPalette(AppColorExtension c) {
    return [
      c.brandPrimary.withValues(alpha: 0.15),
      c.stateSuccessBg.withValues(alpha: 0.15),
      c.stateInfoBg.withValues(alpha: 0.15),
      c.stateWarningBg.withValues(alpha: 0.15),
      c.stateErrorBg.withValues(alpha: 0.15),
    ];
  }

  /// 이름 기반 배경색 선택
  static Color backgroundForName(AppColorExtension c, String name) {
    final palette = initialsPalette(c);
    final hash = name.isEmpty ? 0 : name.codeUnits.reduce((a, b) => a + b);
    return palette[hash % palette.length];
  }

  /// 이름 기반 텍스트 색상 선택
  static Color textForName(AppColorExtension c, String name) {
    final hash = name.isEmpty ? 0 : name.codeUnits.reduce((a, b) => a + b);
    final colors = [
      c.brandText,
      c.stateSuccessText,
      c.stateInfoText,
      c.stateWarningText,
      c.stateErrorText,
    ];
    return colors[hash % colors.length];
  }
}
