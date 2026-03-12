import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/comment/domain/entities/comment.dart';
import 'package:frontend/features/post/domain/entities/author.dart';

/// Comment Entity 테스트
///
/// 검증 항목:
/// 1. Freezed 불변성 (copyWith, ==, hashCode)
/// 2. 필수 필드 테스트 (id, postId, content, author, createdAt)
/// 3. 선택적 필드 테스트 (updatedAt, depth, parentCommentId)
void main() {
  group('Comment Entity Tests', () {
    final author = Author(id: 1, name: '테스트 작성자');
    final now = DateTime.now();

    test('필수 필드로 Comment 생성', () {
      // Given / When
      final comment = Comment(
        id: 1,
        postId: 10,
        content: '댓글 내용',
        author: author,
        createdAt: now,
      );

      // Then
      expect(comment.id, 1);
      expect(comment.postId, 10);
      expect(comment.content, '댓글 내용');
      expect(comment.author, author);
      expect(comment.createdAt, now);
      expect(comment.updatedAt, isNull);
      expect(comment.depth, 0);
      expect(comment.parentCommentId, isNull);
    });

    test('대댓글 생성 (depth=1, parentCommentId 있음)', () {
      // Given / When
      final reply = Comment(
        id: 2,
        postId: 10,
        content: '대댓글 내용',
        author: author,
        createdAt: now,
        depth: 1,
        parentCommentId: 1,
      );

      // Then
      expect(reply.depth, 1);
      expect(reply.parentCommentId, 1);
    });

    test('수정된 댓글 (updatedAt 있음)', () {
      // Given
      final updatedAt = now.add(const Duration(hours: 1));

      // When
      final comment = Comment(
        id: 3,
        postId: 10,
        content: '수정된 내용',
        author: author,
        createdAt: now,
        updatedAt: updatedAt,
      );

      // Then
      expect(comment.updatedAt, updatedAt);
    });

    test('copyWith - 내용 수정', () {
      // Given
      final original = Comment(
        id: 4,
        postId: 10,
        content: '원래 내용',
        author: author,
        createdAt: now,
      );

      // When
      final updated = original.copyWith(
        content: '수정된 내용',
        updatedAt: now.add(const Duration(minutes: 5)),
      );

      // Then
      expect(updated.id, 4);
      expect(updated.content, '수정된 내용');
      expect(updated.updatedAt, isNotNull);
    });

    test('동등성 비교 - 동일한 필드', () {
      // Given
      final comment1 = Comment(
        id: 5,
        postId: 10,
        content: '댓글',
        author: author,
        createdAt: now,
      );
      final comment2 = Comment(
        id: 5,
        postId: 10,
        content: '댓글',
        author: author,
        createdAt: now,
      );

      // When / Then
      expect(comment1, equals(comment2));
      expect(comment1.hashCode, equals(comment2.hashCode));
    });

    test('동등성 비교 - 다른 ID', () {
      // Given
      final comment1 = Comment(
        id: 6,
        postId: 10,
        content: '댓글',
        author: author,
        createdAt: now,
      );
      final comment2 = Comment(
        id: 7,
        postId: 10,
        content: '댓글',
        author: author,
        createdAt: now,
      );

      // When / Then
      expect(comment1, isNot(equals(comment2)));
    });
  });
}
