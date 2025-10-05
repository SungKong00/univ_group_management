import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme.dart';
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
  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceStateProvider);
    final channels = workspaceState.channels;
    final selectedChannel = channels.firstWhere(
      (ch) => ch.id.toString() == widget.channelId,
      orElse: () => Channel(
        id: 0,
        name: '채널',
        description: '',
        type: 'GENERAL',
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
          onPressed: () {
            // 뒤로가기: Step 2 → Step 1
            ref
                .read(workspaceStateProvider.notifier)
                .setMobileView(MobileWorkspaceView.channelList);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedChannel.name,
              style: AppTheme.titleLarge.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            if (selectedChannel.description?.isNotEmpty ?? false)
              Text(
                selectedChannel.description ?? '',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.neutral900),
            onPressed: () {
              // TODO: 채널 설정 메뉴
            },
          ),
        ],
      ),
      body: Column(
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
                  top: BorderSide(
                    color: AppColors.lightOutline,
                    width: 1,
                  ),
                ),
              ),
              child: PostComposer(
                canWrite: widget.permissions?.canWritePost ?? false,
                canUploadFile: widget.permissions?.canUploadFile ?? false,
                isLoading: false,
                onSubmit: (content) => _handleSubmitPost(content),
              ),
            ),
        ],
      ),
    );
  }

  /// 게시글 작성 핸들러
  Future<void> _handleSubmitPost(String content) async {
    if (content.trim().isEmpty) {
      return;
    }

    try {
      await _postService.createPost(widget.channelId, content);

      // 게시글 목록 새로고침
      setState(() {
        _postListKey++;
      });
    } catch (e) {
      // 에러 처리 (TODO: 사용자에게 에러 메시지 표시)
      print('게시글 작성 실패: $e');
    }
  }
}
