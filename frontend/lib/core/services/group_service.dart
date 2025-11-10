import 'dart:developer' as developer;
import '../models/group_models.dart';
import '../models/auth_models.dart';
import '../models/place/place.dart';
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
  /// Throws exception on error for proper error handling upstream
  Future<List<GroupMembership>> getMyGroups() async {
    try {
      developer.log('Fetching my groups from /me/groups', name: 'GroupService');

      final response = await _dioClient.get<Map<String, dynamic>>('/me/groups');

      developer.log(
        'Received response: statusCode=${response.statusCode}, hasData=${response.data != null}',
        name: 'GroupService',
      );

      if (response.data == null) {
        throw Exception('Empty response from server');
      }

      final apiResponse = ApiResponse.fromJson(response.data!, (json) {
        if (json is List) {
          return json
              .map(
                (item) =>
                    GroupMembership.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
        return <GroupMembership>[];
      });

      if (!apiResponse.success) {
        final errorMsg = apiResponse.message ?? 'Unknown error';
        developer.log(
          'API returned success=false: $errorMsg',
          name: 'GroupService',
          level: 900,
        );
        throw Exception(errorMsg);
      }

      if (apiResponse.data == null) {
        developer.log(
          'API returned null data',
          name: 'GroupService',
          level: 900,
        );
        throw Exception('No data in response');
      }

      developer.log(
        'Successfully fetched ${apiResponse.data!.length} groups',
        name: 'GroupService',
      );
      return apiResponse.data!;
    } catch (e) {
      developer.log(
        'Error fetching my groups: $e',
        name: 'GroupService',
        level: 1000,
      );
      rethrow; // Propagate error for proper handling upstream
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
      developer.log(
        'No groups available for top-level selection',
        name: 'GroupService',
      );
      return null;
    }

    // Find minimum level
    final minLevel = groups.map((g) => g.level).reduce((a, b) => a < b ? a : b);
    final topLevelGroups = groups.where((g) => g.level == minLevel).toList();

    // Sort by id and select first
    topLevelGroups.sort((a, b) => a.id.compareTo(b.id));
    final selected = topLevelGroups.first;

    developer.log(
      'Selected top-level group: ${selected.name} (id: ${selected.id}, level: ${selected.level})',
      name: 'GroupService',
    );
    return selected;
  }

  /// Get group hierarchy
  ///
  /// GET /api/groups/hierarchy
  /// Returns all groups with parent-child relationships
  Future<List<GroupHierarchyNode>> getHierarchy() async {
    try {
      developer.log('Fetching group hierarchy', name: 'GroupService');

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/hierarchy',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map(
                  (item) =>
                      GroupHierarchyNode.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
          return <GroupHierarchyNode>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} hierarchy nodes',
            name: 'GroupService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch hierarchy: ${apiResponse.message}',
            name: 'GroupService',
            level: 900,
          );
          return [];
        }
      }

      return [];
    } catch (e) {
      developer.log(
        'Error fetching hierarchy: $e',
        name: 'GroupService',
        level: 900,
      );
      return [];
    }
  }

  /// Update group information
  ///
  /// PUT /api/groups/{groupId}
  /// Requires GROUP_MANAGE permission
  Future<void> updateGroup(int groupId, UpdateGroupRequest request) async {
    try {
      developer.log(
        'Updating group $groupId with request: ${request.toJson()}',
        name: 'GroupService',
      );

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
          developer.log(
            'Successfully updated group $groupId',
            name: 'GroupService',
          );
        } else {
          developer.log(
            'Failed to update group: ${apiResponse.message}',
            name: 'GroupService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to update group');
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log(
        'Error updating group: $e',
        name: 'GroupService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Create subgroup request
  ///
  /// POST /api/groups/{parentId}/sub-groups/requests
  /// Requires GROUP_MANAGE permission
  /// Returns void (request is created for admin approval)
  Future<void> createSubgroup(
    int parentId,
    CreateSubgroupRequest request,
  ) async {
    try {
      developer.log(
        'Creating subgroup request under parent $parentId with request: ${request.toJson()}',
        name: 'GroupService',
      );

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/groups/$parentId/sub-groups/requests',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json,
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully created subgroup request',
            name: 'GroupService',
          );
        } else {
          developer.log(
            'Failed to create subgroup request: ${apiResponse.message}',
            name: 'GroupService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to create subgroup request',
          );
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log(
        'Error creating subgroup request: $e',
        name: 'GroupService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get subgroup creation requests for a group
  ///
  /// GET /api/groups/{groupId}/sub-groups/requests
  /// Requires GROUP_MANAGE permission
  /// Returns list of pending subgroup requests
  Future<List<SubGroupRequestResponse>> getSubGroupRequests(int groupId) async {
    try {
      developer.log(
        'Fetching subgroup requests for group $groupId',
        name: 'GroupService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/sub-groups/requests',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map(
                  (item) => SubGroupRequestResponse.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
          }
          return <SubGroupRequestResponse>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} subgroup requests',
            name: 'GroupService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch subgroup requests: ${apiResponse.message}',
            name: 'GroupService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to fetch subgroup requests',
          );
        }
      }

      return [];
    } catch (e) {
      developer.log(
        'Error fetching subgroup requests: $e',
        name: 'GroupService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Review subgroup creation request (approve or reject)
  ///
  /// PATCH /api/groups/{groupId}/sub-groups/requests/{requestId}
  /// Requires GROUP_MANAGE permission
  /// action: "APPROVE" or "REJECT"
  Future<void> reviewSubGroupRequest(
    int groupId,
    int requestId,
    ReviewSubGroupRequestRequest request,
  ) async {
    try {
      developer.log(
        'Reviewing subgroup request $requestId for group $groupId with action: ${request.action}',
        name: 'GroupService',
      );

      final response = await _dioClient.patch<Map<String, dynamic>>(
        '/groups/$groupId/sub-groups/requests/$requestId',
        data: request.toJson(),
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(
          response.data!,
          (json) => json,
        );

        if (apiResponse.success) {
          developer.log(
            'Successfully reviewed subgroup request',
            name: 'GroupService',
          );
        } else {
          developer.log(
            'Failed to review subgroup request: ${apiResponse.message}',
            name: 'GroupService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to review subgroup request',
          );
        }
      } else {
        throw Exception('Empty response from server');
      }
    } catch (e) {
      developer.log(
        'Error reviewing subgroup request: $e',
        name: 'GroupService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get available places for a group
  ///
  /// GET /api/groups/{groupId}/available-places
  /// Returns list of places that the group has permission to reserve
  Future<List<Place>> getAvailablePlaces(int groupId) async {
    try {
      developer.log(
        'Fetching available places for group $groupId',
        name: 'GroupService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/available-places',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map((item) => Place.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <Place>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} available places',
            name: 'GroupService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch available places: ${apiResponse.message}',
            name: 'GroupService',
            level: 900,
          );
          throw Exception(
            apiResponse.message ?? 'Failed to fetch available places',
          );
        }
      }

      return [];
    } catch (e) {
      developer.log(
        'Error fetching available places: $e',
        name: 'GroupService',
        level: 900,
      );
      rethrow;
    }
  }

  /// Get sub-groups (children) of a group
  ///
  /// GET /api/groups/{groupId}/sub-groups
  /// Returns list of groups that are direct children of the specified group
  Future<List<GroupSummaryResponse>> getSubGroups(int groupId) async {
    try {
      developer.log(
        'Fetching sub-groups for group $groupId',
        name: 'GroupService',
      );

      final response = await _dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/sub-groups',
      );

      if (response.data != null) {
        final apiResponse = ApiResponse.fromJson(response.data!, (json) {
          if (json is List) {
            return json
                .map(
                  (item) => GroupSummaryResponse.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
          }
          return <GroupSummaryResponse>[];
        });

        if (apiResponse.success && apiResponse.data != null) {
          developer.log(
            'Successfully fetched ${apiResponse.data!.length} sub-groups',
            name: 'GroupService',
          );
          return apiResponse.data!;
        } else {
          developer.log(
            'Failed to fetch sub-groups: ${apiResponse.message}',
            name: 'GroupService',
            level: 900,
          );
          throw Exception(apiResponse.message ?? 'Failed to fetch sub-groups');
        }
      }

      return [];
    } catch (e) {
      developer.log(
        'Error fetching sub-groups: $e',
        name: 'GroupService',
        level: 900,
      );
      rethrow;
    }
  }
}
