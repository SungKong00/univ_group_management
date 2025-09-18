import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WorkspaceDesktopSkeleton extends StatelessWidget {
  const WorkspaceDesktopSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 1024;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          if (!isNarrow) const _LeftSidebar(width: 280),
          if (isNarrow)
            const _CollapsedSidebar(),
          const Expanded(child: _ChannelPage()),
        ],
      ),
    );
  }
}

// Left Sidebar (fixed width)
class _LeftSidebar extends StatelessWidget {
  final double width;
  const _LeftSidebar({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppTheme.border)),
            ),
            child: Text('컴퓨터공학과', style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppTheme.border)),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: const [
                  _SidebarSection(title: 'Calendar', items: [
                    _SidebarItem(icon: Icons.calendar_month, label: '전체 일정'),
                  ]),
                  _SidebarSection(title: 'Projects', items: [
                    _SidebarItem(icon: Icons.folder_copy_outlined, label: '캡스톤 디자인'),
                  ]),
                  _SidebarSection(title: 'Direct Messages', items: [
                    _SidebarItem(icon: Icons.person_outline, label: '김민준'),
                    _SidebarItem(icon: Icons.person_outline, label: '이서연'),
                  ]),
                  _SidebarSection(title: '공식 그룹', items: [
                    _SidebarItem(icon: Icons.verified_outlined, label: '학생회'),
                  ]),
                  _SidebarSection(title: '자율 그룹', items: [
                    _SidebarItem(icon: Icons.groups_2_outlined, label: '알고리즘 스터디'),
                  ]),
                  _SidebarSection(title: '관리자 기능', items: [
                    _SidebarItem(icon: Icons.settings_outlined, label: '멤버 관리'),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedSidebar extends StatelessWidget {
  const _CollapsedSidebar();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: const [
          SizedBox(height: 16),
          Icon(Icons.campaign, size: 20, color: AppTheme.onTextSecondary),
          SizedBox(height: 16),
          Icon(Icons.chat_bubble_outline, size: 20, color: AppTheme.onTextSecondary),
          SizedBox(height: 16),
          Icon(Icons.how_to_vote, size: 20, color: AppTheme.onTextSecondary),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final List<_SidebarItem> items;
  const _SidebarSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(title, style: Theme.of(context).textTheme.labelSmall),
          ),
          ...items,
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SidebarItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.onTextSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Main Area
class _ChannelPage extends StatelessWidget {
  const _ChannelPage();
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 768;
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ChannelHeader(compact: compact)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const _AnnouncementCard(),
                    const SizedBox(height: 16),
                    const _PollCard(),
                    const SizedBox(height: 96), // space for composer
                  ],
                ),
              ),
            ),
          ],
        ),
        const Align(alignment: Alignment.bottomCenter, child: _ComposerBar()),
      ],
    );
  }
}

class _ChannelHeader extends StatelessWidget {
  final bool compact;
  const _ChannelHeader({required this.compact});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    _crumb(context, '컴퓨터공학과'),
                    const Text('›', style: TextStyle(color: AppTheme.onTextSecondary)),
                    _crumb(context, '공지사항'),
                    Text(' #공지사항', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  Text(
                    '중요한 공지사항을 확인하세요',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              _pillButton(context, Icons.group_outlined, '멤버 보기'),
              _pillButton(context, Icons.info_outline, '채널 정보'),
              _pillButton(context, Icons.more_horiz, '더보기'),
            ],
          )
        ],
      ),
    );
  }

  Widget _crumb(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onTextSecondary),
      );

  Widget _pillButton(BuildContext context, IconData icon, String label) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: AppTheme.onTextSecondary),
      label: Text(label, style: Theme.of(context).textTheme.bodySmall),
      style: TextButton.styleFrom(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.onTextSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.border)),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard();
  @override
  Widget build(BuildContext context) {
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(radius: 16, child: Text('김', style: TextStyle(fontSize: 12))),
              const SizedBox(width: 12),
              Text('김민준', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              _chip('학생회장'),
              const Spacer(),
              Text('오전 9:30', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '안녕하세요, 학생회장 김민준입니다.\n9월 15일(금) 오후 2시에 예정된 정기회의 장소가 변경되었습니다.\n변경 전: 2학관 201호 → 변경 후: 학생회관 대회의실\n참석 예정인 분들은 착오 없으시기 바랍니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statusChip('확인 필요', AppTheme.info),
              const SizedBox(width: 8),
              _statusChip('진행중', AppTheme.warn),
            ],
          ),
          const SizedBox(height: 12),
          _progressBar(context, completed: 35, total: 50),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.favorite_border, size: 18, color: AppTheme.onTextSecondary),
              SizedBox(width: 8),
              Icon(Icons.mode_comment_outlined, size: 18, color: AppTheme.onTextSecondary),
              SizedBox(width: 8),
              Icon(Icons.more_horiz, size: 18, color: AppTheme.onTextSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
    );
  }

  Widget _progressBar(BuildContext context, {required int completed, required int total}) {
    final ratio = (completed / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.divider,
            borderRadius: BorderRadius.circular(999),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * ratio,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$completed/$total명 확인',
          style: Theme.of(context).textTheme.labelSmall,
        )
      ],
    );
  }
}

class _PollCard extends StatelessWidget {
  const _PollCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: AppStyles.radius16,
        border: const Border.fromBorderSide(BorderSide(color: AppTheme.border)),
        boxShadow: AppStyles.softShadow,
      ),
      padding: AppStyles.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('동아리 가을 MT 장소 정하기', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _pollOption(context, '강릉', 0.52, 12),
          const SizedBox(height: 8),
          _pollOption(context, '부산', 0.28, 9),
          const SizedBox(height: 8),
          _pollOption(context, '제주도', 0.20, 7),
          const SizedBox(height: 12),
          Row(
            children: [
              _mutedText(context, '👤 28명 참여'),
              const SizedBox(width: 12),
              _mutedText(context, '⏰ 마감: 8월 20일'),
              const Spacer(),
              _disabledButton(context, '투표'),
            ],
          )
        ],
      ),
    );
  }

  Widget _pollOption(BuildContext context, String label, double ratio, int count) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text('${count}표', style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _mutedText(BuildContext context, String text) => Text(text, style: Theme.of(context).textTheme.labelSmall);

  Widget _disabledButton(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onTextSecondary)),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Message to #공지사항',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.insert_chart),
            tooltip: '차트',
            color: AppTheme.onTextSecondary,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.attachment),
            tooltip: '첨부',
            color: AppTheme.onTextSecondary,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.emoji_emotions),
            tooltip: '이모지',
            color: AppTheme.onTextSecondary,
          ),
        ],
      ),
    );
  }
}

