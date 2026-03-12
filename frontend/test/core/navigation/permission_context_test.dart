import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/navigation/permission_context.dart';

void main() {
  group('PermissionContext', () {
    test('creates permission context with required fields', () {
      const context = PermissionContext(
        groupId: 1,
        permissions: {'GROUP_MANAGE', 'MEMBER_KICK'},
        isAdmin: false,
      );

      expect(context.groupId, 1);
      expect(context.permissions, {'GROUP_MANAGE', 'MEMBER_KICK'});
      expect(context.isAdmin, isFalse);
      expect(context.isLoading, isFalse);
    });

    test('hasPermission returns true when permission exists', () {
      const context = PermissionContext(
        groupId: 1,
        permissions: {'GROUP_MANAGE', 'MEMBER_KICK'},
        isAdmin: false,
      );

      expect(context.hasPermission('GROUP_MANAGE'), isTrue);
      expect(context.hasPermission('MEMBER_KICK'), isTrue);
    });

    test('hasPermission returns false when permission does not exist', () {
      const context = PermissionContext(
        groupId: 1,
        permissions: {'GROUP_MANAGE'},
        isAdmin: false,
      );

      expect(context.hasPermission('MEMBER_KICK'), isFalse);
      expect(context.hasPermission('CHANNEL_DELETE'), isFalse);
    });

    test('canAccessAdmin returns true when isAdmin is true', () {
      const context = PermissionContext(
        groupId: 1,
        permissions: {},
        isAdmin: true,
      );

      expect(context.canAccessAdmin(), isTrue);
    });

    test('canAccessAdmin returns true when has GROUP_MANAGE permission', () {
      const context = PermissionContext(
        groupId: 1,
        permissions: {'GROUP_MANAGE'},
        isAdmin: false,
      );

      expect(context.canAccessAdmin(), isTrue);
    });

    test('canAccessAdmin returns false without admin role or permission', () {
      const context = PermissionContext(
        groupId: 1,
        permissions: {'MEMBER_KICK'},
        isAdmin: false,
      );

      expect(context.canAccessAdmin(), isFalse);
    });

    test('supports isLoading flag', () {
      const context = PermissionContext(
        groupId: 1,
        permissions: {},
        isAdmin: false,
        isLoading: true,
      );

      expect(context.isLoading, isTrue);
    });

    test('isLoading defaults to false', () {
      const context = PermissionContext(
        groupId: 1,
        permissions: {},
        isAdmin: false,
      );

      expect(context.isLoading, isFalse);
    });

    test('supports equality comparison', () {
      const context1 = PermissionContext(
        groupId: 1,
        permissions: {'GROUP_MANAGE'},
        isAdmin: false,
      );
      const context2 = PermissionContext(
        groupId: 1,
        permissions: {'GROUP_MANAGE'},
        isAdmin: false,
      );
      const context3 = PermissionContext(
        groupId: 2,
        permissions: {'GROUP_MANAGE'},
        isAdmin: false,
      );

      expect(context1, equals(context2));
      expect(context1, isNot(equals(context3)));
    });

    test('supports JSON serialization', () {
      const context = PermissionContext(
        groupId: 1,
        permissions: {'GROUP_MANAGE', 'MEMBER_KICK'},
        isAdmin: true,
      );
      final json = context.toJson();
      final decoded = PermissionContext.fromJson(json);

      expect(decoded, equals(context));
    });
  });
}
