import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/post/domain/entities/author.dart';
import 'package:frontend/features/post/domain/entities/pagination.dart';
import 'package:frontend/features/post/domain/entities/post.dart';
import 'package:frontend/features/post/domain/usecases/get_posts_usecase.dart';
import 'package:frontend/features/post/presentation/providers/post_list_notifier.dart';
import 'package:frontend/features/post/presentation/providers/post_usecase_providers.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'post_list_notifier_test.mocks.dart';

@GenerateMocks([GetPostsUseCase])
void main() {
  group('PostListAsyncNotifier Tests', () {
    late MockGetPostsUseCase mockUseCase;
    late ProviderContainer container;

    setUp(() {
      mockUseCase = MockGetPostsUseCase();
    });

    tearDown(() {
      container.dispose();
    });

    ProviderContainer createContainer(String channelId) {
      return ProviderContainer(
        overrides: [
          getPostsUseCaseProvider.overrideWithValue(mockUseCase),
        ],
      );
    }

    Post createTestPost({
      required int id,
      required String content,
      DateTime? createdAt,
    }) {
      return Post(
        id: id,
        content: content,
        createdAt: createdAt ?? DateTime.now(),
        updatedAt: createdAt ?? DateTime.now(),
        author: const Author(
          id: 1,
          name: 'Test User',
        ),
      );
    }

    test('초기 로딩 - UseCase 호출하여 게시글 로드', () async {
      // Given
      final posts = [
        createTestPost(id: 1, content: 'Post 1'),
        createTestPost(id: 2, content: 'Post 2'),
      ];
      const pagination = Pagination(
        hasMore: true,
        currentPage: 0,
        totalPages: 5,
        totalElements: 100,
      );

      when(mockUseCase('channel-1', page: 0))
          .thenAnswer((_) async => (posts, pagination));

      container = createContainer('channel-1');

      // When
      final state = await container
          .read(postListAsyncNotifierProvider('channel-1').future);

      // Then
      expect(state.posts, equals(posts));
      expect(state.hasMore, isTrue);
      expect(state.currentPage, 1); // 다음 페이지
      expect(state.isLoading, isFalse);
      verify(mockUseCase('channel-1', page: 0)).called(1);
    });

    test('초기 로딩 실패 - Exception 발생', () async {
      // Given
      when(mockUseCase('channel-1', page: 0))
          .thenThrow(Exception('Network error'));

      container = createContainer('channel-1');

      // When
      final stateFuture =
          container.read(postListAsyncNotifierProvider('channel-1').future);

      // Then
      await expectLater(stateFuture, throwsA(isA<Exception>()));
    });

    test('loadMore() - 추가 페이지 로드', () async {
      // Given
      final initialPosts = [
        createTestPost(id: 1, content: 'Post 1'),
      ];
      const initialPagination = Pagination(
        hasMore: true,
        currentPage: 0,
        totalPages: 2,
        totalElements: 2,
      );

      final morePosts = [
        createTestPost(id: 2, content: 'Post 2'),
      ];
      const morePagination = Pagination(
        hasMore: false,
        currentPage: 1,
        totalPages: 2,
        totalElements: 2,
      );

      when(mockUseCase('channel-1', page: 0))
          .thenAnswer((_) async => (initialPosts, initialPagination));

      container = createContainer('channel-1');

      await container.read(postListAsyncNotifierProvider('channel-1').future);

      when(mockUseCase('channel-1', page: 1))
          .thenAnswer((_) async => (morePosts, morePagination));

      // When
      await container
          .read(postListAsyncNotifierProvider('channel-1').notifier)
          .loadMore();

      // Then
      final state = container.read(postListAsyncNotifierProvider('channel-1'));
      expect(state.value!.posts.length, 2);
      expect(state.value!.hasMore, isFalse);
      expect(state.value!.currentPage, 2);
    });

    test('loadMore() - isLoading이 true이면 중복 호출 방지', () async {
      // Given
      final posts = [createTestPost(id: 1, content: 'Post 1')];
      const pagination = Pagination(
        hasMore: true,
        currentPage: 0,
        totalPages: 5,
        totalElements: 10,
      );

      when(mockUseCase('channel-1', page: 0))
          .thenAnswer((_) async => (posts, pagination));

      container = createContainer('channel-1');

      await container.read(postListAsyncNotifierProvider('channel-1').future);

      // When - 동시에 loadMore 2번 호출
      final notifier =
          container.read(postListAsyncNotifierProvider('channel-1').notifier);

      // 첫 호출은 느리게 응답
      when(mockUseCase('channel-1', page: 1)).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return ([createTestPost(id: 2, content: 'Post 2')], pagination);
        },
      );

      final future1 = notifier.loadMore();
      final future2 = notifier.loadMore();

      await Future.wait([future1, future2]);

      // Then - UseCase는 1번만 호출됨
      verify(mockUseCase('channel-1', page: 1)).called(1);
    });

    test('loadMore() - hasMore가 false이면 호출 안 함', () async {
      // Given
      final posts = [createTestPost(id: 1, content: 'Post 1')];
      const pagination = Pagination(
        hasMore: false,
        currentPage: 0,
        totalPages: 1,
        totalElements: 1,
      );

      when(mockUseCase('channel-1', page: 0))
          .thenAnswer((_) async => (posts, pagination));

      container = createContainer('channel-1');

      await container.read(postListAsyncNotifierProvider('channel-1').future);

      // When
      await container
          .read(postListAsyncNotifierProvider('channel-1').notifier)
          .loadMore();

      // Then
      verifyNever(mockUseCase('channel-1', page: 1));
    });

    test('loadMore() - 에러 발생 시 isLoading을 false로 복구', () async {
      // Given
      final posts = [createTestPost(id: 1, content: 'Post 1')];
      const pagination = Pagination(
        hasMore: true,
        currentPage: 0,
        totalPages: 5,
        totalElements: 10,
      );

      when(mockUseCase('channel-1', page: 0))
          .thenAnswer((_) async => (posts, pagination));

      container = createContainer('channel-1');

      await container.read(postListAsyncNotifierProvider('channel-1').future);

      when(mockUseCase('channel-1', page: 1))
          .thenThrow(Exception('Network error'));

      // When
      await container
          .read(postListAsyncNotifierProvider('channel-1').notifier)
          .loadMore();

      // Then
      final state = container.read(postListAsyncNotifierProvider('channel-1'));
      expect(state.value!.isLoading, isFalse);
    });

    test('addPost() - 낙관적 업데이트', () async {
      // Given
      final initialPosts = [
        createTestPost(id: 1, content: 'Post 1'),
      ];
      const pagination = Pagination(
        hasMore: false,
        currentPage: 0,
        totalPages: 1,
        totalElements: 1,
      );

      when(mockUseCase('channel-1', page: 0))
          .thenAnswer((_) async => (initialPosts, pagination));

      container = createContainer('channel-1');

      await container.read(postListAsyncNotifierProvider('channel-1').future);

      // When
      final newPost = createTestPost(id: 2, content: 'New Post');
      container
          .read(postListAsyncNotifierProvider('channel-1').notifier)
          .addPost(newPost);

      // Then
      final state = container.read(postListAsyncNotifierProvider('channel-1'));
      expect(state.value!.posts.length, 2);
      expect(state.value!.posts.first.id, 2); // 최신 게시글이 맨 앞
    });

    test('updatePost() - 게시글 내용 수정', () async {
      // Given
      final posts = [
        createTestPost(id: 1, content: 'Original Content'),
        createTestPost(id: 2, content: 'Post 2'),
      ];
      const pagination = Pagination(
        hasMore: false,
        currentPage: 0,
        totalPages: 1,
        totalElements: 2,
      );

      when(mockUseCase('channel-1', page: 0))
          .thenAnswer((_) async => (posts, pagination));

      container = createContainer('channel-1');

      await container.read(postListAsyncNotifierProvider('channel-1').future);

      // When
      container
          .read(postListAsyncNotifierProvider('channel-1').notifier)
          .updatePost(1, 'Updated Content');

      // Then
      final state = container.read(postListAsyncNotifierProvider('channel-1'));
      final updatedPost = state.value!.posts.firstWhere((p) => p.id == 1);
      expect(updatedPost.content, 'Updated Content');
    });

    test('removePost() - 게시글 삭제', () async {
      // Given
      final posts = [
        createTestPost(id: 1, content: 'Post 1'),
        createTestPost(id: 2, content: 'Post 2'),
      ];
      const pagination = Pagination(
        hasMore: false,
        currentPage: 0,
        totalPages: 1,
        totalElements: 2,
      );

      when(mockUseCase('channel-1', page: 0))
          .thenAnswer((_) async => (posts, pagination));

      container = createContainer('channel-1');

      await container.read(postListAsyncNotifierProvider('channel-1').future);

      // When
      container
          .read(postListAsyncNotifierProvider('channel-1').notifier)
          .removePost(1);

      // Then
      final state = container.read(postListAsyncNotifierProvider('channel-1'));
      expect(state.value!.posts.length, 1);
      expect(state.value!.posts.first.id, 2);
    });

    test('상태가 null이면 낙관적 업데이트 무시', () async {
      // Given
      container = createContainer('channel-1');

      // When - 초기화 전에 addPost 호출
      container
          .read(postListAsyncNotifierProvider('channel-1').notifier)
          .addPost(createTestPost(id: 1, content: 'Post'));

      // Then - 에러 없이 무시됨
      final state = container.read(postListAsyncNotifierProvider('channel-1'));
      expect(state.isLoading, isTrue); // 아직 로딩 중
    });
  });
}
