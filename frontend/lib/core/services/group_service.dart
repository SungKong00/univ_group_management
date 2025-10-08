import 'dart:developer' as developer;
import '../models/group_models.dart';
import '../models/auth_models.dart';
import '../network/dio_client.dart';

/// Group Service
///
/// Provides API methods for fetching user's group memberships and selecting top-level groups.
class GroupService {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal();

  final DioClient _dioClient = DioClient();

  /// Get current user's group memberships
  ///
  /// GET /me/groups
  /// Returns list sorted by level (ascending) then id (ascending)
  Future<List<GroupMembership>> getMyGroups() async {
    try {
      developer.log('Fetching my groups', name: 'GroupService');

      final response = await _dioClient.get<Map<String, dynamic>>('/me/groups');

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) {
            if (json is List) {
              return json.map((item) => GroupMembership.fromJson(item as Map<String, dynamic>)).toList();
            }
            return <GroupMembership>[];
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          developer.log('Successfully fetched ${apiResponse.data!.length} groups', name: 'GroupService');
          return apiResponse.data!;
        } else {
          developer.log('Failed to fetch my groups: ${apiResponse.message}', name: 'GroupService', level: 900);
          return [];
        }
      }

      return [];
    } catch (e) {
      developer.log('Error fetching my groups: $e', name: 'GroupService', level: 900);
      return [];
    }
  }

  /// Select top-level group from user's memberships
  ///
  /// Logic:
  /// 1. Filter groups with minimum level (0 is highest)
  /// 2. Among same level groups, select one with minimum id (earliest joined)
  /// 3. Return null if no groups available
  GroupMembership? getTopLevelGroup(List<GroupMembership> groups) {
    if (groups.isEmpty) {
      developer.log('No groups available for top-level selection', name: 'GroupService');
      return null;
    }

    // Find minimum level
    final minLevel = groups.map((g) => g.level).reduce((a, b) => a < b ? a : b);
    final topLevelGroups = groups.where((g) => g.level == minLevel).toList();

    // Sort by id and select first
    topLevelGroups.sort((a, b) => a.id.compareTo(b.id));
    final selected = topLevelGroups.first;

    developer.log('Selected top-level group: ${selected.name} (id: ${selected.id}, level: ${selected.level})', name: 'GroupService');
    return selected;
  }

  /// Update group information
  ///
  /// PUT /api/groups/{groupId}
  /// Requires GROUP_MANAGE permission
  Future<void> updateGroup(int groupId, UpdateGroupRequest request) async {
    try {
      developer.log('Updating group $groupId with request: ${request.toJson()}', name: 'GroupService');

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/groups/$groupId',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json,
        );

        if (apiResponse.success) {
          developer.log('Successfully updated group $groupId', name: 'GroupService');
        } else {
          developer.log('Failed to update group: ${apiResponse.message}', name: 'GroupService', level: 900);
          throw Exception(apiResponse.message ?? 'Failed to update group');
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log('Error updating group: $e', name: 'GroupService', level: 900);
      rethrow;
    }
  }
}
