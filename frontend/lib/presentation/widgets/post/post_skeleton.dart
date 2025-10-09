import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 게시글 로딩 스켈레톤 UI
///
/// 게시글 목록 로딩 중 표시되는 플레이스홀더
class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지 스켈레톤
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 12),
          // 콘텐츠 스켈레톤
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자명 + 시간 스켈레톤
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 본문 스켈레톤
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 150,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // 댓글 버튼 스켈레톤
                Container(
                  width: 100,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 여러 개의 게시글 스켈레톤을 표시
class PostListSkeleton extends StatelessWidget {
  final int count;

  const PostListSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: count,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppColors.neutral200),
      itemBuilder: (context, index) => const PostSkeleton(),
    );
  }
}
