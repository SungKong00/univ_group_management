import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/comment_models.dart';
import '../../../../core/services/comment_service.dart';

/// CommentService Provider (Singleton)
final commentServiceProvider = Provider<CommentService>((ref) {
  return CommentService();
});

/// 댓글 작성 요청 파라미터
class CreateCommentParams {
  final int postId;
  final String content;
  final int? parentCommentId;

  const CreateCommentParams({
    required this.postId,
    required this.content,
    this.parentCommentId,
  });
}

/// 댓글 작성 Provider
///
/// Usage:
/// ```dart
/// final params = CreateCommentParams(postId: 123, content: '댓글 내용');
/// final result = await ref.read(createCommentProvider(params).future);
/// ```
final createCommentProvider = FutureProvider.autoDispose
    .family<Comment, CreateCommentParams>((ref, params) async {
      final commentService = ref.read(commentServiceProvider);
      return await commentService.createComment(
        params.postId,
        params.content,
        parentCommentId: params.parentCommentId,
      );
    });

/// 댓글 목록 조회 Provider
///
/// Usage:
/// ```dart
/// final commentsAsync = ref.watch(fetchCommentsProvider(postId));
/// ```
final fetchCommentsProvider = FutureProvider.autoDispose
    .family<List<Comment>, int>((ref, postId) async {
      final commentService = ref.read(commentServiceProvider);
      return await commentService.fetchComments(postId);
    });
