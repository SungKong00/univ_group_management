import 'enums.dart';

/// Responsive Design Tokens
///
/// Material Design 3 breakpoints(600/1440px) 및 1440px 기준 그리드 시스템을 따르는 반응형 디자인 토큰의 정적 유틸리티 클래스
///
/// 핵심 원칙:
/// - MediaQuery.sizeOf() 사용 (성능 최적화)
/// - 디바이스 타입 체크 금지 (Platform.isAndroid 등)
/// - 유연한 레이아웃 (Flexible, Expanded 기반)
/// - 모든 그리드 계산은 1440px 기준 (GridLayoutTokens와 일관성)
class ResponsiveTokens {
  ResponsiveTokens._();

  // ═══════════════════════════════════════════════════════════════════════════
  // Breakpoints (5-step responsive system: 450/768/1024/1440/1920px)
  // ═══════════════════════════════════════════════════════════════════════════

  /// XS breakpoint (< 450px) - Small mobile devices
  static const double xs = 450.0;

  /// SM breakpoint (450-768px) - Large mobile devices
  static const double sm = 768.0;

  /// MD breakpoint (768-1024px) - Tablets (portrait)
  static const double md = 1024.0;

  /// LG breakpoint (1024-1440px) - Tablets (landscape) / Laptops
  static const double lg = 1440.0;

  /// XL breakpoint (>= 1440px) - Large laptops / Desktop monitors
  static const double xl = 1920.0;

  // Legacy breakpoints (deprecated - for backward compatibility)
  @deprecated
  static const double mobile = 450.0; // Use ScreenSize.xs instead
  @deprecated
  static const double tablet = 768.0; // Use ScreenSize.md instead
  @deprecated
  static const double desktop = 1440.0; // Use ScreenSize.lg instead

  // ═══════════════════════════════════════════════════════════════════════════
  // Spacing Scale (8px grid system)
  // ═══════════════════════════════════════════════════════════════════════════

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;
  static const double space96 = 96.0;
  static const double space128 = 128.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // Responsive Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// 화면 너비에 따른 페이지 패딩 계산 (사이드 마진)
  ///
  /// XS (< 450px): 16px - 작은 폰
  /// SM (450-768px): 20px - 큰 폰
  /// MD (768-1024px): 24px - 태블릿 세로
  /// LG (1024-1440px): 28px - 태블릿 가로 / 노트북
  /// XL (≥ 1440px): 32px - 데스크톱 모니터
  static double pagePadding(double width) {
    if (width < sm) return 16.0;   // XS: 16px
    if (width < md) return 20.0;   // SM: 20px
    if (width < lg) return 24.0;   // MD: 24px
    if (width < xl) return 28.0;   // LG: 28px
    return 32.0;                    // XL: 32px
  }

  /// 화면 너비에 따른 그리드 컬럼 수 계산 (Material Design 3 컬럼 시스템)
  ///
  /// XS (< 450px): 4개 컬럼 - 작은 폰
  /// SM (450-768px): 8개 컬럼 - 큰 폰
  /// MD (768-1024px): 12개 컬럼 - 태블릿 세로
  /// LG (1024-1440px): 16개 컬럼 - 태블릿 가로 / 노트북
  /// XL (≥ 1440px): 20개 컬럼 - 데스크톱 모니터
  static int columnCount(double width) {
    if (width < sm) return 4;    // XS: 4 columns
    if (width < md) return 8;    // SM: 8 columns
    if (width < lg) return 12;   // MD: 12 columns
    if (width < xl) return 16;   // LG: 16 columns
    return 20;                    // XL: 20 columns
  }

