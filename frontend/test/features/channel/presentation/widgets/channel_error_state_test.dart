import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/channel/presentation/widgets/channel_error_state.dart';

/// ChannelErrorState Widget Tests
///
/// Note: ChannelView 전체는 PostList와의 의존성 때문에 통합 테스트에서 다룸
/// 여기서는 ChannelErrorState 위젯만 단위 테스트로 검증
void main() {
  group('ChannelErrorState Widget Tests', () {
    testWidgets('권한 없음 상태 - noPermission UI 렌더링', (tester) async {
      // Arrange
      final widget = ChannelErrorState.noPermission();

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('이 채널을 볼 권한이 없습니다'), findsOneWidget);
      expect(find.text('권한 관리자에게 문의하세요'), findsOneWidget);
    });

    testWidgets('에러 상태 - error UI 렌더링', (tester) async {
      // Arrange
      final widget = ChannelErrorState.error(Exception('Network error'));

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('채널을 불러올 수 없습니다'), findsOneWidget);
      expect(find.textContaining('Exception: Network error'), findsOneWidget);
    });

    testWidgets('커스텀 메시지 - 직접 생성', (tester) async {
      // Arrange
      final widget = const ChannelErrorState(
        icon: Icons.info_outline,
        title: 'Custom Title',
        subtitle: 'Custom Subtitle',
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom Subtitle'), findsOneWidget);
    });
  });
}
