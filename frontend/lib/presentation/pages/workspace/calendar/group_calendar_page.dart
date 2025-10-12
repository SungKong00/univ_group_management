import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/calendar/group_event.dart';
import '../../../../core/models/calendar/update_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/group_calendar_provider.dart';
import '../../../providers/group_permission_provider.dart';
import 'widgets/group_event_form_dialog.dart';

/// Main page for group calendar.
class GroupCalendarPage extends ConsumerStatefulWidget {
  final int groupId;

  const GroupCalendarPage({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupCalendarPage> createState() => _GroupCalendarPageState();
}

class _GroupCalendarPageState extends ConsumerState<GroupCalendarPage>
    with SingleTickerProviderStateMixin {
  final DateTime _focusedDate = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.brand,
        unselectedLabelColor: AppColors.neutral600,
        indicatorColor: AppColors.brand,
        indicatorWeight: 2,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: '그룹 캘린더'),
          Tab(text: '장소 캘린더'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildGroupCalendarTab(),
        _buildPlaceCalendarTab(),
      ],
    );
  }

  Widget _buildGroupCalendarTab() {
    final state = ref.watch(groupCalendarProvider(widget.groupId));

    return Stack(
      children: [
        Builder(
          builder: (context) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error.withOpacity(0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '오류가 발생했습니다',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: _loadEvents,
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }

            if (state.events.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 64,
                      color: AppColors.neutral400,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '등록된 일정이 없습니다',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '+ 버튼을 눌러 첫 일정을 추가해보세요',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral600,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.events.length,
              itemBuilder: (context, index) {
                final event = state.events[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                        color: event.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(event.title)),
                        if (event.isOfficial)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '공식',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        if (event.isRecurring)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.repeat,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          _formatDateRange(event.startDate, event.endDate, event.isAllDay),
                        ),
                        if (event.location != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.place, size: 14),
                              const SizedBox(width: 4),
                              Text(event.location!),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showEventActions(event),
                    ),
                    onTap: () => _showEventDetail(event),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _showCreateDialog,
            tooltip: '일정 추가',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCalendarTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.place,
            size: 64,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '장소 캘린더',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '준비 중입니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral600,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end, bool isAllDay) {
    final dateFormat = 'yyyy-MM-dd';
    final timeFormat = 'HH:mm';

    if (isAllDay) {
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        return '$dateFormat (종일)';
      }
      return '${_format(start, dateFormat)} ~ ${_format(end, dateFormat)} (종일)';
    }

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${_format(start, dateFormat)} ${_format(start, timeFormat)} ~ ${_format(end, timeFormat)}';
    }

    return '${_format(start, '$dateFormat $timeFormat')} ~ ${_format(end, '$dateFormat $timeFormat')}';
  }

  String _format(DateTime date, String pattern) {
    if (pattern == 'yyyy-MM-dd') {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } else if (pattern == 'HH:mm') {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _showCreateDialog() async {
    // Check if user has CALENDAR_MANAGE permission to create official events
    final permissionsAsync =
        ref.read(groupPermissionsProvider(widget.groupId));

    // Wait for permissions to load if not already loaded
    final permissions = await permissionsAsync.when(
      data: (permissions) async => permissions,
      loading: () async {
        // Wait for the future to complete
        return await ref.read(groupPermissionsProvider(widget.groupId).future);
      },
      error: (_, __) async => <String>{},
    );

    final canCreateOfficial = permissions.contains('CALENDAR_MANAGE');

    final result = await showGroupEventFormDialog(
      context,
      anchorDate: _focusedDate,
      canCreateOfficial: canCreateOfficial,
    );

    if (result != null && mounted) {
      try {
        await ref
            .read(groupCalendarProvider(widget.groupId).notifier)
            .createEvent(
          groupId: widget.groupId,
          title: result.title,
          description: result.description,
          location: result.location,
          startDate: result.startDate,
          endDate: result.endDate,
          isAllDay: result.isAllDay,
          isOfficial: result.isOfficial,
          color: result.color.toHex(),
          recurrence: result.recurrence,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정이 추가되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('일정 추가 실패: ${e.toString()}')),
          );
        }
      }
    }
  }

  /// Check if the current user can modify the given event.
  bool _canModifyEvent(GroupEvent event) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;

    // Check if user has CALENDAR_MANAGE permission
    final permissionsAsync =
        ref.read(groupPermissionsProvider(widget.groupId));
    final hasCalendarManage = permissionsAsync.maybeWhen(
      data: (permissions) => permissions.contains('CALENDAR_MANAGE'),
      orElse: () => false,
    );

    // Official events: Require CALENDAR_MANAGE permission
    if (event.isOfficial) {
      return hasCalendarManage;
    }

    // Unofficial events: Creator or CALENDAR_MANAGE
    return event.creatorId == currentUser.id || hasCalendarManage;
  }

  Future<void> _showEventDetail(GroupEvent event) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: event.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (event.isOfficial)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '공식',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.brand,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            if (event.isRecurring) ...[
                              if (event.isOfficial) const SizedBox(width: 8),
                              const Icon(Icons.repeat, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '반복',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_canModifyEvent(event))
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEventActions(event);
                      },
                    ),
                ],
              ),
              const Divider(height: AppSpacing.md),
              _buildDetailRow(
                Icons.schedule,
                '시간',
                _formatDateRange(event.startDate, event.endDate, event.isAllDay),
              ),
              if (event.location != null)
                _buildDetailRow(Icons.place, '장소', event.location!),
              if (event.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRow(
                  Icons.notes,
                  '설명',
                  event.description!,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              _buildDetailRow(
                Icons.person,
                '작성자',
                event.creatorName,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '생성: ${_formatDateTime(event.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral600,
                    ),
              ),
              Text(
                '수정: ${_formatDateTime(event.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.neutral600),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.neutral600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_format(dateTime, 'yyyy-MM-dd')} ${_format(dateTime, 'HH:mm')}';
  }

  Future<void> _showEventActions(GroupEvent event) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.action),
                title: const Text('수정'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleEditEvent(event);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('삭제'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleDeleteEvent(event);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('취소'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEditEvent(GroupEvent event) async {
    UpdateScope? updateScope;

    if (event.isRecurring) {
      updateScope = await _showUpdateScopeDialog();
      if (updateScope == null) return; // User cancelled
    }

    if (!mounted) return;

    final result = await showGroupEventFormDialog(
      context,
      initial: event,
      canCreateOfficial: event.isOfficial, // Keep the same official status
    );

    if (result != null && mounted) {
      try {
        await ref
            .read(groupCalendarProvider(widget.groupId).notifier)
            .updateEvent(
          groupId: widget.groupId,
          eventId: event.id,
          title: result.title,
          description: result.description,
          location: result.location,
          startDate: result.startDate,
          endDate: result.endDate,
          isAllDay: result.isAllDay,
          color: result.color.toHex(),
          updateScope: updateScope ?? UpdateScope.thisEvent,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정이 수정되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('일정 수정 실패: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteEvent(GroupEvent event) async {
    UpdateScope? deleteScope;

    if (event.isRecurring) {
      deleteScope = await _showUpdateScopeDialog(isDelete: true);
      if (deleteScope == null) return; // User cancelled
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text(
          event.isRecurring && deleteScope == UpdateScope.allEvents
              ? '이후 모든 반복 일정이 삭제됩니다. 계속하시겠습니까?'
              : '이 일정을 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(groupCalendarProvider(widget.groupId).notifier)
            .deleteEvent(
          groupId: widget.groupId,
          eventId: event.id,
          deleteScope: deleteScope ?? UpdateScope.thisEvent,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정이 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('일정 삭제 실패: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<UpdateScope?> _showUpdateScopeDialog({bool isDelete = false}) async {
    return showDialog<UpdateScope>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDelete ? '반복 일정 삭제' : '반복 일정 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isDelete
                  ? '어떤 일정을 삭제하시겠습니까?'
                  : '어떤 일정을 수정하시겠습니까?',
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(UpdateScope.thisEvent),
              child: const Text('이 일정만'),
            ),
            const SizedBox(height: AppSpacing.xs),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(UpdateScope.allEvents),
              child: const Text('이후 모든 반복 일정'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}

extension on Color {
  String toHex() {
    return '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
