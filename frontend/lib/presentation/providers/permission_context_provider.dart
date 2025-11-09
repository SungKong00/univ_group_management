import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/permission_context.dart';
import 'package:frontend/core/network/dio_client.dart';

/// StateNotifier for managing permission context
class PermissionContextNotifier extends StateNotifier<PermissionContext> {
  final Ref ref;
  final DioClient _dioClient = DioClient();

  PermissionContextNotifier(this.ref)
      : super(const PermissionContext(
          groupId: -1,
          permissions: {},
          isAdmin: false,
          isLoading: true,
        ));

  /// Load permissions for a specific group from the API
  Future<void> loadPermissions(int groupId) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _dioClient.get(
        '/api/groups/$groupId/members/me/permissions',
      );

      // Parse response - expected format: { "permissions": ["PERM1", "PERM2"], "isAdmin": bool }
      final data = response.data;
      final permissions = (data['permissions'] as List?)
              ?.map((p) => p.toString())
              .toSet() ??
          <String>{};
      final isAdmin = data['isAdmin'] as bool? ?? false;

      state = PermissionContext(
        groupId: groupId,
        permissions: permissions,
        isAdmin: isAdmin,
        isLoading: false,
      );
    } catch (e) {
      // On error, set empty permissions
      state = PermissionContext(
        groupId: groupId,
        permissions: {},
        isAdmin: false,
        isLoading: false,
      );
      rethrow;
    }
  }

  /// Clear all permission state
  void clear() {
    state = const PermissionContext(
      groupId: -1,
      permissions: {},
      isAdmin: false,
      isLoading: false,
    );
  }
}

/// Provider for permission context management (auto-disposed when group changes)
final permissionContextProvider =
    StateNotifierProvider.autoDispose<PermissionContextNotifier, PermissionContext>(
  (ref) => PermissionContextNotifier(ref),
);
