import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/repositories/read_position_repository.dart';
import 'channel_providers.dart';

part 'channel_read_position_notifier.freezed.dart';

/// 채널 읽음 위치 상태
@freezed
class ChannelReadPositionState with _$ChannelReadPositionState {
  const factory ChannelReadPositionState({
    /// 채널별 마지막 읽은 게시글 ID {channelId: lastReadPostId}
    @Default({}) Map<int, int> lastReadPostIdMap,

    /// 채널별 읽지 않은 글 개수 {channelId: unreadCount}
    @Default({}) Map<int, int> unreadCountMap,

    /// 현재 보고 있는 게시글 ID (가시성 추적)
    int? currentVisiblePostId,

    /// 현재 활성 채널 ID
    int? activeChannelId,
  }) = _ChannelReadPositionState;
}

/// 채널 읽음 위치 추적 Notifier
///
/// WorkspaceStateNotifier에서 분리된 독립 Provider.
/// 책임: 채널별 읽음 위치, 가시성 추적, 뱃지 카운트 관리.
class ChannelReadPositionNotifier
    extends StateNotifier<ChannelReadPositionState> {
  final ReadPositionRepository _repository;
  final Ref _ref;

  // 가시성 추적
  final Set<int> _visiblePostIds = {};
  int? _highestEverVisibleId;
  Timer? _debounceTimer;

  ChannelReadPositionNotifier(this._repository, this._ref)
    : super(const ChannelReadPositionState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 채널 진입 시 읽음 위치 로드
  Future<void> loadReadPosition(int channelId) async {
    final position = await _repository.getReadPosition(channelId);
    final unreadCount = await _repository.getUnreadCount(channelId);

    state = state.copyWith(
      activeChannelId: channelId,
      lastReadPostIdMap: {
        ...state.lastReadPostIdMap,
        channelId: position ?? -1, // -1 = 읽음 이력 없음
      },
      unreadCountMap: {...state.unreadCountMap, channelId: unreadCount},
      currentVisiblePostId: null, // 새 채널 진입 시 초기화
    );

    // 가시성 추적 초기화
    _visiblePostIds.clear();
    _highestEverVisibleId = null;
  }

  /// 채널 퇴장 시 읽음 위치 저장
  Future<void> saveReadPosition(int channelId) async {
    final currentVisible = state.currentVisiblePostId;
    if (currentVisible == null) return;

    await _repository.saveAndRefreshUnreadCount(channelId, currentVisible);

    // 뱃지 카운트 갱신
    final unreadCount = await _repository.getUnreadCount(channelId);
    state = state.copyWith(
      unreadCountMap: {...state.unreadCountMap, channelId: unreadCount},
    );
  }

  /// 게시글 가시성 업데이트 (VisibilityDetector에서 호출)
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
      state = state.copyWith(currentVisiblePostId: maxId);
    }
  }

  /// 모든 채널의 뱃지 카운트 일괄 갱신
  ///
  /// 채널 전환 시 호출하여 모든 채널의 뱃지를 동시 갱신합니다.
  /// 백그라운드로 실행되며 에러 시에도 무시합니다.
  Future<void> refreshAllBadges(List<int> channelIds) async {
    if (channelIds.isEmpty) return;

    try {
      // Batch UseCase 사용
      final useCase = _ref.read(getBatchUnreadCountsUseCaseProvider);
      final counts = await useCase(channelIds);

      // 상태 갱신
      state = state.copyWith(
        unreadCountMap: {...state.unreadCountMap, ...counts},
      );
    } catch (e) {
      // 백그라운드 작업이므로 에러 무시
    }
  }
}

/// ChannelReadPositionNotifier Provider
final channelReadPositionProvider =
    StateNotifierProvider<
      ChannelReadPositionNotifier,
      ChannelReadPositionState
    >((ref) {
      final repository = ref.watch(readPositionRepositoryProvider);
      return ChannelReadPositionNotifier(repository, ref);
    });
