import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/channel_models.dart';
import '../../../../core/models/auth_models.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/snack_bar_helper.dart';
import '../../../providers/my_groups_provider.dart';
import '../../../providers/workspace_state_provider.dart';
import '../../../widgets/dialogs/create_channel_dialog.dart';
import '../../../widgets/dialogs/channel_permissions_dialog.dart';
import '../../../widgets/common/state_view.dart';
import '../providers/channel_management_provider.dart';

/// 채널 목록 섹션
///
/// 그룹의 채널 목록을 표시하고 관리하는 위젯
class ChannelListSection extends ConsumerWidget {
  final int groupId;
  final bool isDesktop;

  const ChannelListSection({
    super.key,
    required this.groupId,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelListProvider(groupId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 + 새 채널 추가 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '채널 목록',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral900,
                  ),
            ),
            Flexible(
              child: ElevatedButton.icon(
                onPressed: () => _handleCreateChannel(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('새 채널 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? AppSpacing.md : AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        // 채널 목록
        StateView<List<Channel>>(
          value: channelsAsync,
          emptyChecker: (channels) => channels.isEmpty,
          emptyIcon: Icons.tag,
          emptyTitle: '채널이 없습니다',
          emptyDescription: '새 채널을 추가하여 시작하세요',
          builder: (context, channels) => _buildChannelList(channels),
        ),
      ],
    );
  }

  Widget _buildChannelList(List<Channel> channels) {
    return Builder(
      builder: (context) {
        return Column(
          children: channels.map((channel) {
            return _buildChannelCard(context, channel);
          }).toList(),
        );
      },
    );
  }

  Widget _buildChannelCard(BuildContext context, Channel channel) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _handleChannelTap(context, channel),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 채널 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.tag,
                  color: AppColors.brand,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // 채널 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            channel.name,
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: channel.type == 'ANNOUNCEMENT'
                                ? AppColors.warning.withValues(alpha: 0.1)
                                : AppColors.neutral200,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            channel.type == 'ANNOUNCEMENT' ? '공지' : '일반',
                            style: AppTheme.bodySmall.copyWith(
                              color: channel.type == 'ANNOUNCEMENT'
                                  ? AppColors.warning
                                  : AppColors.neutral700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (channel.description != null &&
                        channel.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        channel.description!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.neutral600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // 권한 설정 버튼
              IconButton(
                icon: const Icon(Icons.settings, size: 20),
                onPressed: () => _handleChannelSettings(context, channel),
                tooltip: '채널 권한 설정',
                color: AppColors.neutral600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleChannelTap(BuildContext context, Channel channel) {
    // 채널 상세 보기 또는 다른 동작
    // 현재는 권한 설정으로 이동
    _handleChannelSettings(context, channel);
  }

  Future<void> _handleChannelSettings(BuildContext context, Channel channel) async {
    // 권한 설정 다이얼로그 표시
    final result = await showChannelPermissionsDialog(
      context,
      channelId: channel.id,
      channelName: channel.name,
      groupId: groupId,
      isRequired: false,
    );

    if (result && context.mounted) {
      AppSnackBar.info(context, '채널 "${channel.name}" 권한이 업데이트되었습니다');
    }
  }

  Future<void> _handleCreateChannel(BuildContext context, WidgetRef ref) async {
    try {
      // 워크스페이스 ID 조회
      final dioClient = DioClient();
      final response = await dioClient.get<Map<String, dynamic>>(
        '/groups/$groupId/workspaces',
      );

      if (response.data == null || !context.mounted) return;

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (json) {
          if (json is List && json.isNotEmpty) {
            final workspace = json.first as Map<String, dynamic>;
            return workspace['id'] as int;
          }
          return null;
        },
      );

      if (!apiResponse.success || apiResponse.data == null) {
        if (context.mounted) {
          AppSnackBar.error(context, '워크스페이스를 찾을 수 없습니다');
        }
        return;
      }

      final workspaceId = apiResponse.data!;

      // 채널 생성 다이얼로그
      if (!context.mounted) return;
      final channel = await showCreateChannelDialog(
        context,
        workspaceId: workspaceId,
        groupId: groupId,
      );

      if (channel != null) {
        // 권한 설정 다이얼로그
        if (!context.mounted) return;
        final permissionsSet = await showChannelPermissionsDialog(
          context,
          channelId: channel.id,
          channelName: channel.name,
          groupId: groupId,
          isRequired: true,
        );

        if (permissionsSet) {
          // 채널 목록 새로고침
          ref.invalidate(channelListProvider(groupId));

          // workspace state도 새로고침
          ref.read(workspaceStateProvider.notifier).loadChannels(
            groupId.toString(),
            membership: (await ref.read(myGroupsProvider.future))
                .firstWhere((g) => g.id == groupId),
          );

          // 성공 메시지
          if (context.mounted) {
            AppSnackBar.success(
              context,
              '채널 "${channel.name}"이(가) 생성되고 권한이 설정되었습니다',
              duration: const Duration(seconds: 3),
            );
          }
        } else {
          // 권한 설정 취소
          if (context.mounted) {
            AppSnackBar.warning(
              context,
              '채널 "${channel.name}"이(가) 생성되었으나 권한 설정이 필요합니다',
              duration: const Duration(seconds: 3),
            );
          }
          // 목록 새로고침
          ref.invalidate(channelListProvider(groupId));
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, '오류가 발생했습니다: $e');
      }
    }
  }
}
