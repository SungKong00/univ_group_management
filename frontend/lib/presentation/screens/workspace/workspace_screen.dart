import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../widgets/loading_overlay.dart';
import 'components/workspace_empty_state.dart';
import 'layouts/workspace_desktop_layout.dart';
import 'layouts/workspace_mobile_layout.dart';
import '../../../data/models/workspace_models.dart';

class WorkspaceScreen extends StatefulWidget {
  final int groupId;
  final String? groupName;

  const WorkspaceScreen({
    super.key,
    required this.groupId,
    this.groupName,
  });

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  bool _hasInitialized = false;
  double? _previousWidth;
  bool _isHandlingResize = false;
  Timer? _resizeDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeWorkspace();
  }

  @override
  void dispose() {
    _resizeDebounceTimer?.cancel();
    super.dispose();
  }

  void _initializeWorkspace() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final workspaceProvider = context.read<WorkspaceProvider>();
      final channelProvider = context.read<ChannelProvider>();
      final uiStateProvider = context.read<UIStateProvider>();

      workspaceProvider.reset();
      channelProvider.reset();
      uiStateProvider.reset();

      final isDesktop = MediaQuery.of(context).size.width >= 900;

      workspaceProvider
          .loadWorkspace(
        widget.groupId,
        autoSelectFirstChannel: isDesktop,
        mobileNavigatorVisible: !isDesktop,
      )
          .then((_) async {
        if (!mounted) return;

        uiStateProvider.markAsInitialLoadComplete();

        final channels = workspaceProvider.channels;
        final currentChannel = channelProvider.currentChannel;
        final hasCurrentChannel = currentChannel != null &&
            channels.any((channel) => channel.id == currentChannel.id);

        if (isDesktop) {
          if (!hasCurrentChannel && channels.isNotEmpty) {
            await channelProvider.selectChannel(channels.first);
          }
          if (!mounted) return;
          uiStateProvider.setMobileNavigatorVisible(false);
        } else {
          uiStateProvider.showMobileNavigator();
        }

        _hasInitialized = true;
      });
    });
  }

  void _handleScreenSizeChange(double currentWidth,
      WorkspaceProvider workspaceProvider, UIStateProvider uiStateProvider) {
    if (_isHandlingResize) return;

    if (_previousWidth == null) {
      _previousWidth = currentWidth;
      if (kDebugMode) {
        print('[반응형] 초기 화면 너비 설정: ${currentWidth.toInt()}px');
      }
      return;
    }

    final wasDesktop = _previousWidth! >= 900;
    final isNowDesktop = currentWidth >= 900;
    final isNowMobile = !isNowDesktop;

    if (wasDesktop != isNowDesktop) {
      if (kDebugMode) {
        print(
            '[반응형] 화면 전환 감지: ${wasDesktop ? "데스크톱" : "모바일"} → ${isNowDesktop ? "데스크톱" : "모바일"} (${currentWidth.toInt()}px)');
      }

      _resizeDebounceTimer?.cancel();
      _resizeDebounceTimer = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;

        if (_hasInitialized) {
          _isHandlingResize = true;

          try {
            uiStateProvider.handleResponsiveTransition(isNowMobile);
            if (kDebugMode) {
              print(
                  '[반응형] handleResponsiveTransition 호출됨 (디바운싱 후): isNowMobile=$isNowMobile');
            }
          } finally {
            _isHandlingResize = false;
          }
        } else {
          if (kDebugMode) {
            print('[반응형] 초기화 미완료로 인해 전환 스킵');
          }
        }
      });
    }

    _previousWidth = currentWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Consumer3<WorkspaceProvider, ChannelProvider, UIStateProvider>(
          builder: (context, workspaceProvider, channelProvider,
              uiStateProvider, child) {
            final workspace = workspaceProvider.currentWorkspace;
            final currentWidth = constraints.maxWidth;
            final isDesktop = currentWidth >= 900;

            _handleScreenSizeChange(
                currentWidth, workspaceProvider, uiStateProvider);

            Widget body;
            if (workspace == null) {
              body = WorkspaceEmptyState(
                groupId: widget.groupId,
                onBack: () => Navigator.of(context).pop(),
              );
            } else if (isDesktop) {
              body = WorkspaceDesktopLayout(workspace: workspace);
            } else {
              body = WorkspaceMobileLayout(workspace: workspace);
            }

            final scaffold = Scaffold(
              backgroundColor: Theme.of(context).colorScheme.background,
              body: LoadingOverlay(
                isLoading: workspaceProvider.isLoading,
                child: body,
              ),
            );

            if (isDesktop) {
              return scaffold;
            }

            return WillPopScope(
              onWillPop: () async {
                if (uiStateProvider.selectedPostForComments != null) {
                  uiStateProvider.hideCommentsSidebar();
                  return false;
                }
                if (!uiStateProvider.isMobileNavigatorVisible) {
                  uiStateProvider.showMobileNavigator();
                  return false;
                }
                return true;
              },
              child: scaffold,
            );
          },
        );
      },
    );
  }
}

// WorkspaceContent 클래스 - 별도 사용을 위한 독립적인 위젯
class WorkspaceContent extends StatefulWidget {
  final int groupId;
  final String? groupName;
  final VoidCallback? onBack;

  const WorkspaceContent({
    super.key,
    required this.groupId,
    this.groupName,
    this.onBack,
  });

  @override
  State<WorkspaceContent> createState() => _WorkspaceContentState();
}

class _WorkspaceContentState extends State<WorkspaceContent> {
  @override
  void initState() {
    super.initState();
    _initializeWorkspace();
  }

  void _initializeWorkspace() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final workspaceProvider = context.read<WorkspaceProvider>();
      final channelProvider = context.read<ChannelProvider>();
      final uiStateProvider = context.read<UIStateProvider>();

      workspaceProvider.reset();
      channelProvider.reset();
      uiStateProvider.reset();

      final isDesktop = MediaQuery.of(context).size.width >= 900;
      workspaceProvider
          .loadWorkspace(
        widget.groupId,
        autoSelectFirstChannel: isDesktop,
        mobileNavigatorVisible: !isDesktop,
      )
          .then((_) async {
        if (!mounted) return;

        uiStateProvider.markAsInitialLoadComplete();

        final channels = workspaceProvider.channels;
        final currentChannel = channelProvider.currentChannel;
        final hasCurrentChannel = currentChannel != null &&
            channels.any((channel) => channel.id == currentChannel.id);

        if (isDesktop) {
          if (!hasCurrentChannel && channels.isNotEmpty) {
            await channelProvider.selectChannel(channels.first);
          }
          if (!mounted) return;
          uiStateProvider.setMobileNavigatorVisible(false);
        } else {
          uiStateProvider.showMobileNavigator();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<WorkspaceProvider, ChannelProvider, UIStateProvider>(
      builder: (context, workspaceProvider, channelProvider, uiStateProvider,
          child) {
        final workspace = workspaceProvider.currentWorkspace;
        final isDesktop = MediaQuery.of(context).size.width >= 900;

        Widget body;
        if (workspace == null) {
          body = WorkspaceEmptyState(
            groupId: widget.groupId,
            onBack: widget.onBack,
          );
        } else if (isDesktop) {
          body = WorkspaceDesktopLayout(workspace: workspace);
        } else {
          body = WorkspaceMobileLayout(workspace: workspace);
        }

        return LoadingOverlay(
          isLoading: workspaceProvider.isLoading,
          child: body,
        );
      },
    );
  }
}