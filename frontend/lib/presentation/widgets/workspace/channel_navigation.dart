import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/channel_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/workspace_state_provider.dart';
import 'channel_item.dart';

/// Channel Navigation Widget
///
/// Displays workspace navigation with:
/// - Top section: Group Home and Calendar buttons
/// - Middle section: Channel list
/// - Bottom section: Admin page button (conditional)
///
/// Features slide animation from left (-256px) to visible.
class ChannelNavigation extends ConsumerStatefulWidget {
  final List<Channel> channels;
  final String? selectedChannelId;
  final bool hasAnyGroupPermission;
  final Map<String, int> unreadCounts; // Dummy data
  final bool isVisible;

  const ChannelNavigation({
    super.key,
    required this.channels,
    this.selectedChannelId,
    required this.hasAnyGroupPermission,
    required this.unreadCounts,
    this.isVisible = true,
  });

  @override
  ConsumerState<ChannelNavigation> createState() => _ChannelNavigationState();
}

class _ChannelNavigationState extends ConsumerState<ChannelNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // Start from left (-256px)
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppMotion.easing,
    ));

    // Start animation when widget is first built
    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ChannelNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: AppConstants.sidebarWidth,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: AppColors.lightOutline, width: 1),
          ),
        ),
        child: Column(
          children: [
            _buildTopSection(),
            const Divider(height: 1, thickness: 1),
            _buildChannelList(),
            if (widget.hasAnyGroupPermission) ...[
              const Divider(height: 1, thickness: 1),
              _buildBottomSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.neutral700),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.lightOnSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        itemCount: widget.channels.length,
        itemBuilder: (context, index) {
          final channel = widget.channels[index];
          final channelId = channel.id.toString();
          final isSelected = widget.selectedChannelId == channelId;
          final unreadCount = widget.unreadCounts[channelId] ?? 0;

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

  Widget _buildBottomSection() {
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, size: 20, color: AppColors.neutral700),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '관리자 페이지',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.lightOnSurface,
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
