import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// Cupertino-style Time Picker Component
///
/// A native iOS-style time picker that provides a wheel scrolling interface
/// for selecting hours and minutes. Wraps CupertinoDatePicker with custom
/// design system integration.
///
/// Features:
/// - iOS native wheel picker UX
/// - Hour and minute selection (24-hour format)
/// - Two input modes:
///   - Free input mode: 1-minute intervals (0-59)
///   - Interval mode: Fixed intervals (15 minutes default)
/// - Brand color integration via CupertinoTheme
/// - Disabled state support
///
/// Design:
/// - Follows Toss design system (brand colors, spacing)
/// - Consistent with TimeSpinner API for easy migration
/// - Reusable across the app
class CupertinoTimePicker extends StatefulWidget {
  /// Initial time value
  final DateTime initialTime;

  /// Callback when time changes
  final ValueChanged<DateTime> onTimeChanged;

  /// Minute interval (default: 15 minutes)
  /// Supported values: 1, 5, 10, 15, 30
  final int minuteInterval;

  /// Enable/disable the picker
  final bool enabled;

  /// Label text (optional, e.g., "시작 시간")
  final String? label;

  /// Free input mode (default: false = interval mode)
  /// - true: 1-minute intervals (0-59)
  /// - false: Fixed intervals (minuteInterval)
  final bool freeInputMode;

  const CupertinoTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    this.minuteInterval = 15,
    this.enabled = true,
    this.label,
    this.freeInputMode = false,
  }) : assert(
          minuteInterval == 1 ||
              minuteInterval == 5 ||
              minuteInterval == 10 ||
              minuteInterval == 15 ||
              minuteInterval == 30,
          'minuteInterval must be 1, 5, 10, 15, or 30',
        );

  @override
  State<CupertinoTimePicker> createState() => _CupertinoTimePickerState();
}

class _CupertinoTimePickerState extends State<CupertinoTimePicker> {
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  void didUpdateWidget(covariant CupertinoTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTime != oldWidget.initialTime) {
      setState(() {
        _selectedTime = widget.initialTime;
      });
    }
  }

  /// Handle time change from picker
  void _handleTimeChange(DateTime newTime) {
    if (!widget.enabled) return;

    // Round minutes if in interval mode
    DateTime adjustedTime = newTime;
    if (!widget.freeInputMode) {
      final roundedMinute =
          (newTime.minute ~/ widget.minuteInterval) * widget.minuteInterval;
      adjustedTime = DateTime(
        newTime.year,
        newTime.month,
        newTime.day,
        newTime.hour,
        roundedMinute,
      );
    }

    setState(() {
      _selectedTime = adjustedTime;
    });
    widget.onTimeChanged(adjustedTime);
  }

  @override
  Widget build(BuildContext context) {
    // Determine effective minute interval
    final effectiveInterval = widget.freeInputMode ? 1 : widget.minuteInterval;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Optional label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTheme.titleLarge.copyWith(
              color: widget.enabled ? AppColors.neutral800 : AppColors.neutral500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],

        // Picker container with design system styling
        Container(
          height: 180, // Compact height for dialog usage
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.surface : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: widget.enabled
                  ? AppColors.lightOutline
                  : AppColors.neutral300,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Stack(
              children: [
                // CupertinoDatePicker with brand theme
                CupertinoTheme(
                  data: CupertinoThemeData(
                    // Brand color integration
                    primaryColor: AppColors.brand,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: AppTheme.headlineMedium.copyWith(
                        color: widget.enabled
                            ? AppColors.neutral900
                            : AppColors.neutral500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    minuteInterval: effectiveInterval,
                    initialDateTime: _selectedTime,
                    onDateTimeChanged: _handleTimeChange,
                  ),
                ),

                // Disabled overlay (semi-transparent)
                if (!widget.enabled)
                  Positioned.fill(
                    child: Container(
                      color: AppColors.neutral100.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Helper text for interval mode
        if (!widget.freeInputMode && widget.minuteInterval > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${widget.minuteInterval}분 단위로 선택됩니다',
            style: AppTheme.bodySmall.copyWith(
              color: widget.enabled ? AppColors.neutral600 : AppColors.neutral400,
            ),
          ),
        ],
      ],
    );
  }
}
