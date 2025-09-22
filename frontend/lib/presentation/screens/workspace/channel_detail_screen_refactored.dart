import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../../data/models/workspace_models.dart';
import '../../widgets/loading_overlay.dart';

import 'components/channel_app_bar/channel_app_bar_title.dart';
import 'components/channel_app_bar/channel_app_bar_actions.dart';
import 'layouts/channel_layouts.dart';

class ChannelDetailScreen extends StatelessWidget {
  final ChannelModel channel;

  const ChannelDetailScreen({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<WorkspaceProvider, ChannelProvider, UIStateProvider>(
      builder: (context, workspaceProvider, channelProvider, uiStateProvider,
          child) {
        final isCommentView = uiStateProvider.selectedPostForComments != null;
        final isDesktop =
            MediaQuery.of(context).size.width >= ResponsiveBreakpoints.mobile;

        return Scaffold(
          appBar: AppBar(
            leading: !isDesktop && isCommentView
                ? IconButton(
                    key: const Key('comment_back_button'),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '',
                    onPressed: () => uiStateProvider.hideCommentsSidebar(),
                  )
                : null,
            title: isCommentView
                ? const CommentsAppBarTitle()
                : ChannelAppBarTitle(channel: channel),
            actions: isCommentView
                ? null
                : [ChannelAppBarActions(channel: channel)],
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 1,
          ),
          body: ChannelDetailView(
            channel: channel,
            autoLoad: true,
            showLoadingOverlay: true,
          ),
        );
      },
    );
  }
}

class ChannelDetailView extends StatefulWidget {
  final ChannelModel channel;
  final bool autoLoad;
  final EdgeInsets contentPadding;
  final bool showLoadingOverlay;
  final bool forceMobileLayout;

  const ChannelDetailView({
    super.key,
    required this.channel,
    this.autoLoad = false,
    this.contentPadding = const EdgeInsets.all(16),
    this.showLoadingOverlay = false,
    this.forceMobileLayout = false,
  });

  @override
  State<ChannelDetailView> createState() => _ChannelDetailViewState();
}

class _ChannelDetailViewState extends State<ChannelDetailView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChannelProvider>().selectChannel(widget.channel);
      });
    }
  }

  @override
  void didUpdateWidget(covariant ChannelDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoLoad && widget.channel.id != oldWidget.channel.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChannelProvider>().selectChannel(widget.channel);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<WorkspaceProvider, ChannelProvider, UIStateProvider>(
      builder: (context, workspaceProvider, channelProvider, uiStateProvider,
          child) {
        final posts = channelProvider.currentChannelPosts;
        final isCommentView = uiStateProvider.selectedPostForComments != null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktopPlatform = kIsWeb ||
                defaultTargetPlatform == TargetPlatform.macOS ||
                defaultTargetPlatform == TargetPlatform.windows ||
                defaultTargetPlatform == TargetPlatform.linux ||
                defaultTargetPlatform == TargetPlatform.fuchsia;

            final bool isCommentsSidebarVisible =
                uiStateProvider.isCommentsSidebarVisible;
            final double effectiveBreakpoint = isCommentsSidebarVisible
                ? ResponsiveBreakpoints.mobile - 200
                : ResponsiveBreakpoints.mobile;

            final bool isDesktop = isDesktopPlatform &&
                !widget.forceMobileLayout &&
                constraints.maxWidth >= effectiveBreakpoint;

            if (isDesktop) {
              return ChannelDesktopLayout(
                channel: widget.channel,
                posts: posts,
                workspaceProvider: workspaceProvider,
                channelProvider: channelProvider,
                uiStateProvider: uiStateProvider,
                scrollController: _scrollController,
                contentPadding: widget.contentPadding,
                showLoadingOverlay: widget.showLoadingOverlay,
              );
            }

            if (isCommentView) {
              return ChannelMobileCommentLayout(
                channel: widget.channel,
                workspaceProvider: workspaceProvider,
                channelProvider: channelProvider,
                uiStateProvider: uiStateProvider,
                scrollController: _scrollController,
                showLoadingOverlay: widget.showLoadingOverlay,
              );
            } else {
              return ChannelMobilePostLayout(
                channel: widget.channel,
                posts: posts,
                workspaceProvider: workspaceProvider,
                channelProvider: channelProvider,
                uiStateProvider: uiStateProvider,
                scrollController: _scrollController,
                contentPadding: widget.contentPadding,
                showLoadingOverlay: widget.showLoadingOverlay,
              );
            }
          },
        );
      },
    );
  }
}