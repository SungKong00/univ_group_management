import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 읽음 위치 추적 Notifier
///
/// VisibilityDetector와 연동하여 읽은 게시글 위치를 추적합니다.
///
/// 주요 기능:
/// - 200ms 디바운스로 읽음 위치 업데이트 최적화
/// - 가시성 50% 이상 게시글만 읽음 처리
/// - 최고 읽은 위치 추적 (절대 감소하지 않음)
class ReadPositionNotifier extends AutoDisposeNotifier<int?> {
  final Set<int> _visiblePostIds = {};
  int? _highestEverVisibleId;
  Timer? _debounceTimer;
  void Function(int postId)? _onReadPositionUpdate;

  @override
  int? build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return null;
  }

  /// 읽음 위치 업데이트 콜백 설정
  ///
  /// Widget에서 WorkspaceStateProvider 업데이트 로직을 주입합니다.
  void setOnReadPositionUpdate(void Function(int postId) callback) {
    _onReadPositionUpdate = callback;
  }

  /// 게시글 가시성 업데이트
  void updateVisibility(int postId, bool isVisible) {
    if (isVisible) {
      _visiblePostIds.add(postId);
    } else {
      _visiblePostIds.remove(postId);
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      _updateReadPosition();
    });
  }

  void _updateReadPosition() {
    if (_visiblePostIds.isEmpty) return;

    final maxId = _visiblePostIds.reduce((a, b) => a > b ? a : b);

    if (_highestEverVisibleId == null || maxId > _highestEverVisibleId!) {
      _highestEverVisibleId = maxId;
      state = maxId;

      // 콜백 실행 (외부에서 주입)
      _onReadPositionUpdate?.call(maxId);
    }
  }

  void reset() {
    _debounceTimer?.cancel();
    _visiblePostIds.clear();
    _highestEverVisibleId = null;
    state = null;
  }

  int? get highestReadId => _highestEverVisibleId;
}

final readPositionProvider =
    NotifierProvider.autoDispose<ReadPositionNotifier, int?>(
        ReadPositionNotifier.new);
