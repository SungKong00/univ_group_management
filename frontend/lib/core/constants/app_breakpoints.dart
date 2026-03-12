/// 반응형 디자인 브레이크포인트 상수
///
/// 디자인 시스템 문서 (docs/ui-ux/concepts/design-system.md) 기준:
/// - MOBILE: 0-600px
/// - TABLET: 601-800px
/// - DESKTOP: 801px+
/// - NARROW_DESKTOP: 801-849px (좁은 데스크톱)
class AppBreakpoints {
  AppBreakpoints._();

  /// 모바일 최대 너비 (600px)
  static const double mobile = 600.0;

  /// 태블릿 최대 너비 (800px)
  static const double tablet = 800.0;

  /// 데스크톱 최소 너비 (801px)
  static const double desktop = 801.0;

  /// 좁은 데스크톱 최대 너비 (850px)
  /// 워크스페이스 등 특정 레이아웃에서 사용
  static const double narrowDesktop = 850.0;

  /// 현재 너비가 모바일 범위인지 확인
  static bool isMobile(double width) => width <= mobile;

  /// 현재 너비가 태블릿 범위인지 확인
  static bool isTablet(double width) => width > mobile && width <= tablet;

  /// 현재 너비가 데스크톱 범위인지 확인
  static bool isDesktop(double width) => width > tablet;

  /// 현재 너비가 좁은 데스크톱 범위인지 확인 (801-850px)
  static bool isNarrowDesktop(double width) {
    return width > tablet && width < narrowDesktop;
  }

  /// 현재 너비가 넓은 데스크톱 범위인지 확인 (850px+)
  static bool isWideDesktop(double width) => width >= narrowDesktop;
}

/// 반응형 상태를 나타내는 enum
enum ResponsiveState {
  mobile,
  tablet,
  narrowDesktop,
  wideDesktop;

  /// 너비를 기준으로 ResponsiveState 생성
  static ResponsiveState fromWidth(double width) {
    if (AppBreakpoints.isMobile(width)) {
      return ResponsiveState.mobile;
    } else if (AppBreakpoints.isTablet(width)) {
      return ResponsiveState.tablet;
    } else if (AppBreakpoints.isNarrowDesktop(width)) {
      return ResponsiveState.narrowDesktop;
    } else {
      return ResponsiveState.wideDesktop;
    }
  }

  bool get isMobile => this == ResponsiveState.mobile;
  bool get isTablet => this == ResponsiveState.tablet;
  bool get isNarrowDesktop => this == ResponsiveState.narrowDesktop;
  bool get isWideDesktop => this == ResponsiveState.wideDesktop;
  bool get isDesktop => isNarrowDesktop || isWideDesktop;
}
