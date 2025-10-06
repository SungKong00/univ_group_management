import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 날짜 구분선 위젯
///
/// 날짜가 바뀔 때 게시글 사이에 "── 2025년 10월 5일 ──" 형태로 표시
class DateDivider extends StatelessWidget {
  final DateTime date;

  const DateDivider({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    // 한국어 로케일로 날짜 포맷팅 (fallback 처리)
    String dateText;
    try {
      final formatter = DateFormat('yyyy년 M월 d일', 'ko_KR');
      dateText = formatter.format(date);
    } catch (e) {
      // 로케일 초기화 실패 시 기본 포맷 사용
      final formatter = DateFormat('yyyy-MM-dd');
      dateText = formatter.format(date);
    }

    return Container(
      // Sticky 시 배경색이 필요 (스크롤 시 컨텐츠가 뒤에 보이지 않도록)
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.neutral300,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              dateText,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.neutral300,
            ),
          ),
        ],
      ),
    );
  }
}
