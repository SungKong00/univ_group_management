import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/post/presentation/providers/post_list_notifier.dart';
import 'post_empty_state.dart';
import 'post_error_state.dart';
import 'post_skeleton.dart';

/// 게시글 목록 뷰 위젯 (AsyncNotifier 패턴)
///
/// AsyncValue.when() 패턴을 사용하여 로딩/에러/데이터 상태를 처리합니다.
/// - loading: PostListSkeleton 표시
/// - error: PostErrorState 표시 (재시도 버튼)
/// - data: 게시글 목록 또는 빈 상태 표시
///
/// 주의: 이 위젯은 순수 UI 컴포넌트이며, 스크롤 제어 로직은 부모 위젯에서 처리해야 합니다.
class PostListView extends ConsumerWidget {
  final String channelId;
  final Widget Function(dynamic) buildScrollView;

  const PostListView({
    super.key,
    required this.channelId,
    required this.buildScrollView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postListAsync = ref.watch(postListAsyncNotifierProvider(channelId));

    return postListAsync.when(
      loading: () => const PostListSkeleton(),
      error: (error, stack) => PostErrorState(
        errorMessage: error.toString(),
        onRetry: () {
          // AsyncNotifier 재시작
          ref.invalidate(postListAsyncNotifierProvider(channelId));
        },
      ),
      data: (postListState) {
        // 빈 상태 처리
        if (postListState.posts.isEmpty) {
          return const PostEmptyState();
        }

        // 데이터가 있으면 스크롤뷰 렌더링 (부모 위젯에서 제공)
        return buildScrollView(postListState);
      },
    );
  }
}
