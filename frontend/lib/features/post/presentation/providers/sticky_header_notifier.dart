import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sticky Header 상태
///
/// 현재 상단에 고정된 날짜를 관리합니다.
class StickyHeaderState {
  final DateTime? date;

  const StickyHeaderState({this.date});

  StickyHeaderState copyWith({DateTime? date}) {
    return StickyHeaderState(date: date ?? this.date);
  }
}

/// Sticky Header Notifier
///
/// 스크롤 위치에 따라 상단에 고정할 날짜를 계산하고 업데이트합니다.
///
/// 주요 기능:
/// - RenderBox 위치 계산으로 현재 화면 상단의 날짜 감지
/// - 스크롤 이벤트 연동
/// - 날짜 변경 시에만 상태 업데이트 (불필요한 rebuild 방지)
class StickyHeaderNotifier
    extends AutoDisposeNotifier<StickyHeaderState> {
  final Map<int, GlobalKey> _keys = {};
  final Map<int, DateTime> _dates = {};

  @override
  StickyHeaderState build() {
    ref.onDispose(() {
      _keys.clear();
      _dates.clear();
    });
    return const StickyHeaderState();
  }

  /// 날짜 헤더 키 등록
  ///
  /// [index]: 아이템 인덱스
  /// [date]: 날짜
  GlobalKey registerDateHeader(int index, DateTime date) {
    _dates[index] = date;
    if (!_keys.containsKey(index)) {
      _keys[index] = GlobalKey();
    }
    return _keys[index]!;
  }

  /// 스크롤 위치 기반 Sticky 날짜 업데이트
  ///
  /// [threshold]: 화면 상단 임계값 (TopNavigation + ChannelHeader)
  void updateStickyDate(double threshold) {
    DateTime? newStickyDate;

    for (final entry in _dates.entries) {
      final key = _keys[entry.key];
      if (key?.currentContext == null) continue;

      final box = key!.currentContext!.findRenderObject() as RenderBox?;
      if (box == null) continue;

      final pos = box.localToGlobal(Offset.zero);

      // 화면 상단 임계값 아래에 있으면 Sticky 후보
      if (pos.dy <= threshold) {
        newStickyDate = entry.value;
      } else {
        break; // 첫 번째로 임계값을 넘는 항목에서 중단
      }
    }

    // 날짜가 변경된 경우에만 상태 업데이트
    if (newStickyDate != state.date) {
      state = StickyHeaderState(date: newStickyDate);
    }
  }

  /// Sticky Header 초기화
  void reset() {
    _keys.clear();
    _dates.clear();
    state = const StickyHeaderState();
  }
}

/// Sticky Header Provider
///
/// Sticky Header 상태를 제공합니다.
final stickyHeaderProvider =
    NotifierProvider.autoDispose<StickyHeaderNotifier, StickyHeaderState>(
        StickyHeaderNotifier.new);
