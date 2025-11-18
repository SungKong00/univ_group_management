import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/widgets/comment/comment_item.dart';
import '../../../../presentation/widgets/common/app_empty_state.dart';
import '../../domain/entities/comment.dart';
import '../providers/comment_list_notifier.dart';
import '../utils/comment_converter.dart';

/// 댓글 목록 위젯 (Clean Architecture)
///
/// commentListProvider를 감시하여 댓글 목록을 표시합니다.
/// - 로딩: CircularProgressIndicator 표시
/// - 에러: 에러 메시지 표시
/// - 빈 목록: AppEmptyState.noComments() 표시
/// - 데이터: 댓글 목록 표시 (CommentItem 사용)
///
/// Features:
/// - AsyncValue.when() 패턴 사용
/// - 삭제 기능 지원 (CommentListNotifier.deleteComment 호출)
/// - 100줄 원칙 준수
class CommentListView extends ConsumerWidget {
  final int postId;
  final VoidCallback? onTapReply;

  const CommentListView({
    super.key,
    required this.postId,
    this.onTapReply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // commentListProvider 감시 (자동 로딩)
    final commentsAsync = ref.watch(commentListProvider(postId));

    return commentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildError(error),
      data: (comments) => _buildCommentList(comments, ref),
    );
  }

  /// 에러 상태 UI
  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  /// 댓글 목록 UI
  Widget _buildCommentList(List<Comment> comments, WidgetRef ref) {
    // 빈 댓글 목록
    if (comments.isEmpty) {
      return AppEmptyState.noComments();
    }

    // 댓글 목록 표시
    return ListView.builder(
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];

        // Old Comment model로 변환 (CommentItem 호환성)
        final oldComment = CommentConverter.toOldComment(comment);

        return CommentItem(
          comment: oldComment,
          onTapReply: onTapReply,
          onTapDelete: () => _handleDelete(ref, comment.id),
        );
      },
    );
  }

  /// 댓글 삭제 핸들러
  Future<void> _handleDelete(WidgetRef ref, int commentId) async {
    final notifier = ref.read(commentListProvider(postId).notifier);
    await notifier.deleteComment(commentId);
  }
}
