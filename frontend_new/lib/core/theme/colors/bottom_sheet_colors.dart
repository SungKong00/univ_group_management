import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// BottomSheet 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class BottomSheetColors {
  /// 배경 색상
  final Color background;

  /// 드래그 핸들 색상
  final Color dragHandle;

  /// 테두리 색상
  final Color border;

  /// 오버레이 색상 (모달용)
  final Color overlay;

  const BottomSheetColors({
    required this.background,
    required this.dragHandle,
    required this.border,
    required this.overlay,
  });

  /// Type별 팩토리 메서드
  factory BottomSheetColors.from(AppColorExtension c, AppBottomSheetType type) {
    return switch (type) {
      AppBottomSheetType.modal => BottomSheetColors(
        background: c.surfaceSecondary,
        dragHandle: c.borderSecondary,
        border: c.borderPrimary,
        overlay: c.overlayScrim,
      ),
      AppBottomSheetType.persistent => BottomSheetColors(
        background: c.surfaceSecondary,
        dragHandle: c.borderSecondary,
        border: c.borderPrimary,
        overlay: Colors.transparent,
      ),
    };
  }
}
