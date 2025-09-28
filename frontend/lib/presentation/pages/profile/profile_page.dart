import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_outline,
              size: 64,
              color: AppTheme.brandPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              '프로필',
              style: AppTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '계정 설정 및 프로필 관리',
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