import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/navigation/view_context.dart';
import 'package:frontend/core/navigation/workspace_route.dart';

void main() {
  group('ViewContext', () {
    test('creates home view context', () {
      const context = ViewContext(type: ViewType.home);

      expect(context.type, ViewType.home);
      expect(context.channelId, isNull);
    });

    test('creates channel view context with channelId', () {
      const context = ViewContext(type: ViewType.channel, channelId: 5);

      expect(context.type, ViewType.channel);
      expect(context.channelId, 5);
    });

    test('creates context from home route', () {
      const route = WorkspaceRoute.home(groupId: 1);
      final context = ViewContext.fromRoute(route);

      expect(context.type, ViewType.home);
      expect(context.channelId, isNull);
    });

    test('creates context from channel route', () {
      const route = WorkspaceRoute.channel(groupId: 1, channelId: 5);
      final context = ViewContext.fromRoute(route);

      expect(context.type, ViewType.channel);
      expect(context.channelId, 5);
    });

    test('creates context from calendar route', () {
      const route = WorkspaceRoute.calendar(groupId: 1);
      final context = ViewContext.fromRoute(route);

      expect(context.type, ViewType.calendar);
      expect(context.channelId, isNull);
    });

    test('creates context from admin route', () {
      const route = WorkspaceRoute.admin(groupId: 1);
      final context = ViewContext.fromRoute(route);

      expect(context.type, ViewType.admin);
      expect(context.channelId, isNull);
    });

    test('creates context from memberManagement route', () {
      const route = WorkspaceRoute.memberManagement(groupId: 1);
      final context = ViewContext.fromRoute(route);

      expect(context.type, ViewType.memberManagement);
      expect(context.channelId, isNull);
    });

    test('supports metadata', () {
      const context = ViewContext(
        type: ViewType.calendar,
        metadata: {'scrollPosition': 100.0},
      );

      expect(context.metadata, isNotNull);
      expect(context.metadata!['scrollPosition'], 100.0);
    });

    test('supports equality comparison', () {
      const context1 = ViewContext(type: ViewType.home);
      const context2 = ViewContext(type: ViewType.home);
      const context3 = ViewContext(type: ViewType.channel, channelId: 5);

      expect(context1, equals(context2));
      expect(context1, isNot(equals(context3)));
    });

    test('supports JSON serialization', () {
      const context = ViewContext(type: ViewType.channel, channelId: 5);
      final json = context.toJson();
      final decoded = ViewContext.fromJson(json);

      expect(decoded, equals(context));
    });
  });
}
