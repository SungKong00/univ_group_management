import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/navigation/navigation_state.dart';
import 'package:frontend/core/navigation/workspace_route.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

/// Phase 6: T111-T112 - 스크롤 위치 및 폼 데이터 보존 테스트
///
/// 요구사항:
/// - T111: 스크롤 위치를 5단계까지 보존
/// - T112: 폼 데이터를 5단계까지 보존
/// - LRU 정책으로 오래된 데이터 자동 제거
///
/// 테스트 범위:
/// - 스크롤 위치 저장 및 복원
/// - 폼 데이터 저장 및 복원
/// - LRU 정책 (5개 초과 시 가장 오래된 항목 제거)
/// - route별 독립적 저장
void main() {
  group('T111-T112: Scroll Position & Form Data Preservation Tests', () {
    late NavigationStateNotifier notifier;

    setUp(() {
      notifier = NavigationStateNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    group('T111: Scroll Position Preservation', () {
      test('should save and restore scroll position for current route', () {
        // Setup: 2개 route 스택 생성
        notifier.state = NavigationState(
          stack: [
            const WorkspaceRoute.home(groupId: 1),
            const WorkspaceRoute.channel(groupId: 1, channelId: 10),
          ],
          currentIndex: 1,
        );

        // Save scroll position for channel route
        notifier.saveScrollPosition(250.5);

        // Verify position saved
        expect(notifier.getScrollPosition(), 250.5);

        // Navigate back to home
        notifier.pop();

        // Scroll position should be null for home
        expect(notifier.getScrollPosition(), isNull);

        // Navigate forward to channel again
        notifier.state = notifier.state.copyWith(currentIndex: 1);

        // Scroll position should be restored
        expect(notifier.getScrollPosition(), 250.5);
      });

      test('should maintain up to 5 scroll positions (LRU)', () {
        // Create 6 routes
        final routes = List.generate(
          6,
          (i) => WorkspaceRoute.channel(groupId: 1, channelId: i),
        );
        notifier.state = NavigationState(stack: routes, currentIndex: 0);

        // Save scroll positions for all 6 routes
        for (int i = 0; i < 6; i++) {
          notifier.state = notifier.state.copyWith(currentIndex: i);
          notifier.saveScrollPosition(i * 100.0);
        }

        // Verify only 5 positions are kept (oldest removed)
        expect(notifier.state.scrollPositions.length, 5);

        // First route's position should be removed (LRU)
        final firstRouteHash = routes[0].hashCode;
        expect(
          notifier.state.scrollPositions.containsKey(firstRouteHash),
          isFalse,
        );

        // Last 5 routes' positions should be preserved
        for (int i = 1; i < 6; i++) {
          final routeHash = routes[i].hashCode;
          expect(notifier.state.scrollPositions[routeHash], i * 100.0);
        }
      });

      test('should handle multiple updates to same route', () {
        notifier.state = NavigationState(
          stack: [const WorkspaceRoute.home(groupId: 1)],
          currentIndex: 0,
        );

        // Save position 3 times
        notifier.saveScrollPosition(100.0);
        notifier.saveScrollPosition(200.0);
        notifier.saveScrollPosition(300.0);

        // Only latest position should be saved
        expect(notifier.getScrollPosition(), 300.0);
        expect(notifier.state.scrollPositions.length, 1);
      });

      test('should return null for route without saved position', () {
        notifier.state = NavigationState(
          stack: [const WorkspaceRoute.home(groupId: 1)],
          currentIndex: 0,
        );

        // No position saved yet
        expect(notifier.getScrollPosition(), isNull);
      });

      test('should not save position when no current route', () {
        // Empty stack
        expect(notifier.state.current, isNull);

        // Try to save position
        notifier.saveScrollPosition(100.0);

        // No position should be saved
        expect(notifier.state.scrollPositions.isEmpty, isTrue);
      });
    });

    group('T112: Form Data Preservation', () {
      test('should save and restore form data for current route', () {
        // Setup: 2개 route 스택 생성
        notifier.state = NavigationState(
          stack: [
            const WorkspaceRoute.home(groupId: 1),
            const WorkspaceRoute.channel(groupId: 1, channelId: 10),
          ],
          currentIndex: 1,
        );

        // Save form data for channel route
        final formData = {
          'title': '테스트 게시글',
          'content': '내용입니다',
          'isDraft': true,
        };
        notifier.saveFormData(formData);

        // Verify form data saved
        final restored = notifier.getFormData();
        expect(restored, isNotNull);
        expect(restored!['title'], '테스트 게시글');
        expect(restored['content'], '내용입니다');
        expect(restored['isDraft'], true);

        // Navigate back to home
        notifier.pop();

        // Form data should be null for home
        expect(notifier.getFormData(), isNull);

        // Navigate forward to channel again
        notifier.state = notifier.state.copyWith(currentIndex: 1);

        // Form data should be restored
        final restoredAgain = notifier.getFormData();
        expect(restoredAgain, isNotNull);
        expect(restoredAgain!['title'], '테스트 게시글');
      });

      test('should maintain up to 5 form data states (LRU)', () {
        // Create 6 routes
        final routes = List.generate(
          6,
          (i) => WorkspaceRoute.channel(groupId: 1, channelId: i),
        );
        notifier.state = NavigationState(stack: routes, currentIndex: 0);

        // Save form data for all 6 routes
        for (int i = 0; i < 6; i++) {
          notifier.state = notifier.state.copyWith(currentIndex: i);
          notifier.saveFormData({'index': i});
        }

        // Verify only 5 form states are kept (oldest removed)
        expect(notifier.state.formData.length, 5);

        // First route's form data should be removed (LRU)
        final firstRouteHash = routes[0].hashCode;
        expect(notifier.state.formData.containsKey(firstRouteHash), isFalse);

        // Last 5 routes' form data should be preserved
        for (int i = 1; i < 6; i++) {
          final routeHash = routes[i].hashCode;
          expect(notifier.state.formData[routeHash]!['index'], i);
        }
      });

      test('should clear form data for current route', () {
        notifier.state = NavigationState(
          stack: [const WorkspaceRoute.home(groupId: 1)],
          currentIndex: 0,
        );

        // Save form data
        notifier.saveFormData({'title': '테스트'});
        expect(notifier.getFormData(), isNotNull);

        // Clear form data
        notifier.clearFormData();
        expect(notifier.getFormData(), isNull);
      });

      test('should handle complex form data types', () {
        notifier.state = NavigationState(
          stack: [const WorkspaceRoute.home(groupId: 1)],
          currentIndex: 0,
        );

        // Complex form data with nested objects, lists, etc.
        final complexData = {
          'title': '복잡한 폼',
          'tags': ['태그1', '태그2', '태그3'],
          'metadata': {
            'createdAt': '2025-01-10T12:00:00Z',
            'author': 'test_user',
          },
          'attachments': [
            {'name': 'file1.pdf', 'size': 1024},
            {'name': 'file2.jpg', 'size': 2048},
          ],
        };

        notifier.saveFormData(complexData);

        final restored = notifier.getFormData();
        expect(restored, isNotNull);
        expect(restored!['title'], '복잡한 폼');
        expect(restored['tags'], ['태그1', '태그2', '태그3']);
        expect(restored['metadata']['author'], 'test_user');
        expect((restored['attachments'] as List).length, 2);
      });

      test('should not save form data when no current route', () {
        // Empty stack
        expect(notifier.state.current, isNull);

        // Try to save form data
        notifier.saveFormData({'title': '테스트'});

        // No form data should be saved
        expect(notifier.state.formData.isEmpty, isTrue);
      });

      test('should not clear form data when no current route', () {
        // Empty stack
        expect(notifier.state.current, isNull);

        // Try to clear form data (should not throw)
        notifier.clearFormData();

        // No change
        expect(notifier.state.formData.isEmpty, isTrue);
      });
    });

    group('T111-T112: Combined Preservation', () {
      test('should preserve both scroll and form data independently', () {
        notifier.state = NavigationState(
          stack: [
            const WorkspaceRoute.home(groupId: 1),
            const WorkspaceRoute.channel(groupId: 1, channelId: 10),
          ],
          currentIndex: 1,
        );

        // Save both scroll and form data for channel route
        notifier.saveScrollPosition(500.0);
        notifier.saveFormData({'title': '게시글 작성 중'});

        // Both should be saved
        expect(notifier.getScrollPosition(), 500.0);
        expect(notifier.getFormData()!['title'], '게시글 작성 중');

        // Navigate back
        notifier.pop();

        // Both should be null for home
        expect(notifier.getScrollPosition(), isNull);
        expect(notifier.getFormData(), isNull);

        // Navigate forward again
        notifier.state = notifier.state.copyWith(currentIndex: 1);

        // Both should be restored
        expect(notifier.getScrollPosition(), 500.0);
        expect(notifier.getFormData()!['title'], '게시글 작성 중');
      });

      test('should handle route replacement correctly', () {
        notifier.state = NavigationState(
          stack: [const WorkspaceRoute.channel(groupId: 1, channelId: 10)],
          currentIndex: 0,
        );

        // Save data for first channel
        notifier.saveScrollPosition(100.0);
        notifier.saveFormData({'channelId': 10});

        // Replace with different channel
        notifier.replace(
          const WorkspaceRoute.channel(groupId: 1, channelId: 20),
        );

        // Old data should not apply to new route
        expect(notifier.getScrollPosition(), isNull);
        expect(notifier.getFormData(), isNull);

        // Save new data for new channel
        notifier.saveScrollPosition(200.0);
        notifier.saveFormData({'channelId': 20});

        // New data should be saved
        expect(notifier.getScrollPosition(), 200.0);
        expect(notifier.getFormData()!['channelId'], 20);
      });
    });
  });
}
