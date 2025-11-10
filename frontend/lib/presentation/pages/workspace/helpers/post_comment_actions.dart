import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snack_bar_helper.dart';
import '../../../providers/workspace_state_provider.dart';
import '../providers/post_actions_provider.dart';
import '../providers/comment_actions_provider.dart';

/// 워크스페이스에서 게시글 및 댓글 작성을 처리하는 Helper 클래스
class PostCommentActions {
  /// 게시글 작성 처리
  static Future<void> handleSubmitPost({
    required BuildContext context,
    required WidgetRef ref,
    required String content,
    required VoidCallback onSuccess,
  }) async {
    final channelId = ref.read(currentChannelIdProvider);

    if (channelId == null) {
      throw Exception('채널을 선택해주세요');
    }

    final params = CreatePostParams(channelId: channelId, content: content);
    final newPost = await ref.read(createPostProvider(params).future);

    // ✅ 새 글 작성 후 읽음 위치 자동 업데이트 (자신의 글은 읽지 않은 글 표시 안 함)
    final channelIdInt = int.tryParse(channelId);
    if (channelIdInt != null) {
      await ref
          .read(workspaceStateProvider.notifier)
          .saveReadPosition(channelIdInt, newPost.id);
      // 뱃지 업데이트 (읽지 않은 글 개수 재계산)
      await ref
          .read(workspaceStateProvider.notifier)
          .loadUnreadCount(channelIdInt);
    }

    // 게시글 작성 성공 후 목록 새로고침
    onSuccess();

    if (context.mounted) {
      AppSnackBar.info(context, '게시글이 작성되었습니다');
    }
  }

  /// 댓글 작성 처리
  static Future<void> handleSubmitComment({
    required BuildContext context,
    required WidgetRef ref,
    required String content,
    required VoidCallback onSuccess,
  }) async {
    final postIdStr = ref.read(workspaceSelectedPostIdProvider);

    if (postIdStr == null) {
      throw Exception('게시글을 선택해주세요');
    }

    final postId = int.parse(postIdStr);
    final params = CreateCommentParams(postId: postId, content: content);
    await ref.read(createCommentProvider(params).future);

    // 댓글 작성 성공 후 목록 새로고침
    onSuccess();

    if (context.mounted) {
      AppSnackBar.info(context, '댓글이 작성되었습니다');
    }
  }
}
