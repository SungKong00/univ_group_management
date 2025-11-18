import '../entities/channel.dart';
import '../entities/channel_permissions.dart';

/// Channel repository interface
///
/// Defines the contract for channel data access operations.
/// This interface follows Clean Architecture principles by keeping
/// the domain layer independent of data sources and implementation details.
abstract class ChannelRepository {
  /// Retrieves all channels for a given workspace
  ///
  /// [workspaceId] The unique identifier of the workspace
  /// Returns a list of [Channel] entities
  /// Throws an exception if the operation fails
  Future<List<Channel>> getChannels(String workspaceId);

  /// Retrieves the current user's permissions for a specific channel
  ///
  /// [channelId] The unique identifier of the channel
  /// Returns [ChannelPermissions] containing the user's permission list
  /// Throws an exception if the operation fails or channel is not found
  Future<ChannelPermissions> getMyPermissions(int channelId);

  /// Creates a new channel in the specified workspace
  ///
  /// [workspaceId] The unique identifier of the workspace
  /// [name] The name of the new channel
  /// [type] The type of the channel (e.g., 'ANNOUNCEMENT', 'TEXT')
  /// [description] Optional description of the channel
  /// Returns the newly created [Channel] entity
  /// Throws an exception if the operation fails or user lacks permissions
  Future<Channel> createChannel({
    required String workspaceId,
    required String name,
    required String type,
    String? description,
  });
}
