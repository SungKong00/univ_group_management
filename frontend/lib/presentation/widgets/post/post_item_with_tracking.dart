import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../features/post/domain/entities/post.dart';
import '../../../features/channel/presentation/providers/read_position_notifier.dart';
import 'post_item.dart';

/// 가시성 추적이 가능한 게시글 아이템 위젯
///
/// Features:
/// - VisibilityDetector로 가시성 추적
/// - visibleFraction >= 0.3일 때 markAsRead 호출
/// - PostItem 재사용 (DRY 원칙)
class PostItemWithTracking extends ConsumerWidget {
  final Post post;
  final int channelId;
  final VoidCallback? onTapComment;
  final VoidCallback? onTapPost;
  final VoidCallback? onPostUpdated;
  final VoidCallback? onPostDeleted;

  const PostItemWithTracking({
    super.key,
    required this.post,
    required this.channelId,
    this.onTapComment,
    this.onTapPost,
    this.onPostUpdated,
    this.onPostDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VisibilityDetector(
      key: Key('post_${post.id}'),
      onVisibilityChanged: (info) {
        // 30% 이상 보이면 읽음 처리
        if (info.visibleFraction >= 0.3) {
          ref
              .read(readPositionProvider(channelId).notifier)
              .markAsRead(post.id);
        }
      },
      child: PostItem(
        post: post,
        onTapComment: onTapComment,
        onTapPost: onTapPost,
        onPostUpdated: onPostUpdated,
        onPostDeleted: onPostDeleted,
      ),
    );
  }
}
