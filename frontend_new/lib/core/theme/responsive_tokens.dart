/// Responsive Design Tokens
///
/// Material Design 3 breakpoints(600/1024/1440px)와 Flutter best practices를 따르는 반응형 디자인 토큰의 정적 유틸리티 클래스
///
/// 핵심 원칙:
/// - MediaQuery.sizeOf() 사용 (성능 최적화)
/// - 디바이스 타입 체크 금지 (Platform.isAndroid 등)
/// - 유연한 레이아웃 (Flexible, Expanded 기반)
class ResponsiveTokens {
  ResponsiveTokens._();

  // ═══════════════════════════════════════════════════════════════════════════
  // Breakpoints (Material Design 3 기준)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mobile breakpoint (< 600px)
  static const double mobile = 600.0;

  /// Tablet breakpoint (600-1024px)
  static const double tablet = 1024.0;

  /// Desktop breakpoint (>= 1024px)
  static const double desktop = 1440.0;

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

  /// 화면 너비에 따른 페이지 패딩 계산
  static double pagePadding(double width) {
    if (width < mobile) return 16.0; // Mobile: 16px
    if (width < tablet) return 24.0; // Tablet: 24px
    return 32.0; // Desktop: 32px
  }

  /// 화면 너비에 따른 그리드 컬럼 수 계산
  static int columnCount(double width) {
    if (width < mobile) return 4; // Mobile: 4 columns
    if (width < tablet) return 8; // Tablet: 8 columns
    return 12; // Desktop: 12 columns
  }

  /// 화면 너비에 따른 폰트 스케일 계산
  ///
  /// Mobile에서 약간 축소하여 가독성 유지
  static double fontScale(double width) {
    if (width < mobile) return 0.9; // Mobile: 10% 축소
    if (width < tablet) return 1.0; // Tablet: 기본
    return 1.0; // Desktop: 기본
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Component Sizes
  // ═══════════════════════════════════════════════════════════════════════════

  /// 버튼 높이 (iOS 최소 터치 영역 44px 권장)
  static double buttonHeight(double width) {
    if (width < mobile) return 40.0;
    return 44.0;
  }

  /// 입력 필드 높이
  static double inputHeight(double width) {
    if (width < mobile) return 40.0;
    return 44.0;
  }

  /// 카드 패딩
  static double cardPadding(double width) {
    if (width < mobile) return 12.0;
    if (width < tablet) return 16.0;
    return 20.0;
  }

  /// 카드 사이 간격
  static double cardGap(double width) {
    if (width < mobile) return 12.0;
    return 16.0;
  }

  /// 아이콘 크기
  static double iconSize(double width) {
    if (width < mobile) return 20.0;
    return 24.0;
  }

  /// 아바타 크기
  static double avatarSize(double width) {
    if (width < mobile) return 32.0;
    return 40.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Button Padding (Size별 반응형 패딩)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 버튼 Small - 가로 패딩
  static double buttonSmallPaddingH(double width) {
    if (width < mobile) return 10.0;
    return 12.0;
  }

  /// 버튼 Small - 세로 패딩
  static double buttonSmallPaddingV(double width) {
    if (width < mobile) return 4.0;
    return 6.0;
  }

  /// 버튼 Medium - 가로 패딩
  static double buttonMediumPaddingH(double width) {
    if (width < mobile) return 14.0;
    return 16.0;
  }

  /// 버튼 Medium - 세로 패딩
  static double buttonMediumPaddingV(double width) {
    if (width < mobile) return 8.0;
    return 10.0;
  }

  /// 버튼 Large - 가로 패딩
  static double buttonLargePaddingH(double width) {
    if (width < mobile) return 18.0;
    return 20.0;
  }

  /// 버튼 Large - 세로 패딩
  static double buttonLargePaddingV(double width) {
    if (width < mobile) return 10.0;
    return 12.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Border Radius
  // ═══════════════════════════════════════════════════════════════════════════

  /// 버튼/카드 border radius
  static double componentBorderRadius(double width) {
    if (width < mobile) return 6.0;
    return 6.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Input Field Padding
  // ═══════════════════════════════════════════════════════════════════════════

  /// 입력 필드 가로 패딩
  static double inputPaddingH(double width) {
    if (width < mobile) return 10.0;
    return 12.0;
  }

  /// 입력 필드 세로 패딩
  static double inputPaddingV(double width) {
    if (width < mobile) return 10.0;
    return 12.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Layout Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// 화면 크기 타입 판단
  static ScreenSize getScreenSize(double width) {
    if (width < mobile) return ScreenSize.mobile;
    if (width < tablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// Mobile 화면인지 확인
  static bool isMobile(double width) => width < mobile;

  /// Tablet 화면인지 확인
  static bool isTablet(double width) => width >= mobile && width < tablet;

  /// Desktop 화면인지 확인
  static bool isDesktop(double width) => width >= tablet;

  /// 최소 터치 영역 크기 (iOS/Android 접근성 가이드라인)
  static const double minTapSize = 44.0;

  /// 최대 컨텐츠 너비 (가독성을 위한 제한)
  static const double maxContentWidth = 1024.0;

  /// 최대 텍스트 컬럼 너비 (prose)
  static const double maxProseWidth = 624.0;
}

/// 화면 크기 타입
enum ScreenSize { mobile, tablet, desktop }
