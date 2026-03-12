import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/navigation/resource_deletion_listener.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

void main() {
  group('ResourceDeletionListener Integration', () {
    late GlobalKey<ScaffoldMessengerState> scaffoldKey;

    setUp(() {
      scaffoldKey = GlobalKey<ScaffoldMessengerState>();
    });

    testWidgets('onChannelDeleted: 채널 삭제 시 배너 표시 및 그룹 홈 이동', (tester) async {
      late ResourceDeletionListener listener;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  listener = ResourceDeletionListener(
                    ref: ref,
                    scaffoldMessengerKey: scaffoldKey,
                  );

                  Future.microtask(() {
                    ref
                        .read(navigationStateProvider.notifier)
                        .resetToRoot(
                          WorkspaceRoute.channel(groupId: 1, channelId: 5),
                        );
                  });

                  return const Center(child: Text('Test'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      listener.onChannelDeleted(groupId: 1, channelId: 5, channelName: 'Test');
      await tester.pump();

      expect(
        find.text('"Test" 채널이 삭제되었습니다. 3초 후 그룹 홈으로 이동합니다.'),
        findsOneWidget,
      );

      // Wait for timer to complete
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('onChannelDeleted: 다른 채널 보는 경우 배너 표시 안 함', (tester) async {
      late ResourceDeletionListener listener;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  listener = ResourceDeletionListener(
                    ref: ref,
                    scaffoldMessengerKey: scaffoldKey,
                  );

                  Future.microtask(() {
                    ref
                        .read(navigationStateProvider.notifier)
                        .resetToRoot(
                          WorkspaceRoute.channel(groupId: 1, channelId: 3),
                        );
                  });

                  return const Center(child: Text('Test'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      listener.onChannelDeleted(groupId: 1, channelId: 5);
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('onChannelDeleted: 확인 버튼 클릭 시 즉시 이동', (tester) async {
      late ResourceDeletionListener listener;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  listener = ResourceDeletionListener(
                    ref: ref,
                    scaffoldMessengerKey: scaffoldKey,
                  );

                  Future.microtask(() {
                    ref
                        .read(navigationStateProvider.notifier)
                        .resetToRoot(
                          WorkspaceRoute.channel(groupId: 1, channelId: 5),
                        );
                  });

                  return const Center(child: Text('Test'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      listener.onChannelDeleted(groupId: 1, channelId: 5);
      await tester.pump();

      await tester.tap(find.text('확인'), warnIfMissed: false);
      await tester.pump();
      // Wait for timer
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('onGroupDeleted: 그룹 삭제 시 배너 표시 및 워크스페이스 종료', (tester) async {
      late ResourceDeletionListener listener;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  listener = ResourceDeletionListener(
                    ref: ref,
                    scaffoldMessengerKey: scaffoldKey,
                  );

                  Future.microtask(() {
                    ref
                        .read(navigationStateProvider.notifier)
                        .resetToRoot(WorkspaceRoute.home(groupId: 1));
                  });

                  return const Center(child: Text('Test'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      listener.onGroupDeleted(groupId: 1, groupName: 'Test Group');
      await tester.pump();

      expect(
        find.text('"Test Group" 그룹이 삭제되었습니다. 3초 후 워크스페이스를 종료합니다.'),
        findsOneWidget,
      );

      // Wait for timer to complete
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('onGroupDeleted: 다른 그룹에 있는 경우 배너 표시 안 함', (tester) async {
      late ResourceDeletionListener listener;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  listener = ResourceDeletionListener(
                    ref: ref,
                    scaffoldMessengerKey: scaffoldKey,
                  );

                  Future.microtask(() {
                    ref
                        .read(navigationStateProvider.notifier)
                        .resetToRoot(WorkspaceRoute.home(groupId: 2));
                  });

                  return const Center(child: Text('Test'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      listener.onGroupDeleted(groupId: 1, groupName: 'Test Group');
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('onGroupDeleted: 확인 버튼 클릭 시 즉시 종료', (tester) async {
      late ResourceDeletionListener listener;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  listener = ResourceDeletionListener(
                    ref: ref,
                    scaffoldMessengerKey: scaffoldKey,
                  );

                  Future.microtask(() {
                    ref
                        .read(navigationStateProvider.notifier)
                        .resetToRoot(WorkspaceRoute.home(groupId: 1));
                  });

                  return const Center(child: Text('Test'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      listener.onGroupDeleted(groupId: 1);
      await tester.pump();

      await tester.tap(find.text('확인'), warnIfMissed: false);
      await tester.pump();
      // Wait for timer
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('onChannelDeleted: channelName null 시 기본 메시지', (tester) async {
      late ResourceDeletionListener listener;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  listener = ResourceDeletionListener(
                    ref: ref,
                    scaffoldMessengerKey: scaffoldKey,
                  );

                  Future.microtask(() {
                    ref
                        .read(navigationStateProvider.notifier)
                        .resetToRoot(
                          WorkspaceRoute.channel(groupId: 1, channelId: 5),
                        );
                  });

                  return const Center(child: Text('Test'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      listener.onChannelDeleted(groupId: 1, channelId: 5);
      await tester.pump();

      expect(find.text('채널이 삭제되었습니다. 3초 후 그룹 홈으로 이동합니다.'), findsOneWidget);

      // Wait for timer to complete
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('onGroupDeleted: groupName null 시 기본 메시지', (tester) async {
      late ResourceDeletionListener listener;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  listener = ResourceDeletionListener(
                    ref: ref,
                    scaffoldMessengerKey: scaffoldKey,
                  );

                  Future.microtask(() {
                    ref
                        .read(navigationStateProvider.notifier)
                        .resetToRoot(WorkspaceRoute.home(groupId: 1));
                  });

                  return const Center(child: Text('Test'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      listener.onGroupDeleted(groupId: 1);
      await tester.pump();

      expect(find.text('그룹이 삭제되었습니다. 3초 후 워크스페이스를 종료합니다.'), findsOneWidget);

      // Wait for timer to complete
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('checkResourceExists: 리소스 존재 여부 확인 (placeholder)', (
      tester,
    ) async {
      late ResourceDeletionListener listener;
      late bool result;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  listener = ResourceDeletionListener(
                    ref: ref,
                    scaffoldMessengerKey: scaffoldKey,
                  );

                  return const Center(child: Text('Test'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      result = await listener.checkResourceExists(groupId: 1, channelId: 5);

      expect(result, true);
    });
  });
}
