import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 읽지 않은 글 구분선 위젯
///
/// 읽지 않은 글 중 가장 오래된 글 위에 표시됩니다.
///
/// Features:
/// - "읽지 않은 글" 텍스트 표시
/// - 브랜드 컬러 강조선 (빨간색 대신 보라색)
/// - 읽지 않은 글 개수 표시
class UnreadDivider extends StatelessWidget {
  final int unreadCount;

  const UnreadDivider({super.key, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.brandLight.withOpacity(0.1),
      child: Row(
        children: [
          // 좌측 라인
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brandLight.withOpacity(0.1),
                    AppColors.brand,
                  ],
                ),
              ),
            ),
          ),
          // 텍스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '읽지 않은 글 ($unreadCount)',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 우측 라인
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brand,
                    AppColors.brandLight.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
