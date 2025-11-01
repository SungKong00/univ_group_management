import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/post_models.dart';
import 'post_preview_notifier.dart';

/// 게시글 작성 요청 파라미터
class CreatePostParams {
  final String channelId;
  final String content;

  const CreatePostParams({required this.channelId, required this.content});
}

/// 게시글 수정 요청 파라미터
class UpdatePostParams {
  final int postId;
  final String content;

  const UpdatePostParams({required this.postId, required this.content});
}

/// 게시글 작성 Provider
///
/// Usage:
/// ```dart
/// final result = await ref.read(createPostProvider(params).future);
/// ```
final createPostProvider = FutureProvider.autoDispose
    .family<Post, CreatePostParams>((ref, params) async {
      final postService = ref.read(postServiceProvider);
      return await postService.createPost(params.channelId, params.content);
    });

/// 게시글 수정 Provider
///
/// Usage:
/// ```dart
/// final result = await ref.read(updatePostProvider(params).future);
/// ```
final updatePostProvider = FutureProvider.autoDispose
    .family<Post, UpdatePostParams>((ref, params) async {
      final postService = ref.read(postServiceProvider);
      return await postService.updatePost(params.postId, params.content);
    });

/// 게시글 삭제 Provider
///
/// Usage:
/// ```dart
/// await ref.read(deletePostProvider(postId).future);
/// ```
final deletePostProvider = FutureProvider.autoDispose.family<void, int>((
  ref,
  postId,
) async {
  final postService = ref.read(postServiceProvider);
  await postService.deletePost(postId);
});

/// 게시글 단일 조회 Provider
///
/// Usage:
/// ```dart
/// final postAsync = ref.watch(fetchSinglePostProvider(postId));
/// postAsync.when(
///   data: (post) => ...,
///   loading: () => ...,
///   error: (err, stack) => ...,
/// );
/// ```
final fetchSinglePostProvider = FutureProvider.autoDispose.family<Post, int>((
  ref,
  postId,
) async {
  final postService = ref.read(postServiceProvider);
  return await postService.getPost(postId);
});
