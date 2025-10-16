import 'dart:developer' as developer;
import '../models/channel_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

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
}
