import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/permission_context.dart';
import 'package:frontend/presentation/providers/permission_context_provider.dart';

void main() {
  group('PermissionContextNotifier', () {
    late ProviderContainer container;
    late PermissionContextNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(permissionContextProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with loading state', () {
      final state = container.read(permissionContextProvider);

      expect(state.groupId, -1);
      expect(state.permissions, isEmpty);
      expect(state.isAdmin, isFalse);
      expect(state.isLoading, isTrue);
    });

    test('clear resets to initial state', () {
      // Set some state first
      notifier.state = const PermissionContext(
        groupId: 1,
        permissions: {'GROUP_MANAGE'},
        isAdmin: true,
        isLoading: false,
      );

      // Then clear
      notifier.clear();

      expect(notifier.state.groupId, -1);
      expect(notifier.state.permissions, isEmpty);
      expect(notifier.state.isAdmin, isFalse);
      expect(notifier.state.isLoading, isFalse);
    });

    test('hasPermission returns correct value', () {
      notifier.state = const PermissionContext(
        groupId: 1,
        permissions: {'GROUP_MANAGE', 'MEMBER_KICK'},
        isAdmin: false,
        isLoading: false,
      );

      expect(notifier.state.hasPermission('GROUP_MANAGE'), isTrue);
      expect(notifier.state.hasPermission('MEMBER_KICK'), isTrue);
      expect(notifier.state.hasPermission('CHANNEL_DELETE'), isFalse);
    });

    test('canAccessAdmin returns true for admin users', () {
      notifier.state = const PermissionContext(
        groupId: 1,
        permissions: {},
        isAdmin: true,
        isLoading: false,
      );

      expect(notifier.state.canAccessAdmin(), isTrue);
    });

    test('canAccessAdmin returns true for users with GROUP_MANAGE', () {
      notifier.state = const PermissionContext(
        groupId: 1,
        permissions: {'GROUP_MANAGE'},
        isAdmin: false,
        isLoading: false,
      );

      expect(notifier.state.canAccessAdmin(), isTrue);
    });

    test('canAccessAdmin returns false for regular users', () {
      notifier.state = const PermissionContext(
        groupId: 1,
        permissions: {'MEMBER_VIEW'},
        isAdmin: false,
        isLoading: false,
      );

      expect(notifier.state.canAccessAdmin(), isFalse);
    });

    // Note: Testing loadPermissions() requires mocking DioClient
    // This is left for integration tests or can be added with proper mocking setup
  });
}
