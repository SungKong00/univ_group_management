import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/constants/app_constants.dart';
import 'package:frontend/core/navigation/navigation_controller.dart';

void main() {
  group('NavigationController workspace back stack', () {
    late NavigationController controller;

    setUp(() {
      controller = NavigationController();
    });

    test('navigates home when first workspace page is popped', () {
      controller.navigateTo('${AppConstants.workspaceRoute}/group-1');

      expect(controller.state.currentRoute, '${AppConstants.workspaceRoute}/group-1');

      final targetRoute = controller.goBack();

      expect(targetRoute, AppConstants.homeRoute);
      expect(controller.state.currentRoute, AppConstants.homeRoute);
      expect(controller.state.currentTab, NavigationTab.home);
    });

    test('returns to previous workspace entry before exiting to home', () {
      controller.navigateTo('${AppConstants.workspaceRoute}/group-1');
      controller.navigateTo('${AppConstants.workspaceRoute}/group-2');

      final firstBack = controller.goBack();

      expect(firstBack, '${AppConstants.workspaceRoute}/group-1');
      expect(controller.state.currentRoute, '${AppConstants.workspaceRoute}/group-1');
      expect(controller.state.currentTab, NavigationTab.workspace);

      final secondBack = controller.goBack();

      expect(secondBack, AppConstants.homeRoute);
      expect(controller.state.currentRoute, AppConstants.homeRoute);
      expect(controller.state.currentTab, NavigationTab.home);
    });

    test('persists navigation context for future workspace pages', () {
      controller.navigateTo(
        '${AppConstants.workspaceRoute}/group-1/channel/notice',
        context: {
          'groupId': 'group-1',
          'channelId': 'notice',
        },
      );

      final history = controller.state.tabHistories[NavigationTab.workspace];

      expect(history, isNotNull);
      expect(history!.last.route, '${AppConstants.workspaceRoute}/group-1/channel/notice');

      final context = history.last.context;
      expect(context, isNotNull);
      expect(context!['groupId'], 'group-1');
      expect(context['channelId'], 'notice');
    });
  });
}
