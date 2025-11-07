import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../../core/models/post_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../common/collapsible_content.dart';

/// 게시글 미리보기 카드 위젯
///
/// 댓글 화면 상단에 부모 게시글을 요약 형태로 표시합니다.
/// - 작성자 프로필 + 이름 + 시간
/// - 본문 (3-5줄 미리보기, CollapsibleContent로 펼치기/접기)
/// - 카드 형태 디자인 (배경색으로 댓글 영역과 구분)
///
/// 사용 예시:
/// ```dart
/// PostPreviewCard(
///   post: post,
///   maxLines: 5,
/// )
/// ```
class PostPreviewCard extends StatelessWidget {
  /// 미리보기할 게시글
  final Post post;

  /// 본문 미리보기 최대 줄 수 (기본값: 5)
  final int maxLines;

  const PostPreviewCard({super.key, required this.post, this.maxLines = 5});

  @override
  Widget build(BuildContext context) {
    // 화면 크기로 모바일 여부 판단 (responsive_framework 토큰 사용)
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final isMobile = !isDesktop;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightOutline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 프로필 + 작성자 + 시간
          _buildHeader(),
          const SizedBox(height: 12),
          // 본문 (펼치기/접기 가능) - 프로필 이미지와 정렬
          Padding(
            padding: const EdgeInsets.only(left: 52), // 프로필(40) + 간격(12) = 52
            child: CollapsibleContent(
              content: post.content,
              maxLines: maxLines,
              style: AppTheme.bodyMedium,
              // 모바일에서는 펼쳤을 때 내부 스크롤을 허용하고 10줄까지 보이게 함
              expandedScrollable: isMobile,
              expandedMaxLines: isMobile ? 10 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // 프로필 이미지
        _buildProfileImage(),
        const SizedBox(width: 12),
        // 작성자 + 시간
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDateTime(post.createdAt),
                style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    final hasImage =
        post.authorProfileUrl != null && post.authorProfileUrl!.isNotEmpty;

    if (hasImage) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(post.authorProfileUrl!),
        backgroundColor: AppColors.neutral200,
      );
    }

    // 기본 아바타 (이니셜)
    final initial = post.authorName.isNotEmpty
        ? post.authorName[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.brand,
      child: Text(
        initial,
        style: AppTheme.titleMedium.copyWith(color: Colors.white),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // 오늘 날짜면 시간만 표시
    if (difference.inDays == 0) {
      final timeFormatter = DateFormat('a h:mm', 'ko_KR');
      return timeFormatter.format(dateTime);
    }

    // 어제면 "어제" 표시
    if (difference.inDays == 1) {
      return '어제';
    }

    // 일주일 이내면 상대 시간
    if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    }

    // 그 외는 날짜 표시
    final dateFormatter = DateFormat('M월 d일', 'ko_KR');
    return dateFormatter.format(dateTime);
  }
}
