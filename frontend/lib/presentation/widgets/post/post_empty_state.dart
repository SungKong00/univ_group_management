import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 게시글 빈 상태 위젯
///
/// 채널에 게시글이 없을 때 표시되는 UI입니다.
/// - 한글 메시지 사용
/// - 아이콘 + 텍스트 중앙 정렬
class PostEmptyState extends StatelessWidget {
  const PostEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 게시글이 없습니다',
              style: AppTheme.headlineMedium.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 게시글을 작성해보세요',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
