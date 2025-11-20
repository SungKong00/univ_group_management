import '../../domain/repositories/read_position_repository.dart';
import '../datasources/read_position_local_data_source.dart';
import '../datasources/read_position_remote_datasource.dart';

/// Read position repository implementation
///
/// Implements the [ReadPositionRepository] interface by coordinating
/// between local cache (SharedPreferences) and remote API.
/// Strategy: Cache-first for reads, Remote+Cache for writes.
class ReadPositionRepositoryImpl implements ReadPositionRepository {
  final ReadPositionLocalDataSource _localDataSource;
  final ReadPositionRemoteDataSource _remoteDataSource;

  ReadPositionRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<int?> getReadPosition(int channelId) async {
    // 1. Try local cache first (fast path)
    final localPosition = await _localDataSource.getReadPosition(channelId);
    if (localPosition != null) {
      return localPosition;
    }

    // 2. Fetch from remote API
    final remoteDto = await _remoteDataSource.getReadPosition(channelId);
    if (remoteDto == null) {
      return null;
    }

    // 3. Update local cache
    await _localDataSource.updateReadPosition(
      channelId,
      remoteDto.lastReadPostId,
    );

    return remoteDto.lastReadPostId;
  }

  @override
  Future<void> updateReadPosition(int channelId, int position) async {
    // 1. Update remote API first
    await _remoteDataSource.updateReadPosition(channelId, position);

    // 2. Update local cache
    await _localDataSource.updateReadPosition(channelId, position);
  }

  @override
  Future<int> getUnreadCount(int channelId) async {
    // Always fetch from remote (real-time data)
    return await _remoteDataSource.getUnreadCount(channelId);
  }

  @override
  Future<Map<int, int>> getAllReadPositions(List<int> channelIds) async {
    // Batch fetch from remote API
    return await _remoteDataSource.getBatchUnreadCounts(channelIds);
  }

  @override
  Future<void> saveAndRefreshUnreadCount(int channelId, int position) async {
    // Combined operation: save position + refresh count
    await updateReadPosition(channelId, position);
    // Note: Unread count refresh is handled by caller
  }
}
