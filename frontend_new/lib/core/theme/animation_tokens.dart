import 'package:flutter/material.dart';

/// Animation Design Tokens
///
/// Animation duration과 curve를 중앙화하여 관리합니다.
/// 모든 컴포넌트에서 하드코딩된 Duration과 Curve를 제거하고 이 토큰을 사용하도록 통일합니다.
class AnimationTokens {
  AnimationTokens._();

  // ============================================================
  // Animation Duration
  // ============================================================

  /// 빠른 애니메이션 (150ms)
  /// 사용: 빠른 피드백이 필요한 UI 인터랙션 (버튼 호버, 아이콘 변경, 토글)
  static const Duration durationQuick = Duration(milliseconds: 150);

  /// 표준 애니메이션 (200ms)
  /// 사용: 일반적인 UI 전환 (모달 오픈, 탭 전환, 리스트 스크롤)
  static const Duration durationStandard = Duration(milliseconds: 200);

  /// 부드러운 애니메이션 (250ms)
  /// 사용: 큰 변화나 강조 애니메이션 (페이지 전환, 확대/축소, 슬라이드)
  static const Duration durationSmooth = Duration(milliseconds: 250);

  // ============================================================
  // Animation Curve (Easing Function)
  // ============================================================

  /// 기본 출력 곡선 (easeOutCubic)
  /// 사용: 일반적인 UI 애니메이션의 표준 곡선
  static const Curve curveDefault = Curves.easeOutCubic;

  /// 부드러운 출력 곡선 (easeOut)
  /// 사용: 긴 애니메이션이나 페이지 전환
  static const Curve curveSmooth = Curves.easeOut;

  /// In-Out 곡선 (easeInOut)
  /// 사용: 슬라이드 애니메이션, 높이/너비 변경
  static const Curve curveSlide = Curves.easeInOut;

  /// 탄성 곡선 (elasticOut)
  /// 사용: 주목할 만한 엠파시스 애니메이션
  static const Curve curveElastic = Curves.elasticOut;

  // ============================================================
  // Predefined Animation Combinations
  // ============================================================

  /// 빠른 기본 애니메이션
  static const Duration fastDuration = durationQuick;
  static const Curve fastCurve = curveDefault;

  /// 표준 기본 애니메이션
  static const Duration standardDuration = durationStandard;
  static const Curve standardCurve = curveDefault;

  /// 부드러운 기본 애니메이션
  static const Duration smoothDuration = durationSmooth;
  static const Curve smoothCurve = curveSmooth;
}
