import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 날짜 구분선 위젯
///
/// 날짜가 바뀔 때 게시글 사이에 "── 2025년 10월 5일 ──" 형태로 표시
class DateDivider extends StatelessWidget {
  final DateTime date;

  const DateDivider({super.key, required this.date});

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

    // 라이트 모드에서는 게시글 패딩 배경인 lightBackground(neutral100)를 사용하고,
    // 다크 모드에서는 elevated surface를 사용하여 이질감이 없도록 처리합니다.
    final bgColor = context.isDarkMode
        ? AppColors.darkElevated
        : AppColors.lightBackground;

    // 구분선과 텍스트 색은 현재 테마의 outline/onSurface를 기반으로 선택
    final outlineColor = Theme.of(context).colorScheme.outline;
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: bgColor,
      child: Container(
        // 상하 패딩을 조정해 선이 텍스트에 더 가깝게 위치하도록 함
        padding: const EdgeInsets.only(top: 4.0, bottom: 0.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 1,
                    // 테마 outline 색 사용
                    color: outlineColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  dateText,
                  style: AppTheme.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(height: 1, color: outlineColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
