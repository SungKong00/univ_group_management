import 'package:flutter/material.dart';
import 'responsive_tokens.dart';
import 'enums.dart';

/// Card Design System Tokens
///
/// 모든 카드 컴포넌트가 준수하는 중앙화된 토큰 시스템
/// - 레이아웃: Padding, Gap, BorderRadius, Shadow
/// - 타이포그래피: 각 요소별 TextStyle
/// - 애니메이션: Duration, Curve
/// - 상태: Hover, Selected, Disabled

/// Card Design Tokens (5-step responsive system)
///
/// 카드 크기는 화면 크기에 따라 다르게 조정됩니다.
/// [GridLayoutTokens]와 연동하여 정확한 열 수를 보장합니다.
class CardDesignTokens {
  CardDesignTokens._();

  // ════════════════════════════════════════════════════════════════════════════
  // 고정 크기 토큰
  // ════════════════════════════════════════════════════════════════════════════

  /// 카드 기본 높이 (WideCard)
  static const double wideCardHeight = 200;

  /// 컴팩트 카드 기본 크기
  static const double compactCardSize = 120;

  /// 이미지 AspectRatio 기본값들
  static const Map<String, double> imageAspectRatios = {
    'vertical': 3 / 4, // VerticalCard
    'horizontal': 4 / 3, // HorizontalCard
    'wide': 21 / 9, // WideCard (배너)
    'compact': 1 / 1, // CompactCard (정사각형)
  };

  /// 아이콘 크기
  static const Map<String, double> iconSizes = {
    'compact': 64, // CompactCard
    'small': 32,
    'medium': 48,
    'large': 64,
  };

  // ════════════════════════════════════════════════════════════════════════════
  // 텍스트 라인 수 제한
  // ════════════════════════════════════════════════════════════════════════════

  /// 텍스트 라인 수 제한 (기본)
  static const Map<String, int> textLineNumbers = {
    'title': 3, // 제목: 3줄 최대
    'subtitle': 2, // 부제목: 2줄 최대
    'description': 3, // 설명: 3줄 최대
    'meta': 1, // 메타: 1줄
  };

  /// 각 요소별 텍스트 줄 수 제한 (카드 타입별 상세)
  static const Map<String, Map<String, int>> textLineNumbersByCard = {
    'vertical': {'meta': 1, 'title': 3, 'subtitle': 2, 'description': 3},
    'horizontal': {'meta': 1, 'title': 2, 'subtitle': 1, 'description': 2},
    'compact': {'meta': 1, 'title': 2},
    'selectable': {'title': 1, 'subtitle': 1},
    'wide': {'title': 2, 'subtitle': 1, 'description': 2},
  };

  // ════════════════════════════════════════════════════════════════════════════
  // 애니메이션 & 상태
  // ════════════════════════════════════════════════════════════════════════════

  /// 애니메이션 설정
  static const Duration hoverAnimationDuration = Duration(milliseconds: 200);
  static const Curve hoverAnimationCurve = Curves.easeInOut;

  /// 배경 오버레이 강도
  static const double wideCardOverlayOpacity = 0.3;

  /// HorizontalCard 이미지 너비 비율
  static const double horizontalImageWidthRatio = 0.4;

  /// 선택 상태 테두리 굵기
  static const double selectedBorderWidth = 2.0;
  static const double normalBorderWidth = 1.0;

  /// Hover/Selected 상태 불투명도
  static const double disabledOpacity = 0.6;
  static const double hoverScale = 1.01;

  /// 카드 높이 비율 (상태별)
  static const Map<CardVariant, double> cardHeightRatios = {
    CardVariant.vertical: 4 / 3, // 3:4 비율
    CardVariant.horizontal: 3 / 4, // 4:3 비율 (높이는 더 짧음)
    CardVariant.compact: 1, // 1:1 (정사각형)
    CardVariant.selectable: 0.35, // 작은 높이 (가로 카드)
    CardVariant.wide: 1, // 고정 높이 사용
  };

  // ════════════════════════════════════════════════════════════════════════════
  // 반응형 카드 크기 (Breakpoint별)
  // ════════════════════════════════════════════════════════════════════════════

  /// 카드 너비 조회 (반응형)
  ///
  /// [cardType] - 카드 종류 ('vertical', 'horizontal', 'compact', 'selectable', 'wide')
  /// [width] - 화면 너비 (px)
  /// 반환값 - {'min': double, 'max': double, 'preferred': double}
  ///
  /// 주의: 이 메서드보다 [GridLayoutTokens.forCardType]을 사용하는 것이 권장됩니다.
  /// GridLayoutTokens는 열 수까지 고려한 더 정확한 계산을 제공합니다.
  static Map<String, double> getCardWidths(String cardType, double width) {
    final screenSize = ResponsiveTokens.getScreenSize(width);
    return _cardWidthsByBreakpoint[cardType]![screenSize]!;
  }

