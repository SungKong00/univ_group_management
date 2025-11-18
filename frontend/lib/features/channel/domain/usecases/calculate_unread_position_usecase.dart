import '../../../post/domain/entities/post.dart';
import '../entities/unread_position_result.dart';

/// 읽지 않은 게시글 위치를 계산하는 UseCase
///
/// 순수 함수로 구현되어 Side Effect가 없으며, 테스트하기 쉬운 구조입니다.
///
/// 비즈니스 규칙:
/// - 마지막 읽은 위치가 없으면 첫 게시글로 이동
/// - 마지막 읽은 위치가 있으면 그 다음 게시글로 이동
/// - 모두 읽었으면 unreadIndex는 null
class CalculateUnreadPositionUseCase {
  /// 읽지 않은 첫 게시글 위치 계산
  ///
  /// [posts] 게시글 목록 (flat list)
  /// [lastReadPostId] 마지막으로 읽은 게시글 ID (없으면 null)
  ///
  /// Returns: 계산 결과 (UnreadPositionResult)
  UnreadPositionResult call(List<Post> posts, int? lastReadPostId) {
    // Edge case: 빈 리스트
    if (posts.isEmpty) {
      return const UnreadPositionResult(
        unreadIndex: null,
        totalUnread: 0,
        hasUnread: false,
      );
    }

    // Case 1: 읽은 위치 없음 → 첫 게시글로 이동
    if (lastReadPostId == null) {
      return UnreadPositionResult(
        unreadIndex: 0,
        totalUnread: posts.length,
        hasUnread: true,
      );
    }

    // Case 2: 읽은 위치 있음 → 다음 읽지 않은 게시글 찾기
    final lastReadIndex = _findPostIndex(posts, lastReadPostId);

    // 읽은 게시글이 목록에 없음 → 첫 게시글로 이동
    if (lastReadIndex == -1) {
      return UnreadPositionResult(
        unreadIndex: 0,
        totalUnread: posts.length,
        hasUnread: true,
      );
    }

    // 다음 게시글 인덱스 계산
    final nextUnreadIndex = lastReadIndex + 1;

    // Case 3: 모두 읽음
    if (nextUnreadIndex >= posts.length) {
      return const UnreadPositionResult(
        unreadIndex: null,
        totalUnread: 0,
        hasUnread: false,
      );
    }

    // Case 4: 읽지 않은 게시글 있음
    final totalUnread = posts.length - nextUnreadIndex;
    return UnreadPositionResult(
      unreadIndex: nextUnreadIndex,
      totalUnread: totalUnread,
      hasUnread: true,
    );
  }

  /// 게시글 목록에서 특정 ID의 인덱스를 찾는 헬퍼 메서드
  ///
  /// [posts] 게시글 목록
  /// [postId] 찾을 게시글 ID
  ///
  /// Returns: 인덱스 (없으면 -1)
  int _findPostIndex(List<Post> posts, int postId) {
    for (int i = 0; i < posts.length; i++) {
      if (posts[i].id == postId) {
        return i;
      }
    }
    return -1;
  }
}
