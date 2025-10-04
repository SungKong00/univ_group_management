import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/channel_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../providers/workspace_state_provider.dart';
import 'channel_item.dart';

/// Mobile Channel List Widget
///
/// Displays full-screen channel navigation optimized for mobile devices:
/// - Top section: Group name header
/// - Middle section: Group Home and Calendar buttons
/// - Main section: Channel list (ListView)
/// - Bottom section: Admin page button (conditional)
///
/// Design System Compliance:
/// - 4pt grid system for spacing
/// - Full-width layout (width: double.infinity)
/// - Touch-optimized target sizes (min 44px height)
class MobileChannelList extends ConsumerWidget {
  final List<Channel> channels;
  final String? selectedChannelId;
  final bool hasAnyGroupPermission;
  final Map<String, int> unreadCounts;
  final String? currentGroupId;
  final String? currentGroupName;

  const MobileChannelList({
    super.key,
    required this.channels,
    this.selectedChannelId,
    required this.hasAnyGroupPermission,
    required this.unreadCounts,
    this.currentGroupId,
    this.currentGroupName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, thickness: 1),
          _buildTopSection(ref),
          const Divider(height: 1, thickness: 1),
          _buildChannelList(ref),
          if (hasAnyGroupPermission) ...[
            const Divider(height: 1, thickness: 1),
            _buildBottomSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentGroupName != null) ...[
            Text(
              currentGroupName!,
              style: AppTheme.headlineMedium.copyWith(
                color: AppColors.neutral900,
              ),
            ),
          ] else ...[
            Text(
              '그룹 선택',
              style: AppTheme.headlineMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopSection(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopButton(
            icon: Icons.home_outlined,
            label: '그룹 홈',
            onTap: () {
              ref.read(workspaceStateProvider.notifier).showGroupHome();
            },
          ),
          const SizedBox(height: AppSpacing.xxs),
          _buildTopButton(
            icon: Icons.calendar_today_outlined,
            label: '캘린더',
            onTap: () {
              ref.read(workspaceStateProvider.notifier).showCalendar();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          // Touch-optimized height (min 44px)
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: AppColors.neutral700),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelList(WidgetRef ref) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          final channelId = channel.id.toString();
          final isSelected = selectedChannelId == channelId;
          final unreadCount = unreadCounts[channelId] ?? 0;

          return ChannelItem(
            channel: channel,
            isSelected: isSelected,
            unreadCount: unreadCount,
            onTap: () {
              ref.read(workspaceStateProvider.notifier).showChannel(channelId);
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to admin page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('관리자 페이지 (준비 중)')),
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            // Touch-optimized height (min 44px)
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.settings_outlined,
                  size: 24,
                  color: AppColors.neutral700,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '관리자 페이지',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
