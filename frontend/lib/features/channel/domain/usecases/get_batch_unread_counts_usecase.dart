import '../repositories/read_position_repository.dart';

/// Batch Unread Count UseCase
///
/// 여러 채널의 읽지 않은 글 개수를 일괄 조회합니다.
/// 채널 전환 시 모든 채널의 뱃지를 동시 갱신하는 데 사용됩니다.
class GetBatchUnreadCountsUseCase {
  final ReadPositionRepository _repository;

  GetBatchUnreadCountsUseCase(this._repository);

  /// 여러 채널의 읽지 않은 글 개수 조회
  ///
  /// [channelIds] 조회할 채널 ID 목록
  /// Returns {channelId: unreadCount} Map
  Future<Map<int, int>> call(List<int> channelIds) async {
    final counts = <int, int>{};

    // 각 채널의 읽지 않은 글 개수 조회
    for (final channelId in channelIds) {
      try {
        final count = await _repository.getUnreadCount(channelId);
        counts[channelId] = count;
      } catch (e) {
        // 개별 채널 실패해도 다른 채널 계속 조회
        counts[channelId] = 0;
      }
    }

    return counts;
  }
}
