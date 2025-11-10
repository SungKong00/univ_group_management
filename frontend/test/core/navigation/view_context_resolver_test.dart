import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/navigation/view_context.dart';
import 'package:frontend/core/navigation/view_context_resolver.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/core/navigation/permission_context.dart';

void main() {
  group('ViewContextResolver', () {
    late ProviderContainer container;
    late ViewContextResolver resolver;

    setUp(() {
      container = ProviderContainer();
      // Create a callback that matches the Ref interface
      resolver = container.read(viewContextResolverProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('resolveTargetRoute', () {
      test('resolves home → home', () async {
        final context = const ViewContext(type: ViewType.home);
        final permissions = const PermissionContext(
          groupId: 2,
          permissions: {},
          isAdmin: false,
        );

        final result = await resolver.resolveTargetRoute(
          context,
          2,
          permissions,
        );

        expect(result, isA<WorkspaceRoute>());
        result.when(
          home: (groupId) => expect(groupId, 2),
          channel: (_, __) => fail('Expected home route'),
          calendar: (_) => fail('Expected home route'),
          admin: (_) => fail('Expected home route'),
          memberManagement: (_) => fail('Expected home route'),
        );
      });

      test('resolves calendar → calendar', () async {
        final context = const ViewContext(type: ViewType.calendar);
        final permissions = const PermissionContext(
          groupId: 2,
          permissions: {},
          isAdmin: false,
        );

        final result = await resolver.resolveTargetRoute(
          context,
          2,
          permissions,
        );

        expect(result, isA<WorkspaceRoute>());
        result.when(
          home: (_) => fail('Expected calendar route'),
          channel: (_, __) => fail('Expected calendar route'),
          calendar: (groupId) => expect(groupId, 2),
          admin: (_) => fail('Expected calendar route'),
          memberManagement: (_) => fail('Expected calendar route'),
        );
      });

      test('resolves admin → admin when user has permission', () async {
        final context = const ViewContext(type: ViewType.admin);
        final permissions = const PermissionContext(
          groupId: 2,
          permissions: {'GROUP_MANAGE'},
          isAdmin: false,
        );

        final result = await resolver.resolveTargetRoute(
          context,
          2,
          permissions,
        );

        expect(result, isA<WorkspaceRoute>());
        result.when(
          home: (_) => fail('Expected admin route'),
          channel: (_, __) => fail('Expected admin route'),
          calendar: (_) => fail('Expected admin route'),
          admin: (groupId) => expect(groupId, 2),
          memberManagement: (_) => fail('Expected admin route'),
        );
      });

      test(
        'resolves admin → home fallback when user lacks permission',
        () async {
          final context = const ViewContext(type: ViewType.admin);
          final permissions = const PermissionContext(
            groupId: 2,
            permissions: {},
            isAdmin: false,
          );

          final result = await resolver.resolveTargetRoute(
            context,
            2,
            permissions,
          );

          expect(result, isA<WorkspaceRoute>());
          result.when(
            home: (groupId) => expect(groupId, 2),
            channel: (_, __) => fail('Expected home fallback'),
            calendar: (_) => fail('Expected home fallback'),
            admin: (_) => fail('Expected home fallback'),
            memberManagement: (_) => fail('Expected home fallback'),
          );
        },
      );

      test('resolves admin → admin when user is admin', () async {
        final context = const ViewContext(type: ViewType.admin);
        final permissions = const PermissionContext(
          groupId: 2,
          permissions: {},
          isAdmin: true,
        );

        final result = await resolver.resolveTargetRoute(
          context,
          2,
          permissions,
        );

        expect(result, isA<WorkspaceRoute>());
        result.when(
          home: (_) => fail('Expected admin route'),
          channel: (_, __) => fail('Expected admin route'),
          calendar: (_) => fail('Expected admin route'),
          admin: (groupId) => expect(groupId, 2),
          memberManagement: (_) => fail('Expected admin route'),
        );
      });

      test(
        'resolves memberManagement → memberManagement when user has permission',
        () async {
          final context = const ViewContext(type: ViewType.memberManagement);
          final permissions = const PermissionContext(
            groupId: 2,
            permissions: {'MEMBER_MANAGE'},
            isAdmin: false,
          );

          final result = await resolver.resolveTargetRoute(
            context,
            2,
            permissions,
          );

          expect(result, isA<WorkspaceRoute>());
          result.when(
            home: (_) => fail('Expected memberManagement route'),
            channel: (_, __) => fail('Expected memberManagement route'),
            calendar: (_) => fail('Expected memberManagement route'),
            admin: (_) => fail('Expected memberManagement route'),
            memberManagement: (groupId) => expect(groupId, 2),
          );
        },
      );

      test(
        'resolves memberManagement → home fallback when user lacks permission',
        () async {
          final context = const ViewContext(type: ViewType.memberManagement);
          final permissions = const PermissionContext(
            groupId: 2,
            permissions: {},
            isAdmin: false,
          );

          final result = await resolver.resolveTargetRoute(
            context,
            2,
            permissions,
          );

          expect(result, isA<WorkspaceRoute>());
          result.when(
            home: (groupId) => expect(groupId, 2),
            channel: (_, __) => fail('Expected home fallback'),
            calendar: (_) => fail('Expected home fallback'),
            admin: (_) => fail('Expected home fallback'),
            memberManagement: (_) => fail('Expected home fallback'),
          );
        },
      );
    });

    group('channel resolution', () {
      test('resolves channel → first channel by creation date', () async {
        // Note: This test requires mocking ChannelService
        // For now, this is a placeholder showing expected behavior

        // Expected behavior:
        // - Fetch channels from API
        // - Sort by createdAt (earliest first)
        // - Return first accessible channel
        // - Fallback to home if no channels
      });

      test('resolves channel → home when no accessible channels', () async {
        // Expected behavior:
        // - Fetch channels returns empty list
        // - Return home route as fallback
      });

      test('sorts channels by createdAt timestamp correctly', () async {
        // Expected behavior:
        // - Given 3 channels with different createdAt values
        // - Should select the one with earliest timestamp
      });

      test('handles channels without createdAt field', () async {
        // Expected behavior:
        // - Channels without createdAt fall back to id sorting
        // - Lower id = created earlier
      });
    });
  });
}
