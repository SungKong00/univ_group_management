import 'package:freezed_annotation/freezed_annotation.dart';

part 'membership_info.freezed.dart';

/// Membership info domain entity
///
/// Represents a user's membership information for a group.
/// Contains the user's role and permissions within the group.
@freezed
class MembershipInfo with _$MembershipInfo {
  const factory MembershipInfo({
    /// Group ID the membership belongs to
    required int groupId,

    /// Role of the user in the group
    /// Examples: 'OWNER', 'ADMIN', 'MEMBER'
    required String role,

    /// List of permission strings the user has in the group
    required List<String> permissions,
  }) = _MembershipInfo;

  const MembershipInfo._();

  /// Check if the user has a specific permission
  ///
  /// [permission] The permission string to check
  /// Returns true if the user has the permission
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Check if the user is the group owner
  bool get isOwner => role == 'OWNER';

  /// Check if the user is an admin
  bool get isAdmin => role == 'ADMIN';

  /// Check if the user is a regular member
  bool get isMember => role == 'MEMBER';

  /// Check if the user can manage members
  bool get canManageMembers => hasPermission('MEMBER_MANAGE');

  /// Check if the user can manage channels
  bool get canManageChannels => hasPermission('CHANNEL_MANAGE');
}
