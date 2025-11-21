import 'package:flutter/material.dart';

/// 반응형 디자인 토큰
///
/// Breakpoint(600/1024/1440px), 페이지 여백, 그리드 시스템, 컴포넌트 크기 등 반응형 디자인에 필요한 값들을 const로 정의합니다.
/// 각 화면 크기에 맞는 유틸리티 메서드(pagePadding, gridColumns, buttonHeight 등)를 제공합니다.
class AppResponsiveExtension extends ThemeExtension<AppResponsiveExtension> {
  // ============================================================
  // Breakpoints
  // ============================================================

  /// 모바일 breakpoint (600px)
  final double mobile;

  /// 태블릿 breakpoint (1024px)
  final double tablet;

  /// 데스크톱 breakpoint (1440px)
  final double desktop;

  // ============================================================
  // 페이지 여백 (Page Padding)
  // ============================================================

  /// 모바일 페이지 여백 (16px)
  final double pagePaddingMobile;

  /// 태블릿 페이지 여백 (24px)
  final double pagePaddingTablet;

  /// 데스크톱 페이지 여백 (32px)
  final double pagePaddingDesktop;

  // ============================================================
  // 레이아웃 제약
  // ============================================================

  /// 기본 콘텐츠 최대 너비 (1024px)
  final double maxContentWidth;

  /// 산문(글) 최대 너비 (624px) - 가독성 최적화
  final double maxProseWidth;

  /// Wide 콘텐츠 최대 너비 (1440px)
  final double maxWideContentWidth;

  // ============================================================
  // 그리드 시스템
  // ============================================================

  /// 모바일 그리드 컬럼 수 (4)
  final int gridColumnsMobile;

  /// 태블릿 그리드 컬럼 수 (8)
  final int gridColumnsTablet;

  /// 데스크톱 그리드 컬럼 수 (12)
  final int gridColumnsDesktop;

  /// 모바일 그리드 gutter (16px)
  final double gridGutterMobile;

  /// 태블릿 그리드 gutter (24px)
  final double gridGutterTablet;

  /// 데스크톱 그리드 gutter (24px)
  final double gridGutterDesktop;

  // ============================================================
  // 사이드바 너비
  // ============================================================

  /// 사이드바 축소 너비 (64px)
  final double sidebarWidthCollapsed;

  /// 사이드바 확장 너비 (244px)
  final double sidebarWidthExpanded;

  // ============================================================
  // 헤더 높이
  // ============================================================

  /// 모바일 헤더 높이 (56px)
  final double headerHeightMobile;

  /// 데스크톱 헤더 높이 (64px)
  final double headerHeightDesktop;

  // ============================================================
  // 컴포넌트 크기
  // ============================================================

  /// 모바일 버튼 높이 (40px)
  final double buttonHeightMobile;

  /// 데스크톱 버튼 높이 (44px)
  final double buttonHeightDesktop;

  /// 모바일 Input 높이 (40px)
  final double inputHeightMobile;

  /// 데스크톱 Input 높이 (44px)
  final double inputHeightDesktop;

  /// 모바일 카드 여백 (12px)
  final double cardPaddingMobile;

  /// 태블릿 카드 여백 (16px)
  final double cardPaddingTablet;

  /// 데스크톱 카드 여백 (20px)
  final double cardPaddingDesktop;

  /// 모바일 아이콘 크기 (20px)
  final double iconSizeMobile;

  /// 데스크톱 아이콘 크기 (24px)
  final double iconSizeDesktop;

  const AppResponsiveExtension({
    // Breakpoints
    required this.mobile,
    required this.tablet,
    required this.desktop,
    // Page padding
    required this.pagePaddingMobile,
    required this.pagePaddingTablet,
    required this.pagePaddingDesktop,
    // Layout constraints
    required this.maxContentWidth,
    required this.maxProseWidth,
    required this.maxWideContentWidth,
    // Grid
    required this.gridColumnsMobile,
    required this.gridColumnsTablet,
    required this.gridColumnsDesktop,
    required this.gridGutterMobile,
    required this.gridGutterTablet,
    required this.gridGutterDesktop,
    // Sidebar
    required this.sidebarWidthCollapsed,
    required this.sidebarWidthExpanded,
    // Header
    required this.headerHeightMobile,
    required this.headerHeightDesktop,
    // Components
    required this.buttonHeightMobile,
    required this.buttonHeightDesktop,
    required this.inputHeightMobile,
    required this.inputHeightDesktop,
    required this.cardPaddingMobile,
    required this.cardPaddingTablet,
    required this.cardPaddingDesktop,
    required this.iconSizeMobile,
    required this.iconSizeDesktop,
  });