  /// Breakpoint별 카드 크기 테이블
  ///
  /// 각 breakpoint에서 카드 타입별 min/max/preferred 크기를 정의합니다.
  /// GridLayoutTokens의 열 수 계산과 연동됩니다.
  /// 모든 값은 8px 그리드 시스템을 따릅니다.
  static const Map<String, Map<ScreenSize, Map<String, double>>>
  _cardWidthsByBreakpoint = {
    'vertical': {
      ScreenSize.xs: {
        'min': 280,
        'max': 400,
        'preferred': 320,
      }, // 35×8, 50×8, 40×8
      ScreenSize.sm: {
        'min': 200,
        'max': 320,
        'preferred': 256,
      }, // 25×8, 40×8, 32×8
      ScreenSize.md: {
        'min': 240,
        'max': 360,
        'preferred': 280,
      }, // 30×8, 45×8, 35×8
      ScreenSize.lg: {
        'min': 280,
        'max': 424,
        'preferred': 344,
      }, // 35×8, 53×8, 43×8
      ScreenSize.xl: {
        'min': 304,
        'max': 480,
        'preferred': 384,
      }, // 38×8, 60×8, 48×8
    },
    'horizontal': {
      ScreenSize.xs: {
        'min': 304,
        'max': 504,
        'preferred': 400,
      }, // 38×8, 63×8, 50×8
      ScreenSize.sm: {
        'min': 280,
        'max': 400,
        'preferred': 344,
      }, // 35×8, 50×8, 43×8
      ScreenSize.md: {
        'min': 320,
        'max': 456,
        'preferred': 384,
      }, // 40×8, 57×8, 48×8
      ScreenSize.lg: {
        'min': 400,
        'max': 552,
        'preferred': 480,
      }, // 50×8, 69×8, 60×8
      ScreenSize.xl: {
        'min': 448,
        'max': 648,
        'preferred': 552,
      }, // 56×8, 81×8, 69×8
    },
    'compact': {
      ScreenSize.xs: {
        'min': 80,
        'max': 120,
        'preferred': 96,
      }, // 10×8, 15×8, 12×8
      ScreenSize.sm: {
        'min': 96,
        'max': 136,
        'preferred': 120,
      }, // 12×8, 17×8, 15×8
      ScreenSize.md: {
        'min': 96,
        'max': 160,
        'preferred': 128,
      }, // 12×8, 20×8, 16×8
      ScreenSize.lg: {
        'min': 120,
        'max': 176,
        'preferred': 152,
      }, // 15×8, 22×8, 19×8
      ScreenSize.xl: {
        'min': 136,
        'max': 200,
        'preferred': 168,
      }, // 17×8, 25×8, 21×8
    },
    'selectable': {
      ScreenSize.xs: {
        'min': 280,
        'max': 504,
        'preferred': 352,
      }, // 35×8, 63×8, 44×8
      ScreenSize.sm: {
        'min': 280,
        'max': 400,
        'preferred': 344,
      }, // 35×8, 50×8, 43×8
      ScreenSize.md: {
        'min': 304,
        'max': 456,
        'preferred': 368,
      }, // 38×8, 57×8, 46×8
      ScreenSize.lg: {
        'min': 352,
        'max': 504,
        'preferred': 424,
      }, // 44×8, 63×8, 53×8
      ScreenSize.xl: {
        'min': 400,
        'max': 552,
        'preferred': 480,
      }, // 50×8, 69×8, 60×8
    },
    'wide': {
      ScreenSize.xs: {
        'min': 320,
        'max': 600,
        'preferred': 400,
      }, // 40×8, 75×8, 50×8
      ScreenSize.sm: {
        'min': 400,
        'max': 800,
        'preferred': 600,
      }, // 50×8, 100×8, 75×8
      ScreenSize.md: {
        'min': 600,
        'max': 1200,
        'preferred': 896,
      }, // 75×8, 150×8, 112×8
      ScreenSize.lg: {
        'min': 800,
        'max': 1600,
        'preferred': 1200,
      }, // 100×8, 200×8, 150×8
      ScreenSize.xl: {
        'min': 1000, // 125×8
        'max': 2000, // 250×8
        'preferred': double.infinity,
      },
    },
  };

  // ════════════════════════════════════════════════════════════════════════════
  // TextStyle 정의
  // ════════════════════════════════════════════════════════════════════════════

  /// TextStyle 정의 (각 요소별)
  static TextStyle getTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
  }

  static TextStyle getSubtitleStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500, height: 1.4);
  }

  static TextStyle getDescriptionStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(height: 1.5);
  }

  static TextStyle getMetaStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 반응형 패딩/간격 헬퍼 (ResponsiveTokens 래퍼)
  // ════════════════════════════════════════════════════════════════════════════

  /// 카드 패딩 (ResponsiveTokens.cardPadding 래퍼)
  static double cardPadding(double width) =>
      ResponsiveTokens.cardPadding(width);

  /// 카드 간격 (ResponsiveTokens.cardGap 래퍼)
  static double cardGap(double width) => ResponsiveTokens.cardGap(width);
}
