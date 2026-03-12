import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel.freezed.dart';

/// Channel domain entity
///
/// Represents a channel in the workspace.
/// Channels are used to organize posts and discussions.
@freezed
class Channel with _$Channel {
  const factory Channel({
    /// Unique identifier for the channel
    required int id,

    /// Name of the channel
    required String name,

    /// Type of the channel (e.g., 'ANNOUNCEMENT', 'TEXT')
    required String type,

    /// Optional description of the channel
    String? description,

    /// Timestamp when the channel was created
    DateTime? createdAt,
  }) = _Channel;
}
