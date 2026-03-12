import 'package:flutter/material.dart';

/// 다이얼로그 호출을 표준화하는 헬퍼 클래스
///
/// 토스 디자인 원칙 적용:
/// - 단순함: 일관된 다이얼로그 호출 패턴
/// - 위계: 타입별 명확한 반환값
/// - 피드백: barrierDismissible 제어
///
/// 주요 기능:
/// - showConfirm: bool 반환 (확인/취소 다이얼로그)
/// - show: 제네릭 T? 반환 (커스텀 데이터 반환)
/// - showAlert: void 반환 (알림 다이얼로그)
class AppDialogHelpers {
  AppDialogHelpers._();

  /// 단순 확인 다이얼로그 (반환: bool)
  ///
  /// 사용 예시:
  /// ```dart
  /// final confirmed = await AppDialogHelpers.showConfirm(
  ///   context,
  ///   dialog: const LogoutDialog(),
  /// );
  /// if (confirmed) {
  ///   // 확인 로직 실행
  /// }
  /// ```
  ///
  /// [context]: BuildContext (필수)
  /// [dialog]: 표시할 다이얼로그 위젯 (필수)
  /// [barrierDismissible]: 배경 터치로 닫기 허용 (기본값: true)
  ///
  /// Returns: true (확인), false (취소 또는 닫기)
  static Future<bool> showConfirm(
    BuildContext context, {
    required Widget dialog,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => dialog,
    );
    return result ?? false;
  }

  /// 제네릭 다이얼로그 (반환: T?)
  ///
  /// 사용 예시:
  /// ```dart
  /// final event = await AppDialogHelpers.show<PersonalEventRequest>(
  ///   context,
  ///   dialog: EventFormDialog(),
  /// );
  /// if (event != null) {
  ///   // 반환된 데이터 처리
  /// }
  /// ```
  ///
  /// [context]: BuildContext (필수)
  /// [dialog]: 표시할 다이얼로그 위젯 (필수)
  /// [barrierDismissible]: 배경 터치로 닫기 허용 (기본값: true)
  ///
  /// Returns: T? (다이얼로그에서 반환한 데이터 또는 null)
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget dialog,
    bool barrierDismissible = true,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => dialog,
    );
  }

  /// 알림 다이얼로그 (반환: void)
  ///
  /// 사용 예시:
  /// ```dart
  /// await AppDialogHelpers.showAlert(
  ///   context,
  ///   dialog: AlertDialog(
  ///     title: Text('알림'),
  ///     content: Text('작업이 완료되었습니다'),
  ///   ),
  /// );
  /// ```
  ///
  /// [context]: BuildContext (필수)
  /// [dialog]: 표시할 다이얼로그 위젯 (필수)
  /// [barrierDismissible]: 배경 터치로 닫기 허용 (기본값: true)
  ///
  /// Returns: void
  static Future<void> showAlert(
    BuildContext context, {
    required Widget dialog,
    bool barrierDismissible = true,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => dialog,
    );
  }
}
