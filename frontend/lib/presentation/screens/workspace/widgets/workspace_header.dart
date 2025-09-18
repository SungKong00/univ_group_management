import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../../data/models/workspace_models.dart';

class WorkspaceHeader extends StatelessWidget {
  final WorkspaceDetailModel workspace;
  final ChannelModel? channel;
  final VoidCallback onBack;
  final VoidCallback? onShowMembers;
  final VoidCallback? onShowChannelInfo;
  final VoidCallback? onShowManagement;

  const WorkspaceHeader({
    super.key,
    required this.workspace,
    this.channel,
    required this.onBack,
    this.onShowMembers,
    this.onShowChannelInfo,
    this.onShowManagement,
  });

  @override
  Widget build(BuildContext context) {
    final showingAnnouncements = channel == null;
    final provider = context.read<WorkspaceProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사이드바가 숨겨져 있을 때만 토글 버튼 표시
          if (!provider.isSidebarVisible) ...[
            IconButton(
              onPressed: provider.toggleSidebar,
              icon: const Icon(Icons.menu, color: AppTheme.onTextSecondary),
              tooltip: '사이드바 보기',
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: AppTheme.onTextSecondary),
            tooltip: '뒤로가기',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    _breadcrumbText(context, workspace.group.name),
                    const Text('›', style: TextStyle(color: AppTheme.onTextSecondary)),
                    _breadcrumbText(context, showingAnnouncements ? '공지사항' : channel!.name),
                    if (!showingAnnouncements)
                      Text(
                        ' #${channel!.name}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                if (showingAnnouncements && (workspace.workspace.description?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      workspace.workspace.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onShowMembers != null)
                TextButton.icon(
                  onPressed: onShowMembers,
                  icon: const Icon(Icons.group_outlined, size: 18, color: AppTheme.onTextSecondary),
                  label: const Text('멤버 보기'),
                  style: _pillButtonStyle(),
                ),
              if (onShowChannelInfo != null)
                TextButton.icon(
                  onPressed: channel != null ? onShowChannelInfo : null,
                  icon: const Icon(Icons.info_outline, size: 18, color: AppTheme.onTextSecondary),
                  label: const Text('채널 정보'),
                  style: _pillButtonStyle(),
                ),
              if (onShowManagement != null)
                TextButton.icon(
                  onPressed: onShowManagement,
                  icon: const Icon(Icons.more_horiz, size: 18, color: AppTheme.onTextSecondary),
                  label: const Text('더보기'),
                  style: _pillButtonStyle(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  ButtonStyle _pillButtonStyle() {
    return TextButton.styleFrom(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.onTextSecondary,
      disabledForegroundColor: AppTheme.onTextSecondary.withOpacity(0.4),
      disabledBackgroundColor: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
    );
  }

  Widget _breadcrumbText(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.onTextSecondary,
          ),
    );
  }
}