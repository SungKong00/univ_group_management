import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_outlined,
              size: 64,
              color: AppColors.brand,
            ),
            const SizedBox(height: 16),
            Text(
              '나의 활동',
              style: AppTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '내 참여 기록을 확인할 수 있습니다',
              style: AppTheme.bodyLarge.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}