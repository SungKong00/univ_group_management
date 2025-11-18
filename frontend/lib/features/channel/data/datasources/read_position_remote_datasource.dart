import '../../../../core/services/channel_service.dart';

/// 읽기 위치 원격 데이터 소스 추상 클래스
abstract class ReadPositionRemoteDataSource {
  /// 채널의 읽기 위치 조회 (API)
  ///
  /// [channelId] 채널 ID
  /// Returns 마지막으로 읽은 게시글 ID (Backend 미구현 시 null)
  Future<int?> getReadPosition(int channelId);

  /// 채널의 읽기 위치 업데이트 (API)
  ///
  /// [channelId] 채널 ID
  /// [position] 마지막으로 읽은 게시글 ID
  Future<void> updateReadPosition(int channelId, int position);

  /// 채널의 읽지 않은 글 개수 조회 (API)
  ///
  /// [channelId] 채널 ID
  /// Returns 읽지 않은 게시글 개수
  Future<int> getUnreadCount(int channelId);

  /// 여러 채널의 읽지 않은 글 개수 조회 (Batch API)
  ///
  /// [channelIds] 채널 ID 목록
  /// Returns channelId → unreadCount 맵
  Future<Map<int, int>> getUnreadCounts(List<int> channelIds);
}

/// 읽기 위치 원격 데이터 소스 구현
///
/// ChannelService를 사용하여 Backend API와 통신합니다.
/// 읽기 위치 저장 API는 Backend 미구현 상태이므로 Mock 처리합니다.
class ReadPositionRemoteDataSourceImpl
    implements ReadPositionRemoteDataSource {
  final ChannelService _channelService;

  ReadPositionRemoteDataSourceImpl(this._channelService);

  @override
  Future<int?> getReadPosition(int channelId) async {
    // TODO: Backend에 읽기 위치 조회 API 구현 시 연결
    // GET /channels/{channelId}/read-position
    return null; // 현재는 로컬 상태만 사용
  }

  @override
  Future<void> updateReadPosition(int channelId, int position) async {
    // TODO: Backend에 읽기 위치 업데이트 API 구현 시 연결
    // PUT /channels/{channelId}/read-position
    // Best-Effort: 실패해도 로컬 상태는 유지
  }

  @override
  Future<int> getUnreadCount(int channelId) async {
    return await _channelService.getUnreadCount(channelId);
  }

  @override
  Future<Map<int, int>> getUnreadCounts(List<int> channelIds) async {
    return await _channelService.getUnreadCounts(channelIds);
  }
}
