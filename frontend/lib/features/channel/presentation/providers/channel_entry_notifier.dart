import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/channel_entry_result.dart';
import 'channel_providers.dart';

/// Channel Entry AsyncNotifier
///
/// Manages the state of entering a channel, including loading
/// permissions, posts, and read positions.
///
/// Features:
/// - Automatic loading on provider creation (build method)
/// - Parallel loading of permissions, posts, and read positions
/// - Race Condition prevention (atomic loading)
/// - Manual refresh support
///
/// Uses Family pattern to create separate instances per channel.
class ChannelEntryNotifier
    extends AutoDisposeFamilyAsyncNotifier<ChannelEntryResult, Channel> {
  @override
  Future<ChannelEntryResult> build(Channel channel) async {
    // Automatically enter the channel when provider is first accessed
    return await _enterChannel(channel);
  }

  /// Enters the channel and loads all necessary data
  ///
  /// Loads the following data in parallel:
  /// - Channel permissions
  /// - Last read position
  /// - Post list
  ///
  /// This prevents Race Conditions by ensuring all data is loaded atomically.
  Future<ChannelEntryResult> _enterChannel(Channel channel) async {
    final useCase = ref.read(enterChannelUseCaseProvider);

    try {
      return await useCase(channel);
    } catch (e) {
      throw Exception('채널 진입에 실패했습니다 ($e)');
    }
  }

  /// Refreshes the channel entry
  ///
  /// Call this when:
  /// - Channel permissions have changed
  /// - New posts have been added
  /// - Read position needs to be updated
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _enterChannel(arg));
  }

  /// Updates the read position locally
  ///
  /// This is an optimistic update - the read position is updated immediately
  /// without waiting for a server response.
  ///
  /// Use this after marking posts as read to update the UI instantly.
  void updateReadPosition(int? newPosition) {
    state.whenData((result) {
      state = AsyncValue.data(
        ChannelEntryResult(
          channel: result.channel,
          permissions: result.permissions,
          posts: result.posts,
          readPosition: newPosition,
        ),
      );
    });
  }
}

/// Channel Entry Provider
///
/// Provides the channel entry result for the specified channel.
/// Automatically loads all necessary data when first accessed.
///
/// Use this provider when entering a channel to get permissions,
/// posts, and read positions in a single atomic operation.
final channelEntryProvider = AsyncNotifierProvider.autoDispose
    .family<ChannelEntryNotifier, ChannelEntryResult, Channel>(
      ChannelEntryNotifier.new,
    );
