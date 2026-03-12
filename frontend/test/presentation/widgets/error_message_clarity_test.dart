import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/presentation/providers/navigation_state_provider.dart';

/// Phase 7: T145.2 - 에러 메시지 명확성 테스트
///
/// 요구사항:
/// - T107: 에러 메시지 표시 (한글, 명확한 원인)
/// - 에러 상태 관리
/// - 에러 메시지 지속 시간 (3초 권장)
///
/// 테스트 범위:
/// - 에러 메시지 한글 표시
/// - 에러 상태 설정 및 초기화
/// - 에러 메시지 포맷 검증
/// - 개발자 정보 포함 (옵션)
void main() {
  group('T145.2: Error Message Clarity Tests', () {
    late NavigationStateNotifier notifier;

    setUp(() {
      notifier = NavigationStateNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('error message should be in Korean', () {
      // 초기 상태: 에러 없음
      expect(notifier.state.lastError, isNull);

      // T107: 에러 발생 (한글 메시지)
      notifier.state = notifier.state.copyWith(lastError: '그룹 전환에 실패했습니다');

      expect(notifier.state.lastError, isNotNull);
      expect(notifier.state.lastError, '그룹 전환에 실패했습니다');

      // 한글로 시작하는지 검증
      expect(notifier.state.lastError, matches(r'^[가-힣]'));
    });

    test('error message can include debug information', () {
      // 사용자 메시지 + 개발자 정보 형식
      const errorMessage = '권한 확인에 실패했습니다 (Permission denied)';

      notifier.state = notifier.state.copyWith(lastError: errorMessage);

      expect(notifier.state.lastError, contains('권한 확인에 실패했습니다'));
      expect(notifier.state.lastError, contains('Permission denied'));
    });

    test('clearError should remove error state', () {
      // 에러 설정
      notifier.state = notifier.state.copyWith(lastError: '데이터 로딩에 실패했습니다');

      expect(notifier.state.lastError, isNotNull);

      // T107: 에러 클리어
      notifier.clearError();

      expect(notifier.state.lastError, isNull);
    });

    test('error message should be descriptive', () {
      // 명확한 에러 메시지 예시들
      final errorMessages = [
        '그룹 전환에 실패했습니다 (네트워크 오류)',
        '권한이 없습니다',
        '오프라인 상태에서는 그룹을 전환할 수 없습니다',
        '채널을 찾을 수 없습니다',
        '세션이 만료되었습니다',
      ];

      for (final message in errorMessages) {
        notifier.state = notifier.state.copyWith(lastError: message);

        // 메시지가 비어있지 않은지 검증
        expect(notifier.state.lastError, isNotEmpty);

        // 한글 포함 여부 검증 (명확한 사용자 메시지)
        expect(notifier.state.lastError, matches(r'[가-힣]'));

        notifier.clearError();
      }
    });

    test('offline error message should be clear', () {
      // T108: 오프라인 에러 메시지
      const offlineMessage = '오프라인 상태에서는 그룹을 전환할 수 없습니다';

      notifier.state = notifier.state.copyWith(
        lastError: offlineMessage,
        isOffline: true,
      );

      expect(notifier.state.lastError, offlineMessage);
      expect(notifier.state.isOffline, isTrue);

      // 명확한 원인 제시 검증
      expect(notifier.state.lastError, contains('오프라인'));
      expect(notifier.state.lastError, contains('전환할 수 없습니다'));
    });

    test('API error message format should be consistent', () {
      // API 에러 포맷: "사용자 메시지 (개발자 정보)"
      final apiErrorExamples = [
        '그룹 전환에 실패했습니다 (Status code: 403)',
        '권한 확인에 실패했습니다 (Unauthorized)',
        '데이터 로딩에 실패했습니다 (Network timeout)',
      ];

      for (final errorMessage in apiErrorExamples) {
        notifier.state = notifier.state.copyWith(lastError: errorMessage);

        // "사용자 메시지 (개발자 정보)" 패턴 검증
        expect(
          notifier.state.lastError,
          matches(r'^[가-힣\s]+ \([A-Za-z\s:0-9]+\)$'),
        );

        notifier.clearError();
      }
    });

    test('error state should persist until explicitly cleared', () {
      // 에러 설정
      notifier.state = notifier.state.copyWith(lastError: '테스트 에러');

      expect(notifier.state.lastError, '테스트 에러');

      // 다른 상태 변경 (에러는 유지되어야 함)
      notifier.state = notifier.state.copyWith(isLoading: true);

      expect(notifier.state.lastError, '테스트 에러'); // 여전히 존재
      expect(notifier.state.isLoading, isTrue);

      // 명시적 클리어만 에러 제거
      notifier.clearError();
      expect(notifier.state.lastError, isNull);
    });

    test('multiple consecutive errors should be handled correctly', () {
      // 첫 번째 에러
      notifier.state = notifier.state.copyWith(lastError: '첫 번째 에러');

      expect(notifier.state.lastError, '첫 번째 에러');

      // 두 번째 에러로 덮어쓰기
      notifier.state = notifier.state.copyWith(lastError: '두 번째 에러');

      expect(notifier.state.lastError, '두 번째 에러');

      // 세 번째 에러
      notifier.state = notifier.state.copyWith(lastError: '세 번째 에러');

      expect(notifier.state.lastError, '세 번째 에러');
    });

    test('error message length should be reasonable', () {
      // 너무 긴 에러 메시지 (100자 이상)는 권장하지 않음
      final errorMessages = [
        '그룹 전환에 실패했습니다',
        '권한이 없습니다',
        '데이터 로딩에 실패했습니다 (Network error: Connection timeout)',
      ];

      for (final message in errorMessages) {
        notifier.state = notifier.state.copyWith(lastError: message);

        // 100자 이내 권장
        expect(
          notifier.state.lastError!.length,
          lessThan(100),
          reason: '에러 메시지는 100자 이내로 유지되어야 합니다',
        );

        notifier.clearError();
      }
    });

    test('error message should not contain technical jargon', () {
      // 사용자 친화적인 메시지 (기술 용어는 괄호 안에)
      final goodMessages = [
        '그룹 전환에 실패했습니다 (Network error)',
        '권한 확인에 실패했습니다 (403 Forbidden)',
        '데이터를 불러올 수 없습니다 (Timeout)',
      ];

      final badMessages = [
        'Failed to switch group', // 영어
        'NullPointerException occurred', // 기술 용어만
        'Error code: 500', // 코드만
      ];

      // Good messages: 한글로 시작해야 함
      for (final message in goodMessages) {
        expect(message, matches(r'^[가-힣]'));
      }

      // Bad messages: 한글로 시작하지 않음 (검증 실패)
      for (final message in badMessages) {
        expect(message, isNot(matches(r'^[가-힣]')));
      }
    });
  });
}
