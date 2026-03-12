import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/workspace_state_provider.dart';
import '../../pages/workspace/widgets/post_preview_widget.dart';
import '../comment/comment_list.dart';
import '../comment/comment_composer.dart';
import '../../pages/workspace/helpers/post_comment_actions.dart';

/// 댓글 사이드바 뷰 위젯
///
/// 게시글 미리보기, 댓글 목록, 댓글 작성 폼을 포함하는
/// 데스크톱 모드의 댓글 사이드바 컴포넌트
class CommentsSidebarView extends ConsumerWidget {
  final VoidCallback onClose;
  final int commentListKey;
  final VoidCallback onCommentSubmitted;

  const CommentsSidebarView({
    super.key,
    required this.onClose,
    required this.commentListKey,
    required this.onCommentSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postIdStr = ref.watch(workspaceSelectedPostIdProvider);
    final postId = postIdStr != null ? int.tryParse(postIdStr) : null;
    final channelPermissions = ref.watch(workspaceChannelPermissionsProvider);
    final canWrite = channelPermissions?.canWriteComment ?? false;
    final isLoadingPermissions = ref.watch(
      workspaceIsLoadingPermissionsProvider,
    );

    return Stack(
      children: [
        Column(
          children: [
            // 게시글 미리보기
            PostPreviewWidget(onClose: onClose),

            const Divider(height: 1, thickness: 1),

            // 댓글 목록
            if (postId != null)
              Expanded(
                child: CommentList(
                  key: ValueKey('comment_list_${postId}_$commentListKey'),
                  postId: postId,
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    '게시글을 선택해주세요',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ),
            // 댓글 입력창
            if (postId != null)
              Padding(
                padding: EdgeInsets.all(AppSpacing.xs),
                child: CommentComposer(
                  canWrite: canWrite,
                  isLoading: isLoadingPermissions,
                  onSubmit: (content) => PostCommentActions.handleSubmitComment(
                    context: context,
                    ref: ref,
                    content: content,
                    onSuccess: onCommentSubmitted,
                  ),
                ),
              ),
          ],
        ),
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
}
