import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/post_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snack_bar_helper.dart';
import '../../providers/auth_provider.dart';
import '../common/collapsible_content.dart';
import '../common/option_menu.dart';
import 'edit_post_dialog.dart';
import 'delete_post_dialog.dart';

/// 개별 게시글 아이템 위젯 (Slack 스타일)
///
/// 프로필 이미지 + 작성자 + 시간 + 본문 + 댓글 버튼
class PostItem extends ConsumerStatefulWidget {
  final Post post;
  final VoidCallback? onTapComment;
  final VoidCallback? onTapPost;
  final VoidCallback? onPostUpdated;
  final VoidCallback? onPostDeleted;

  const PostItem({
    super.key,
    required this.post,
    this.onTapComment,
    this.onTapPost,
    this.onPostUpdated,
    this.onPostDeleted,
  });

  @override
  ConsumerState<PostItem> createState() => _PostItemState();
}

class _PostItemState extends ConsumerState<PostItem> {
  bool _isCommentHovered = false;

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => EditPostDialog(
        postId: widget.post.id,
        initialContent: widget.post.content,
        onSuccess: widget.onPostUpdated,
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => DeletePostDialog(
        postId: widget.post.id,
        onSuccess: widget.onPostDeleted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    final currentUser = ref.watch(currentUserProvider);
    final isAuthor = currentUser?.id == widget.post.authorId;

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
                  _buildHeader(isAuthor),
                  const SizedBox(height: 6),
                  // 본문
                  _buildContent(),
                  const SizedBox(height: 12),
                  // 댓글 버튼 (모바일: 패딩 축소)
                  Padding(
                    padding: EdgeInsets.only(right: isMobile ? 8 : 64),
                    child: _buildCommentButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final hasImage =
        widget.post.authorProfileUrl != null &&
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
        style: AppTheme.titleMedium.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(bool isAuthor) {
    // 수정 여부 판단: updatedAt이 null이 아니고, createdAt과 다른 경우
    final isEdited = widget.post.updatedAt != null &&
        widget.post.updatedAt != widget.post.createdAt;

    // 작성 시간 (항상 표시)
    final timeFormatter = DateFormat('HH:mm', 'ko_KR');
    final createdTimeText = timeFormatter.format(widget.post.createdAt);

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
          style: AppTheme.bodySmall.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(width: 8),
        // 작성 시간 (항상 표시)
        Text(
          createdTimeText,
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.neutral600,
          ),
        ),
        // 수정된 경우 추가 표시
        if (isEdited) ...[
          const SizedBox(width: 8),
          Text(
            '•',
            style: AppTheme.bodySmall.copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('MM/dd HH:mm', 'ko_KR').format(widget.post.updatedAt!)} 수정됨',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.neutral500,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(width: 8),
        OptionMenu(
          items: [
            // 작성자 본인만 수정/삭제 가능
            if (isAuthor) ...[
              OptionMenuItem(
                label: '수정',
                icon: Icons.edit_outlined,
                onTap: _showEditDialog,
              ),
            ],
            // 모든 사용자가 신고 가능
            OptionMenuItem(
              label: '신고하기',
              icon: Icons.flag_outlined,
              onTap: () {
                // TODO: 신고 기능 구현
                AppSnackBar.info(context, '신고 기능은 추후 구현 예정입니다.');
              },
            ),
            // 삭제는 가장 위험한 액션이므로 맨 아래 배치
            if (isAuthor)
              OptionMenuItem(
                label: '삭제',
                icon: Icons.delete_outline,
                onTap: _showDeleteDialog,
                isDestructive: true,
              ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildContent() {
    // 반응형 maxLines 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600; // 기존 브레이크포인트 유지
    final maxLines = isMobile ? 10 : 20;

    return CollapsibleContent(
      content: widget.post.content,
      maxLines: maxLines,
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
      final lastCommentTime = widget.post.lastCommentedAt != null
          ? _formatRelativeTime(widget.post.lastCommentedAt!)
          : '';
      buttonText = '${widget.post.commentCount}개의 댓글';
      if (lastCommentTime.isNotEmpty) {
        buttonText += ' • $lastCommentTime';
      }
    } else {
      buttonText = '댓글 작성하기';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 너비 파악
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth <= 600;

        // 반응형 너비 계산
        // 모바일: 부모(게시글 콘텐츠) 너비의 85% (오버플로우 방지)
        // 웹: 최대 800px
        final buttonWidth = isMobile ? constraints.maxWidth * 0.85 : 800.0;

        return MouseRegion(
          onEnter: (_) => setState(() => _isCommentHovered = true),
          onExit: (_) => setState(() => _isCommentHovered = false),
          child: InkWell(
            onTap: widget.onTapComment,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: buttonWidth,
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
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽: 아이콘 + 텍스트 (오버플로우 방지)
                  Flexible(
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
                        Flexible(
                          child: Text(
                            buttonText,
                            style: AppTheme.bodySmall.copyWith(
                              color: _isCommentHovered
                                  ? AppColors.brand
                                  : AppColors.neutral700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 오른쪽: ">" 아이콘
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: _isCommentHovered
                        ? AppColors.brand
                        : AppColors.neutral600,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
