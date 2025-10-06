import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/channel_models.dart';
import '../../../core/models/page_breadcrumb.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../providers/workspace_state_provider.dart';
import 'channel_item.dart';
import 'workspace_header.dart';

/// Channel Navigation Widget
///
/// Displays workspace navigation with:
/// - Top section: Group Home and Calendar buttons
/// - Middle section: Channel list
/// - Bottom section: Admin page button (conditional)
///
/// Features a deferred slide-in animation that begins once the global sidebar has
/// collapsed, creating a seamless hand-off between the two navigation rails.
class ChannelNavigation extends ConsumerStatefulWidget {
  final double width; // 반응형 너비
  final List<Channel> channels;
  final String? selectedChannelId;
  final bool hasAnyGroupPermission;
  final Map<String, int> unreadCounts; // Dummy data
  final bool isVisible;
  final String? currentGroupId; // 현재 선택된 그룹 ID
  final String? currentGroupName; // 현재 선택된 그룹 이름

  const ChannelNavigation({
    super.key,
    required this.width,
    required this.channels,
    this.selectedChannelId,
    required this.hasAnyGroupPermission,
    required this.unreadCounts,
    this.isVisible = true,
    this.currentGroupId,
    this.currentGroupName,
  });

  @override
  ConsumerState<ChannelNavigation> createState() => _ChannelNavigationState();
}

class _ChannelNavigationState extends ConsumerState<ChannelNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _entranceOffset;
  ProviderSubscription<NavigationState>? _navigationSubscription;
  bool _hasPlayedEntrance = false;
  int _entranceRequestId = 0;
  static const Duration _entranceDelay = Duration.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );

    _entranceOffset = Tween<double>(
      begin: -widget.width,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppMotion.easing,
      ),
    );

    // 워크스페이스 진입 시 글로벌 네비게이션 축소와 동시에 등장하도록 대기한다.
    _navigationSubscription = ref.listenManual<NavigationState>(
      navigationControllerProvider,
      _handleNavigationChange,
    );

    final navigationState = ref.read(navigationControllerProvider);
    if (widget.isVisible && navigationState.shouldCollapseSidebar) {
      _scheduleEntrance();
    }
  }

  @override
  void didUpdateWidget(ChannelNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _scheduleEntrance(reset: true);
      } else {
        _animationController.reverse();
        _hasPlayedEntrance = false;
      }
    }
  }

  @override
  void dispose() {
    _navigationSubscription?.close();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceOffset,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_entranceOffset.value, 0),
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: AppColors.lightOutline, width: 1),
          ),
        ),
        child: Column(
          children: [
            // 워크스페이스 헤더 (그룹 드롭다운 포함)
            // Simplicity First: 제목 제거, 그룹명만 표시
            if (widget.currentGroupName != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: WorkspaceHeader(
                  breadcrumb: PageBreadcrumb(
                    title: '', // 제목 없음 (Simplicity First)
                    path: [widget.currentGroupName!], // 그룹명만
                  ),
                  currentGroupId: widget.currentGroupId,
                  channelBarWidth: widget.width, // 반응형 너비 전달
                ),
              ),
            const Divider(height: 1, thickness: 1),
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

  void _handleNavigationChange(NavigationState? previous, NavigationState next) {
    if (!widget.isVisible) {
      return;
    }

    if (next.shouldCollapseSidebar && !_hasPlayedEntrance) {
      _scheduleEntrance();
    }
  }

  void _scheduleEntrance({bool reset = false}) {
    if (_hasPlayedEntrance && !reset) {
      return;
    }

    if (reset) {
      _hasPlayedEntrance = false;
      _animationController.reset();
    }

    // 글로벌 네비게이션 축소와 거의 동시에 진입하도록 짧은 지연을 둔다.
    final int requestId = ++_entranceRequestId;
    Future.delayed(_entranceDelay, () {
      if (!mounted || _hasPlayedEntrance || requestId != _entranceRequestId) {
        return;
      }
      _animationController.forward();
      _hasPlayedEntrance = true;
    });
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 섹션 제목: 그룹 메뉴
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xxs,
              bottom: AppSpacing.xxs,
            ),
            child: Text(
              '그룹 메뉴',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.neutral600,
              ),
            ),
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 섹션 제목: 채널
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              top: AppSpacing.xs,
              bottom: AppSpacing.xxs,
            ),
            child: Text(
              '채널',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.neutral600,
              ),
            ),
          ),
          Expanded(
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
          ),
        ],
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
