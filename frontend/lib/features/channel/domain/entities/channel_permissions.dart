import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_permissions.freezed.dart';

/// Channel permissions domain entity
///
/// Represents the permissions a user has for a specific channel.
/// Permissions determine what actions a user can perform in the channel.
@freezed
class ChannelPermissions with _$ChannelPermissions {
  const factory ChannelPermissions({
    /// List of permission strings
    /// Examples: 'POST_READ', 'POST_WRITE', 'COMMENT_WRITE', 'CHANNEL_MANAGE'
    required List<String> permissions,
  }) = _ChannelPermissions;

  const ChannelPermissions._();

  /// Check if the user has a specific permission
  ///
  /// [permission] The permission string to check
  /// Returns true if the user has the permission
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Check if the user can read posts in the channel
  bool get canReadPosts => hasPermission('POST_READ');

  /// Check if the user can write posts in the channel
  bool get canWritePosts => hasPermission('POST_WRITE');

  /// Check if the user can write comments
  bool get canWriteComments => hasPermission('COMMENT_WRITE');

  /// Check if the user can manage the channel
  bool get canManageChannel => hasPermission('CHANNEL_MANAGE');
}
