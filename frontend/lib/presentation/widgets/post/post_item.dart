import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/post_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 개별 게시글 아이템 위젯 (Slack 스타일)
///
/// 프로필 이미지 + 작성자 + 시간 + 본문 + 댓글 버튼
class PostItem extends StatefulWidget {
  final Post post;
  final VoidCallback? onTapComment;
  final VoidCallback? onTapPost;

  const PostItem({
    super.key,
    required this.post,
    this.onTapComment,
    this.onTapPost,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool _isCommentHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTapPost,
      hoverColor: AppColors.neutral100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 이미지
            _buildProfileImage(),
            const SizedBox(width: 12),
            // 콘텐츠 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 + 시간
                  _buildHeader(),
                  const SizedBox(height: 6),
                  // 본문
                  _buildContent(),
                  const SizedBox(height: 12),
                  // 댓글 버튼
                  _buildCommentButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final hasImage = widget.post.authorProfileUrl != null &&
        widget.post.authorProfileUrl!.isNotEmpty;

    if (hasImage) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(widget.post.authorProfileUrl!),
        backgroundColor: AppColors.neutral200,
      );
    }

    // 기본 아바타 (이니셜)
    final initial = widget.post.authorName.isNotEmpty
        ? widget.post.authorName[0].toUpperCase()
        : '?';

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

  Widget _buildHeader() {
    final timeFormatter = DateFormat('a h:mm', 'ko_KR');
    final timeText = timeFormatter.format(widget.post.createdAt);

    return Row(
      children: [
        Text(
          widget.post.authorName,
          style: AppTheme.titleMedium.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '•',
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.neutral500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          timeText,
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Text(
      widget.post.content,
      style: AppTheme.bodyMedium.copyWith(
        color: AppColors.neutral900,
        height: 1.5,
      ),
    );
  }

  Widget _buildCommentButton() {
    final hasComments = widget.post.commentCount > 0;
    String buttonText;

    if (_isCommentHovered && hasComments) {
      buttonText = '댓글 펼치기';
    } else if (hasComments) {
      final lastCommentTime = widget.post.lastCommentAt != null
          ? _formatRelativeTime(widget.post.lastCommentAt!)
          : '';
      buttonText = '${widget.post.commentCount}개의 댓글';
      if (lastCommentTime.isNotEmpty) {
        buttonText += ' • $lastCommentTime';
      }
    } else {
      buttonText = '댓글 작성하기';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isCommentHovered = true),
      onExit: (_) => setState(() => _isCommentHovered = false),
      child: InkWell(
        onTap: widget.onTapComment,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isCommentHovered
                  ? AppColors.brand
                  : Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: _isCommentHovered
                    ? AppColors.brand
                    : AppColors.neutral600,
              ),
              const SizedBox(width: 6),
              Text(
                buttonText,
                style: AppTheme.bodySmall.copyWith(
                  color: _isCommentHovered
                      ? AppColors.brand
                      : AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      final formatter = DateFormat('M월 d일', 'ko_KR');
      return formatter.format(dateTime);
    }
  }
}
