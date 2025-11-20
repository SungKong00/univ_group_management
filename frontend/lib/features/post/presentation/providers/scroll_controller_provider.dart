import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// AutoScrollController Provider
///
/// 채널별로 독립적인 AutoScrollController 인스턴스를 관리합니다.
///
/// 주요 기능:
/// - 채널 전환 시 자동으로 이전 Controller dispose (autoDispose)
/// - AutoScrollController 재사용 (family 패턴)
/// - 메모리 누수 방지
class ScrollControllerNotifier
    extends AutoDisposeFamilyNotifier<AutoScrollController, String> {
  @override
  AutoScrollController build(String channelId) {
    final controller = AutoScrollController();

    // autoDispose 시 Controller 자동 해제
    ref.onDispose(() {
      controller.dispose();
    });

    return controller;
  }

  /// 특정 인덱스로 스크롤
  ///
  /// [index]: 스크롤할 아이템 인덱스
  /// [duration]: 애니메이션 지속 시간
  Future<void> scrollToIndex(
    int index, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    await state.scrollToIndex(
      index,
      preferPosition: AutoScrollPosition.begin,
      duration: duration,
    );
  }

  /// 현재 스크롤 위치
  double get offset => state.offset;

  /// 스크롤 가능 여부
  bool get hasClients => state.hasClients;
}

/// Scroll Controller Provider
///
/// 채널별로 독립적인 AutoScrollController를 제공합니다.
///
/// Usage:
/// ```dart
/// final controller = ref.watch(scrollControllerProvider(channelId));
/// ```
final scrollControllerProvider = NotifierProvider.autoDispose
    .family<ScrollControllerNotifier, AutoScrollController, String>(
      ScrollControllerNotifier.new,
    );
