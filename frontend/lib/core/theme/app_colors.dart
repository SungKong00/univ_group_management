import 'package:flutter/material.dart';
import 'color_tokens.dart';

/// 시맨틱 컬러 시스템 (Semantic Colors)
///
/// 다크모드 지원을 위한 추상화 레이어
/// ColorTokens의 원시 값을 역할 기반으로 재정의하여,
/// 향후 테마 전환 시 자동으로 올바른 컬러가 적용되도록 합니다.
///
/// 사용법:
/// ```dart
/// // 정적 사용
/// Container(color: AppColors.brand)
///
/// // 컨텍스트 기반 (테마 자동 대응)
/// Container(color: context.surface)
/// ```
class AppColors {
  AppColors._(); // 인스턴스 생성 방지

  // ========== Brand Colors ==========
  /// 브랜드 메인 컬러 (학교 공식 퍼플)
  /// 용도: 로고, 브랜드 아이덴티티, 포커스 링
  static const Color brand = ColorTokens.brandPurple;

  /// 브랜드 강조 컬러 (진한 퍼플)
  /// 용도: Hover, Active 상태
  static const Color brandStrong = ColorTokens.brandStrong;

  /// 브랜드 연한 컬러 (연한 퍼플)
  /// 용도: 톤 컨테이너, 칩 배경, 강조 배경
  static const Color brandLight = ColorTokens.brandLight;

  // ========== Action Colors ==========
  /// Primary Action 컬러 (액션 블루)
  /// 용도: 가장 중요한 CTA 버튼, 링크, 활성 상태
  static const Color action = ColorTokens.actionBlue;

  /// Action Hover 상태
  static const Color actionHover = ColorTokens.actionBlueHover;

  /// Action Tonal 배경 (선택/하이라이트 표면)
  static const Color actionTonalBg = ColorTokens.actionTonalBg;

  // ========== Feedback Colors ==========
  /// 성공/긍정 피드백 (그린)
  static const Color success = ColorTokens.successGreen;

  /// 경고 피드백 (옐로우)
  static const Color warning = ColorTokens.warningYellow;

  /// 오류/위험 알림 (레드)
  static const Color error = ColorTokens.errorRed;

  // ========== Light Mode Surface ==========
  /// 라이트 모드 기본 배경
  static const Color lightSurface = ColorTokens.neutralWhite;

  /// 라이트 모드 기본 텍스트
  static const Color lightOnSurface = ColorTokens.neutral900;

  /// 라이트 모드 보조 텍스트
  static const Color lightSecondary = ColorTokens.neutral700;

  /// 라이트 모드 경계선/구분선
  static const Color lightOutline = ColorTokens.neutral300;

  /// 라이트 모드 배경 보조
  static const Color lightBackground = ColorTokens.neutral100;

  // ========== Dark Mode Surface ==========
  /// 다크 모드 기본 배경 (리치 블랙)
  static const Color darkSurface = ColorTokens.darkSurface;

  /// 다크 모드 카드/패널 배경 (서피스 엘리베이트)
  static const Color darkElevated = ColorTokens.darkElevated;

  /// 다크 모드 기본 텍스트 (화이트)
  static const Color darkOnSurface = ColorTokens.neutralWhite;

  /// 다크 모드 보조 텍스트 (쿨 그레이)
  static const Color darkSecondary = ColorTokens.darkGray;

  /// 다크 모드 경계선
  static const Color darkOutline = ColorTokens.darkDisabledBg;

  // ========== Focus & Interaction ==========
  /// 포커스 링 컬러 (브랜드 기반, 45% 투명도)
  static const Color focusRing = Color.fromRGBO(92, 6, 140, 0.45);

  // ========== Disabled States ==========
  /// Disabled 배경 (Light Mode)
  static const Color disabledBgLight = ColorTokens.neutral300;

  /// Disabled 텍스트 (Light Mode)
  static const Color disabledTextLight = ColorTokens.neutral500;

  /// Disabled 배경 (Dark Mode)
  static const Color disabledBgDark = ColorTokens.darkDisabledBg;

  /// Disabled 텍스트 (Dark Mode)
  static const Color disabledTextDark = ColorTokens.darkDisabledText;

  // ========== Brand Container (보조 색상) ==========
  /// 브랜드 컨테이너 (연한 퍼플 - Light Mode)
  static const Color brandContainerLight = Color(0xFFF3E5F5);

  /// 브랜드 컨테이너 (어두운 퍼플 - Dark Mode)
  static const Color brandContainerDark = Color(0xFF3E1A5C);

  // ========== Convenience Aliases (하위 호환성) ==========
  /// 기본 Surface (Light Mode 기본값)
  static const Color surface = lightSurface;

  /// 기본 OnSurface (Light Mode 기본값)
  static const Color onSurface = lightOnSurface;

  /// 기본 Outline (Light Mode 기본값)
  static const Color outline = lightOutline;

  /// Neutral 계열 (ColorTokens 직접 노출)
  static const Color neutral100 = ColorTokens.neutral100;
  static const Color neutral200 = ColorTokens.neutral200;
  static const Color neutral300 = ColorTokens.neutral300;
  static const Color neutral400 = ColorTokens.neutral400;
  static const Color neutral500 = ColorTokens.neutral500;
  static const Color neutral600 = ColorTokens.neutral600;
  static const Color neutral700 = ColorTokens.neutral700;
  static const Color neutral800 = ColorTokens.neutral800;
  static const Color neutral900 = ColorTokens.neutral900;

  /// OnPrimary 편의 속성
  static const Color onPrimary = Colors.white;
}

/// 컨텍스트 기반 컬러 헬퍼 Extension
///
/// 다크모드 자동 대응을 위해 Theme.of(context)를 통해 접근
/// 위젯 내에서 `context.surface`, `context.primary` 형태로 사용
extension AppColorsContext on BuildContext {
  /// 현재 테마의 ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// 현재 테마가 다크 모드인지 확인
  bool get isDarkMode => colorScheme.brightness == Brightness.dark;

  // ========== Surface Colors ==========
  Color get surface => colorScheme.surface;
  Color get onSurface => colorScheme.onSurface;

  // ========== Primary Colors (Brand) ==========
  Color get primary => colorScheme.primary;
  Color get onPrimary => colorScheme.onPrimary;
  Color get primaryContainer => colorScheme.primaryContainer;

  // ========== Secondary Colors (Action) ==========
  Color get secondary => colorScheme.secondary;
  Color get onSecondary => colorScheme.onSecondary;

  // ========== Error Colors ==========
  Color get error => colorScheme.error;
  Color get onError => colorScheme.onError;

  // ========== Outline ==========
  Color get outline => colorScheme.outline;
}
