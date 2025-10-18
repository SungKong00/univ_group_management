import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/place/place_availability.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/place_provider.dart';

/// Place Availability Settings Page
///
/// Allows managing operating hours for a place by day of week.
/// Each day can have multiple time slots.
///
/// DEPRECATED: This page uses the old PlaceAvailability system (multiple time slots per day).
/// For new implementations, use PlaceOperatingHoursDisplay widget from place_admin feature
/// which uses the new PlaceOperatingHours system (single time slot per day).
@Deprecated('Use PlaceOperatingHoursDisplay from place_admin feature instead')
class PlaceAvailabilitySettingsPage extends ConsumerStatefulWidget {
  final int placeId;

  const PlaceAvailabilitySettingsPage({
    required this.placeId,
    super.key,
  });

  @override
  ConsumerState<PlaceAvailabilitySettingsPage> createState() =>
      _PlaceAvailabilitySettingsPageState();
}

class _PlaceAvailabilitySettingsPageState
    extends ConsumerState<PlaceAvailabilitySettingsPage> {
  // Local state: time slots by day of week
  final Map<DayOfWeek, List<AvailabilityEntry>> _availabilities = {
    for (var day in DayOfWeek.values) day: [],
  };

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Load existing availabilities after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAvailabilities());
  }

  /// Load existing availabilities from API
  Future<void> _loadAvailabilities() async {
    try {
      final placeDetail = await ref.read(placeDetailProvider(widget.placeId).future);
      if (placeDetail != null && mounted) {
        setState(() {
          // Clear existing entries before loading
          for (var day in DayOfWeek.values) {
            _availabilities[day]!.clear();
          }

          // Group availabilities by day of week
          // ignore: deprecated_member_use
          for (var availability in placeDetail.availabilities) {
            _availabilities[availability.dayOfWeek]!.add(
              AvailabilityEntry(
                id: availability.id,
                startTime: availability.startTime,
                endTime: availability.endTime,
                displayOrder: availability.displayOrder,
              ),
            );
          }

          // Sort by display order
          for (var day in DayOfWeek.values) {
            _availabilities[day]!.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
          }

          _isInitialized = true;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('장소 정보를 불러오는 데 실패했습니다: $error')),
        );
        // Also set initialized to true on error to stop loading
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeDetailAsync = ref.watch(placeDetailProvider(widget.placeId));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('운영시간 설정'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTheme.titleLarge.copyWith(
          color: AppColors.neutral900,
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _isLoading ? null : _saveAvailabilities,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.brand,
                        ),
                      ),
                    )
                  : Text(
                      '저장',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppColors.brand,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: placeDetailAsync.when(
        data: (placeDetail) {
          if (placeDetail == null) {
            return Center(
              child: Text(
                '장소 정보를 찾을 수 없습니다',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            );
          }

          return Column(
            children: [
              // Place info card
              Container(
                margin: EdgeInsets.all(AppSpacing.sm),
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: AppColors.neutral300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.place,
                      size: 32,
                      color: AppColors.brand,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            placeDetail.place.displayName,
                            style: AppTheme.titleLarge.copyWith(
                              color: AppColors.neutral900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${placeDetail.place.building} ${placeDetail.place.roomNumber}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Day-by-day availability sections
              Expanded(
                child: !_isInitialized
                    ? Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        children: DayOfWeek.values.map((day) {
                          return _buildDaySection(day);
                        }).toList(),
                      ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
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
                '오류가 발생했습니다',
                style: AppTheme.titleLarge.copyWith(
                  color: AppColors.neutral900,
                ),
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                error.toString(),
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a section for a specific day of week
  Widget _buildDaySection(DayOfWeek day) {
    final entries = _availabilities[day]!;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.xxs),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: AppColors.neutral300,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          day.displayName,
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        subtitle: entries.isEmpty
            ? Text(
                '운영시간 없음',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.neutral500,
                ),
              )
            : Text(
                '${entries.length}개 시간대',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.brand,
                ),
              ),
        children: [
          // Existing time slots
          ...entries.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;

            return ListTile(
              leading: Icon(
                Icons.schedule,
                color: AppColors.neutral600,
              ),
              title: Text(
                '${_formatTime(entry.startTime)} - ${_formatTime(entry.endTime)}',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppColors.neutral900,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: AppColors.brand),
                    onPressed: () => _editTimeSlot(day, index, entry),
                    tooltip: '수정',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _removeTimeSlot(day, index),
                    tooltip: '삭제',
                  ),
                ],
              ),
              onTap: () => _editTimeSlot(day, index, entry),
            );
          }),

          // "Add time slot" button
          ListTile(
            leading: Icon(
              Icons.add_circle_outline,
              color: AppColors.brand,
            ),
            title: Text(
              '시간대 추가',
              style: AppTheme.bodyLarge.copyWith(
                color: AppColors.brand,
              ),
            ),
            onTap: () => _addTimeSlot(day),
          ),
        ],
      ),
    );
  }

  /// Format TimeOfDay to HH:mm string
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  /// Add a new time slot for a day
  Future<void> _addTimeSlot(DayOfWeek day) async {
    final startTime = await _pickTime(
      context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      title: '시작 시간',
    );
    if (startTime == null || !mounted) return;

    final endTime = await _pickTime(
      context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      title: '종료 시간',
    );
    if (endTime == null || !mounted) return;

    // Validate: end time must be after start time
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('종료 시간은 시작 시간보다 늦어야 합니다'),
          ),
        );
      }
      return;
    }

    setState(() {
      _availabilities[day]!.add(
        AvailabilityEntry(
          startTime: startTime,
          endTime: endTime,
          displayOrder: _availabilities[day]!.length,
        ),
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('시간대가 추가되었습니다 (저장 버튼을 눌러 완료하세요)'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Edit an existing time slot
  Future<void> _editTimeSlot(
    DayOfWeek day,
    int index,
    AvailabilityEntry entry,
  ) async {
    final startTime = await _pickTime(
      context,
      initialTime: entry.startTime,
      title: '시작 시간',
    );
    if (startTime == null || !mounted) return;

    final endTime = await _pickTime(
      context,
      initialTime: entry.endTime,
      title: '종료 시간',
    );
    if (endTime == null || !mounted) return;

    // Validate: end time must be after start time
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('종료 시간은 시작 시간보다 늦어야 합니다'),
          ),
        );
      }
      return;
    }

    setState(() {
      _availabilities[day]![index] = entry.copyWith(
        startTime: startTime,
        endTime: endTime,
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('시간대가 수정되었습니다 (저장 버튼을 눌러 완료하세요)'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Remove a time slot
  void _removeTimeSlot(DayOfWeek day, int index) {
    setState(() {
      _availabilities[day]!.removeAt(index);

      // Re-index displayOrder
      for (var i = 0; i < _availabilities[day]!.length; i++) {
        _availabilities[day]![i] = _availabilities[day]![i].copyWith(
          displayOrder: i,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('시간대가 삭제되었습니다 (저장 버튼을 눌러 완료하세요)'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  /// Show time picker dialog
  Future<TimeOfDay?> _pickTime(
    BuildContext context, {
    required TimeOfDay initialTime,
    String? title,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: title,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.brand,
              onPrimary: Colors.white,
              onSurface: AppColors.neutral900,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// Save all availabilities to server
  Future<void> _saveAvailabilities() async {
    setState(() => _isLoading = true);

    try {
      // Convert all time slots to AvailabilityRequest list
      final requests = <AvailabilityRequest>[];

      for (var day in DayOfWeek.values) {
        final entries = _availabilities[day]!;
        for (var i = 0; i < entries.length; i++) {
          requests.add(
            AvailabilityRequest(
              dayOfWeek: day,
              startTime: entries[i].startTime,
              endTime: entries[i].endTime,
              displayOrder: i,
            ),
          );
        }
      }

      // Call API
      // ignore: deprecated_member_use_from_same_package
      await ref.read(placeManagementProvider.notifier).setAvailabilities(
            widget.placeId,
            requests,
          );

      // Invalidate cache to refresh data
      ref.invalidate(placeDetailProvider(widget.placeId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('운영시간이 저장되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, stack) {
      developer.log(
        'Failed to save availabilities',
        name: 'PlaceAvailabilitySettingsPage',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Local state entry for managing availability time slots
class AvailabilityEntry {
  final int? id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int displayOrder;

  AvailabilityEntry({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.displayOrder,
  });

  AvailabilityEntry copyWith({
    int? id,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? displayOrder,
  }) {
    return AvailabilityEntry(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
