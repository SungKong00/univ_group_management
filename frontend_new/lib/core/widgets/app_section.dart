import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/enums.dart';

/// 페이지 섹션 컨테이너
///
/// 페이지를 여러 블록으로 나누고, 중앙 정렬, 최대 너비, 일관된 간격을 제공합니다.
///
/// **책임**:
/// - 섹션 레이아웃 (제목 + 콘텐츠)
/// - 반응형 패딩/간격 (ResponsiveTokens) + 고정 간격 (AppSpacingExtension)
/// - 섹션 스타일 (standard/compact)
/// - 배경색 관리
///
/// **Spacing 구조**:
/// ```
/// 수직 간격: ResponsiveTokens.sectionVerticalGap(width) [반응형]
///   ↓ (모바일: 32px, 태블릿: 48px, 데스크톱: 64px)
/// [섹션]
///   ├─ 제목
///   │  ↓ (고정: 12px)
///   └─ 콘텐츠
/// ```
///
/// **사용 예시**:
/// ```dart
/// // 기본 사용
/// AppSection(
///   title: 'Pricing Plans',
///   child: PricingCardsGrid(),
/// )
///
/// // Compact 스타일 (배경색 자동 적용)
/// AppSection(
///   title: 'Details',
///   child: DetailContent(),
///   variant: SectionVariant.compact,
/// )
///
/// // 커스텀 배경색
/// AppSection(
///   title: 'Custom',
///   child: Content(),
///   backgroundColor: Colors.red,
/// )
/// ```
class AppSection extends StatelessWidget {
  /// 섹션 콘텐츠 (필수)
  final Widget child;

  /// 섹션 제목 (선택)
  final String? title;

  /// 섹션 스타일 (기본값: standard)
  ///
  /// - standard: 투명 배경, 표준 간격
  /// - compact: surfaceSecondary 배경, 50% 축소된 간격
  final SectionVariant variant;

  /// 배경색 (선택, variant 기본값 재정의)
  ///
  /// null이면 variant에 따른 기본값 사용
  final Color? backgroundColor;

  const AppSection({
    super.key,
    required this.child,
    this.title,
    this.variant = SectionVariant.standard,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // ========================================================
    // Step 1: 토큰 추출
    // ========================================================
    final colorExt = context.appColors;
    final spacing = context.appSpacing;
    final width = MediaQuery.sizeOf(context).width;

    // Spacing tokens:
    // - verticalGap: 반응형 (화면 크기별로 다름)
    // - contentGap: 고정값 (4dp 그리드 기반)
    // - horizontalPadding: 반응형
    final verticalGap = ResponsiveTokens.sectionVerticalGap(width);
    final contentGap =
        spacing.medium; // 12px (ResponsiveTokens.sectionContentGap와 동일값)
    final horizontalPadding = ResponsiveTokens.pagePadding(width);
    final maxWidth = ResponsiveTokens.sectionMaxWidth(width);

    // Border & radius
    final borderRadius = BorderTokens.largeRadius();

    // ========================================================
    // Step 2: 배경색 결정 (variant 또는 custom)
    // ========================================================
    final bgColor = _getBackgroundColor(colorExt);

    // ========================================================
    // Step 3: 간격 계산 (variant에 따라)
    // ========================================================
    final (actualVerticalGap, actualContentGap) = _getSpacing(
      verticalGap,
      contentGap,
    );

    // ========================================================
    // Step 4: 제목과 콘텐츠 빌드
    // ========================================================
    final titleWidget = title != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: colorExt.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: actualContentGap),
            ],
          )
        : null;

    // ========================================================
    // Step 5: 컨테이너 조합
    // ========================================================
    return Padding(
      padding: EdgeInsets.symmetric(vertical: actualVerticalGap),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
            ),
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [if (titleWidget != null) titleWidget, child],
            ),
          ),
        ),
      ),
    );
  }

  /// variant에 따른 배경색 결정
  Color _getBackgroundColor(AppColorExtension colors) {
    // 명시적 backgroundColor 있으면 우선
    if (backgroundColor != null) return backgroundColor!;

    // variant에 따른 기본값
    return switch (variant) {
      SectionVariant.standard => Colors.transparent,
      SectionVariant.compact => colors.surfaceSecondary,
    };
  }

  /// variant에 따른 간격 결정
  ///
  /// Returns: (verticalGap, contentGap)
  (double, double) _getSpacing(double verticalGap, double contentGap) {
    return switch (variant) {
      SectionVariant.standard => (verticalGap, contentGap),
      SectionVariant.compact => (verticalGap * 0.3, contentGap * 0.3),
    };
  }
}
