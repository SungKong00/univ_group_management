import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/post/domain/entities/author.dart';
import 'package:frontend/features/post/domain/entities/post.dart';
import 'package:frontend/features/post/domain/entities/pagination.dart';
import 'package:frontend/features/post/domain/usecases/get_posts_usecase.dart';
import 'package:frontend/features/post/presentation/providers/post_usecase_providers.dart';
import 'package:frontend/features/post/presentation/providers/post_list_state.dart';
import 'package:frontend/presentation/widgets/post/post_list_view.dart';
import 'package:frontend/presentation/widgets/post/post_empty_state.dart';
import 'package:frontend/presentation/widgets/post/post_error_state.dart';
import 'package:frontend/presentation/widgets/post/post_skeleton.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'post_list_view_test.mocks.dart';

/// PostListView Widget Tests
///
/// AsyncValue.when() 패턴을 사용한 상태별 UI 검증:
/// - loading: PostListSkeleton 표시
/// - error: PostErrorState 표시 (재시도 버튼)
/// - data (빈 목록): PostEmptyState 표시
/// - data (게시글 있음): buildScrollView 콜백 호출
@GenerateMocks([GetPostsUseCase])
void main() {
  group('PostListView Widget Tests', () {
    const testChannelId = 'test-channel-1';
    late MockGetPostsUseCase mockUseCase;

    setUp(() {
      mockUseCase = MockGetPostsUseCase();
    });

    testWidgets('AsyncValue.data (빈 목록) - PostEmptyState 표시', (tester) async {
      // Arrange: 빈 목록 반환
      when(mockUseCase(testChannelId, page: 0)).thenAnswer(
        (_) async => (
          <Post>[],
          const Pagination(
            totalPages: 0,
            currentPage: 0,
            totalElements: 0,
            hasMore: false,
          ),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getPostsUseCaseProvider.overrideWithValue(mockUseCase),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PostListView(
                channelId: testChannelId,
                buildScrollView: _buildDummyScrollView,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: PostEmptyState 표시
      expect(find.byType(PostEmptyState), findsOneWidget);
      expect(find.text('아직 게시글이 없습니다'), findsOneWidget);
    });

    testWidgets('AsyncValue.data (게시글 있음) - buildScrollView 호출', (tester) async {
      // Arrange: 게시글 목록 반환
      final mockPosts = [
        Post(
          id: 1,
          content: 'Test post 1',
          author: const Author(id: 100, name: 'User 1'),
          createdAt: DateTime(2025, 11, 19, 10, 0),
        ),
        Post(
          id: 2,
          content: 'Test post 2',
          author: const Author(id: 101, name: 'User 2'),
          createdAt: DateTime(2025, 11, 19, 11, 0),
        ),
      ];

      when(mockUseCase(testChannelId, page: 0)).thenAnswer(
        (_) async => (
          mockPosts,
          const Pagination(
            totalPages: 1,
            currentPage: 0,
            totalElements: 2,
            hasMore: true,
          ),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getPostsUseCaseProvider.overrideWithValue(mockUseCase),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PostListView(
                channelId: testChannelId,
                buildScrollView: (state) {
                  return const Text('ScrollView with posts');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: buildScrollView 콜백이 호출되어 커스텀 위젯 렌더링
      expect(find.text('ScrollView with posts'), findsOneWidget);
      expect(find.byType(PostEmptyState), findsNothing);
    });

    testWidgets('AsyncValue.error - PostErrorState 표시', (tester) async {
      // Arrange: 에러 발생
      when(mockUseCase(testChannelId, page: 0)).thenThrow(
        Exception('Network failure'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getPostsUseCaseProvider.overrideWithValue(mockUseCase),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PostListView(
                channelId: testChannelId,
                buildScrollView: _buildDummyScrollView,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: PostErrorState 표시
      expect(find.byType(PostErrorState), findsOneWidget);
      expect(find.text('게시글을 불러올 수 없습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('buildScrollView 콜백에 PostListState 전달 확인', (tester) async {
      // Arrange: 게시글 목록 반환
      final mockPosts = [
        Post(
          id: 1,
          content: 'Test post',
          author: const Author(id: 100, name: 'User'),
          createdAt: DateTime(2025, 11, 19),
        ),
      ];

      when(mockUseCase(testChannelId, page: 0)).thenAnswer(
        (_) async => (
          mockPosts,
          const Pagination(
            totalPages: 1,
            currentPage: 0,
            totalElements: 1,
            hasMore: false,
          ),
        ),
      );

      PostListState? receivedState;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getPostsUseCaseProvider.overrideWithValue(mockUseCase),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PostListView(
                channelId: testChannelId,
                buildScrollView: (state) {
                  receivedState = state as PostListState;
                  return const Text('ScrollView');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: PostListState가 전달되었는지 확인
      expect(receivedState, isNotNull);
      expect(receivedState!.posts.length, 1);
    });
  });
}

/// Dummy buildScrollView 콜백
Widget _buildDummyScrollView(dynamic state) => const Text('ScrollView');
