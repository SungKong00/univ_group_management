import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_batch_unread_counts_usecase.dart';
import 'channel_providers.dart';

/// 읽지 않은 글 배지 Notifier
///
/// Features:
/// - 채널별 읽지 않은 글 개수 관리
/// - 배치 갱신 지원 (refreshAll)
/// - 개별 채널 갱신 지원
class UnreadBadgeNotifier extends AutoDisposeFamilyAsyncNotifier<int, int> {
  @override
  Future<int> build(int channelId) async {
    // 초기 읽지 않은 글 개수 로드
    final useCase = ref.read(getBatchUnreadCountsUseCaseProvider);
    final results = await useCase([channelId]);
    return results[channelId] ?? 0;
  }

  /// 배치 갱신 (여러 채널 동시 갱신)
  ///
  /// [channelIds] 갱신할 채널 ID 목록
  ///
  /// 워크스페이스 전환, 그룹 전환 시 사용
  static Future<void> refreshAll(WidgetRef ref, List<int> channelIds) async {
    final useCase = ref.read(getBatchUnreadCountsUseCaseProvider);

    try {
      final results = await useCase(channelIds);

      // 각 채널의 provider 상태 업데이트
      for (final channelId in channelIds) {
        final provider = unreadBadgeProvider(channelId);
        ref.read(provider.notifier).state = AsyncValue.data(
          results[channelId] ?? 0,
        );
      }
    } catch (e) {
      // 에러 무시 (배지는 중요하지 않은 기능)
    }
  }

  /// 개별 채널 갱신
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(getBatchUnreadCountsUseCaseProvider);
      final results = await useCase([arg]);
      return results[arg] ?? 0;
    });
  }

  /// 읽지 않은 글 개수 감소 (낙관적 업데이트)
  void decrement() {
    state.whenData((count) {
      if (count > 0) {
        state = AsyncValue.data(count - 1);
      }
    });
  }
}

/// Unread Badge Provider
final unreadBadgeProvider = AsyncNotifierProvider.autoDispose
    .family<UnreadBadgeNotifier, int, int>(UnreadBadgeNotifier.new);
