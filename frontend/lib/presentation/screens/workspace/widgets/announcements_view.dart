import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_button.dart';
import '../../../../data/models/workspace_models.dart';

class AnnouncementsView extends StatelessWidget {
  final WorkspaceDetailModel workspace;
  final List<PostModel> announcements;
  final VoidCallback? onCreateAnnouncement;

  const AnnouncementsView({
    super.key,
    required this.workspace,
    required this.announcements,
    this.onCreateAnnouncement,
  });

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      children: [
        if (workspace.canCreateAnnouncements && onCreateAnnouncement != null)
          Align(
            alignment: Alignment.centerLeft,
            child: CommonButton(
              text: '공지사항 작성',
              icon: Icons.add,
              onPressed: onCreateAnnouncement!,
            ),
          ),
        if (workspace.canCreateAnnouncements) const SizedBox(height: 24),
        ...announcements.map(
          (announcement) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAnnouncementCard(context, announcement),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign_outlined, size: 64, color: AppTheme.onTextSecondary),
            const SizedBox(height: 16),
            Text(
              '아직 공지사항이 없습니다',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 공지사항을 작성해보세요',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (workspace.canCreateAnnouncements && onCreateAnnouncement != null) ...[
              const SizedBox(height: 24),
              CommonButton(
                text: '공지사항 작성',
                icon: Icons.add,
                onPressed: onCreateAnnouncement!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, PostModel announcement) {
    final textTheme = Theme.of(context).textTheme;
    final author = announcement.author;

    return InkWell(
      onTap: () => _showAnnouncementDetail(context, announcement),
      borderRadius: AppStyles.radius16,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: AppStyles.radius16,
          border: const Border.fromBorderSide(BorderSide(color: AppTheme.border)),
          boxShadow: AppStyles.softShadow,
        ),
        padding: AppStyles.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(author.name.isNotEmpty ? author.name[0] : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.name,
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatRelativeTime(announcement.createdAt),
                        style: textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                if (announcement.isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.push_pin, size: 12, color: AppTheme.primary),
                        SizedBox(width: 4),
                        Text(
                          '고정',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (announcement.title.isNotEmpty) ...[
              Text(
                announcement.title,
                style: textTheme.titleLarge?.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              announcement.content,
              style: textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (announcement.likeCount > 0) ...[
                  const Icon(Icons.favorite_border, size: 18, color: AppTheme.onTextSecondary),
                  const SizedBox(width: 4),
                  Text('${announcement.likeCount}', style: textTheme.labelSmall),
                  const SizedBox(width: 12),
                ],
                const Icon(Icons.mode_comment_outlined, size: 18, color: AppTheme.onTextSecondary),
                const SizedBox(width: 4),
                Text('댓글 보기', style: textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays >= 7) {
      return '${time.month}/${time.day}';
    }
    if (diff.inDays >= 1) {
      return '${diff.inDays}일 전';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours}시간 전';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}분 전';
    }
    return '방금 전';
  }

  void _showAnnouncementDetail(BuildContext context, PostModel announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (announcement.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 12, color: Theme.of(context).colorScheme.onPrimary),
                          const SizedBox(width: 4),
                          Text(
                            '고정 공지',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text(
                    _formatDateTime(announcement.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                announcement.title.isNotEmpty ? announcement.title : '공지',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text(announcement.author.name.isNotEmpty ? announcement.author.name[0] : '?'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    announcement.author.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    announcement.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final datePart = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final timePart = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$datePart $timePart';
  }
}

// AppStyles 클래스가 없다면 임시로 정의
class AppStyles {
  static const radius16 = BorderRadius.all(Radius.circular(16));
  static const cardPadding = EdgeInsets.all(16);
  static const softShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}