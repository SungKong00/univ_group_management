import 'package:flutter/material.dart';
import '../theme/responsive_tokens.dart';
import '../theme/enums.dart';

/// Responsive Builder Widget
///
/// MediaQuery.sizeOf()를 사용하여 화면 크기에 따라 다른 레이아웃을 빌드합니다.
///
/// **사용 예시:**
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, screenSize, width) {
///     return Padding(
///       padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
///       child: screenSize == ScreenSize.mobile
///           ? _buildMobileLayout()
///           : _buildDesktopLayout(),
///     );
///   },
/// )
/// ```
///
/// **Flutter Best Practices:**
/// - MediaQuery.sizeOf() 사용 (MediaQuery.of()보다 성능 최적화)
/// - 디바이스 타입 체크 금지 (Platform.isAndroid 등)
/// - LayoutBuilder와 조합 가능 (부모 제약 기반 레이아웃)
class ResponsiveBuilder extends StatelessWidget {
  /// 화면 크기에 따라 다른 위젯을 빌드하는 함수
  ///
  /// [context] - BuildContext
  /// [screenSize] - 화면 크기 타입 (mobile, tablet, desktop)
  /// [width] - 실제 화면 너비 (px)
  final Widget Function(
    BuildContext context,
    ScreenSize screenSize,
    double width,
  )
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    // MediaQuery.sizeOf() 사용 (성능 최적화)
    final width = MediaQuery.sizeOf(context).width;
    final screenSize = ResponsiveTokens.getScreenSize(width);

    return builder(context, screenSize, width);
  }
}

/// Responsive Value Helper
///
/// 화면 크기에 따라 다른 값을 반환하는 헬퍼 클래스
///
/// **사용 예시:**
/// ```dart
/// final padding = ResponsiveValue<double>(
///   mobile: 16.0,
///   tablet: 24.0,
///   desktop: 32.0,
/// ).getValue(context);
/// ```
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({required this.mobile, this.tablet, this.desktop});

  /// BuildContext로부터 화면 크기를 판단하여 적절한 값 반환
  T getValue(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return getValueFromWidth(width);
  }

  /// 화면 너비로부터 직접 값 반환
  T getValueFromWidth(double width) {
    final screenSize = ResponsiveTokens.getScreenSize(width);

    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile; // tablet이 null이면 mobile 값 사용
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile; // 폴백 체인
    }
  }
}

/// Conditional Responsive Widget
///
/// 화면 크기 조건에 따라 위젯을 표시하거나 숨김
///
/// **사용 예시:**
/// ```dart
/// ShowOnMobile(child: Text('Mobile only')),
/// HideOnMobile(child: Text('Tablet and Desktop')),
/// ```
class ShowOnMobile extends StatelessWidget {
  final Widget child;

  const ShowOnMobile({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveTokens.isMobile(width) ? child : const SizedBox.shrink();
  }
}

class HideOnMobile extends StatelessWidget {
  final Widget child;

  const HideOnMobile({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveTokens.isMobile(width) ? const SizedBox.shrink() : child;
  }
}

class ShowOnTablet extends StatelessWidget {
  final Widget child;

  const ShowOnTablet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveTokens.isTablet(width) ? child : const SizedBox.shrink();
  }
}

class ShowOnDesktop extends StatelessWidget {
  final Widget child;

  const ShowOnDesktop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveTokens.isDesktop(width) ? child : const SizedBox.shrink();
  }
}

/// Responsive Layout Helper
///
/// 화면 크기에 따라 Column과 Row를 자동으로 전환
///
/// **사용 예시:**
/// ```dart
/// ResponsiveLayout(
///   children: [Widget1(), Widget2()],
///   mobileDirection: Axis.vertical,   // Mobile: Column
///   desktopDirection: Axis.horizontal, // Desktop: Row
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final List<Widget> children;
  final Axis mobileDirection;
  final Axis desktopDirection;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveLayout({
    super.key,
    required this.children,
    this.mobileDirection = Axis.vertical,
    this.desktopDirection = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize, width) {
        final isMobile = screenSize == ScreenSize.mobile;
        final direction = isMobile ? mobileDirection : desktopDirection;

        // spacing을 적용한 children 생성
        final spacedChildren = <Widget>[];
        for (int i = 0; i < children.length; i++) {
          spacedChildren.add(children[i]);
          if (i < children.length - 1) {
            spacedChildren.add(
              SizedBox(
                width: direction == Axis.horizontal ? spacing : 0,
                height: direction == Axis.vertical ? spacing : 0,
              ),
            );
          }
        }

        if (direction == Axis.vertical) {
          return Column(
            mainAxisSize: MainAxisSize.min, // ✅ ScrollView 호환
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: spacedChildren,
          );
        } else {
          // ✅ IntrinsicHeight로 감싸서 높이 제약 제공
          return IntrinsicHeight(
            child: Row(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              children: spacedChildren,
            ),
          );
        }
      },
    );
  }
}
