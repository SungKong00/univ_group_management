import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/responsive_tokens.dart';

/// 반응형 카드 그리드 레이아웃
///
/// Material Design 3 breakpoints 기반으로 화면 크기에 따라 자동으로
/// 열 개수를 조정하는 재사용 가능한 그리드 컴포넌트입니다.
///
/// **핵심 기능:**
/// - maxItemWidth 기준으로 열 개수 자동 계산
/// - 화면이 넓을 때 가운데 정렬 + 최대 폭 제한
/// - ResponsiveTokens 기반 디자인 시스템 준수
/// - 카드 개수 제한 없음 (itemCount만 맞으면 동작)
///
/// **사용 예시:**
/// ```dart
/// ResponsiveCardGrid(
///   itemCount: pricingPlans.length,
///   itemBuilder: (context, index) => PricingCard(plan: pricingPlans[index]),
///   childAspectRatio: 4 / 5,  // 카드 비율 (가로/세로)
///   maxItemWidth: 360,        // 선택 (기본값 360)
/// )
/// ```
class ResponsiveCardGrid extends StatelessWidget {
  /// 그리드에 표시할 아이템 개수
  final int itemCount;

  /// 인덱스 기반 아이템 빌더
  final IndexedWidgetBuilder itemBuilder;

  /// 카드 하나의 최대 폭 (이 값을 기준으로 열 개수가 자동 계산됨)
  ///
  /// 프로젝트 기본값: 360px (Material Design 3 최적 카드 폭)
  final double maxItemWidth;

  /// 카드 비율 (가로 / 세로)
  ///
  /// **예시:**
  /// - PricingCard: 4 / 5 (세로로 약간 긴 형태)
  /// - CustomerCard: 4 / 5
  /// - 정사각형 카드: 1 / 1
  /// - 가로로 긴 카드: 16 / 9
  final double childAspectRatio;

  /// 카드 간 간격 (선택)
  ///
  /// null이면 자동으로 ResponsiveTokens.cardGap(width) 사용
  /// - 모바일(< 600px): 12px
  /// - 태블릿+(≥ 600px): 16px
  final double? spacing;

  const ResponsiveCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.childAspectRatio,
    this.maxItemWidth = 360,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    // MediaQuery.sizeOf() 사용 (성능 최적화)
    final width = MediaQuery.sizeOf(context).width;

    // 디자인 시스템 토큰 기반 간격 계산
    final gap = spacing ?? ResponsiveTokens.cardGap(width);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // 1. 이 너비에서 들어갈 수 있는 최대 열 개수 추정
        //    예: 1200px / (360px + 16px) = 3.19 → 3열
        final estimatedColumns = math.max(
          1,
          (availableWidth / (maxItemWidth + gap)).floor(),
        );

        // 2. 실제 그리드가 차지할 폭 계산
        //    예: 3열 × 360px + 2개 간격 × 16px = 1112px
        final gridWidth = math.min(
          availableWidth,
          estimatedColumns * maxItemWidth + (estimatedColumns - 1) * gap,
        );

        // 3. 가운데 정렬 + GridView 렌더링
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: gridWidth,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxItemWidth,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: itemCount,
              itemBuilder: itemBuilder,
            ),
          ),
        );
      },
    );
  }
}
