import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// ColorPicker 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class ColorPickerColors {
  /// 배경 색상
  final Color background;

  /// 테두리 색상
  final Color border;

  /// 테두리 색상 (선택됨)
  final Color borderSelected;

  /// 체크 아이콘 색상
  final Color checkIcon;

  /// 라벨 텍스트 색상
  final Color labelText;

  /// 비활성화 텍스트 색상
  final Color disabledText;

  /// 팔레트 배경 색상
  final Color paletteBackground;

  /// 슬라이더 트랙 색상
  final Color sliderTrack;

  /// 프리뷰 테두리 색상
  final Color previewBorder;

  /// HEX 입력 배경 색상
  final Color hexInputBackground;

  /// HEX 입력 텍스트 색상
  final Color hexInputText;

  const ColorPickerColors({
    required this.background,
    required this.border,
    required this.borderSelected,
    required this.checkIcon,
    required this.labelText,
    required this.disabledText,
    required this.paletteBackground,
    required this.sliderTrack,
    required this.previewBorder,
    required this.hexInputBackground,
    required this.hexInputText,
  });

  /// 기본 팩토리 메서드
  factory ColorPickerColors.from(AppColorExtension c) {
    return ColorPickerColors(
      background: c.surfaceSecondary,
      border: c.borderSecondary,
      borderSelected: c.brandPrimary,
      checkIcon: Colors.white,
      labelText: c.textPrimary,
      disabledText: c.textQuaternary,
      paletteBackground: c.surfaceTertiary,
      sliderTrack: c.surfaceQuaternary,
      previewBorder: c.borderPrimary,
      hexInputBackground: c.surfaceTertiary,
      hexInputText: c.textPrimary,
    );
  }
}