  /// 기본 반응형 설정 (Linear.app 기준)
  factory AppResponsiveExtension.standard() {
    return const AppResponsiveExtension(
      // Breakpoints
      mobile: 600.0,
      tablet: 1024.0,
      desktop: 1440.0,
      // Page padding
      pagePaddingMobile: 16.0,
      pagePaddingTablet: 24.0,
      pagePaddingDesktop: 32.0,
      // Layout constraints
      maxContentWidth: 1024.0,
      maxProseWidth: 624.0,
      maxWideContentWidth: 1440.0,
      // Grid
      gridColumnsMobile: 4,
      gridColumnsTablet: 8,
      gridColumnsDesktop: 12,
      gridGutterMobile: 16.0,
      gridGutterTablet: 24.0,
      gridGutterDesktop: 24.0,
      // Sidebar
      sidebarWidthCollapsed: 64.0,
      sidebarWidthExpanded: 244.0,
      // Header
      headerHeightMobile: 56.0,
      headerHeightDesktop: 64.0,
      // Components
      buttonHeightMobile: 40.0,
      buttonHeightDesktop: 44.0,
      inputHeightMobile: 40.0,
      inputHeightDesktop: 44.0,
      cardPaddingMobile: 12.0,
      cardPaddingTablet: 16.0,
      cardPaddingDesktop: 20.0,
      iconSizeMobile: 20.0,
      iconSizeDesktop: 24.0,
    );
  }

