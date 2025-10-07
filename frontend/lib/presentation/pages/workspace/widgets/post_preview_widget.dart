import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/post_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../widgets/common/collapsible_content.dart';
import '../providers/post_preview_notifier.dart';

/// 게시글 미리보기 위젯
///
/// 웹 데스크톱 댓글 사이드바에서 선택된 게시글 정보를 표시
/// Provider 기반으로 상태 관리
class PostPreviewWidget extends ConsumerWidget {
  /// X 버튼 클릭 시 호출될 콜백
  final VoidCallback onClose;

  const PostPreviewWidget({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewState = ref.watch(postPreviewProvider);

    return Stack(
      children: [
        // 메인 컨텐츠
        _buildContent(previewState),
        // X 버튼 (우측 상단)
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            iconSize: 20,
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(PostPreviewState state) {
    // 로딩 중
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 에러 발생
    if (state.errorMessage != null) {
      return _buildErrorState(state.errorMessage!);
    }

    // 게시글 로드 성공
    if (state.post != null) {
      return _buildPostContent(state.post!);
    }

    // 빈 상태 (정상적으로는 발생하지 않음)
    return const SizedBox.shrink();
  }

  Widget _buildErrorState(String errorMessage) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(244, 67, 54, 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent(Post post) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 프로필 + 작성자 + 시간 (X 버튼 공간 확보를 위해 우측 패딩 추가)
          Padding(
            padding: const EdgeInsets.only(right: 40), // X 버튼 영역 확보
            child: _buildPostHeader(post),
          ),
          const SizedBox(height: 12),
          // 본문 (펼치기/접기 가능)
          Padding(
            padding: const EdgeInsets.only(left: 52), // 프로필(40) + 간격(12) = 52
            child: CollapsibleContent(
              content: post.content,
              maxLines: 5,
              style: AppTheme.bodyMedium,
              expandedScrollable: true,
            ),
          ),
          const SizedBox(height: 16),
          // 작성일 (고정)
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              DateFormatter.formatFullDate(post.createdAt),
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostHeader(Post post) {
    return Row(
      children: [
        // 프로필 이미지
        _buildPostProfileImage(post),
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
                DateFormatter.formatRelativeTime(post.createdAt),
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostProfileImage(Post post) {
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
    final initial =
        post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.brand,
      child: Text(
        initial,
        style: AppTheme.titleMedium.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}
