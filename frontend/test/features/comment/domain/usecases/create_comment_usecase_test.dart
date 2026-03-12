import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/comment/domain/entities/comment.dart';
import 'package:frontend/features/comment/domain/repositories/comment_repository.dart';
import 'package:frontend/features/comment/domain/usecases/create_comment_usecase.dart';
import 'package:frontend/features/post/domain/entities/author.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'create_comment_usecase_test.mocks.dart';

@GenerateMocks([CommentRepository])
void main() {
  group('CreateCommentUseCase Tests', () {
    late CreateCommentUseCase useCase;
    late MockCommentRepository mockRepository;

    setUp(() {
      mockRepository = MockCommentRepository();
      useCase = CreateCommentUseCase(mockRepository);
    });

    test('정상 케이스 - 최상위 댓글 생성 성공', () async {
      // Given
      final postId = 1;
      final content = '새로운 댓글';
      final author = Author(id: 1, name: '작성자');
      final createdComment = Comment(
        id: 1,
        postId: postId,
        content: content,
        author: author,
        createdAt: DateTime.now(),
      );

      when(
        mockRepository.createComment(
          postId: postId,
          content: content,
          parentCommentId: null,
        ),
      ).thenAnswer((_) async => createdComment);

      // When
      final result = await useCase(postId: postId, content: content);

      // Then
      expect(result, equals(createdComment));
      verify(
        mockRepository.createComment(
          postId: postId,
          content: content,
          parentCommentId: null,
        ),
      ).called(1);
    });

    test('정상 케이스 - 대댓글 생성 성공', () async {
      // Given
      final postId = 1;
      final content = '대댓글';
      final parentCommentId = 5;
      final author = Author(id: 1, name: '작성자');
      final createdReply = Comment(
        id: 2,
        postId: postId,
        content: content,
        author: author,
        createdAt: DateTime.now(),
        depth: 1,
        parentCommentId: parentCommentId,
      );

      when(
        mockRepository.createComment(
          postId: postId,
          content: content,
          parentCommentId: parentCommentId,
        ),
      ).thenAnswer((_) async => createdReply);

      // When
      final result = await useCase(
        postId: postId,
        content: content,
        parentCommentId: parentCommentId,
      );

      // Then
      expect(result, equals(createdReply));
      verify(
        mockRepository.createComment(
          postId: postId,
          content: content,
          parentCommentId: parentCommentId,
        ),
      ).called(1);
    });

    test('입력 검증 - postId가 0', () async {
      // When / Then
      expect(
        () => useCase(postId: 0, content: '댓글'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Post ID must be positive',
          ),
        ),
      );

      verifyNever(
        mockRepository.createComment(
          postId: anyNamed('postId'),
          content: anyNamed('content'),
          parentCommentId: anyNamed('parentCommentId'),
        ),
      );
    });

    test('입력 검증 - 빈 내용', () async {
      // When / Then
      expect(
        () => useCase(postId: 1, content: ''),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Comment content cannot be empty',
          ),
        ),
      );

      verifyNever(
        mockRepository.createComment(
          postId: anyNamed('postId'),
          content: anyNamed('content'),
          parentCommentId: anyNamed('parentCommentId'),
        ),
      );
    });

    test('입력 검증 - 공백만 있는 내용', () async {
      // When / Then
      expect(
        () => useCase(postId: 1, content: '   '),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(
        mockRepository.createComment(
          postId: anyNamed('postId'),
          content: anyNamed('content'),
          parentCommentId: anyNamed('parentCommentId'),
        ),
      );
    });

    test('입력 검증 - parentCommentId가 0', () async {
      // When / Then
      expect(
        () => useCase(postId: 1, content: '댓글', parentCommentId: 0),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Parent comment ID must be positive',
          ),
        ),
      );

      verifyNever(
        mockRepository.createComment(
          postId: anyNamed('postId'),
          content: anyNamed('content'),
          parentCommentId: anyNamed('parentCommentId'),
        ),
      );
    });

    test('내용 앞뒤 공백 제거', () async {
      // Given
      final postId = 1;
      final content = '  댓글 내용  ';
      final author = Author(id: 1, name: '작성자');
      final createdComment = Comment(
        id: 1,
        postId: postId,
        content: '댓글 내용',
        author: author,
        createdAt: DateTime.now(),
      );

      when(
        mockRepository.createComment(
          postId: postId,
          content: '댓글 내용',
          parentCommentId: null,
        ),
      ).thenAnswer((_) async => createdComment);

      // When
      await useCase(postId: postId, content: content);

      // Then
      verify(
        mockRepository.createComment(
          postId: postId,
          content: '댓글 내용',
          parentCommentId: null,
        ),
      ).called(1);
    });
  });
}
