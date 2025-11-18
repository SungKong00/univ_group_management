import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/presentation/widgets/post/post_empty_state.dart';

/// PostEmptyState Widget Tests
///
/// 빈 게시글 상태 UI 검증:
/// - 아이콘 렌더링 (article_outlined)
/// - 한글 메시지 표시
/// - 서브타이틀 표시
/// - 접근성 (Semantics) 확인
void main() {
  group('PostEmptyState Widget Tests', () {
    testWidgets('빈 상태 UI 렌더링 - 아이콘, 메시지, 서브타이틀', (tester) async {
      // Arrange
      const widget = PostEmptyState();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: 아이콘 렌더링
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);

      // Assert: 메인 메시지
      expect(find.text('아직 게시글이 없습니다'), findsOneWidget);

      // Assert: 서브타이틀
      expect(find.text('첫 번째 게시글을 작성해보세요'), findsOneWidget);
    });

    testWidgets('아이콘 스타일 확인 (크기, 색상)', (tester) async {
      // Arrange
      const widget = PostEmptyState();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: 아이콘 속성
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.article_outlined));
      expect(iconWidget.size, 64);
      expect(iconWidget.color, AppColors.neutral400);
    });

    testWidgets('접근성 - Semantics 확인', (tester) async {
      // Arrange
      const widget = PostEmptyState();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: 텍스트가 스크린 리더에서 읽힐 수 있는지 확인
      final finder = find.text('아직 게시글이 없습니다');
      expect(finder, findsOneWidget);

      // Semantics 노드 확인
      final semantics = tester.getSemantics(finder);
      expect(semantics.label, contains('아직 게시글이 없습니다'));
    });

    testWidgets('Column 중앙 정렬 확인', (tester) async {
      // Arrange
      const widget = PostEmptyState();

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Column이 중앙 정렬
      final columnWidget = tester.widget<Column>(find.byType(Column));
      expect(columnWidget.mainAxisAlignment, MainAxisAlignment.center);
    });
  });
}
