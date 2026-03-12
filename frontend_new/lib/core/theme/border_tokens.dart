import 'package:flutter/material.dart';

/// Border Design Tokens
///
/// Border width와 radius의 표준값을 중앙화하여 관리합니다.
/// 모든 컴포넌트에서 하드코딩된 border 값을 제거하고 이 토큰을 사용하도록 통일합니다.
class BorderTokens {
  BorderTokens._();

  // ============================================================
  // Border Width (선 두께)
  // ============================================================

  /// 기본 테두리 너비 (1px)
  /// 사용: 카드, 입력창, 기본 테두리
  static const double widthThin = 1.0;

  /// 포커스/활성 테두리 너비 (2px)
  /// 사용: 포커스된 입력창, 선택된 아이템, 강조 테두리
  static const double widthFocus = 2.0;

  // ============================================================
  // Border Radius (모서리 반경)
  // ============================================================

  /// 작은 모서리 반경 (4px)
  /// 사용: 작은 컴포넌트, 제한적인 공간
  static const double radiusSmall = 4.0;

  /// 기본 모서리 반경 (6px)
  /// 사용: 기본 카드, 버튼, 입력창
  static const double radiusMedium = 6.0;

  /// 중간 모서리 반경 (8px)
  /// 사용: 컨테이너, 토스트, 팝업
  static const double radiusLarge = 8.0;

  /// 큰 모서리 반경 (12px)
  /// 사용: 큰 카드, 모달, 시트
  static const double radiusXL = 12.0;

  /// 더 큰 모서리 반경 (16px)
  /// 사용: 큰 섹션 컨테이너
  static const double radiusXXL = 16.0;

  /// 완전 둥근 모서리 (20px)
  /// 사용: 원형에 가까운 요소, 큰 버튼
  static const double radiusRound = 20.0;

  // ============================================================
  // Border Side Helper
  // ============================================================

  /// 기본 테두리 (1px, semantic color)
  static BorderSide thin(Color color) =>
      BorderSide(color: color, width: widthThin);

  /// 포커스 테두리 (2px, semantic color)
  static BorderSide focus(Color color) =>
      BorderSide(color: color, width: widthFocus);

  // ============================================================
  // BorderRadius Helper
  // ============================================================

  /// 작은 모서리 반경 BorderRadius
  static BorderRadius smallRadius() => BorderRadius.circular(radiusSmall);

  /// 기본 모서리 반경 BorderRadius
  static BorderRadius mediumRadius() => BorderRadius.circular(radiusMedium);

  /// 중간 모서리 반경 BorderRadius
  static BorderRadius largeRadius() => BorderRadius.circular(radiusLarge);

  /// 큰 모서리 반경 BorderRadius
  static BorderRadius xlRadius() => BorderRadius.circular(radiusXL);

  /// 더 큰 모서리 반경 BorderRadius
  static BorderRadius xxlRadius() => BorderRadius.circular(radiusXXL);

  /// 완전 둥근 모서리 BorderRadius
  static BorderRadius roundRadius() => BorderRadius.circular(radiusRound);

  // ============================================================
  // Switch Border Width (Phase 5)
  // ============================================================

  /// 스위치 기본 테두리 너비 (1px)
  /// 사용: 비활성 스위치, 호버 상태
  static const double switchBorderThin = widthThin;

  /// 스위치 포커스 테두리 너비 (2px)
  /// 사용: 포커스된 스위치
  static const double switchBorderFocus = widthFocus;
}
