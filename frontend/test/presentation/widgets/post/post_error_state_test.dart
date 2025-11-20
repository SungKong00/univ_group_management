import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/presentation/widgets/post/post_error_state.dart';

/// PostErrorState Widget Tests
///
/// 게시글 에러 상태 UI 검증:
/// - 에러 아이콘 렌더링 (error_outline)
/// - 한글 메시지 + 영어 디버깅 정보 표시
/// - 재시도 버튼 렌더링
/// - 버튼 클릭 시 onRetry 콜백 호출
void main() {
  group('PostErrorState Widget Tests', () {
    testWidgets('에러 상태 UI 렌더링 - 아이콘, 메시지, 재시도 버튼', (tester) async {
      // Arrange
      bool retryClicked = false;
      final widget = PostErrorState(
        errorMessage: 'Exception: Network error',
        onRetry: () {
          retryClicked = true;
        },
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      await tester.pumpAndSettle();

      // Assert: 에러 아이콘
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Assert: 메인 메시지 (한글)
      expect(find.text('게시글을 불러올 수 없습니다'), findsOneWidget);

      // Assert: 디버깅 정보 (에러 메시지)
      expect(find.text('Exception: Network error'), findsOneWidget);

      // Assert: 재시도 버튼
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('재시도 버튼 클릭 시 onRetry 콜백 호출', (tester) async {
      // Arrange
      bool retryClicked = false;
      final widget = PostErrorState(
        errorMessage: 'Test error',
        onRetry: () {
          retryClicked = true;
        },
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      await tester.pumpAndSettle();

      // Tap 재시도 버튼
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      // Assert: 콜백 호출 확인
      expect(retryClicked, isTrue);
    });

    testWidgets('한글 메시지 + 영어 디버깅 정보 혼합 표시', (tester) async {
      // Arrange
      final widget = PostErrorState(
        errorMessage: 'Connection refused: localhost:8080',
        onRetry: () {},
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      await tester.pumpAndSettle();

      // Assert: 한글 사용자 메시지
      expect(find.text('게시글을 불러올 수 없습니다'), findsOneWidget);

      // Assert: 영어 디버깅 정보
      expect(find.text('Connection refused: localhost:8080'), findsOneWidget);
    });

    testWidgets('에러 아이콘 스타일 확인 (크기, 색상)', (tester) async {
      // Arrange
      final widget = PostErrorState(errorMessage: 'Test error', onRetry: () {});

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      await tester.pumpAndSettle();

      // Assert: 아이콘 속성
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(iconWidget.size, 64);
      expect(iconWidget.color, AppColors.error);
    });

    testWidgets('재시도 버튼 스타일 확인 (배경색, 텍스트 색상)', (tester) async {
      // Arrange
      final widget = PostErrorState(errorMessage: 'Test error', onRetry: () {});

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      await tester.pumpAndSettle();

      // Assert: ElevatedButton 존재
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Assert: 버튼 텍스트
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('Column 중앙 정렬 확인', (tester) async {
      // Arrange
      final widget = PostErrorState(errorMessage: 'Test error', onRetry: () {});

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      await tester.pumpAndSettle();

      // Assert: Column이 중앙 정렬
      final columnWidget = tester.widget<Column>(find.byType(Column));
      expect(columnWidget.mainAxisAlignment, MainAxisAlignment.center);
    });
  });
}
