import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../presentation/widgets/post/post_list.dart';
import '../../../../presentation/widgets/post/post_composer.dart';
import '../../domain/entities/channel.dart';
import '../providers/channel_entry_notifier.dart';
import 'channel_error_state.dart';

/// 채널 뷰 위젯 (Clean Architecture)
///
/// channelEntryProvider를 감시하여 채널 진입 시 필요한 데이터를 로드합니다.
/// - 로딩: CircularProgressIndicator 표시
/// - 에러: 에러 메시지 표시
/// - 데이터: 게시글 목록 + 작성 폼 표시
///
/// Features:
/// - AsyncValue.when() 패턴 사용
/// - Race Condition 방지 (EnterChannelUseCase 병렬 로딩)
/// - 권한 기반 UI 제어 (POST_READ, POST_WRITE)
class ChannelView extends ConsumerWidget {
  final Channel channel;
  final Function(int postId)? onTapComment;
  final Future<void> Function(String content) onSubmitPost;
  final int postReloadTick;

  const ChannelView({
    super.key,
    required this.channel,
    required this.onSubmitPost,
    this.onTapComment,
    this.postReloadTick = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // channelEntryProvider 감시 (자동 로딩)
    final entryState = ref.watch(channelEntryProvider(channel));

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 13.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 채널 이름 헤더
          Text(channel.name, style: AppTheme.headlineMedium),
          const SizedBox(height: 0),

          // 게시글 목록 영역
          Expanded(
            child: entryState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ChannelErrorState.error(error),
              data: (result) => _buildContent(result, ref),
            ),
          ),

          // 게시글 작성 폼
          _buildComposer(entryState),
        ],
      ),
    );
  }

  /// 데이터 로드 완료 상태 UI
  Widget _buildContent(dynamic result, WidgetRef ref) {
    final permissions = result.permissions;

    // 권한 체크 (POST_READ)
    if (!permissions.canReadPosts) {
      return ChannelErrorState.noPermission();
    }

    // 게시글 목록 표시
    return PostList(
      key: ValueKey('post_list_${channel.id}_$postReloadTick'),
      channelId: channel.id.toString(),
      canWrite: permissions.canWritePosts,
      onTapComment: onTapComment,
    );
  }

  /// 게시글 작성 폼
  Widget _buildComposer(AsyncValue<dynamic> entryState) {
    return entryState.when(
      data: (result) => PostComposer(
        canWrite: result.permissions.canWritePosts,
        canUploadFile: result.permissions.hasPermission('FILE_UPLOAD'),
        isLoading: false,
        onSubmit: onSubmitPost,
      ),
      loading: () => PostComposer(
        canWrite: false,
        canUploadFile: false,
        isLoading: true,
        onSubmit: onSubmitPost,
      ),
      error: (_, __) => PostComposer(
        canWrite: false,
        canUploadFile: false,
        isLoading: false,
        onSubmit: onSubmitPost,
      ),
    );
  }
}
