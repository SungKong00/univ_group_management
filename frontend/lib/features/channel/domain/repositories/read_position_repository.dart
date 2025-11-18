/// Read position repository interface
///
/// Defines the contract for managing user's read positions in channels.
/// Read positions track the last post a user has seen in each channel,
/// enabling features like "unread" badges and scroll restoration.
///
/// Note: This is currently designed for in-memory session state.
/// Backend API integration may be added in future iterations.
abstract class ReadPositionRepository {
  /// Retrieves the last read position for a channel
  ///
  /// [channelId] The unique identifier of the channel
  /// Returns the post ID of the last read position, or null if not set
  Future<int?> getReadPosition(int channelId);

  /// Updates the read position for a channel
  ///
  /// [channelId] The unique identifier of the channel
  /// [position] The post ID to mark as the last read position
  /// Throws an exception if the operation fails
  Future<void> updateReadPosition(int channelId, int position);
}
