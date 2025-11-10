import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// 다이얼로그 진입/퇴출 애니메이션을 제공하는 믹스인
///
/// 토스 디자인 원칙:
/// - 피드백: 120ms 빠른 진입 애니메이션
/// - 단순함: 페이드인 + 스케일 조합 (0.95 → 1.0)
///
/// 사용법:
/// StatefulWidget with SingleTickerProviderStateMixin에 혼합하여 사용
///
/// ```dart
/// class _MyDialogState extends State<MyDialog>
///     with SingleTickerProviderStateMixin, DialogAnimationMixin {
///   @override
///   void initState() {
///     super.initState();
///     initDialogAnimation();
///   }
///
///   @override
///   void dispose() {
///     disposeDialogAnimation();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return buildAnimatedDialog(
///       Dialog(child: /* ... */),
///     );
///   }
/// }
/// ```
mixin DialogAnimationMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  /// 애니메이션 컨트롤러
  late AnimationController animationController;

  /// 페이드 인/아웃 애니메이션 (0.0 → 1.0)
  late Animation<double> fadeAnimation;

  /// 스케일 애니메이션 (0.95 → 1.0)
  late Animation<double> scaleAnimation;

  /// 애니메이션 초기화
  ///
  /// initState()에서 호출해야 합니다.
  void initDialogAnimation() {
    animationController = AnimationController(
      duration: AppMotion.quick,
      vsync: this,
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: AppMotion.easing),
    );

    scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: AppMotion.easing),
    );

    animationController.forward();
  }

  /// 애니메이션 정리
  ///
  /// dispose()에서 호출해야 합니다.
  void disposeDialogAnimation() {
    animationController.dispose();
  }

  /// 애니메이션이 적용된 다이얼로그 빌드
  ///
  /// [child]에 Dialog 또는 AlertDialog를 전달합니다.
  ///
  /// 예시:
  /// ```dart
  /// return buildAnimatedDialog(
  ///   Dialog(
  ///     child: YourDialogContent(),
  ///   ),
  /// );
  /// ```
  Widget buildAnimatedDialog(Widget child) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, _) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
    );
  }
}
