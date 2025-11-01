import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/comment_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme.dart';
import '../common/option_menu.dart';

/// 개별 댓글 아이템 위젯
class CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onTapReply;
  final VoidCallback? onTapDelete;

  const CommentItem({
    super.key,
    required this.comment,
    this.onTapReply,
    this.onTapDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: comment.depth > 0 ? 32.0 : AppSpacing.xs,
        top: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileImage(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 6),
                _buildContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    final hasImage =
        comment.authorProfileUrl != null &&
        comment.authorProfileUrl!.isNotEmpty;

    if (hasImage) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(comment.authorProfileUrl!),
        backgroundColor: AppColors.neutral200,
      );
    }

    final initial = comment.authorName.isNotEmpty
        ? comment.authorName[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.neutral400,
      child: Text(
        initial,
        style: AppTheme.bodySmall.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    final timeFormatter = DateFormat('a h:mm', 'ko_KR');
    final timeText = timeFormatter.format(comment.createdAt);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                comment.authorName,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: AppTheme.bodySmall.copyWith(color: AppColors.neutral500),
              ),
            ],
          ),
        ),
        // TODO: 기능 연결 필요
        OptionMenu(
          items: [
            OptionMenuItem(
              label: '수정',
              icon: Icons.edit_outlined,
              onTap: () {},
            ),
            OptionMenuItem(
              label: '신고하기',
              icon: Icons.flag_outlined,
              onTap: () {},
            ),
            OptionMenuItem(
              label: '삭제',
              icon: Icons.delete_outline,
              onTap: () {},
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Text(
      comment.content,
      style: AppTheme.bodyMedium.copyWith(
        color: AppColors.neutral900,
        height: 1.4,
      ),
    );
  }
}
