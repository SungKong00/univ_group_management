import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme.dart';
import '../../providers/workspace_state_provider.dart';
import '../comment/comment_list.dart';
import '../comment/comment_composer.dart';
import '../../../core/services/comment_service.dart';
import '../../../core/models/channel_models.dart';

/// 모바일 댓글 뷰 (Step 3: 게시글 선택 후 댓글 목록)
class MobilePostCommentsView extends ConsumerStatefulWidget {
  final String postId;
  final String channelId;
  final String groupId;
  final ChannelPermissions? permissions;

  const MobilePostCommentsView({
    super.key,
    required this.postId,
    required this.channelId,
    required this.groupId,
    this.permissions,
  });

  @override
  ConsumerState<MobilePostCommentsView> createState() =>
      _MobilePostCommentsViewState();
}

class _MobilePostCommentsViewState
    extends ConsumerState<MobilePostCommentsView> {
  int _commentListKey = 0;
  final CommentService _commentService = CommentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
          onPressed: () {
            // 뒤로가기: Step 3 → Step 2
            ref.read(workspaceStateProvider.notifier).handleMobileBack();
          },
        ),
        title: Text(
          '댓글',
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.neutral900),
            onPressed: () {
              // TODO: 댓글 옵션 메뉴
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 댓글 목록
          Expanded(
            child: CommentList(
              key: ValueKey('mobile_comment_list_${widget.postId}_$_commentListKey'),
              postId: int.parse(widget.postId),
            ),
          ),

          // 댓글 작성 입력창
          if (widget.permissions?.canWriteComment ?? false)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.lightOutline,
                    width: 1,
                  ),
                ),
              ),
              child: CommentComposer(
                canWrite: widget.permissions?.canWriteComment ?? false,
                isLoading: false,
                onSubmit: (content) => _handleSubmitComment(content),
              ),
            ),
        ],
      ),
    );
  }

  /// 댓글 작성 핸들러
  Future<void> _handleSubmitComment(String content) async {
    if (content.trim().isEmpty) {
      return;
    }

    try {
      final postIdInt = int.parse(widget.postId);
      await _commentService.createComment(postIdInt, content);

      // 댓글 목록 새로고침
      setState(() {
        _commentListKey++;
      });
    } catch (e) {
      // 에러 처리 (TODO: 사용자에게 에러 메시지 표시)
      print('댓글 작성 실패: $e');
    }
  }
}
