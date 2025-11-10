import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/navigation/workspace_route.dart';

void main() {
  group('WorkspaceRoute', () {
    test('creates home route with groupId', () {
      const route = WorkspaceRoute.home(groupId: 1);

      expect(route, isA<HomeRoute>());
      route.when(
        home: (groupId) => expect(groupId, 1),
        channel: (_, __) => fail('Should be home route'),
        calendar: (_) => fail('Should be home route'),
        admin: (_) => fail('Should be home route'),
        memberManagement: (_) => fail('Should be home route'),
      );
    });

    test('creates channel route with groupId and channelId', () {
      const route = WorkspaceRoute.channel(groupId: 1, channelId: 5);

      expect(route, isA<ChannelRoute>());
      route.when(
        home: (_) => fail('Should be channel route'),
        channel: (groupId, channelId) {
          expect(groupId, 1);
          expect(channelId, 5);
        },
        calendar: (_) => fail('Should be channel route'),
        admin: (_) => fail('Should be channel route'),
        memberManagement: (_) => fail('Should be channel route'),
      );
    });

    test('creates calendar route with groupId', () {
      const route = WorkspaceRoute.calendar(groupId: 1);

      expect(route, isA<CalendarRoute>());
      route.when(
        home: (_) => fail('Should be calendar route'),
        channel: (_, __) => fail('Should be calendar route'),
        calendar: (groupId) => expect(groupId, 1),
        admin: (_) => fail('Should be calendar route'),
        memberManagement: (_) => fail('Should be calendar route'),
      );
    });

    test('creates admin route with groupId', () {
      const route = WorkspaceRoute.admin(groupId: 1);

      expect(route, isA<AdminRoute>());
      route.when(
        home: (_) => fail('Should be admin route'),
        channel: (_, __) => fail('Should be admin route'),
        calendar: (_) => fail('Should be admin route'),
        admin: (groupId) => expect(groupId, 1),
        memberManagement: (_) => fail('Should be admin route'),
      );
    });

    test('creates memberManagement route with groupId', () {
      const route = WorkspaceRoute.memberManagement(groupId: 1);

      expect(route, isA<MemberManagementRoute>());
      route.when(
        home: (_) => fail('Should be memberManagement route'),
        channel: (_, __) => fail('Should be memberManagement route'),
        calendar: (_) => fail('Should be memberManagement route'),
        admin: (_) => fail('Should be memberManagement route'),
        memberManagement: (groupId) => expect(groupId, 1),
      );
    });

    test('supports equality comparison', () {
      const route1 = WorkspaceRoute.home(groupId: 1);
      const route2 = WorkspaceRoute.home(groupId: 1);
      const route3 = WorkspaceRoute.home(groupId: 2);

      expect(route1, equals(route2));
      expect(route1, isNot(equals(route3)));
    });

    test('supports JSON serialization', () {
      const route = WorkspaceRoute.channel(groupId: 1, channelId: 5);
      final json = route.toJson();
      final decoded = WorkspaceRoute.fromJson(json);

      expect(decoded, equals(route));
    });
  });
}
