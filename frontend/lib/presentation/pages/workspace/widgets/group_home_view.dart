import 'package:flutter/material.dart';
import '../../../../core/utils/snack_bar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../providers/my_groups_provider.dart';
import '../../../providers/workspace_state_provider.dart';
import '../../../providers/group_calendar_provider.dart';
import '../../../widgets/dialogs/create_subgroup_dialog.dart';
import '../../../widgets/common/section_card.dart';
import '../../../widgets/calendar/compact_month_calendar.dart';

/// 그룹 홈 페이지
///
/// 왼쪽: 읽지 않은 글 개수 + 리스트
/// 오른쪽: 작은 달력 + 일정표
/// 하단: 하위 그룹 생성 버튼 (권한 기반)
class GroupHomeView extends ConsumerWidget {
  const GroupHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAnyGroupPermission = ref.watch(
      workspaceHasAnyGroupPermissionProvider,
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return Container(
            color: AppColors.lightBackground,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: isWide
                  ? _buildWideLayout(context, hasAnyGroupPermission, ref)
                  : _buildNarrowLayout(context, hasAnyGroupPermission, ref),
            ),
          );
        },
      ),
    );
  }

  /// Wide Layout (Desktop): 2-column layout
  Widget _buildWideLayout(BuildContext context, bool hasAnyGroupPermission, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with button
        _buildHeader(context, hasAnyGroupPermission, ref),
        SizedBox(height: AppSpacing.md),

        // Two-column layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Unread posts
            Expanded(
              flex: 2,
              child: _buildUnreadPostsSection(context),
            ),
            SizedBox(width: AppSpacing.md),

            // Right: Calendar + Schedule
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildCalendarWidget(context, ref),
                  SizedBox(height: AppSpacing.md),
                  _buildScheduleWidget(context),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Narrow Layout (Mobile/Tablet): Single column layout
  Widget _buildNarrowLayout(BuildContext context, bool hasAnyGroupPermission, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with button
        _buildHeader(context, hasAnyGroupPermission, ref),
        SizedBox(height: AppSpacing.md),

        // Unread posts
        _buildUnreadPostsSection(context),
        SizedBox(height: AppSpacing.md),

        // Calendar
        _buildCalendarWidget(context, ref),
        SizedBox(height: AppSpacing.md),

        // Schedule
        _buildScheduleWidget(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool hasAnyGroupPermission, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 좁은 화면(< 600px)에서는 버튼을 아래로 배치
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          // 좁은 화면: 세로 배치
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '그룹 홈',
                    style: AppTheme.displaySmall.copyWith(
                      color: AppColors.lightOnSurface,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    '그룹의 주요 정보와 최근 활동을 한눈에 확인하세요',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
              // Button with Description (if has permission)
              if (hasAnyGroupPermission) ...[
                SizedBox(height: AppSpacing.sm),
                _buildCreateSubgroupSection(context, ref),
              ],
            ],
          );
        }

        // 넓은 화면: 가로 배치
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '그룹 홈',
                    style: AppTheme.displaySmall.copyWith(
                      color: AppColors.lightOnSurface,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    '그룹의 주요 정보와 최근 활동을 한눈에 확인하세요',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            // Button with Description (if has permission)
            if (hasAnyGroupPermission) ...[
              SizedBox(width: AppSpacing.md),
              _buildCreateSubgroupSection(context, ref),
            ],
          ],
        );
      },
    );
  }

  /// 하위 그룹 만들기 버튼 + 설명 (Title + Description 패턴)
  Widget _buildCreateSubgroupSection(BuildContext context, WidgetRef ref) {
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Button (Title)
          OutlinedButton.icon(
            onPressed: () async {
              final workspaceState = ref.read(workspaceStateProvider);
              final selectedGroupId = workspaceState.selectedGroupId;

              if (selectedGroupId == null) {
                AppSnackBar.info(context, '그룹 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.');
                return;
              }

              // Get group details from myGroupsProvider
              final myGroupsAsync = ref.read(myGroupsProvider);
              final myGroups = myGroupsAsync.value;

              if (myGroups == null) {
                AppSnackBar.info(context, '그룹 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.');
                return;
              }

              final selectedGroup = myGroups.firstWhere(
                (group) => group.id.toString() == selectedGroupId,
                orElse: () => throw Exception('선택된 그룹을 찾을 수 없습니다.'),
              );

              showCreateSubgroupDialog(
                context,
                groupId: selectedGroup.id,
                parentGroupName: selectedGroup.name,
              );
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('하위 그룹 만들기'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
            ),
          ),
          SizedBox(height: 4),
          // Description
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.xxs),
            child: Text(
              '이 그룹의 하위 조직을 만들어 보세요',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadPostsSection(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 20,
                color: AppColors.brand,
              ),
              SizedBox(width: AppSpacing.xxs),
              Text(
                '읽지 않은 글',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppColors.lightOnSurface,
                ),
              ),
              SizedBox(width: AppSpacing.xxs),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandContainerLight,
                  borderRadius: BorderRadius.circular(100.0),
                ),
                child: Text(
                  '3',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // Unread post list (skeleton)
          _buildPostItem(
            icon: Icons.article_outlined,
            title: '새로운 공지사항: 2025년 정기 총회 안내',
            channel: '공지사항',
            time: '2시간 전',
          ),
          Divider(height: AppSpacing.sm),
          _buildPostItem(
            icon: Icons.forum_outlined,
            title: '프로젝트 회의 결과 공유',
            channel: '일반',
            time: '5시간 전',
          ),
          Divider(height: AppSpacing.sm),
          _buildPostItem(
            icon: Icons.event_outlined,
            title: '다음 주 정기 모임 일정 투표',
            channel: '행사',
            time: '1일 전',
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem({
    required IconData icon,
    required String title,
    required String channel,
    required String time,
  }) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to post detail
      },
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.brand,
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.lightOnSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        channel,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.neutral400,
                        ),
                      ),
                      Text(
                        time,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarWidget(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceStateProvider);
    final selectedGroupId = workspaceState.selectedGroupId;

    // Parse groupId
    final groupId = selectedGroupId != null ? int.tryParse(selectedGroupId) : null;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: AppColors.action,
              ),
              SizedBox(width: AppSpacing.xxs),
              Text(
                '달력',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppColors.lightOnSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // Calendar content
          Container(
            height: 300, // Increased from 280px to accommodate compact calendar
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(
                color: AppColors.lightOutline,
              ),
            ),
            child: groupId != null
                ? _GroupCalendarWidget(groupId: groupId)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: AppColors.neutral400,
                        ),
                        SizedBox(height: AppSpacing.xxs),
                        Text(
                          '그룹을 선택해주세요',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleWidget(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.event_note_outlined,
                size: 20,
                color: AppColors.success,
              ),
              SizedBox(width: AppSpacing.xxs),
              Text(
                '일정',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppColors.lightOnSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // Schedule items (skeleton)
          _buildScheduleItem(
            date: '10/15',
            day: '화',
            title: '프로젝트 중간 발표',
            time: '14:00',
          ),
          Divider(height: AppSpacing.sm),
          _buildScheduleItem(
            date: '10/18',
            day: '금',
            title: '정기 모임',
            time: '18:00',
          ),
          Divider(height: AppSpacing.sm),
          _buildScheduleItem(
            date: '10/22',
            day: '화',
            title: '워크샵',
            time: '10:00',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required String date,
    required String day,
    required String title,
    required String time,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.actionTonalBg,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.action,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  day,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.action,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.xs),

          // Event info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.lightOnSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  time,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal widget for displaying group calendar in compact view
class _GroupCalendarWidget extends ConsumerStatefulWidget {
  final int groupId;

  const _GroupCalendarWidget({required this.groupId});

  @override
  ConsumerState<_GroupCalendarWidget> createState() =>
      _GroupCalendarWidgetState();
}

class _GroupCalendarWidgetState extends ConsumerState<_GroupCalendarWidget> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  @override
  void didUpdateWidget(_GroupCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      // Group changed, reload events
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    final startOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final endOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);

    await ref.read(groupCalendarProvider(widget.groupId).notifier).loadEvents(
          groupId: widget.groupId,
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(groupCalendarProvider(widget.groupId));

    // 🔍 DEBUG: Print event data pipeline
    print('🔍 [GroupCalendar Debug] GroupId: ${widget.groupId}');
    print('🔍 [GroupCalendar Debug] Total events count: ${calendarState.events.length}');
    print('🔍 [GroupCalendar Debug] Focused month: ${_focusedDate.year}-${_focusedDate.month}');

    // Build event colors map from events
    final eventColorsByDate = <DateTime, List<Color>>{};
    for (final event in calendarState.events) {
      final normalizedStart = _normalizeDate(event.startDate);
      final normalizedEnd = _normalizeDate(event.endDate);

      // 🔍 DEBUG: Print each event details
      print('🔍 [Event] "${event.title}" | Start: $normalizedStart | End: $normalizedEnd | Color: ${event.color}');

      // Add event color to all dates it spans
      var currentDate = normalizedStart;
      while (currentDate.isBefore(normalizedEnd) ||
          currentDate.isAtSameMomentAs(normalizedEnd)) {
        eventColorsByDate.putIfAbsent(currentDate, () => []).add(event.color);
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    // 🔍 DEBUG: Print final eventColorsByDate map
    print('🔍 [GroupCalendar Debug] Event colors by date count: ${eventColorsByDate.length}');
    eventColorsByDate.forEach((date, colors) {
      print('🔍 [Date] $date has ${colors.length} event(s) with colors: $colors');
    });

    if (calendarState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (calendarState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              '일정을 불러오지 못했습니다',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      );
    }

    // Use CompactMonthCalendar widget
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: CompactMonthCalendar(
        focusedDate: _focusedDate,
        selectedDate: _selectedDate,
        eventColorsByDate: eventColorsByDate,
        onPageChanged: (newFocusedDate) {
          setState(() {
            _focusedDate = newFocusedDate;
          });
          _loadEvents();
        },
        onEventDateTap: (date) {
          // Navigate to group calendar page with the selected date
          _navigateToGroupCalendar(date);
        },
        onCalendarTap: () {
          // Navigate to group calendar page (full view)
          _navigateToGroupCalendar(null);
        },
      ),
    );
  }

  void _navigateToGroupCalendar(DateTime? date) {
    // Navigate to workspace calendar view using WorkspaceStateNotifier
    // Pass the selected date to focus on that specific date in the calendar
    ref.read(workspaceStateProvider.notifier).showCalendar(selectedDate: date);
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