  /// 현재 화면 크기에 맞는 페이지 여백 반환
  double pagePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return pagePaddingMobile;
    if (width < tablet) return pagePaddingTablet;
    return pagePaddingDesktop;
  }

  /// 현재 화면 크기에 맞는 그리드 컬럼 수 반환
  int gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return gridColumnsMobile;
    if (width < tablet) return gridColumnsTablet;
    return gridColumnsDesktop;
  }

  /// 현재 화면 크기에 맞는 그리드 gutter 반환
  double gridGutter(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return gridGutterMobile;
    if (width < tablet) return gridGutterTablet;
    return gridGutterDesktop;
  }

  /// 현재 화면 크기에 맞는 카드 여백 반환
  double cardPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return cardPaddingMobile;
    if (width < tablet) return cardPaddingTablet;
    return cardPaddingDesktop;
  }

  /// 현재 화면 크기에 맞는 버튼 높이 반환
  double buttonHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < tablet) return buttonHeightMobile;
    return buttonHeightDesktop;
  }

  /// 현재 화면 크기에 맞는 Input 높이 반환
  double inputHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < tablet) return inputHeightMobile;
    return inputHeightDesktop;
  }

  /// 현재 화면 크기에 맞는 아이콘 크기 반환
  double iconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < tablet) return iconSizeMobile;
    return iconSizeDesktop;
  }

  @override
  ThemeExtension<AppResponsiveExtension> copyWith({
    double? mobile,
    double? tablet,
    double? desktop,
    double? pagePaddingMobile,
    double? pagePaddingTablet,
    double? pagePaddingDesktop,
    double? maxContentWidth,
    double? maxProseWidth,
    double? maxWideContentWidth,
    int? gridColumnsMobile,
    int? gridColumnsTablet,
    int? gridColumnsDesktop,
    double? gridGutterMobile,
    double? gridGutterTablet,
    double? gridGutterDesktop,
    double? sidebarWidthCollapsed,
    double? sidebarWidthExpanded,
    double? headerHeightMobile,
    double? headerHeightDesktop,
    double? buttonHeightMobile,
    double? buttonHeightDesktop,
    double? inputHeightMobile,
    double? inputHeightDesktop,
    double? cardPaddingMobile,
    double? cardPaddingTablet,
    double? cardPaddingDesktop,
    double? iconSizeMobile,
    double? iconSizeDesktop,
  }) {
    return AppResponsiveExtension(
      mobile: mobile ?? this.mobile,
      tablet: tablet ?? this.tablet,
      desktop: desktop ?? this.desktop,
      pagePaddingMobile: pagePaddingMobile ?? this.pagePaddingMobile,
      pagePaddingTablet: pagePaddingTablet ?? this.pagePaddingTablet,
      pagePaddingDesktop: pagePaddingDesktop ?? this.pagePaddingDesktop,
      maxContentWidth: maxContentWidth ?? this.maxContentWidth,
      maxProseWidth: maxProseWidth ?? this.maxProseWidth,
      maxWideContentWidth: maxWideContentWidth ?? this.maxWideContentWidth,
      gridColumnsMobile: gridColumnsMobile ?? this.gridColumnsMobile,
      gridColumnsTablet: gridColumnsTablet ?? this.gridColumnsTablet,
      gridColumnsDesktop: gridColumnsDesktop ?? this.gridColumnsDesktop,
      gridGutterMobile: gridGutterMobile ?? this.gridGutterMobile,
      gridGutterTablet: gridGutterTablet ?? this.gridGutterTablet,
      gridGutterDesktop: gridGutterDesktop ?? this.gridGutterDesktop,
      sidebarWidthCollapsed:
          sidebarWidthCollapsed ?? this.sidebarWidthCollapsed,
      sidebarWidthExpanded: sidebarWidthExpanded ?? this.sidebarWidthExpanded,
      headerHeightMobile: headerHeightMobile ?? this.headerHeightMobile,
      headerHeightDesktop: headerHeightDesktop ?? this.headerHeightDesktop,
      buttonHeightMobile: buttonHeightMobile ?? this.buttonHeightMobile,
      buttonHeightDesktop: buttonHeightDesktop ?? this.buttonHeightDesktop,
      inputHeightMobile: inputHeightMobile ?? this.inputHeightMobile,
      inputHeightDesktop: inputHeightDesktop ?? this.inputHeightDesktop,
      cardPaddingMobile: cardPaddingMobile ?? this.cardPaddingMobile,
      cardPaddingTablet: cardPaddingTablet ?? this.cardPaddingTablet,
      cardPaddingDesktop: cardPaddingDesktop ?? this.cardPaddingDesktop,
      iconSizeMobile: iconSizeMobile ?? this.iconSizeMobile,
      iconSizeDesktop: iconSizeDesktop ?? this.iconSizeDesktop,
    );
  }

  @override
  ThemeExtension<AppResponsiveExtension> lerp(
    covariant ThemeExtension<AppResponsiveExtension>? other,
    double t,
  ) {
    if (other is! AppResponsiveExtension) return this;

    return AppResponsiveExtension(
      mobile: lerpDouble(mobile, other.mobile, t),
      tablet: lerpDouble(tablet, other.tablet, t),
      desktop: lerpDouble(desktop, other.desktop, t),
      pagePaddingMobile: lerpDouble(
        pagePaddingMobile,
        other.pagePaddingMobile,
        t,
      ),
      pagePaddingTablet: lerpDouble(
        pagePaddingTablet,
        other.pagePaddingTablet,
        t,
      ),
      pagePaddingDesktop: lerpDouble(
        pagePaddingDesktop,
        other.pagePaddingDesktop,
        t,
      ),
      maxContentWidth: lerpDouble(maxContentWidth, other.maxContentWidth, t),
      maxProseWidth: lerpDouble(maxProseWidth, other.maxProseWidth, t),
      maxWideContentWidth: lerpDouble(
        maxWideContentWidth,
        other.maxWideContentWidth,
        t,
      ),
      gridColumnsMobile: lerpInt(gridColumnsMobile, other.gridColumnsMobile, t),
      gridColumnsTablet: lerpInt(gridColumnsTablet, other.gridColumnsTablet, t),
      gridColumnsDesktop: lerpInt(
        gridColumnsDesktop,
        other.gridColumnsDesktop,
        t,
      ),
      gridGutterMobile: lerpDouble(gridGutterMobile, other.gridGutterMobile, t),
      gridGutterTablet: lerpDouble(gridGutterTablet, other.gridGutterTablet, t),
      gridGutterDesktop: lerpDouble(
        gridGutterDesktop,
        other.gridGutterDesktop,
        t,
      ),
      sidebarWidthCollapsed: lerpDouble(
        sidebarWidthCollapsed,
        other.sidebarWidthCollapsed,
        t,
      ),
      sidebarWidthExpanded: lerpDouble(
        sidebarWidthExpanded,
        other.sidebarWidthExpanded,
        t,
      ),
      headerHeightMobile: lerpDouble(
        headerHeightMobile,
        other.headerHeightMobile,
        t,
      ),
      headerHeightDesktop: lerpDouble(
        headerHeightDesktop,
        other.headerHeightDesktop,
        t,
      ),
      buttonHeightMobile: lerpDouble(
        buttonHeightMobile,
        other.buttonHeightMobile,
        t,
      ),
      buttonHeightDesktop: lerpDouble(
        buttonHeightDesktop,
        other.buttonHeightDesktop,
        t,
      ),
      inputHeightMobile: lerpDouble(
        inputHeightMobile,
        other.inputHeightMobile,
        t,
      ),
      inputHeightDesktop: lerpDouble(
        inputHeightDesktop,
        other.inputHeightDesktop,
        t,
      ),
      cardPaddingMobile: lerpDouble(
        cardPaddingMobile,
        other.cardPaddingMobile,
        t,
      ),
      cardPaddingTablet: lerpDouble(
        cardPaddingTablet,
        other.cardPaddingTablet,
        t,
      ),
      cardPaddingDesktop: lerpDouble(
        cardPaddingDesktop,
        other.cardPaddingDesktop,
        t,
      ),
      iconSizeMobile: lerpDouble(iconSizeMobile, other.iconSizeMobile, t),
      iconSizeDesktop: lerpDouble(iconSizeDesktop, other.iconSizeDesktop, t),
    );
  }

  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  int lerpInt(int a, int b, double t) {
    return (a + (b - a) * t).round();
  }
}

/// Helper extension for easy access
extension AppResponsiveExtensionHelper on BuildContext {
  AppResponsiveExtension get appResponsive =>
      Theme.of(this).extension<AppResponsiveExtension>()!;
}
