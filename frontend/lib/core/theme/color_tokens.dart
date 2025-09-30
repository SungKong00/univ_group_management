import 'package:flutter/material.dart';

/// 원시 컬러 토큰 (Raw Color Tokens)
///
/// color-guide.md 기준 학교 공식 색상 시스템
/// 이 파일의 값들은 디자인 가이드와 1:1 매핑되며, 직접 사용하지 않고
/// app_colors.dart의 시맨틱 컬러를 통해 접근합니다.
///
/// 참조: docs/ui-ux/concepts/color-guide.md
class ColorTokens {
  ColorTokens._(); // 인스턴스 생성 방지

  // ========== Brand Colors ==========
  /// 메인 퍼플 (학교 공식 색상 Pantone 2597 CVC)
  /// 용도: 로고, 브랜드 아이덴티티, 포인트
  static const Color brandPurple = Color(0xFF5C068C);

  // ========== Action Colors ==========
  /// 하이라이트 블루 (Primary Action)
  /// 용도: 가장 중요한 CTA 버튼, 링크, 활성 탭
  static const Color actionBlue = Color(0xFF1E6FFF);

  /// 하이라이트 블루 Hover 상태
  static const Color actionBlueHover = Color(0xFF3B87FF);

  // ========== Feedback Colors ==========
  /// 민트 그린 (Success / Positive)
  /// 용도: 성공 피드백, 새 콘텐츠 뱃지
  static const Color successMint = Color(0xFF00D9B2);

  /// 에너제틱 레드 (Danger / Alert)
  /// 용도: 오류, 경고, 파괴적 액션 (삭제 등)
  static const Color dangerRed = Color(0xFFE63946);

  // ========== Neutral Colors (Light Mode) ==========
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralBlack = Color(0xFF121212);

  /// 기본 텍스트 (Light Mode)
  static const Color neutral900 = Color(0xFF121212);

  /// 보조 텍스트/경계 (Light Mode)
  static const Color neutral700 = Color(0xFF6C757D);

  /// Disabled 텍스트 (Light Mode)
  static const Color neutral500 = Color(0xFFADB5BD);

  /// Disabled 배경, 경계선 (Light Mode)
  static const Color neutral300 = Color(0xFFE9ECEF);

  /// 배경 보조 (Light Mode)
  static const Color neutral100 = Color(0xFFF8FAFC);

  // ========== Neutral Colors (Dark Mode) ==========
  /// 리치 블랙 (Primary Surface - Dark Mode)
  static const Color darkSurface = Color(0xFF121212);

  /// 서피스 엘리베이트 (카드/패널 배경 - Dark Mode)
  static const Color darkElevated = Color(0xFF1A1A1A);

  /// 쿨 그레이 (보조 텍스트 - Dark Mode)
  static const Color darkGray = Color(0xFFABB8C3);

  /// Disabled 배경 (Dark Mode)
  static const Color darkDisabledBg = Color(0xFF343A40);

  /// Disabled 텍스트 (Dark Mode)
  static const Color darkDisabledText = Color(0xFF6C757D);

  // ========== Google Button Colors (Brand Guidelines) ==========
  /// Google 버튼 텍스트 (Light Mode) - Google 공식 가이드라인
  static const Color googleTextLight = Color(0xFF1F1F1F);

  /// Google 버튼 경계선 (Light Mode) - Material Design 3 스타일
  /// 부드럽고 자연스러운 경계선으로 시각적 계층 개선
  static const Color googleBorderLight = Color(0xFFDADCE0);

  /// Google 버튼 배경 (Dark Mode) - Google 공식 가이드라인
  static const Color googleBgDark = Color(0xFF131314);

  /// Google 버튼 경계선 (Dark Mode) - Material Design 3 스타일
  /// 다크 모드에서 자연스러운 경계선
  static const Color googleBorderDark = Color(0xFF5F6368);

  /// Google 버튼 텍스트 (Dark Mode) - Google 공식 가이드라인
  static const Color googleTextDark = Color(0xFFE3E3E3);
}