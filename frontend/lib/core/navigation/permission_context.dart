import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_context.freezed.dart';
part 'permission_context.g.dart';

/// Encapsulates user permissions for the current group
@freezed
class PermissionContext with _$PermissionContext {
  const factory PermissionContext({
    required int groupId,
    required Set<String> permissions,
    required bool isAdmin,
    @Default(false) bool isLoading,
  }) = _PermissionContext;

  const PermissionContext._();

  /// Checks if the user has a specific permission
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Checks if the user can access admin pages
  bool canAccessAdmin() => isAdmin || permissions.contains('GROUP_MANAGE');

  factory PermissionContext.fromJson(Map<String, dynamic> json) =>
      _$PermissionContextFromJson(json);
}
