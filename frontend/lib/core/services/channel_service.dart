import 'dart:developer' as developer;
import '../models/channel_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';
import '../../data/models/channel/channel_read_position.dart';

/// Channel Service
///
/// Provides API methods for fetching channels and membership information.
class ChannelService {
  static final ChannelService _instance = ChannelService._internal();
  factory ChannelService() => _instance;
  ChannelService._internal();

  final DioClient _dioClient = DioClient();

  /// Get channels for a group
  ///
  /// GET /groups/{groupId}/channels
  Future<List<Channel>> getChannels(int groupId) async {
    try {
      developer.log(
        'Fetching channels for group: $groupId',
        name: 'ChannelService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/channels',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map((item) => Channel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <Channel>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} channels',
            name: 'ChannelService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch channels: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return [];
        }
      }

      return [];
    } catch (e) {
      developer.log(
        'Error fetching channels: $e',
        name: 'ChannelService',
        level: 900,
      );
      return [];
    }
  }

  /// Get current user's membership information in a group
  ///
  /// GET /groups/{groupId}/members/me
  Future<MembershipInfo?> getMyMembership(int groupId) async {
    try {
      developer.log(
        'Fetching membership info for group: $groupId',
        name: 'ChannelService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/members/me',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => MembershipInfo.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched membership info',
            name: 'ChannelService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch membership: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return null;
        }
      }

      return null;
    } catch (e) {
      developer.log(
        'Error fetching membership: $e',
        name: 'ChannelService',
        level: 900,
      );
      return null;
    }
  }

  /// Get current user's permissions for a specific channel
  ///
  /// GET /channels/{channelId}/permissions/me
  Future<ChannelPermissions?> getMyPermissions(int channelId) async {
    try {
      developer.log(
        'Fetching permissions for channel: $channelId',
        name: 'ChannelService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/channels/$channelId/permissions/me',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => ChannelPermissions.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched channel permissions',
            name: 'ChannelService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch channel permissions: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return null;
        }
      }

      return null;
    } catch (e) {
      developer.log(
        'Error fetching channel permissions: $e',
        name: 'ChannelService',
        level: 900,
      );
      return null;
    }
  }

  /// Create a new channel in a workspace
  ///
  /// POST /workspaces/{workspaceId}/channels
  Future<Channel?> createChannel({
    required int workspaceId,
    required String name,
    String? description,
    String? type, // 'TEXT', 'ANNOUNCEMENT'
  }) async {
    try {
      developer.log(
        'Creating channel in workspace: $workspaceId',
        name: 'ChannelService',
      );

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/workspaces/$workspaceId/channels',
        data: {
          'name': name,
          'description': description,
          'type': type ?? 'TEXT',
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => Channel.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully created channel: ${apiResponse.data!.name}',
            name: 'ChannelService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to create channel: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return null;
        }
      }

      return null;
    } catch (e) {
      developer.log(
        'Error creating channel: $e',
        name: 'ChannelService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Create channel role binding
  ///
  /// POST /channels/{channelId}/role-bindings
  Future<bool> createChannelRoleBinding({
    required int channelId,
    required int roleId,
    required List<String> permissions,
  }) async {
    try {
      developer.log(
        'Creating channel role binding: channelId=$channelId, roleId=$roleId',
        name: 'ChannelService',
      );

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/channels/$channelId/role-bindings',
        data: {
          'groupRoleId': roleId,
          'permissions': permissions,
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json,
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully created channel role binding',
            name: 'ChannelService',
          );
          return true;
        } else {
          developer.log(
            'Failed to create channel role binding: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return false;
        }
      }

      return false;
    } catch (e) {
      developer.log(
        'Error creating channel role binding: $e',
        name: 'ChannelService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Update a channel
  ///
  /// PUT /channels/{channelId}
  Future<Channel?> updateChannel({
    required int channelId,
    String? name,
    String? description,
  }) async {
    try {
      developer.log(
        'Updating channel: $channelId',
        name: 'ChannelService',
      );

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/channels/$channelId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => Channel.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully updated channel',
            name: 'ChannelService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to update channel: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return null;
        }
      }

      return null;
    } catch (e) {
      developer.log(
        'Error updating channel: $e',
        name: 'ChannelService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Delete a channel
  ///
  /// DELETE /channels/{channelId}
  Future<bool> deleteChannel(int channelId) async {
    try {
      developer.log(
        'Deleting channel: $channelId',
        name: 'ChannelService',
      );

      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/channels/$channelId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json,
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully deleted channel',
            name: 'ChannelService',
          );
          return true;
        } else {
          developer.log(
            'Failed to delete channel: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return false;
        }
      }

      return false;
    } catch (e) {
      developer.log(
        'Error deleting channel: $e',
        name: 'ChannelService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get channel role bindings
  ///
  /// GET /channels/{channelId}/role-bindings
  Future<List<Map<String, dynamic>>> getChannelRoleBindings(
    int channelId,
  ) async {
    try {
      developer.log(
        'Fetching channel role bindings for channel: $channelId',
        name: 'ChannelService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/channels/$channelId/role-bindings',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) {
            if (json is List) {
              return json.cast<Map<String, dynamic>>();
            }
            return <Map<String, dynamic>>[];
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} role bindings',
            name: 'ChannelService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch channel role bindings: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return [];
        }
      }

      return [];
    } catch (e) {
      developer.log(
        'Error fetching channel role bindings: $e',
        name: 'ChannelService',
        level: 900,
      );
      return [];
    }
  }

  /// Update channel role binding
  ///
  /// PUT /channels/{channelId}/role-bindings/{bindingId}
  Future<bool> updateChannelRoleBinding({
    required int channelId,
    required int bindingId,
    required List<String> permissions,
  }) async {
    try {
      developer.log(
        'Updating channel role binding: channelId=$channelId, bindingId=$bindingId',
        name: 'ChannelService',
      );

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/channels/$channelId/role-bindings/$bindingId',
        data: {
          'permissions': permissions,
        },
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json,
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully updated channel role binding',
            name: 'ChannelService',
          );
          return true;
        } else {
          developer.log(
            'Failed to update channel role binding: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return false;
        }
      }

      return false;
    } catch (e) {
      developer.log(
        'Error updating channel role binding: $e',
        name: 'ChannelService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Delete channel role binding
  ///
  /// DELETE /channels/{channelId}/role-bindings/{bindingId}
  Future<bool> deleteChannelRoleBinding({
    required int channelId,
    required int bindingId,
  }) async {
    try {
      developer.log(
        'Deleting channel role binding: channelId=$channelId, bindingId=$bindingId',
        name: 'ChannelService',
      );

      final response = await _dioClient.delete<Map<String, dynamic>>(
        '/channels/$channelId/role-bindings/$bindingId',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json,
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully deleted channel role binding',
            name: 'ChannelService',
          );
          return true;
        } else {
          developer.log(
            'Failed to delete channel role binding: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return false;
        }
      }

      return false;
    } catch (e) {
      developer.log(
        'Error deleting channel role binding: $e',
        name: 'ChannelService',
        level: 900,
      );
      rethrow;
    }
  }

  // ============================================================
  // Read Position Management
  // ============================================================

  /// Get read position for a channel
  ///
  /// GET /channels/{channelId}/read-position
  /// Returns null if the user has never visited this channel
  Future<ChannelReadPosition?> getReadPosition(int channelId) async {
    try {
      developer.log(
        'Fetching read position for channel: $channelId',
        name: 'ChannelService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/channels/$channelId/read-position',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) {
            if (json == null) return null;
            return ChannelReadPosition.fromJson(json as Map<String, dynamic>);
          },
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully fetched read position',
            name: 'ChannelService',
          );
          return apiResponse.data;
        } else {
          developer.log(
            'Failed to fetch read position: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return null;
        }
      }

      return null;
    } catch (e) {
      developer.log(
        'Error fetching read position: $e',
        name: 'ChannelService',
        level: 900,
      );
      return null;
    }
  }

  /// Update read position for a channel
  ///
  /// PUT /channels/{channelId}/read-position
  /// Best-effort operation - errors are logged but not thrown
  Future<void> updateReadPosition(int channelId, int lastReadPostId) async {
    try {
      developer.log(
        'Updating read position for channel $channelId: lastReadPostId=$lastReadPostId',
        name: 'ChannelService',
      );

      await _dioClient.put<Map<String, dynamic>>(
        '/channels/$channelId/read-position',
        data: {'lastReadPostId': lastReadPostId},
      );

      developer.log(
        'Successfully updated read position',
        name: 'ChannelService',
      );
    } catch (e) {
      developer.log(
        'Error updating read position (best-effort, ignored): $e',
        name: 'ChannelService',
        level: 900,
      );
      // Best-effort: do not rethrow
    }
  }

  /// Get unread count for a single channel
  ///
  /// GET /channels/{channelId}/unread-count
  Future<int> getUnreadCount(int channelId) async {
    try {
      developer.log(
        'Fetching unread count for channel: $channelId',
        name: 'ChannelService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/channels/$channelId/unread-count',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json as int,
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched unread count: ${apiResponse.data}',
            name: 'ChannelService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch unread count: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return 0;
        }
      }

      return 0;
    } catch (e) {
      developer.log(
        'Error fetching unread count: $e',
        name: 'ChannelService',
        level: 900,
      );
      return 0;
    }
  }

  /// Get unread counts for multiple channels (batch query)
  ///
  /// GET /channels/unread-counts?channelIds=1,2,3
  Future<Map<int, int>> getUnreadCounts(List<int> channelIds) async {
    if (channelIds.isEmpty) return {};

    try {
      developer.log(
        'Fetching batch unread counts for ${channelIds.length} channels',
        name: 'ChannelService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/channels/unread-counts',
        queryParameters: {'channelIds': channelIds.join(',')},
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) {
            if (json is List) {
              return json
                  .map((item) =>
                      UnreadCountResponse.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
            return <UnreadCountResponse>[];
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          final unreadMap = Map.fromEntries(
            apiResponse.data!.map((unread) =>
                MapEntry(unread.channelId, unread.unreadCount)),
          );

          developer.log(
            'Successfully fetched ${unreadMap.length} unread counts',
            name: 'ChannelService',
          );
          return unreadMap;
        } else {
          developer.log(
            'Failed to fetch batch unread counts: ${apiResponse.message}',
            name: 'ChannelService',
            level: 900,
          );
          return {};
        }
      }

      return {};
    } catch (e) {
      developer.log(
        'Error fetching batch unread counts: $e',
        name: 'ChannelService',
        level: 900,
      );
      return {};
    }
  }
}