  /// 화면 너비에 따른 폰트 스케일 계산
  static double fontScale(double width) {
    if (width < sm) return 0.85;    // XS: 15% 축소
    if (width < md) return 0.9;     // SM: 10% 축소
    return 1.0;                      // MD+: 기본 (100%)
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Component Sizes
  // ═══════════════════════════════════════════════════════════════════════════

  /// 버튼 높이 (iOS 최소 터치 영역 44px 권장)
  static double buttonHeight(double width) {
    if (width < sm) return 40.0;     // XS/SM: 40px
    if (width < lg) return 44.0;     // MD/LG: 44px (iOS min)
    return 48.0;                      // XL: 48px
  }

  /// 입력 필드 높이
  static double inputHeight(double width) {
    if (width < sm) return 40.0;     // XS/SM: 40px
    if (width < lg) return 44.0;     // MD/LG: 44px
    return 48.0;                      // XL: 48px
  }

  /// 카드 패딩 (Material Design 16dp 기준)
  static double cardPadding(double width) {
    if (width < sm) return 12.0;     // XS/SM: 12px
    if (width < lg) return 16.0;     // MD/LG: 16px
    return 20.0;                      // XL: 20px
  }

  /// 카드 사이 간격
  static double cardGap(double width) {
    if (width < md) return 8.0;      // XS/SM: 8px
    if (width < lg) return 12.0;     // MD: 12px
    return 16.0;                      // LG/XL: 16px
  }

  /// 아이콘 크기
  static double iconSize(double width) {
    if (width < sm) return 20.0;     // XS/SM: 20px
    if (width < lg) return 24.0;     // MD/LG: 24px
    return 28.0;                      // XL: 28px
  }

  /// 아바타 크기
  static double avatarSize(double width) {
    if (width < sm) return 32.0;     // XS/SM: 32px
    if (width < lg) return 40.0;     // MD/LG: 40px
    return 48.0;                      // XL: 48px
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Button Padding (Size별 반응형 패딩)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 버튼 Small - 가로 패딩
  static double buttonSmallPaddingH(double width) {
    if (width < sm) return 10.0;     // XS/SM: 10px
    if (width < lg) return 12.0;     // MD/LG: 12px
    return 14.0;                      // XL: 14px
  }

  /// 버튼 Small - 세로 패딩
  static double buttonSmallPaddingV(double width) {
    if (width < sm) return 4.0;      // XS/SM: 4px
    if (width < lg) return 6.0;      // MD/LG: 6px
    return 8.0;                       // XL: 8px
  }

  /// 버튼 Medium - 가로 패딩
  static double buttonMediumPaddingH(double width) {
    if (width < sm) return 14.0;     // XS/SM: 14px
    if (width < lg) return 16.0;     // MD/LG: 16px
    return 18.0;                      // XL: 18px
  }

  /// 버튼 Medium - 세로 패딩
  static double buttonMediumPaddingV(double width) {
    if (width < sm) return 8.0;      // XS/SM: 8px
    if (width < lg) return 10.0;     // MD/LG: 10px
    return 12.0;                      // XL: 12px
  }

  /// 버튼 Large - 가로 패딩
  static double buttonLargePaddingH(double width) {
    if (width < sm) return 18.0;     // XS/SM: 18px
    if (width < lg) return 20.0;     // MD/LG: 20px
    return 24.0;                      // XL: 24px
  }

  /// 버튼 Large - 세로 패딩
  static double buttonLargePaddingV(double width) {
    if (width < sm) return 10.0;     // XS/SM: 10px
    if (width < lg) return 12.0;     // MD/LG: 12px
    return 16.0;                      // XL: 16px
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Border Radius
  // ═══════════════════════════════════════════════════════════════════════════

  /// 버튼/카드 border radius
  static double componentBorderRadius(double width) {
    if (width < lg) return 6.0;      // XS-MD: 6px
    return 8.0;                       // LG/XL: 8px
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Input Field Padding
  // ═══════════════════════════════════════════════════════════════════════════

  /// 입력 필드 가로 패딩
  static double inputPaddingH(double width) {
    if (width < sm) return 10.0;     // XS/SM: 10px
    if (width < lg) return 12.0;     // MD/LG: 12px
    return 14.0;                      // XL: 14px
  }

  /// 입력 필드 세로 패딩
  static double inputPaddingV(double width) {
    if (width < sm) return 10.0;     // XS/SM: 10px
    if (width < lg) return 12.0;     // MD/LG: 12px
    return 14.0;                      // XL: 14px
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Layout Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// 화면 크기 타입 판단
  static ScreenSize getScreenSize(double width) {
    if (width < sm) return ScreenSize.xs;
    if (width < md) return ScreenSize.sm;
    if (width < lg) return ScreenSize.md;
    if (width < xl) return ScreenSize.lg;
    return ScreenSize.xl;
  }

  /// XS 화면인지 확인 (< 450px)
  static bool isXS(double width) => width < sm;

  /// SM 화면인지 확인 (450-768px)
  static bool isSM(double width) => width >= sm && width < md;

  /// MD 화면인지 확인 (768-1024px)
  static bool isMD(double width) => width >= md && width < lg;

  /// LG 화면인지 확인 (1024-1440px)
  static bool isLG(double width) => width >= lg && width < xl;

  /// XL 화면인지 확인 (>= 1440px)
  static bool isXL(double width) => width >= xl;

  // Legacy helpers (deprecated)
  @deprecated
  static bool isMobile(double width) => isXS(width);
  @deprecated
  static bool isTablet(double width) => isSM(width) || isMD(width);
  @deprecated
  static bool isDesktop(double width) => isLG(width) || isXL(width);

  /// 최소 터치 영역 크기 (iOS/Android 접근성 가이드라인)
  static const double minTapSize = 44.0;

  /// 최대 컨텐츠 너비 (1440px 기준, 그리드 레이아웃 기준선)
  static const double maxContentWidth = 1440.0;

  /// 최대 텍스트 컬럼 너비 (prose)
  static const double maxProseWidth = 624.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // Section Layout Tokens
  // ═══════════════════════════════════════════════════════════════════════════

  /// 섹션 간 세로 간격 (섹션 구분)
  ///
  /// XS (< 450px): 16px
  /// SM (450-768px): 24px
  /// MD (768-1024px): 32px
  /// LG (1024-1440px): 40px
  /// XL (≥ 1440px): 48px
  static double sectionVerticalGap(double width) {
    if (width < sm) return 16.0;    // XS: 16px
    if (width < md) return 24.0;    // SM: 24px
    if (width < lg) return 32.0;    // MD: 32px
    if (width < xl) return 40.0;    // LG: 40px
    return 48.0;                     // XL: 48px
  }

  /// 섹션 내부 콘텐츠 간격 (제목과 콘텐츠 사이)
  ///
  /// 고정값: 24px
  static const double sectionContentGap = 24.0;

  /// 섹션 최대 너비
  ///
  /// XS (< 450px): 450px
  /// SM (450-768px): 750px
  /// MD (768-1024px): 1000px
  /// LG (1024-1440px): 1200px
  /// XL (≥ 1440px): 1400px
  static double sectionMaxWidth(double width) {
    if (width < sm) return 450.0;   // XS: 450px
    if (width < md) return 750.0;   // SM: 750px
    if (width < lg) return 1000.0;  // MD: 1000px
    if (width < xl) return 1200.0;  // LG: 1200px
    return 1400.0;                   // XL: 1400px
  }
}
