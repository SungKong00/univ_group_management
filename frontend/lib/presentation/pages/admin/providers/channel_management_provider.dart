import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/channel_models.dart';
import '../../../../core/services/channel_service.dart';

/// 그룹의 채널 목록 조회 Provider (관리자용 - 권한 필터 없음)
///
/// 채널 관리 페이지에서 CHANNEL_MANAGE 권한이 있는 사용자가
/// POST_READ 권한이 없는 채널도 조회하고 관리할 수 있도록 함
final channelListProvider =
    FutureProvider.family<List<Channel>, int>((ref, groupId) async {
  final service = ChannelService();
  return await service.getChannelsForAdmin(groupId);
});

/// 채널 생성 요청
class CreateChannelParams {
  final int workspaceId;
  final String name;
  final String? description;
  final String? type;

  CreateChannelParams({
    required this.workspaceId,
    required this.name,
    this.description,
    this.type,
  });
}

final createChannelProvider = FutureProvider.autoDispose
    .family<Channel?, CreateChannelParams>((ref, params) async {
  final service = ChannelService();
  return await service.createChannel(
    workspaceId: params.workspaceId,
    name: params.name,
    description: params.description,
    type: params.type,
  );
});

/// 채널 수정 요청
class UpdateChannelParams {
  final int channelId;
  final String? name;
  final String? description;

  UpdateChannelParams({
    required this.channelId,
    this.name,
    this.description,
  });
}

final updateChannelProvider = FutureProvider.autoDispose
    .family<Channel?, UpdateChannelParams>((ref, params) async {
  final service = ChannelService();
  return await service.updateChannel(
    channelId: params.channelId,
    name: params.name,
    description: params.description,
  );
});

/// 채널 삭제 요청
final deleteChannelProvider =
    FutureProvider.autoDispose.family<bool, int>((ref, channelId) async {
  final service = ChannelService();
  return await service.deleteChannel(channelId);
});
