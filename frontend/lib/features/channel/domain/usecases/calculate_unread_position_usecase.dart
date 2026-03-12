import '../entities/unread_position_result.dart';
import '../../../post/domain/entities/post.dart';

/// 읽지 않은 글 위치 계산 UseCase
///
/// 순수 함수로 구현되어 테스트가 용이합니다.
/// Flutter 의존성이 없는 Domain Layer 비즈니스 로직입니다.
///
/// 주요 기능:
/// - 읽지 않은 글의 첫 번째 인덱스 계산
/// - 읽지 않은 글 총 개수 계산
/// - 읽지 않은 글 존재 여부 판단
class CalculateUnreadPositionUseCase {
  /// 읽지 않은 글 위치 계산
  ///
  /// [posts] 게시글 목록 (평탄화된 리스트)
  /// [lastReadPostId] 마지막으로 읽은 게시글 ID (null이면 모두 읽지 않음)
  ///
  /// Returns: UnreadPositionResult
  UnreadPositionResult call(List<Post> posts, int? lastReadPostId) {
    // Edge Case: 빈 게시글 목록
    if (posts.isEmpty) {
      return const UnreadPositionResult(
        unreadIndex: null,
        totalUnread: 0,
        hasUnread: false,
      );
    }

    // Case 1: 읽은 위치 없음 - 모든 게시글이 읽지 않음
    if (lastReadPostId == null) {
      return UnreadPositionResult(
        unreadIndex: 0,
        totalUnread: posts.length,
        hasUnread: true,
      );
    }

    // Case 2: 읽은 위치 있음 - 다음 읽지 않은 게시글 찾기
    final readIndex = posts.indexWhere((post) => post.id == lastReadPostId);

    // Edge Case: 읽은 위치가 목록에 없음 (삭제된 게시글)
    if (readIndex == -1) {
      return UnreadPositionResult(
        unreadIndex: 0,
        totalUnread: posts.length,
        hasUnread: true,
      );
    }

    // Case 3: 모두 읽음 - 마지막 게시글이 읽은 위치
    if (readIndex == posts.length - 1) {
      return const UnreadPositionResult(
        unreadIndex: null,
        totalUnread: 0,
        hasUnread: false,
      );
    }

    // Case 4: 읽지 않은 게시글이 있음
    final firstUnreadIndex = readIndex + 1;
    final totalUnread = posts.length - firstUnreadIndex;

    return UnreadPositionResult(
      unreadIndex: firstUnreadIndex,
      totalUnread: totalUnread,
      hasUnread: true,
    );
  }
}
