import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../../data/models/workspace_models.dart';

class WorkspaceHeader extends StatelessWidget {
  final WorkspaceDetailModel workspace;
  final ChannelModel? channel;
  final VoidCallback onBack;
  final VoidCallback? onShowMembers;
  final VoidCallback? onShowChannelInfo;
  final VoidCallback? onShowManagement;
  final double sidebarWidth;

  const WorkspaceHeader({
    super.key,
    required this.workspace,
    this.channel,
    required this.onBack,
    this.onShowMembers,
    this.onShowChannelInfo,
    this.onShowManagement,
    this.sidebarWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    const double backButtonWidth = 36;
    const double gapBetweenBackAndDropdown = 8;
    const double horizontalPadding = 16;
    final double availableWidth = sidebarWidth - horizontalPadding;
    final double dropdownWidth =
        (availableWidth - backButtonWidth - gapBetweenBackAndDropdown)
            .clamp(0.0, availableWidth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 뒤로가기 버튼 (최우선 배치) - 크기 축소
          IconButton(
            key: const Key('workspace_header_back_button'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back,
                color: AppTheme.onTextSecondary, size: 20),
            tooltip: '',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 8),
          // 그룹명 드롭다운 (사이드바 폭에 맞춘 너비 유지)
          SizedBox(
            width: dropdownWidth,
            child: _buildGroupDropdown(context),
          ),
          // 여백
          const Spacer(),
          // 우측 버튼들
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (onShowMembers != null)
                TextButton.icon(
                  onPressed: onShowMembers,
                  icon: const Icon(Icons.group_outlined,
                      size: 16, color: AppTheme.onTextSecondary),
                  label: const Text('멤버 보기'),
                  style: _pillButtonStyle(context),
                ),
              if (onShowChannelInfo != null)
                TextButton.icon(
                  onPressed: channel != null ? onShowChannelInfo : null,
                  icon: const Icon(Icons.info_outline,
                      size: 16, color: AppTheme.onTextSecondary),
                  label: const Text('채널 정보'),
                  style: _pillButtonStyle(context),
                ),
              if (onShowManagement != null)
                TextButton.icon(
                  onPressed: onShowManagement,
                  icon: const Icon(Icons.more_horiz,
                      size: 16, color: AppTheme.onTextSecondary),
                  label: const Text('더보기'),
                  style: _pillButtonStyle(context),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupDropdown(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          _showGroupSelectionBottomSheet(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              // 그룹 아이콘
              Icon(
                Icons.groups,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              // 그룹명
              Expanded(
                child: Text(
                  workspace.group.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              // 드롭다운 화살표
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppTheme.onTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '그룹 선택',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '현재: ${workspace.group.name}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '그룹 이동 기능은 곧 추가될 예정입니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onTextSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _pillButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.onTextSecondary,
      disabledForegroundColor: AppTheme.onTextSecondary.withOpacity(0.4),
      disabledBackgroundColor: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      minimumSize: const Size(0, 30),
      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.border),
      ),
    );
  }
}
