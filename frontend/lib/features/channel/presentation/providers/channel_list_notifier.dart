import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/providers/workspace_state_provider.dart';
import '../../domain/entities/channel.dart';
import 'channel_providers.dart';

/// Channel List AsyncNotifier
///
/// Manages the state of the channel list for the current group.
/// Uses AsyncNotifier pattern for automatic loading and error handling.
///
/// Features:
/// - Automatic loading on provider creation (build method)
/// - Automatic refresh when group changes
/// - Manual refresh support
/// - Add channel support for optimistic UI updates
class ChannelListNotifier extends AutoDisposeAsyncNotifier<List<Channel>> {
  @override
  Future<List<Channel>> build() async {
    // Watch current group ID to automatically refresh when group changes
    final groupId = ref.watch(currentGroupIdProvider);

    if (groupId == null) {
      // No group selected, return empty list
      return [];
    }

    // Automatically load channels for the current group
    final channels = await _loadChannels(groupId);

    return channels;
  }

  /// Loads channels for the specified group
  Future<List<Channel>> _loadChannels(String groupId) async {
    final useCase = ref.read(getChannelListUseCaseProvider);

    try {
      return await useCase(groupId);
    } catch (e) {
      throw Exception('채널 목록을 불러오는데 실패했습니다 ($e)');
    }
  }

  /// Refreshes the channel list
  ///
  /// Call this when channels are created, updated, or deleted
  /// to ensure the UI reflects the latest state.
  Future<void> refresh() async {
    final groupId = ref.read(currentGroupIdProvider);

    if (groupId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadChannels(groupId));
  }

  /// Adds a newly created channel to the list
  ///
  /// This is an optimistic update - the channel is added immediately
  /// without waiting for a server response.
  ///
  /// Use this after successfully creating a channel to update the UI instantly.
  void addChannel(Channel channel) {
    state.whenData((channels) {
      state = AsyncValue.data([...channels, channel]);
    });
  }

  /// Removes a channel from the list
  ///
  /// This is an optimistic update - the channel is removed immediately
  /// without waiting for a server response.
  ///
  /// Use this after successfully deleting a channel to update the UI instantly.
  void removeChannel(int channelId) {
    state.whenData((channels) {
      final updatedChannels = channels.where((c) => c.id != channelId).toList();
      state = AsyncValue.data(updatedChannels);
    });
  }
}

/// Channel List Provider
///
/// Provides the channel list for the current group.
/// Automatically refreshes when the current group changes.
final channelListProvider =
    AsyncNotifierProvider.autoDispose<ChannelListNotifier, List<Channel>>(
      ChannelListNotifier.new,
    );
