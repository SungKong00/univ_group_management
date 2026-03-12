import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/read_position_repository.dart';
import 'channel_providers.dart';

/// 읽음 위치 상태
class ReadPositionState {
  final int channelId;
  final int? lastReadPostId;
  final DateTime? lastUpdatedAt;

  const ReadPositionState({
    required this.channelId,
    this.lastReadPostId,
    this.lastUpdatedAt,
  });

  ReadPositionState copyWith({int? lastReadPostId, DateTime? lastUpdatedAt}) {
    return ReadPositionState(
      channelId: channelId,
      lastReadPostId: lastReadPostId ?? this.lastReadPostId,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

/// 읽음 위치 관리 Notifier
///
/// Features:
/// - 200ms 디바운싱 (과도한 API 호출 방지)
/// - 낙관적 업데이트 (즉시 UI 반영)
/// - 백그라운드 저장 (재시도 큐)
class ReadPositionNotifier
    extends AutoDisposeFamilyAsyncNotifier<ReadPositionState, int> {
  Timer? _debounceTimer;
  int? _pendingPostId;

  @override
  Future<ReadPositionState> build(int channelId) async {
    // dispose 시 Timer 정리
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    // 초기 읽음 위치 로드
    final repository = ref.read(readPositionRepositoryProvider);
    final lastReadPostId = await repository.getReadPosition(channelId);

    return ReadPositionState(
      channelId: channelId,
      lastReadPostId: lastReadPostId,
      lastUpdatedAt: lastReadPostId != null ? DateTime.now() : null,
    );
  }

  /// 읽음 위치 표시 (200ms 디바운싱)
  ///
  /// [postId] 읽은 게시글 ID
  void markAsRead(int postId) {
    // 낙관적 업데이트 (즉시 UI 반영)
    state.whenData((current) {
      state = AsyncValue.data(
        current.copyWith(lastReadPostId: postId, lastUpdatedAt: DateTime.now()),
      );
    });

    // 디바운싱: 200ms 대기 후 저장
    _pendingPostId = postId;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (_pendingPostId != null) {
        _saveReadPosition(_pendingPostId!);
        _pendingPostId = null;
      }
    });
  }

  /// 백그라운드 저장 (재시도 큐)
  Future<void> _saveReadPosition(int postId) async {
    final repository = ref.read(readPositionRepositoryProvider);

    try {
      await repository.updateReadPosition(arg, postId);
    } catch (e) {
      // 실패 시 재시도 (간단한 구현)
      Future.delayed(const Duration(seconds: 2), () {
        _saveReadPosition(postId);
      });
    }
  }
}

/// Read Position Provider
final readPositionProvider = AsyncNotifierProvider.autoDispose
    .family<ReadPositionNotifier, ReadPositionState, int>(
      ReadPositionNotifier.new,
    );
