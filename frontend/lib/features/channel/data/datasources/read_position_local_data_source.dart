/// 읽기 위치 로컬 데이터 소스 추상 클래스
abstract class ReadPositionLocalDataSource {
  /// 채널의 읽기 위치 조회
  ///
  /// [channelId] 채널 ID
  /// Returns 마지막으로 읽은 게시글 ID (없으면 null)
  Future<int?> getReadPosition(int channelId);

  /// 채널의 읽기 위치 업데이트
  ///
  /// [channelId] 채널 ID
  /// [position] 마지막으로 읽은 게시글 ID
  Future<void> updateReadPosition(int channelId, int position);
}

/// 읽기 위치 로컬 데이터 소스 구현
///
/// 인메모리 상태 관리를 사용하여 읽기 위치를 저장합니다.
/// Backend API가 미구현이므로 로컬 상태만 관리합니다.
class ReadPositionLocalDataSourceImpl implements ReadPositionLocalDataSource {
  /// 채널별 읽기 위치 저장소 (channelId → postId)
  final Map<int, int> _storage = {};

  @override
  Future<int?> getReadPosition(int channelId) async {
    return _storage[channelId];
  }

  @override
  Future<void> updateReadPosition(int channelId, int position) async {
    _storage[channelId] = position;
  }
}
