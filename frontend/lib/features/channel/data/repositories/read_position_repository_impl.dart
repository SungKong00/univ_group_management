import '../../domain/repositories/read_position_repository.dart';
import '../datasources/read_position_local_data_source.dart';
import '../datasources/read_position_remote_datasource.dart';

/// Read position repository implementation
///
/// Implements [ReadPositionRepository] with local + remote data sync.
/// Uses local cache for fast reads, remote API for unread counts.
class ReadPositionRepositoryImpl implements ReadPositionRepository {
  final ReadPositionLocalDataSource _localDataSource;
  final ReadPositionRemoteDataSource _remoteDataSource;

  ReadPositionRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );

  @override
  Future<int?> getReadPosition(int channelId) async {
    // 1. 로컬 캐시 우선 (빠른 응답)
    final local = await _localDataSource.getReadPosition(channelId);
    if (local != null) return local;

    // 2. 원격 API 조회 (초기 로드, 현재는 null 반환)
    final remote = await _remoteDataSource.getReadPosition(channelId);
    if (remote != null) {
      await _localDataSource.updateReadPosition(channelId, remote);
    }
    return remote;
  }

  @override
  Future<void> updateReadPosition(int channelId, int position) async {
    // 1. Optimistic UI: 로컬 즉시 업데이트
    await _localDataSource.updateReadPosition(channelId, position);

    // 2. Best-Effort: 백그라운드 API 호출 (실패해도 로컬 유지)
    _remoteDataSource
        .updateReadPosition(channelId, position)
        .catchError((_) {});
  }

  @override
  Future<int> getUnreadCount(int channelId) async {
    return await _remoteDataSource.getUnreadCount(channelId);
  }

  @override
  Future<Map<int, int>> getAllReadPositions(List<int> channelIds) async {
    final positions = <int, int>{};
    for (final channelId in channelIds) {
      final pos = await getReadPosition(channelId);
      if (pos != null) positions[channelId] = pos;
    }
    return positions;
  }

  @override
  Future<void> saveAndRefreshUnreadCount(int channelId, int position) async {
    // 읽음 위치 저장 (로컬 + API)
    await updateReadPosition(channelId, position);

    // 뱃지 카운트는 별도 Provider(ChannelReadPositionNotifier)에서
    // getUnreadCount() 호출하여 관리
  }
}
