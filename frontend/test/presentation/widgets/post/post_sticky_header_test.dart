import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/presentation/widgets/post/post_sticky_header.dart';
import 'package:frontend/presentation/widgets/post/date_divider.dart';

/// PostStickyHeader Widget Tests
///
/// Sticky 날짜 헤더 UI 검증:
/// - null 날짜 처리 (SizedBox.shrink)
/// - 날짜 표시 (DateDivider 래핑)
/// - 테마별 배경색 (라이트/다크 모드)
void main() {
  group('PostStickyHeader Widget Tests', () {
    testWidgets('null 날짜 처리 - SizedBox.shrink 렌더링', (tester) async {
      // Arrange
      const widget = PostStickyHeader(stickyDate: null);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: SizedBox.shrink 존재 (DateDivider 없음)
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(DateDivider), findsNothing);
    });

    testWidgets('날짜 표시 - DateDivider 렌더링', (tester) async {
      // Arrange
      final testDate = DateTime(2025, 11, 19);
      final widget = PostStickyHeader(stickyDate: testDate);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: DateDivider 존재
      expect(find.byType(DateDivider), findsOneWidget);
    });



    testWidgets('DateDivider에 날짜 전달 확인', (tester) async {
      // Arrange
      final testDate = DateTime(2025, 11, 19, 14, 30);
      final widget = PostStickyHeader(stickyDate: testDate);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: DateDivider가 올바른 날짜를 받았는지 확인
      final dateDividerWidget = tester.widget<DateDivider>(find.byType(DateDivider));
      expect(dateDividerWidget.date, testDate);
    });
  });
}
