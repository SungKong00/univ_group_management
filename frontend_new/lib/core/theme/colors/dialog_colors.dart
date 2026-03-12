import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// Dialog 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class DialogColors {
  /// 배경 색상
  final Color background;

  /// 제목 텍스트 색상
  final Color title;

  /// 설명 텍스트 색상
  final Color description;

  /// 테두리 색상
  final Color border;

  /// 스크림 (배경 오버레이) 색상
  final Color scrim;

  /// 닫기 버튼 색상
  final Color closeButton;

  /// 구분선 색상
  final Color divider;

  const DialogColors({
    required this.background,
    required this.title,
    required this.description,
    required this.border,
    required this.scrim,
    required this.closeButton,
    required this.divider,
  });

  /// 기본 다이얼로그 색상
  factory DialogColors.standard(AppColorExtension c) {
    return DialogColors(
      background: c.surfaceSecondary,
      title: c.textPrimary,
      description: c.textSecondary,
      border: c.borderSecondary,
      scrim: c.overlayScrim,
      closeButton: c.textTertiary,
      divider: c.dividerPrimary,
    );
  }

  /// Destructive (삭제 확인 등) 다이얼로그 색상
  factory DialogColors.destructive(AppColorExtension c) {
    return DialogColors(
      background: c.surfaceSecondary,
      title: c.stateErrorText,
      description: c.textSecondary,
      border: c.stateErrorBg.withValues(alpha: 0.3),
      scrim: c.overlayScrim,
      closeButton: c.textTertiary,
      divider: c.dividerPrimary,
    );
  }
}
