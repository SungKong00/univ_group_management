import 'package:flutter/material.dart';

/// 일정별 고유 색상을 생성하는 유틸리티 클래스
class ColorGenerator {
  /// 12개의 구분 가능한 색상 팔레트
  /// 흰색 텍스트와 충분한 대비(WCAG AA 기준 4.5:1)를 확보한 깊은 톤
  static const List<Color> _colorPalette = [
    Color(0xFF5C068C), // Brand Purple (브랜드 컬러)
    Color(0xFFD32F2F), // Red 700
    Color(0xFF1976D2), // Blue 700
    Color(0xFF388E3C), // Green 700
    Color(0xFFF57C00), // Orange 700
    Color(0xFF7B1FA2), // Purple 700
    Color(0xFF00838F), // Teal 700 (was Cyan)
    Color(0xFFC2185B), // Pink 700
    Color(0xFF512DA8), // Deep Purple 700
    Color(0xFF0277BD), // Light Blue 800 (darkened)
    Color(0xFF00695C), // Teal 800
    Color(0xFF5D4037), // Brown 700
  ];

  /// 일정 ID를 기반으로 고유한 색상을 반환
  ///
  /// 같은 ID는 항상 같은 색상을 반환하여 일관성을 보장합니다.
  static Color getColorForSchedule(String? scheduleId) {
    if (scheduleId == null || scheduleId.isEmpty) {
      // ID가 없는 경우 기본 브랜드 컬러 반환
      return _colorPalette[0];
    }

    // 문자열 해시를 사용하여 색상 인덱스 계산
    int hash = 0;
    for (int i = 0; i < scheduleId.length; i++) {
      hash = 31 * hash + scheduleId.codeUnitAt(i);
    }

    // 음수 방지를 위해 절대값 사용
    final index = hash.abs() % _colorPalette.length;
    return _colorPalette[index];
  }

  /// 색상의 밝기를 조정하여 반환
  ///
  /// [factor]가 1.0보다 크면 밝게, 작으면 어둡게 조정됩니다.
  static Color adjustBrightness(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final adjustedLightness = (hsl.lightness * factor).clamp(0.0, 1.0);
    return hsl.withLightness(adjustedLightness).toColor();
  }

  /// 색상에 대한 대비 텍스트 색상 반환 (흰색 또는 검정색)
  static Color getContrastTextColor(Color backgroundColor) {
    // 색상의 밝기 계산 (W3C 권장 공식)
    final brightness =
        (backgroundColor.red * 299 +
            backgroundColor.green * 587 +
            backgroundColor.blue * 114) /
        1000;

    // 밝기가 128 이상이면 검정색, 이하면 흰색 텍스트 사용
    return brightness > 128 ? Colors.black87 : Colors.white;
  }
}
