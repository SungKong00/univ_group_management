import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/channel_models.dart';
import '../../providers/workspace_state_provider.dart';
import '../post/post_list.dart';
import '../post/post_composer.dart';
import '../../../core/services/post_service.dart';

/// 모바일 게시글 목록 뷰 (Step 2: 채널 선택 후 게시글 목록)
class MobileChannelPostsView extends ConsumerStatefulWidget {
  final String channelId;
  final String groupId;
  final ChannelPermissions? permissions;

  const MobileChannelPostsView({
    super.key,
    required this.channelId,
    required this.groupId,
    this.permissions,
  });

  @override
  ConsumerState<MobileChannelPostsView> createState() =>
      _MobileChannelPostsViewState();
}

class _MobileChannelPostsViewState
    extends ConsumerState<MobileChannelPostsView> {
  int _postListKey = 0;
  int _composerKey = 0;
  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 게시글 목록
        Expanded(
          child: PostList(
            key: ValueKey('mobile_post_list_${widget.channelId}_$_postListKey'),
            channelId: widget.channelId,
            canWrite: widget.permissions?.canWritePost ?? false,
            onTapComment: (postId) {
              // 댓글 버튼 클릭: Step 2 → Step 3
              ref
                  .read(workspaceStateProvider.notifier)
                  .showCommentsForMobile(postId.toString());
            },
          ),
        ),

        // 게시글 작성 입력창
        if (widget.permissions?.canWritePost ?? false)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.lightOutline, width: 1),
              ),
            ),
            child: PostComposer(
              key: ValueKey('post_composer_${widget.channelId}_$_composerKey'),
              canWrite: widget.permissions?.canWritePost ?? false,
              canUploadFile: widget.permissions?.canUploadFile ?? false,
              isLoading: false,
              onSubmit: (content) => _handleSubmitPost(content),
            ),
          ),
      ],
    );
  }

  /// 게시글 작성 핸들러
  Future<void> _handleSubmitPost(String content) async {
    if (content.trim().isEmpty) {
      return;
    }

    try {
      final newPost = await _postService.createPost(widget.channelId, content);

      // ✅ 새 글 작성 후 읽음 위치 자동 업데이트 (자신의 글은 읽지 않은 글 표시 안 함)
      final channelIdInt = int.tryParse(widget.channelId);
      if (channelIdInt != null) {
        await ref
            .read(workspaceStateProvider.notifier)
            .saveReadPosition(channelIdInt, newPost.id);
        // 뱃지 업데이트 (읽지 않은 글 개수 재계산)
        await ref
            .read(workspaceStateProvider.notifier)
            .loadUnreadCount(channelIdInt);
      }

      // 게시글 목록 및 작성기 새로고침
      setState(() {
        _postListKey++;
        _composerKey++;
      });
    } catch (e) {
      // 에러 처리 (TODO: 사용자에게 에러 메시지 표시)
      if (kDebugMode) {
        developer.log('게시글 작성 실패: $e', name: 'MobileChannelPostsView');
      }
    }
  }
}
