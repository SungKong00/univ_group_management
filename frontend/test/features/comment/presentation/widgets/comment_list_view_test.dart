import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/comment/domain/entities/comment.dart';
import 'package:frontend/features/comment/domain/usecases/get_comments_usecase.dart';
import 'package:frontend/features/comment/presentation/providers/comment_providers.dart';
import 'package:frontend/features/comment/presentation/widgets/comment_list_view.dart';
import 'package:frontend/features/post/domain/entities/author.dart';
import 'package:frontend/presentation/widgets/common/app_empty_state.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'comment_list_view_test.mocks.dart';

@GenerateMocks([GetCommentsUseCase])
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('CommentListView Widget Tests', () {
    late MockGetCommentsUseCase mockUseCase;
    late List<Comment> mockComments;

    setUp(() {
      mockUseCase = MockGetCommentsUseCase();

      mockComments = [
        Comment(
          id: 1,
          postId: 1,
          content: 'Test comment 1',
          author: const Author(
            id: 100,
            name: 'Test User 1',
            profileImageUrl: null,
          ),
          createdAt: DateTime(2025, 1, 1, 10, 0),
          depth: 0,
        ),
        Comment(
          id: 2,
          postId: 1,
          content: 'Test comment 2',
          author: const Author(
            id: 101,
            name: 'Test User 2',
            profileImageUrl: null,
          ),
          createdAt: DateTime(2025, 1, 1, 11, 0),
          depth: 0,
        ),
      ];
    });

    testWidgets('빈 댓글 목록 (AppEmptyState) 렌더링 확인', (tester) async {
      // Given: 빈 목록 반환
      when(mockUseCase(1)).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCommentsUseCaseProvider.overrideWithValue(mockUseCase),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CommentListView(postId: 1)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: AppEmptyState 표시
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('아직 댓글이 없습니다'), findsOneWidget);
    });

    testWidgets('댓글 목록 렌더링 확인 (위젯 존재)', (tester) async {
      // Given: 댓글 목록 반환
      when(mockUseCase(1)).thenAnswer((_) async => mockComments);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCommentsUseCaseProvider.overrideWithValue(mockUseCase),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CommentListView(postId: 1)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: ListView 존재 확인
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('AsyncValue.error 상태 렌더링 확인', (tester) async {
      // Given: 에러 발생
      when(mockUseCase(1)).thenThrow(Exception('Test error'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCommentsUseCaseProvider.overrideWithValue(mockUseCase),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CommentListView(postId: 1)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 에러 메시지 표시
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('댓글을 불러오는데 실패했습니다'), findsOneWidget);
    });
  });
}
