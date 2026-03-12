import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/domain/usecases/calculate_unread_position_usecase.dart';
import 'package:frontend/features/post/domain/entities/author.dart';
import 'package:frontend/features/post/domain/entities/post.dart';

/// CalculateUnreadPositionUseCase 테스트
///
/// 가장 중요한 핵심 비즈니스 로직 검증
///
/// 검증 항목:
/// 1. 정상 케이스 - 읽지 않은 게시글이 있는 경우
/// 2. Edge Cases - 빈 게시글 목록, 읽은 위치 없음, 모두 읽음, 삭제된 게시글
/// 3. totalUnread 계산 검증
/// 4. hasUnread 플래그 검증
void main() {
  group('CalculateUnreadPositionUseCase Tests', () {
    late CalculateUnreadPositionUseCase useCase;

    setUp(() {
      useCase = CalculateUnreadPositionUseCase();
    });

    /// 테스트용 게시글 리스트 생성 헬퍼
    List<Post> createPosts(int count) {
      return List.generate(
        count,
        (index) => Post(
          id: index + 1,
          content: '게시글 ${index + 1}',
          author: Author(id: 1, name: '작성자'),
          createdAt: DateTime.now(),
        ),
      );
    }

    test('Edge Case: 빈 게시글 목록', () {
      // Given
      final posts = <Post>[];
      final lastReadPostId = null;

      // When
      final result = useCase(posts, lastReadPostId);

      // Then
      expect(result.unreadIndex, isNull);
      expect(result.totalUnread, equals(0));
      expect(result.hasUnread, isFalse);
    });

    test('Case 1: 읽은 위치 없음 - 첫 게시글로 이동', () {
      // Given
      final posts = createPosts(5);
      final lastReadPostId = null;

      // When
      final result = useCase(posts, lastReadPostId);

      // Then
      expect(result.unreadIndex, equals(0)); // 첫 게시글 인덱스
      expect(result.totalUnread, equals(5)); // 모든 게시글이 읽지 않음
      expect(result.hasUnread, isTrue);
    });

    test('Case 2: 읽은 위치 있음 - 다음 읽지 않은 게시글로 이동', () {
      // Given
      final posts = createPosts(10);
      final lastReadPostId = 3; // 3번 게시글까지 읽음

      // When
      final result = useCase(posts, lastReadPostId);

      // Then
      expect(result.unreadIndex, equals(3)); // 4번 게시글 (인덱스 3)
      expect(result.totalUnread, equals(7)); // 4~10번 게시글 (7개)
      expect(result.hasUnread, isTrue);
    });

    test('Case 3: 모두 읽음 - 마지막 게시글이 읽은 위치', () {
      // Given
      final posts = createPosts(5);
      final lastReadPostId = 5; // 마지막 게시글까지 읽음

      // When
      final result = useCase(posts, lastReadPostId);

      // Then
      expect(result.unreadIndex, isNull); // 읽지 않은 게시글 없음
      expect(result.totalUnread, equals(0));
      expect(result.hasUnread, isFalse);
    });

    test('Edge Case: 읽은 위치가 목록에 없음 - 삭제된 게시글', () {
      // Given
      final posts = createPosts(5); // 1~5번 게시글
      final lastReadPostId = 99; // 존재하지 않는 게시글 ID

      // When
      final result = useCase(posts, lastReadPostId);

      // Then
      expect(result.unreadIndex, equals(0)); // 첫 게시글로 폴백
      expect(result.totalUnread, equals(5)); // 모든 게시글이 읽지 않음
      expect(result.hasUnread, isTrue);
    });

    test('totalUnread 계산 검증 - 중간 위치', () {
      // Given
      final posts = createPosts(20);
      final lastReadPostId = 7; // 7번 게시글까지 읽음

      // When
      final result = useCase(posts, lastReadPostId);

      // Then
      expect(result.unreadIndex, equals(7)); // 8번 게시글 (인덱스 7)
      expect(result.totalUnread, equals(13)); // 8~20번 게시글 (13개)
      expect(result.hasUnread, isTrue);
    });

    test('totalUnread 계산 검증 - 마지막 직전', () {
      // Given
      final posts = createPosts(10);
      final lastReadPostId = 9; // 9번 게시글까지 읽음

      // When
      final result = useCase(posts, lastReadPostId);

      // Then
      expect(result.unreadIndex, equals(9)); // 10번 게시글 (인덱스 9)
      expect(result.totalUnread, equals(1)); // 마지막 1개만 읽지 않음
      expect(result.hasUnread, isTrue);
    });

    test('hasUnread 플래그 - 읽지 않은 게시글이 있을 때 true', () {
      // Given
      final posts = createPosts(3);
      final lastReadPostId = 1; // 1번 게시글까지 읽음

      // When
      final result = useCase(posts, lastReadPostId);

      // Then
      expect(result.hasUnread, isTrue);
      expect(result.totalUnread, greaterThan(0));
      expect(result.unreadIndex, isNotNull);
    });

    test('hasUnread 플래그 - 모두 읽었을 때 false', () {
      // Given
      final posts = createPosts(3);
      final lastReadPostId = 3; // 모두 읽음

      // When
      final result = useCase(posts, lastReadPostId);

      // Then
      expect(result.hasUnread, isFalse);
      expect(result.totalUnread, equals(0));
      expect(result.unreadIndex, isNull);
    });

    test('Edge Case: 게시글 1개만 있고 읽지 않음', () {
      // Given
      final posts = createPosts(1);
      final lastReadPostId = null;

      // When
      final result = useCase(posts, lastReadPostId);

      // Then
      expect(result.unreadIndex, equals(0));
      expect(result.totalUnread, equals(1));
      expect(result.hasUnread, isTrue);
    });

    test('Edge Case: 게시글 1개만 있고 이미 읽음', () {
      // Given
      final posts = createPosts(1);
      final lastReadPostId = 1;

      // When
      final result = useCase(posts, lastReadPostId);

      // Then
      expect(result.unreadIndex, isNull);
      expect(result.totalUnread, equals(0));
      expect(result.hasUnread, isFalse);
    });
  });
}
