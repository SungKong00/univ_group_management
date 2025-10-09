import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.brand,
            ),
            const SizedBox(height: 16),
            Text('캠린더', style: AppTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              '일정 관리 기능을 개발 예정입니다',
              style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
            ),
          ],
        ),
      ),
    );
  }
}
