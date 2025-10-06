import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_theme.dart';

/// 그룹 관리자 페이지
///
/// 그룹 권한을 가진 사용자가 그룹 설정 및 관리 작업을 수행하는 페이지입니다.
/// 현재는 기본 구조만 구현되어 있으며, 향후 그룹 관리 기능이 추가될 예정입니다.
class GroupAdminPage extends StatelessWidget {
  const GroupAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '관리자 페이지',
          style: AppTheme.headlineMedium.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 64,
              color: AppColors.neutral400,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              '관리자 페이지',
              style: AppTheme.headlineMedium.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '(준비 중)',
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
