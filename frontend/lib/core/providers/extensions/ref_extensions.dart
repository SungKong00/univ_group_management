import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod Ref 확장
///
/// 성능 최적화를 위한 헬퍼 메서드 제공
extension RefExtensions on Ref {
  /// 캐시 유지 기간 설정
  ///
  /// 지정된 기간 동안 Provider가 자동으로 dispose되지 않도록 합니다.
  ///
  /// 사용 예:
  /// ```dart
  /// ref.cacheFor(const Duration(minutes: 5));
  /// ```
  void cacheFor(Duration duration) {
    // keepAlive 링크 생성
    final link = keepAlive();

    // 타이머로 지정된 시간 후 자동 dispose
    final timer = Timer(duration, () {
      link.close();
    });

    // Provider가 dispose될 때 타이머도 취소
    onDispose(() {
      timer.cancel();
    });
  }
}
