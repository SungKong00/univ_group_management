import 'package:flutter/material.dart';
import '../../../core/utils/snack_bar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/channel_models.dart';
import '../../../core/models/page_breadcrumb.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/navigation/navigation_controller.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../providers/workspace_state_provider.dart';
import '../dialogs/create_channel_dialog.dart';
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

    _entranceOffset = Tween<double>(begin: -widget.width, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: AppMotion.easing),
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
            if (widget.hasAnyGroupPermission) ...[_buildBottomSection()],
          ],
        ),
      ),
    );
  }

  void _handleNavigationChange(
    NavigationState? previous,
    NavigationState next,
  ) {
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
    return Consumer(
      builder: (context, ref, child) {
        final currentView = ref.watch(workspaceCurrentViewProvider);

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
                isSelected: currentView == WorkspaceView.groupHome,
              ),
              const SizedBox(height: AppSpacing.xxs),
              _buildTopButton(
                icon: Icons.calendar_today_outlined,
                label: '캘린더',
                onTap: () {
                  ref.read(workspaceStateProvider.notifier).showCalendar();
                },
                isSelected: currentView == WorkspaceView.calendar,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected ? AppColors.actionTonalBg : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.action : AppColors.neutral700,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.action
                      : AppColors.lightOnSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelList() {
    return Consumer(
      builder: (context, ref, child) {
        final currentView = ref.watch(workspaceCurrentViewProvider);
        final selectedChannelId = ref.watch(currentChannelIdProvider);
        // Read unread count map from workspace state (real API data, Phase 5)
        final unreadCountMap = ref.watch(
          workspaceStateProvider.select((state) => state.unreadCountMap),
        );

        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 섹션 제목: 채널 + 톱니바퀴 버튼
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.sm,
                  right: AppSpacing.xs,
                  top: AppSpacing.xs,
                  bottom: AppSpacing.xxs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '채널',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral600,
                      ),
                    ),
                    if (widget.hasAnyGroupPermission)
                      _buildChannelManageButton(),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  itemCount: widget.channels.length,
                  itemBuilder: (context, index) {
                    final channel = widget.channels[index];
                    final channelId = channel.id.toString();
                    final isChannelView = currentView == WorkspaceView.channel;
                    final isSelected =
                        isChannelView && selectedChannelId == channelId;
                    // Use real unread count from API (Phase 5)
                    final unreadCount = unreadCountMap[channel.id] ?? 0;

                    return ChannelItem(
                      channel: channel,
                      isSelected: isSelected,
                      unreadCount: unreadCount,
                      onTap: () {
                        ref
                            .read(workspaceStateProvider.notifier)
                            .showChannel(channelId);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSection() {
    return Consumer(
      builder: (context, ref, child) {
        final currentView = ref.watch(workspaceCurrentViewProvider);

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: _buildTopButton(
            icon: Icons.settings_outlined,
            label: '관리자 페이지',
            onTap: () {
              ref.read(workspaceStateProvider.notifier).showGroupAdminPage();
            },
            isSelected: currentView == WorkspaceView.groupAdmin ||
                currentView == WorkspaceView.memberManagement ||
                currentView == WorkspaceView.recruitmentManagement,
          ),
        );
      },
    );
  }

  Widget _buildChannelManageButton() {
    return Consumer(
      builder: (context, ref, child) {
        return IconButton(
          icon: const Icon(Icons.settings, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          tooltip: '채널 관리',
          color: AppColors.neutral600,
          onPressed: () async {
            // 현재 그룹 ID 가져오기
            final groupIdStr = widget.currentGroupId;
            if (groupIdStr == null) return;

            final groupId = int.tryParse(groupIdStr);
            if (groupId == null) return;

            // 워크스페이스 ID 조회
            try {
              final dioClient = DioClient();
              final response = await dioClient.get<Map<String, dynamic>>(
                '/groups/$groupId/workspaces',
              );

              if (response.data == null) return;

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
                  AppSnackBar.info(context, '워크스페이스를 찾을 수 없습니다');
                }
                return;
              }

              final workspaceId = apiResponse.data!;

              // 채널 생성 다이얼로그 표시 (권한 설정 통합)
              if (!context.mounted) return;
              final channel = await showCreateChannelDialog(
                context,
                workspaceId: workspaceId,
                groupId: groupId,
              );

              if (channel != null) {
                // 채널 + 권한이 이미 생성됨 (CreateChannelDialog에서 처리)
                // 채널 목록 새로고침 (Provider 무효화)
                if (!context.mounted) return;
                ref.invalidate(workspaceChannelsProvider);

                // 새로 생성된 채널로 네비게이션
                ref
                    .read(workspaceStateProvider.notifier)
                    .showChannel(channel.id.toString());

                // 성공 메시지 표시
                if (context.mounted) {
                  AppSnackBar.success(
                    context,
                    '채널 "${channel.name}"이(가) 생성되고 권한이 설정되었습니다',
                    duration: const Duration(seconds: 3),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                AppSnackBar.info(context, '오류가 발생했습니다: $e');
              }
            }
          },
        );
      },
    );
  }
}
