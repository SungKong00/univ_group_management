import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// 섹션 카드 컴포넌트
///
/// 일관된 스타일의 카드 컨테이너를 제공하는 재사용 가능한 컴포넌트입니다.
/// Container + BoxDecoration 패턴을 대체하여 코드 중복을 줄이고 일관성을 유지합니다.
///
/// **기본 사용 예시**:
/// ```dart
/// SectionCard(
///   child: Text('카드 내용'),
/// )
/// ```
///
/// **커스텀 패딩**:
/// ```dart
/// SectionCard(
///   padding: EdgeInsets.all(AppSpacing.lg),
///   child: MyWidget(),
/// )
/// ```
///
/// **그림자 없음**:
/// ```dart
/// SectionCard(
///   showShadow: false,
///   child: MyWidget(),
/// )
/// ```
///
/// **커스텀 배경색**:
/// ```dart
/// SectionCard(
///   backgroundColor: AppColors.lightBackground,
///   child: MyWidget(),
/// )
/// ```
class SectionCard extends StatelessWidget {
  /// 카드 내부에 표시할 위젯 (필수)
  final Widget child;

  /// 패딩 (기본값: EdgeInsets.all(AppSpacing.md) = 24px)
  final EdgeInsets? padding;

  /// 그림자 표시 여부 (기본값: true)
  final bool showShadow;

  /// 배경색 (기본값: Colors.white)
  final Color? backgroundColor;

  /// 테두리 반경 (기본값: AppRadius.card = 20px)
  final double? borderRadius;

  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.showShadow = true,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.card),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
