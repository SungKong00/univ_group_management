import 'package:flutter/material.dart';

/// 월간 캘린더 셀 내부에 표시되는 일정 칩 위젯
///
/// 개인 캘린더와 그룹 캘린더 모두에서 사용되는 공통 UI 컴포넌트입니다.
///
/// 스타일:
/// - 둥근 모서리 (8px)
/// - 투명한 배경색 (색상의 12% 불투명도)
/// - 색상 테두리 (1.5px)
/// - 그림자 효과
/// - 텍스트: 제목만 표시 (ellipsis)
class MonthEventChip extends StatelessWidget {
  final String label;
  final Color color;

  const MonthEventChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
