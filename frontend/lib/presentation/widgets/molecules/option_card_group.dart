import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Option Card Group
///
/// SelectableOptionCard 리스트를 그리드/수직 레이아웃으로 배치하는 컴포넌트.
///
/// **기능:**
/// - 수직/수평/그리드 레이아웃 지원
/// - AppSpacing 기반 일관된 간격
/// - 반응형 그리드 (2컬럼 기본)
///
/// **사용 예시:**
/// ```dart
/// OptionCardGroup(
///   direction: Axis.vertical,
///   spacing: AppSpacing.md,
///   children: [
///     SelectableOptionCard(...),
///     SelectableOptionCard(...),
///   ],
/// )
/// ```
class OptionCardGroup extends StatelessWidget {
  /// 카드 리스트
  final List<Widget> children;

  /// 레이아웃 방향 (수직/수평)
  /// null인 경우 그리드 레이아웃 사용
  final Axis? direction;

  /// 카드 간 간격 (기본값: AppSpacing.md = 24px)
  final double spacing;

  /// 그리드 컬럼 수 (direction이 null일 때만 사용, 기본값: 2)
  final int gridColumns;

  const OptionCardGroup({
    super.key,
    required this.children,
    this.direction,
    this.spacing = AppSpacing.md,
    this.gridColumns = 2,
  });

  @override
  Widget build(BuildContext context) {
    // 그리드 레이아웃
    if (direction == null) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: gridColumns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1.5, // 카드 비율 조정
        children: children,
      );
    }

    // 수직/수평 레이아웃
    return Flex(
      direction: direction!,
      mainAxisSize: MainAxisSize.min,
      children: _buildFlexChildren(),
    );
  }

  /// Flex 레이아웃용 자식 요소 생성 (간격 포함)
  List<Widget> _buildFlexChildren() {
    if (children.isEmpty) return [];

    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      // 마지막 요소가 아니면 간격 추가
      if (i < children.length - 1) {
        result.add(
          SizedBox(
            width: direction == Axis.horizontal ? spacing : 0,
            height: direction == Axis.vertical ? spacing : 0,
          ),
        );
      }
    }
    return result;
  }
}
