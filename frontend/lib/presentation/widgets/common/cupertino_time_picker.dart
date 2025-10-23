import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// Simplified Cupertino-style Time Picker (모바일 전용)
///
/// CupertinoPicker 기반의 간단한 시간 선택기
/// - 웹에서는 TimeSpinner 사용 권장
/// - 모바일에서만 사용
class CupertinoTimePicker extends StatefulWidget {
  final DateTime initialTime;
  final ValueChanged<DateTime> onTimeChanged;
  final int minuteInterval;
  final bool enabled;
  final String? label;
  final bool freeInputMode;

  const CupertinoTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    this.minuteInterval = 15,
    this.enabled = true,
    this.label,
    this.freeInputMode = false,
  });

  @override
  State<CupertinoTimePicker> createState() => _CupertinoTimePickerState();
}

class _CupertinoTimePickerState extends State<CupertinoTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late DateTime _currentTime;
  bool _isUpdatingFromParent = false; // Flag to prevent callback during update

  int get _effectiveInterval => widget.freeInputMode ? 1 : widget.minuteInterval;
  int get _minuteItemCount => 60 ~/ _effectiveInterval;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.initialTime;
    _hourController = FixedExtentScrollController(
      initialItem: _currentTime.hour,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _currentTime.minute ~/ _effectiveInterval,
    );
  }

  @override
  void didUpdateWidget(covariant CupertinoTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialTime != oldWidget.initialTime) {
      _isUpdatingFromParent = true;
      _hourController.jumpToItem(widget.initialTime.hour);
      final minuteIndex = widget.initialTime.minute ~/ _effectiveInterval;
      _minuteController.jumpToItem(minuteIndex);
      setState(() {
        _currentTime = widget.initialTime;
      });
      _isUpdatingFromParent = false;
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _handleHourChange(int index) {
    if (!widget.enabled || _isUpdatingFromParent) return;

    final newTime = DateTime(
      _currentTime.year,
      _currentTime.month,
      _currentTime.day,
      index,
      _currentTime.minute,
    );

    setState(() {
      _currentTime = newTime;
    });
    widget.onTimeChanged(newTime);
  }

  void _handleMinuteChange(int index) {
    if (!widget.enabled || _isUpdatingFromParent) return;

    final actualMinute = index * _effectiveInterval;
    final newTime = DateTime(
      _currentTime.year,
      _currentTime.month,
      _currentTime.day,
      _currentTime.hour,
      actualMinute,
    );

    setState(() {
      _currentTime = newTime;
    });
    widget.onTimeChanged(newTime);
  }

  Widget _buildHourPicker() {
    return CupertinoPicker(
      scrollController: _hourController,
      itemExtent: 32.0,
      onSelectedItemChanged: _handleHourChange,
      children: List.generate(24, (i) {
        return Center(
          child: Text(
            i.toString().padLeft(2, '0'),
            style: AppTheme.headlineMedium.copyWith(
              color: widget.enabled ? AppColors.neutral900 : AppColors.neutral500,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMinutePicker() {
    return CupertinoPicker(
      scrollController: _minuteController,
      itemExtent: 32.0,
      onSelectedItemChanged: _handleMinuteChange,
      children: List.generate(_minuteItemCount, (i) {
        final minute = i * _effectiveInterval;
        return Center(
          child: Text(
            minute.toString().padLeft(2, '0'),
            style: AppTheme.headlineMedium.copyWith(
              color: widget.enabled ? AppColors.neutral900 : AppColors.neutral500,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTheme.titleLarge.copyWith(
              color: widget.enabled ? AppColors.neutral800 : AppColors.neutral500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          height: 180.0,
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.surface : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: widget.enabled ? AppColors.lightOutline : AppColors.neutral300,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: IgnorePointer(
              ignoring: !widget.enabled,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(flex: 2, child: _buildHourPicker()),
                  Container(
                    width: 16,
                    alignment: Alignment.center,
                    child: Text(
                      ':',
                      style: AppTheme.headlineMedium.copyWith(
                        color: widget.enabled ? AppColors.neutral900 : AppColors.neutral500,
                      ),
                    ),
                  ),
                  Expanded(flex: 2, child: _buildMinutePicker()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
