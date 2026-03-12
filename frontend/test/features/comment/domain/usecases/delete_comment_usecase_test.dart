import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/comment/domain/repositories/comment_repository.dart';
import 'package:frontend/features/comment/domain/usecases/delete_comment_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'delete_comment_usecase_test.mocks.dart';

@GenerateMocks([CommentRepository])
void main() {
  group('DeleteCommentUseCase Tests', () {
    late DeleteCommentUseCase useCase;
    late MockCommentRepository mockRepository;

    setUp(() {
      mockRepository = MockCommentRepository();
      useCase = DeleteCommentUseCase(mockRepository);
    });

    test('정상 케이스 - 댓글 삭제 성공', () async {
      // Given
      final commentId = 1;

      when(mockRepository.deleteComment(commentId)).thenAnswer((_) async => {});

      // When
      await useCase(commentId);

      // Then
      verify(mockRepository.deleteComment(commentId)).called(1);
    });

    test('입력 검증 - commentId가 0', () async {
      // When / Then
      expect(
        () => useCase(0),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Comment ID must be positive',
          ),
        ),
      );

      verifyNever(mockRepository.deleteComment(any));
    });

    test('입력 검증 - commentId가 음수', () async {
      // When / Then
      expect(() => useCase(-1), throwsA(isA<ArgumentError>()));

      verifyNever(mockRepository.deleteComment(any));
    });

    test('에러 케이스 - Repository 호출 실패 (권한 없음)', () async {
      // Given
      final commentId = 1;
      final exception = Exception('권한이 없습니다');

      when(mockRepository.deleteComment(commentId)).thenThrow(exception);

      // When / Then
      expect(() => useCase(commentId), throwsA(isA<Exception>()));
    });

    test('에러 케이스 - 댓글이 존재하지 않음', () async {
      // Given
      final commentId = 999;
      final exception = Exception('댓글을 찾을 수 없습니다');

      when(mockRepository.deleteComment(commentId)).thenThrow(exception);

      // When / Then
      expect(() => useCase(commentId), throwsA(isA<Exception>()));
    });
  });
}
