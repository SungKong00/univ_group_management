import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/channel_models.dart';
import '../../../providers/workspace_state_provider.dart';
import '../../../widgets/post/post_list.dart';
import '../../../widgets/post/post_composer.dart';
import '../../../utils/responsive_layout_helper.dart';

/// 채널 콘텐츠 뷰
///
/// 선택된 채널의 게시글 목록과 작성 폼을 표시합니다.
/// 권한 에러 처리와 빈 상태 표시를 담당합니다.
class ChannelContentView extends ConsumerStatefulWidget {
  final List<Channel> channels;
  final String selectedChannelId;
  final ChannelPermissions? channelPermissions;
  final bool isLoadingPermissions;
  final Future<void> Function(String content) onSubmitPost;
  // 새 글 작성 후 목록 재초기화를 트리거하기 위한 키 (부모에서 증가시킴)
  final int postReloadTick;

  const ChannelContentView({
    super.key,
    required this.channels,
    required this.selectedChannelId,
    required this.channelPermissions,
    required this.isLoadingPermissions,
    required this.onSubmitPost,
    this.postReloadTick = 0,
  });

  @override
  ConsumerState<ChannelContentView> createState() => _ChannelContentViewState();
}

class _ChannelContentViewState extends ConsumerState<ChannelContentView> {
  int _postListKey = 0;

  @override
  Widget build(BuildContext context) {
    // 선택된 채널 찾기
    Channel? selectedChannel;
    try {
      selectedChannel = widget.channels.firstWhere(
        (channel) => channel.id.toString() == widget.selectedChannelId,
      );
    } catch (e) {
      selectedChannel = null;
    }

    // 채널을 찾지 못한 경우 fallback
    final channelName = selectedChannel?.name ?? '채널을 불러올 수 없습니다';
    final channelPermissions = widget.channelPermissions;
    final canWritePost = channelPermissions?.canWritePost ?? false;

    // 권한이 없는 경우 권한 에러 표시
    if (channelPermissions != null && !channelPermissions.canViewChannel) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppColors.neutral400),
              const SizedBox(height: 16),
              Text(
                '이 채널을 볼 권한이 없습니다',
                style: AppTheme.headlineMedium.copyWith(
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '권한 관리자에게 문의하세요',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      // 상단 패딩을 4px 줄여(16 -> 12) SizedBox와 합쳐 총 20px 감소
      // 추가로 1px 더 줄여 상단 패딩을 11px로 설정 (총 21px 감소에 해당)
      padding: const EdgeInsets.fromLTRB(16.0, 13.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(channelName, style: AppTheme.headlineMedium),
          // 하단 패딩을 20px 줄임 (원래 16px -> 0px)
          const SizedBox(height: 0),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // ResponsiveLayoutHelper로 반응형 상태 확인
                final responsive = ResponsiveLayoutHelper(
                  context: context,
                  constraints: constraints,
                );
                final isNarrowDesktop = responsive.isNarrowDesktop;

                return PostList(
                  key: ValueKey(
                    'post_list_${widget.selectedChannelId}_${widget.postReloadTick}_$_postListKey',
                  ),
                  channelId: widget.selectedChannelId,
                  canWrite: canWritePost,
                  onTapComment: (postId) {
                    ref
                        .read(workspaceStateProvider.notifier)
                        .showComments(
                          postId.toString(),
                          isNarrowDesktop: isNarrowDesktop,
                        );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    final channelPermissions = widget.channelPermissions;
    final isLoadingPermissions = widget.isLoadingPermissions;

    // Determine if user can write posts
    final canWritePost = channelPermissions?.canWritePost ?? false;
    final canUploadFile = channelPermissions?.canUploadFile ?? false;

    return PostComposer(
      canWrite: canWritePost,
      canUploadFile: canUploadFile,
      isLoading: isLoadingPermissions,
      onSubmit: widget.onSubmitPost,
    );
  }

  /// 게시글 목록 새로고침
  void refreshPostList() {
    setState(() {
      _postListKey++;
    });
  }
}
