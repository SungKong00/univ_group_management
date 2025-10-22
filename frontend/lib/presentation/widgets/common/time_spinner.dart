import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// Reusable Time Spinner Component
///
/// A compact time picker UI that allows users to select hours and minutes
/// using increment/decrement buttons (spinner style).
///
/// Features:
/// - Hour spinner (0-23)
/// - Minute spinner (0-59, 15-minute intervals)
/// - Compact vertical layout
/// - Keyboard input support
/// - Callback on time change
///
/// Design:
/// - Follows Toss design system (4pt grid, brand colors)
/// - Row/Column layout constraints compliant
/// - Independent and reusable across the app
class TimeSpinner extends StatefulWidget {
  /// Initial time value
  final DateTime initialTime;

  /// Callback when time changes
  final ValueChanged<DateTime> onTimeChanged;

  /// Minute interval (default: 15 minutes)
  /// Supported values: 1, 5, 10, 15, 30
  final int minuteInterval;

  /// Enable/disable the spinner
  final bool enabled;

  /// Label text (optional, e.g., "시작 시간")
  final String? label;

  const TimeSpinner({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    this.minuteInterval = 15,
    this.enabled = true,
    this.label,
  }) : assert(
          minuteInterval == 1 ||
              minuteInterval == 5 ||
              minuteInterval == 10 ||
              minuteInterval == 15 ||
              minuteInterval == 30,
          'minuteInterval must be 1, 5, 10, 15, or 30',
        );

  @override
  State<TimeSpinner> createState() => _TimeSpinnerState();
}

class _TimeSpinnerState extends State<TimeSpinner> {
  late int _selectedHour;
  late int _selectedMinute;

  // 편집 모드 상태
  bool _isEditingHour = false;
  bool _isEditingMinute = false;

  // TextField 컨트롤러
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();

  // FocusNode
  final _hourFocusNode = FocusNode();
  final _minuteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = _roundToInterval(widget.initialTime.minute);
  }

  @override
  void didUpdateWidget(covariant TimeSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTime != oldWidget.initialTime) {
      setState(() {
        _selectedHour = widget.initialTime.hour;
        _selectedMinute = _roundToInterval(widget.initialTime.minute);
      });
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    super.dispose();
  }

  /// Round minute to the nearest interval
  int _roundToInterval(int minute) {
    return (minute ~/ widget.minuteInterval) * widget.minuteInterval;
  }

  /// Notify parent of time change
  void _notifyTimeChange() {
    final newTime = DateTime(
      widget.initialTime.year,
      widget.initialTime.month,
      widget.initialTime.day,
      _selectedHour,
      _selectedMinute,
    );
    widget.onTimeChanged(newTime);
  }

  /// Increment hour
  void _incrementHour() {
    if (!widget.enabled) return;
    setState(() {
      _selectedHour = (_selectedHour + 1) % 24;
      _notifyTimeChange();
    });
  }

  /// Decrement hour
  void _decrementHour() {
    if (!widget.enabled) return;
    setState(() {
      _selectedHour = (_selectedHour - 1 + 24) % 24;
      _notifyTimeChange();
    });
  }

  /// Increment minute
  void _incrementMinute() {
    if (!widget.enabled) return;
    setState(() {
      _selectedMinute = (_selectedMinute + widget.minuteInterval) % 60;
      _notifyTimeChange();
    });
  }

  /// Decrement minute
  void _decrementMinute() {
    if (!widget.enabled) return;
    setState(() {
      _selectedMinute = (_selectedMinute - widget.minuteInterval + 60) % 60;
      _notifyTimeChange();
    });
  }

  /// Handle hour input from TextField
  void _validateAndApplyHour(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0 && parsed <= 23) {
      setState(() {
        _selectedHour = parsed;
      });
      _notifyTimeChange();
    }
    // Invalid input: revert to previous value (silent recovery)
    setState(() {
      _isEditingHour = false;
    });
  }

  /// Handle minute input from TextField
  void _validateAndApplyMinute(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0 && parsed <= 59) {
      setState(() {
        _selectedMinute = _roundToInterval(parsed);
      });
      _notifyTimeChange();
    }
    // Invalid input: revert to previous value (silent recovery)
    setState(() {
      _isEditingMinute = false;
    });
  }

  /// Build a single spinner column (hour or minute)
  Widget _buildSpinnerColumn({
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Increment button
        _SpinnerButton(
          icon: Icons.keyboard_arrow_up,
          onPressed: widget.enabled ? onIncrement : null,
        ),
        const SizedBox(height: AppSpacing.xxs),
        // Value display (with tap-to-edit)
        GestureDetector(
          onTap: () {
            if (!widget.enabled) return;
            // 시간/분 구분하여 편집 모드 전환
            if (label == '시') {
              setState(() {
                _isEditingHour = true;
                _hourController.clear(); // 기존 값 클리어
              });
              _hourFocusNode.requestFocus(); // 포커스 자동 설정
            } else {
              setState(() {
                _isEditingMinute = true;
                _minuteController.clear();
              });
              _minuteFocusNode.requestFocus();
            }
          },
          child: Container(
            width: 56,
            height: 44,
            decoration: BoxDecoration(
              // 편집 모드: 하이라이트 배경
              color: (label == '시' && _isEditingHour) || (label == '분' && _isEditingMinute)
                  ? AppColors.brandLight // 연한 퍼플 하이라이트
                  : (widget.enabled ? AppColors.surface : AppColors.neutral100),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: widget.enabled ? AppColors.lightOutline : AppColors.neutral300,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: (label == '시' && _isEditingHour)
                ? TextField(
                    controller: _hourController,
                    focusNode: _hourFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: AppTheme.headlineMedium.copyWith(
                      color: AppColors.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _validateAndApplyHour,
                    onTapOutside: (_) => _validateAndApplyHour(_hourController.text),
                  )
                : (label == '분' && _isEditingMinute)
                    ? TextField(
                        controller: _minuteController,
                        focusNode: _minuteFocusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTheme.headlineMedium.copyWith(
                          color: AppColors.neutral900,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: _validateAndApplyMinute,
                        onTapOutside: (_) => _validateAndApplyMinute(_minuteController.text),
                      )
                    : Text(
                        value.toString().padLeft(2, '0'),
                        style: AppTheme.headlineMedium.copyWith(
                          color: widget.enabled ? AppColors.neutral900 : AppColors.neutral500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 4),
        // Label
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: widget.enabled ? AppColors.neutral600 : AppColors.neutral400,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        // Decrement button
        _SpinnerButton(
          icon: Icons.keyboard_arrow_down,
          onPressed: widget.enabled ? onDecrement : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
        // Spinner UI
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hour spinner
            _buildSpinnerColumn(
              label: '시',
              value: _selectedHour,
              onIncrement: _incrementHour,
              onDecrement: _decrementHour,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Colon separator
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                ':',
                style: AppTheme.headlineMedium.copyWith(
                  color: widget.enabled ? AppColors.neutral900 : AppColors.neutral500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Minute spinner
            _buildSpinnerColumn(
              label: '분',
              value: _selectedMinute,
              onIncrement: _incrementMinute,
              onDecrement: _decrementMinute,
            ),
          ],
        ),
      ],
    );
  }
}

/// Internal widget for increment/decrement buttons
class _SpinnerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _SpinnerButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        color: onPressed != null ? AppColors.brand : AppColors.neutral400,
        style: IconButton.styleFrom(
          backgroundColor: onPressed != null ? AppColors.brandLight : AppColors.neutral100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
