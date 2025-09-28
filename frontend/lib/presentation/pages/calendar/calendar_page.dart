import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppTheme.brandPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              '캠린더',
              style: AppTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '일정 관리 기능을 개발 예정입니다',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}