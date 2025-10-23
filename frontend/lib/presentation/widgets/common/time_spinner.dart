import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// Reusable Time Spinner Component (Mobile-optimized)
///
/// A compact time picker UI for mobile that allows users to select hours and minutes
/// using increment/decrement arrow buttons.
///
/// Features:
/// - Hour spinner (0-23)
/// - Minute spinner (0-59)
/// - Two input modes:
///   - Free input mode: Arrow buttons ±1 minute
///   - Interval mode: Arrow buttons ±interval (15, 30 minutes, etc.)
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

  /// Free input mode (default: false = interval mode)
  /// - true: Any minute value (0-59), arrow buttons ±1
  /// - false: Fixed intervals, arrow buttons ±interval
  final bool freeInputMode;

  const TimeSpinner({
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
  State<TimeSpinner> createState() => _TimeSpinnerState();
}

class _TimeSpinnerState extends State<TimeSpinner> {
  late int _selectedHour;
  late int _selectedMinute;

  // Edit mode state
  bool _isEditingHour = false;
  bool _isEditingMinute = false;
  bool _hasError = false;

  // Text editing controllers
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();

  // Focus nodes
  final FocusNode _hourFocusNode = FocusNode();
  final FocusNode _minuteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    // Free mode: use exact minute, Interval mode: round to interval
    _selectedMinute = widget.freeInputMode
        ? widget.initialTime.minute
        : _roundToInterval(widget.initialTime.minute);

    // Listen to focus changes
    _hourFocusNode.addListener(_onHourFocusChange);
    _minuteFocusNode.addListener(_onMinuteFocusChange);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TimeSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTime != oldWidget.initialTime) {
      setState(() {
        _selectedHour = widget.initialTime.hour;
        // Free mode: use exact minute, Interval mode: round to interval
        _selectedMinute = widget.freeInputMode
            ? widget.initialTime.minute
            : _roundToInterval(widget.initialTime.minute);
      });
    }
  }

  /// Round minute to the nearest interval (Floor)
  int _roundToInterval(int minute) {
    return (minute ~/ widget.minuteInterval) * widget.minuteInterval;
  }

  /// Focus change handler for hour
  void _onHourFocusChange() {
    if (!_hourFocusNode.hasFocus && _isEditingHour) {
      _submitHourEdit();
    }
  }

  /// Focus change handler for minute
  void _onMinuteFocusChange() {
    if (!_minuteFocusNode.hasFocus && _isEditingMinute) {
      _submitMinuteEdit();
    }
  }

  /// Enter edit mode for hour
  void _startEditingHour() {
    if (!widget.enabled) return;
    setState(() {
      _isEditingHour = true;
      _hasError = false;
      _hourController.text = _selectedHour.toString().padLeft(2, '0');
    });
    // Request focus and select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hourFocusNode.requestFocus();
      _hourController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _hourController.text.length,
      );
    });
  }

  /// Enter edit mode for minute
  void _startEditingMinute() {
    if (!widget.enabled) return;
    setState(() {
      _isEditingMinute = true;
      _hasError = false;
      _minuteController.text = _selectedMinute.toString().padLeft(2, '0');
    });
    // Request focus and select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _minuteFocusNode.requestFocus();
      _minuteController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _minuteController.text.length,
      );
    });
  }

  /// Submit hour edit
  void _submitHourEdit() {
    final inputValue = _hourController.text.trim();
    final parsedValue = int.tryParse(inputValue);

    if (parsedValue == null || parsedValue < 0 || parsedValue > 23) {
      // Invalid input - show error and restore
      setState(() {
        _hasError = true;
      });
      // Restore after a brief delay
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _isEditingHour = false;
          _hasError = false;
        });
      });
    } else {
      // Valid input
      setState(() {
        _selectedHour = parsedValue;
        _isEditingHour = false;
        _hasError = false;
      });
      _notifyTimeChange();
    }
  }

  /// Submit minute edit
  void _submitMinuteEdit() {
    final inputValue = _minuteController.text.trim();
    final parsedValue = int.tryParse(inputValue);

    if (parsedValue == null || parsedValue < 0 || parsedValue > 59) {
      // Invalid input - show error and restore
      setState(() {
        _hasError = true;
      });
      // Restore after a brief delay
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _isEditingMinute = false;
          _hasError = false;
        });
      });
    } else {
      // Valid input - apply interval rounding if needed
      final finalMinute = widget.freeInputMode
          ? parsedValue
          : _roundToInterval(parsedValue);
      setState(() {
        _selectedMinute = finalMinute;
        _isEditingMinute = false;
        _hasError = false;
      });
      _notifyTimeChange();
    }
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
    // Exit edit mode if active
    if (_isEditingHour) {
      setState(() {
        _isEditingHour = false;
        _hasError = false;
      });
      return;
    }
    setState(() {
      _selectedHour = (_selectedHour + 1) % 24;
      _notifyTimeChange();
    });
  }

  /// Decrement hour
  void _decrementHour() {
    if (!widget.enabled) return;
    // Exit edit mode if active
    if (_isEditingHour) {
      setState(() {
        _isEditingHour = false;
        _hasError = false;
      });
      return;
    }
    setState(() {
      _selectedHour = (_selectedHour - 1 + 24) % 24;
      _notifyTimeChange();
    });
  }

  /// Increment minute
  void _incrementMinute() {
    if (!widget.enabled) return;
    // Exit edit mode if active
    if (_isEditingMinute) {
      setState(() {
        _isEditingMinute = false;
        _hasError = false;
      });
      return;
    }
    setState(() {
      // Free mode: +1, Interval mode: +interval
      final increment = widget.freeInputMode ? 1 : widget.minuteInterval;
      _selectedMinute = (_selectedMinute + increment) % 60;
      _notifyTimeChange();
    });
  }

  /// Decrement minute
  void _decrementMinute() {
    if (!widget.enabled) return;
    // Exit edit mode if active
    if (_isEditingMinute) {
      setState(() {
        _isEditingMinute = false;
        _hasError = false;
      });
      return;
    }
    setState(() {
      // Free mode: -1, Interval mode: -interval
      final decrement = widget.freeInputMode ? 1 : widget.minuteInterval;
      _selectedMinute = (_selectedMinute - decrement + 60) % 60;
      _notifyTimeChange();
    });
  }

  /// Build a single spinner column (hour or minute)
  Widget _buildSpinnerColumn({
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required bool isEditing,
    required TextEditingController controller,
    required FocusNode focusNode,
    required VoidCallback onTap,
    required VoidCallback onSubmit,
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
        // Value display (clickable) or TextField (editing mode)
        InkWell(
          onTap: widget.enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            width: 64,
            height: 44,
            decoration: BoxDecoration(
              color: widget.enabled ? AppColors.surface : AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: _hasError
                    ? Colors.red
                    : (widget.enabled ? AppColors.lightOutline : AppColors.neutral300),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: isEditing
                ? TextField(
                    controller: controller,
                    focusNode: focusNode,
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
                    onSubmitted: (_) => onSubmit(),
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
              isEditing: _isEditingHour,
              controller: _hourController,
              focusNode: _hourFocusNode,
              onTap: _startEditingHour,
              onSubmit: _submitHourEdit,
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
              isEditing: _isEditingMinute,
              controller: _minuteController,
              focusNode: _minuteFocusNode,
              onTap: _startEditingMinute,
              onSubmit: _submitMinuteEdit,
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
      width: 64,
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
