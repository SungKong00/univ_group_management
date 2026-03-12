import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// 채널 관련 에러/빈 상태 표시 위젯
///
/// 에러, 권한 없음, 빈 데이터 등의 상태를 일관된 UI로 표시합니다.
class ChannelErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ChannelErrorState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  /// 에러 상태
  factory ChannelErrorState.error(Object error) {
    return ChannelErrorState(
      icon: Icons.error_outline,
      title: '채널을 불러올 수 없습니다',
      subtitle: error.toString(),
    );
  }

  /// 권한 없음 상태
  factory ChannelErrorState.noPermission() {
    return const ChannelErrorState(
      icon: Icons.lock_outline,
      title: '이 채널을 볼 권한이 없습니다',
      subtitle: '권한 관리자에게 문의하세요',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.neutral400),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.headlineMedium.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
