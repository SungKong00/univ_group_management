import 'package:flutter/material.dart';

/// Card Design System Tokens
///
/// 모든 카드 컴포넌트가 준수하는 중앙화된 토큰 시스템
/// - 레이아웃: Padding, Gap, BorderRadius, Shadow
/// - 타이포그래피: 각 요소별 TextStyle
/// - 애니메이션: Duration, Curve
/// - 상태: Hover, Selected, Disabled
enum CardVariant {
  vertical, // 이미지 상단 + 텍스트
  horizontal, // 이미지 좌측 + 텍스트 우측
  compact, // 아이콘 + 제목 (정사각형)
  selectable, // 체크박스 + 콘텐츠
  wide, // Full-width 배너
}

/// Card Design Tokens (5-step responsive system)
///
/// 카드 크기는 화면 크기에 따라 다르게 조정됩니다.
/// Scale factor 기반으로 자동 계산되며, 특정 카드는 수동 override 가능합니다.
class CardDesignTokens {
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
  // 카드 너비 반응형 시스템 (Scale factor + Override)
  // ════════════════════════════════════════════════════════════════════════════

  /// 기준 breakpoint (MD = 1024px)에서의 카드 너비
  /// 다른 breakpoint는 scale factor로 계산됩니다.
  static const Map<String, Map<String, double>> _baseCardWidths = {
    'vertical': {'min': 240, 'max': 380, 'preferred': 320},
    'horizontal': {'min': 320, 'max': 500, 'preferred': 400},
    'compact': {'min': 100, 'max': 200, 'preferred': 120},
    'selectable': {'min': 280, 'max': 500, 'preferred': 350},
    'wide': {'min': 600, 'max': 2000, 'preferred': double.infinity},
  };

  /// Breakpoint별 scale factor (기준: MD = 1.0)
  ///
  /// XS (< 450px): 0.75 - 더 작은 카드
  /// SM (450-768px): 0.85 - 조금 작은 카드
  /// MD (768-1024px): 1.0 - 기준값
  /// LG (1024-1440px): 1.1 - 조금 큰 카드 (노트북)
  /// XL (>= 1440px): 1.2 - 더 큰 카드 (데스크톱)
  static const Map<String, double> _scaleFactors = {
    'xs': 0.75,
    'sm': 0.85,
    'md': 1.0,
    'lg': 1.1,
    'xl': 1.2,
  };

  /// 수동 override: 특정 카드는 scale factor 대신 고정값 사용
  /// null이면 scale factor 자동 적용
  static const Map<String, Map<String, Map<String, double>>>? _overrides = {
    // 예: 'compact' 카드는 XS에서 커스텀 크기 사용
    // 'compact': {
    //   'xs': {'min': 80, 'max': 140, 'preferred': 110},
    // },
  };

  /// 카드 너비 반응형 조회
  ///
  /// [cardType] - 카드 종류 ('vertical', 'horizontal', 'compact', 'selectable', 'wide')
  /// [width] - 화면 너비 (px)
  /// 반환값 - {'min': double, 'max': double, 'preferred': double}
  static Map<String, double> getCardWidths(String cardType, double width) {
    final breakpoint = _getBreakpointName(width);

    // Override 확인 (있으면 override 값 사용)
    if (_overrides?[cardType]?[breakpoint] != null) {
      return _overrides![cardType]![breakpoint]!;
    }

    // Scale factor 적용
    final base = _baseCardWidths[cardType]!;
    final scale = _scaleFactors[breakpoint]!;

    return {
      'min': (base['min']! * scale).roundToDouble(),
      'max': (base['max']! * scale).roundToDouble(),
      'preferred': (base['preferred']! * scale).roundToDouble(),
    };
  }

  /// 화면 너비에 따른 breakpoint 이름 반환
  static String _getBreakpointName(double width) {
    if (width < 450) return 'xs';
    if (width < 768) return 'sm';
    if (width < 1024) return 'md';
    if (width < 1440) return 'lg';
    return 'xl';
  }

  /// 레거시 호환성: 기준값만 반환 (deprecated)
  @Deprecated('Use getCardWidths(cardType, width) instead')
  static const Map<String, Map<String, double>> cardWidths = _baseCardWidths;

  /// 텍스트 라인 수 제한
  static const Map<String, int> textLineNumbers = {
    'title': 3, // 제목: 3줄 최대
    'subtitle': 2, // 부제목: 2줄 최대
    'description': 3, // 설명: 3줄 최대
    'meta': 1, // 메타: 1줄
  };

  /// 애니메이션 설정
  static const Duration hoverAnimationDuration = Duration(milliseconds: 200);
  static const Curve hoverAnimationCurve = Curves.easeInOut;

  /// 배경 오버레이 강도
  static const double wideCardOverlayOpacity = 0.3;

  /// WideCard 이미지 너비 비율 (HorizontalCard)
  static const double horizontalImageWidthRatio = 0.4;

  /// 선택 상태 테두리 굵기
  static const double selectedBorderWidth = 2.0;
  static const double normalBorderWidth = 1.0;

  /// 반응형 패딩/간격 (ResponsiveTokens 메서드 사용)
  /// - cardPadding(width): 12/16/20px
  /// - cardGap(width): 12/16px
  /// - pagePadding(width): 16/24/32px

  /// 각 요소별 텍스트 줄 수 제한 (상세)
  static const Map<String, Map<String, int>> textLineNumbersByCard = {
    'vertical': {'meta': 1, 'title': 3, 'subtitle': 2, 'description': 3},
    'horizontal': {'meta': 1, 'title': 2, 'subtitle': 1, 'description': 2},
    'compact': {'meta': 1, 'title': 2},
    'selectable': {'title': 1, 'subtitle': 1},
    'wide': {'title': 2, 'subtitle': 1, 'description': 2},
  };

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
}
