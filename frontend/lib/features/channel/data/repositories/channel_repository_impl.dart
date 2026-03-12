import '../../domain/entities/channel.dart';
import '../../domain/entities/channel_permissions.dart';
import '../../domain/repositories/channel_repository.dart';
import '../datasources/channel_remote_data_source.dart';

/// Channel repository implementation
///
/// Implements the [ChannelRepository] interface by delegating to
/// [ChannelRemoteDataSource] and converting DTOs to domain entities.
/// Error handling is already done at the data source level.
class ChannelRepositoryImpl implements ChannelRepository {
  final ChannelRemoteDataSource _remoteDataSource;

  ChannelRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Channel>> getChannels(String workspaceId) async {
    final dtos = await _remoteDataSource.getChannels(workspaceId);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<ChannelPermissions> getMyPermissions(int channelId) async {
    final dto = await _remoteDataSource.getMyPermissions(channelId);
    return dto.toEntity();
  }

  @override
  Future<Channel> createChannel({
    required String workspaceId,
    required String name,
    required String type,
    String? description,
  }) async {
    final dto = await _remoteDataSource.createChannel(
      workspaceId: workspaceId,
      name: name,
      type: type,
      description: description,
    );
    return dto.toEntity();
  }
}
