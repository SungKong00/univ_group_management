import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/comment/domain/entities/comment.dart';
import 'package:frontend/features/comment/domain/usecases/create_comment_usecase.dart';
import 'package:frontend/features/comment/domain/usecases/get_comments_usecase.dart';
import 'package:frontend/features/comment/presentation/providers/comment_providers.dart';
import 'package:frontend/features/comment/presentation/widgets/comment_input.dart';
import 'package:frontend/features/post/domain/entities/author.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'comment_input_test.mocks.dart';

@GenerateMocks([GetCommentsUseCase, CreateCommentUseCase])
void main() {
  group('CommentInput Widget Tests', () {
    late MockGetCommentsUseCase mockGetUseCase;
    late MockCreateCommentUseCase mockCreateUseCase;

    setUp(() {
      mockGetUseCase = MockGetCommentsUseCase();
      mockCreateUseCase = MockCreateCommentUseCase();

      // Default: 빈 댓글 목록 반환
      when(mockGetUseCase(any)).thenAnswer((_) async => []);
    });

    testWidgets('텍스트 입력 확인', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCommentsUseCaseProvider.overrideWithValue(mockGetUseCase),
            createCommentUseCaseProvider.overrideWithValue(mockCreateUseCase),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CommentInput(postId: 1)),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Test comment');
      expect(find.text('Test comment'), findsOneWidget);
    });

    testWidgets('작성 버튼 존재 확인', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCommentsUseCaseProvider.overrideWithValue(mockGetUseCase),
            createCommentUseCaseProvider.overrideWithValue(mockCreateUseCase),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CommentInput(postId: 1)),
          ),
        ),
      );

      final submitButton = find.widgetWithText(ElevatedButton, '작성');
      expect(submitButton, findsOneWidget);
    });

    testWidgets('작성 버튼 클릭 시 createComment 호출 확인', (tester) async {
      // Given: 댓글 생성 성공
      final createdComment = Comment(
        id: 999,
        postId: 1,
        content: 'Test comment',
        author: const Author(
          id: 100,
          name: 'Test User',
          profileImageUrl: null,
        ),
        createdAt: DateTime.now(),
        depth: 0,
      );

      when(mockCreateUseCase(
        postId: anyNamed('postId'),
        content: anyNamed('content'),
        parentCommentId: anyNamed('parentCommentId'),
      )).thenAnswer((_) async => createdComment);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCommentsUseCaseProvider.overrideWithValue(mockGetUseCase),
            createCommentUseCaseProvider.overrideWithValue(mockCreateUseCase),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CommentInput(postId: 1)),
          ),
        ),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test comment');

      final submitButton = find.widgetWithText(ElevatedButton, '작성');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Then: createComment 호출 확인
      verify(mockCreateUseCase(
        postId: 1,
        content: 'Test comment',
        parentCommentId: null,
      )).called(1);
    });
  });
}
