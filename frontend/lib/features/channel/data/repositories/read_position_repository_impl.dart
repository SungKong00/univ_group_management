import '../../domain/repositories/read_position_repository.dart';
import '../datasources/read_position_local_data_source.dart';

/// Read position repository implementation
///
/// Implements the [ReadPositionRepository] interface by delegating to
/// [ReadPositionLocalDataSource] for in-memory session state management.
class ReadPositionRepositoryImpl implements ReadPositionRepository {
  final ReadPositionLocalDataSource _localDataSource;

  ReadPositionRepositoryImpl(this._localDataSource);

  @override
  Future<int?> getReadPosition(int channelId) async {
    return await _localDataSource.getReadPosition(channelId);
  }

  @override
  Future<void> updateReadPosition(int channelId, int position) async {
    return await _localDataSource.updateReadPosition(channelId, position);
  }
}
