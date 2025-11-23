import 'package:flutter/material.dart';
import '../theme/responsive_tokens.dart';
import '../theme/enums.dart';

/// Responsive Builder Widget (5-step responsive system)
///
/// MediaQuery.sizeOf()를 사용하여 화면 크기에 따라 다른 레이아웃을 빌드합니다.
///
/// **사용 예시:**
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, screenSize, width) {
///     return Padding(
///       padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
///       child: switch (screenSize) {
///         ScreenSize.xs || ScreenSize.sm => _buildMobileLayout(),
///         ScreenSize.md => _buildTabletLayout(),
///         _ => _buildDesktopLayout(),
///       },
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
  /// [screenSize] - 화면 크기 타입 (xs, sm, md, lg, xl)
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

/// Responsive Value Helper (5-step responsive system)
///
/// 화면 크기에 따라 다른 값을 반환하는 헬퍼 클래스
///
/// **사용 예시:**
/// ```dart
/// // 모든 값을 지정하는 경우
/// final padding = ResponsiveValue<double>(
///   xs: 16.0,
///   sm: 20.0,
///   md: 24.0,
///   lg: 28.0,
///   xl: 32.0,
/// ).getValue(context);
///
/// // 일부만 지정하는 경우 (폴백 적용)
/// final padding = ResponsiveValue<double>(
///   xs: 16.0,  // sm, md는 이 값 사용
///   lg: 28.0,  // xl은 이 값 사용
/// ).getValue(context);
/// ```
class ResponsiveValue<T> {
  /// XS (< 450px) - Extra Small / Small mobile devices
  final T xs;

  /// SM (450-768px) - Small / Large mobile devices
  /// [null이면 xs 값 사용]
  final T? sm;

  /// MD (768-1024px) - Medium / Tablets (portrait)
  /// [null이면 sm → xs 순서로 폴백]
  final T? md;

  /// LG (1024-1440px) - Large / Tablets (landscape) / Laptops
  /// [null이면 md → sm → xs 순서로 폴백]
  final T? lg;

  /// XL (>= 1440px) - Extra Large / Desktop monitors
  /// [null이면 lg → md → sm → xs 순서로 폴백]
  final T? xl;

  const ResponsiveValue({
    required this.xs,
    this.sm,
    this.md,
    this.lg,
    this.xl,
  });

  /// BuildContext로부터 화면 크기를 판단하여 적절한 값 반환
  T getValue(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return getValueFromWidth(width);
  }

  /// 화면 너비로부터 직접 값 반환 (하위 breakpoint로 폴백)
  T getValueFromWidth(double width) {
    final screenSize = ResponsiveTokens.getScreenSize(width);

    return switch (screenSize) {
      ScreenSize.xs => xs,
      ScreenSize.sm => sm ?? xs,
      ScreenSize.md => md ?? sm ?? xs,
      ScreenSize.lg => lg ?? md ?? sm ?? xs,
      ScreenSize.xl => xl ?? lg ?? md ?? sm ?? xs,
    };
  }
}

/// Conditional Responsive Widget (5-step responsive system)
///
/// 화면 크기 조건에 따라 위젯을 표시하거나 숨김
///
/// **사용 예시:**
/// ```dart
/// // XS (< 450px)에서만 표시
/// ShowOnXS(child: Text('Mobile only')),
/// HideOnXS(child: Text('SM and larger')),
///
/// // LG (1024-1440px)에서만 표시 (노트북)
/// ShowOnLG(child: Text('Laptop only')),
/// ```

/// XS 화면에서만 표시
class ShowOnXS extends StatelessWidget {
  final Widget child;
  const ShowOnXS({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveTokens.isXS(width) ? child : const SizedBox.shrink();
  }
}

/// XS 화면에서 숨김
class HideOnXS extends StatelessWidget {
  final Widget child;
  const HideOnXS({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveTokens.isXS(width) ? const SizedBox.shrink() : child;
  }
}

/// SM 화면에서만 표시
class ShowOnSM extends StatelessWidget {
  final Widget child;
  const ShowOnSM({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveTokens.isSM(width) ? child : const SizedBox.shrink();
  }
}

/// MD 화면에서만 표시
class ShowOnMD extends StatelessWidget {
  final Widget child;
  const ShowOnMD({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveTokens.isMD(width) ? child : const SizedBox.shrink();
  }
}

/// LG 화면에서만 표시 (노트북)
class ShowOnLG extends StatelessWidget {
  final Widget child;
  const ShowOnLG({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveTokens.isLG(width) ? child : const SizedBox.shrink();
  }
}

/// XL 화면에서만 표시 (큰 데스크톱)
class ShowOnXL extends StatelessWidget {
  final Widget child;
  const ShowOnXL({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveTokens.isXL(width) ? child : const SizedBox.shrink();
  }
}

/// 조합: 특정 ScreenSize 조건에서만 표시
class ShowOnScreenSize extends StatelessWidget {
  final Widget child;
  final List<ScreenSize> screenSizes;

  const ShowOnScreenSize({
    super.key,
    required this.child,
    required this.screenSizes,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final screenSize = ResponsiveTokens.getScreenSize(width);
    return screenSizes.contains(screenSize) ? child : const SizedBox.shrink();
  }
}

// Legacy widget names (deprecated - use ShowOn[Size] instead)
@deprecated
class ShowOnMobile extends ShowOnXS {
  const ShowOnMobile({super.key, required super.child});
}

@deprecated
class HideOnMobile extends HideOnXS {
  const HideOnMobile({super.key, required super.child});
}

@deprecated
class ShowOnTablet extends StatelessWidget {
  final Widget child;
  const ShowOnTablet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (ResponsiveTokens.isSM(width) || ResponsiveTokens.isMD(width))
        ? child
        : const SizedBox.shrink();
  }
}

@deprecated
class ShowOnDesktop extends StatelessWidget {
  final Widget child;
  const ShowOnDesktop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (ResponsiveTokens.isLG(width) || ResponsiveTokens.isXL(width))
        ? child
        : const SizedBox.shrink();
  }
}

/// Responsive Layout Helper (5-step responsive system)
///
/// 화면 크기에 따라 Column과 Row를 자동으로 전환
///
/// **사용 예시:**
/// ```dart
/// ResponsiveLayout(
///   children: [Widget1(), Widget2()],
///   compactDirection: Axis.vertical,     // XS/SM/MD: Column
///   expandedDirection: Axis.horizontal,  // LG/XL: Row
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final List<Widget> children;
  final Axis compactDirection;     // XS/SM/MD용 (기본: vertical)
  final Axis expandedDirection;    // LG/XL용 (기본: horizontal)
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveLayout({
    super.key,
    required this.children,
    this.compactDirection = Axis.vertical,
    this.expandedDirection = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize, width) {
        // XS/SM/MD는 compact, LG/XL은 expanded
        final isCompact = screenSize == ScreenSize.xs ||
            screenSize == ScreenSize.sm ||
            screenSize == ScreenSize.md;
        final direction = isCompact ? compactDirection : expandedDirection;

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
