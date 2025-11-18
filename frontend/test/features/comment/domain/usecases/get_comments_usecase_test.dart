import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/comment/domain/entities/comment.dart';
import 'package:frontend/features/comment/domain/repositories/comment_repository.dart';
import 'package:frontend/features/comment/domain/usecases/get_comments_usecase.dart';
import 'package:frontend/features/post/domain/entities/author.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_comments_usecase_test.mocks.dart';

@GenerateMocks([CommentRepository])
void main() {
  group('GetCommentsUseCase Tests', () {
    late GetCommentsUseCase useCase;
    late MockCommentRepository mockRepository;

    setUp(() {
      mockRepository = MockCommentRepository();
      useCase = GetCommentsUseCase(mockRepository);
    });

    test('정상 케이스 - 댓글 목록 조회 성공', () async {
      // Given
      final postId = 1;
      final author = Author(id: 1, name: '작성자');
      final comments = [
        Comment(
          id: 1,
          postId: postId,
          content: '첫 번째 댓글',
          author: author,
          createdAt: DateTime.now(),
        ),
        Comment(
          id: 2,
          postId: postId,
          content: '두 번째 댓글',
          author: author,
          createdAt: DateTime.now(),
        ),
      ];

      when(
        mockRepository.getComments(postId),
      ).thenAnswer((_) async => comments);

      // When
      final result = await useCase(postId);

      // Then
      expect(result, equals(comments));
      verify(mockRepository.getComments(postId)).called(1);
    });

    test('입력 검증 - postId가 0', () async {
      // Given
      final postId = 0;

      // When / Then
      expect(
        () => useCase(postId),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Post ID must be positive',
          ),
        ),
      );

      verifyNever(mockRepository.getComments(any));
    });

    test('입력 검증 - postId가 음수', () async {
      // Given
      final postId = -1;

      // When / Then
      expect(() => useCase(postId), throwsA(isA<ArgumentError>()));

      verifyNever(mockRepository.getComments(any));
    });

    test('에러 케이스 - Repository 호출 실패', () async {
      // Given
      final postId = 1;
      final exception = Exception('네트워크 에러');

      when(mockRepository.getComments(postId)).thenThrow(exception);

      // When / Then
      expect(() => useCase(postId), throwsA(isA<Exception>()));
    });

    test('빈 댓글 목록 반환', () async {
      // Given
      final postId = 2;
      final comments = <Comment>[];

      when(
        mockRepository.getComments(postId),
      ).thenAnswer((_) async => comments);

      // When
      final result = await useCase(postId);

      // Then
      expect(result, isEmpty);
      verify(mockRepository.getComments(postId)).called(1);
    });
  });
}
