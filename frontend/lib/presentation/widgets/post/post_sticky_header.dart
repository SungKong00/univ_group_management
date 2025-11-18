import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'date_divider.dart';

/// Sticky Date Header 위젯
///
/// 스크롤 시 상단에 고정되는 날짜 헤더입니다.
/// - stickyDate가 null이면 숨김
/// - 테마별 배경색 자동 적용
class PostStickyHeader extends StatelessWidget {
  final DateTime? stickyDate;

  const PostStickyHeader({
    super.key,
    required this.stickyDate,
  });

  @override
  Widget build(BuildContext context) {
    if (stickyDate == null) {
      return const SizedBox.shrink();
    }

    final bgColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkElevated
        : AppColors.lightBackground;

    return Material(
      elevation: 0,
      color: bgColor,
      child: DateDivider(date: stickyDate!),
    );
  }
}
