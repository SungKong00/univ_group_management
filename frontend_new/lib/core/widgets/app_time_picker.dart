import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/time_picker_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/responsive_tokens.dart';
import 'app_button.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppTimePickerFormat, AppTimePickerPrecision;

/// 시간 선택을 위한 TimePicker 컴포넌트
///
/// **용도**: 시간 입력, 예약 시간 설정, 알람 설정
/// **접근성**: 키보드 네비게이션, 스크린 리더 지원
///
/// ```dart
/// // 12시간제 시간 선택
/// AppTimePicker(
///   selectedTime: _selectedTime,
///   onTimeSelected: (time) => setState(() => _selectedTime = time),
///   format: AppTimePickerFormat.hour12,
/// )
///
/// // 24시간제 시간 선택
/// AppTimePicker(
///   selectedTime: _selectedTime,
///   onTimeSelected: (time) => setState(() => _selectedTime = time),
///   format: AppTimePickerFormat.hour24,
/// )
///
/// // 분까지만 선택 (초 제외)
/// AppTimePicker(
///   selectedTime: _selectedTime,
///   onTimeSelected: (time) => setState(() => _selectedTime = time),
///   precision: AppTimePickerPrecision.minute,
/// )
/// ```
class AppTimePicker extends StatefulWidget {
  /// 선택된 시간
  final TimeOfDay? selectedTime;

  /// 시간 선택 콜백
  final ValueChanged<TimeOfDay>? onTimeSelected;

  /// 시간 포맷 (12시간/24시간)
  final AppTimePickerFormat format;

  /// 선택 정밀도
  final AppTimePickerPrecision precision;

  /// 분 간격 (1, 5, 10, 15, 30)
  final int minuteInterval;

  /// 초 간격 (1, 5, 10, 15, 30)
  final int secondInterval;

  /// 최소 시간
  final TimeOfDay? minTime;

  /// 최대 시간
  final TimeOfDay? maxTime;

  /// 인라인 모드 (항상 표시)
  final bool isInline;

  /// 플레이스홀더 텍스트
  final String? placeholder;

  /// 라벨
  final String? label;

  /// 도움말 텍스트
  final String? helperText;

  /// 에러 텍스트
  final String? errorText;

  /// 비활성화 여부
  final bool isDisabled;

  const AppTimePicker({
    super.key,
    this.selectedTime,
    this.onTimeSelected,
    this.format = AppTimePickerFormat.hour24,
    this.precision = AppTimePickerPrecision.minute,
    this.minuteInterval = 1,
    this.secondInterval = 1,
    this.minTime,
    this.maxTime,
    this.isInline = false,
    this.placeholder,
    this.label,
    this.helperText,
    this.errorText,
    this.isDisabled = false,
  });

  /// 인라인 팩토리
  factory AppTimePicker.inline({
    Key? key,
    TimeOfDay? selectedTime,
    ValueChanged<TimeOfDay>? onTimeSelected,
    AppTimePickerFormat format = AppTimePickerFormat.hour24,
    AppTimePickerPrecision precision = AppTimePickerPrecision.minute,
    bool isDisabled = false,
  }) {
    return AppTimePicker(
      key: key,
      selectedTime: selectedTime,
      onTimeSelected: onTimeSelected,
      format: format,
      precision: precision,
      isInline: true,
      isDisabled: isDisabled,
    );
  }

  @override
  State<AppTimePicker> createState() => _AppTimePickerState();
}

class _AppTimePickerState extends State<AppTimePicker> {
  bool _isOpen = false;
  late int _tempHour;
  late int _tempMinute;
  late int _tempSecond;
  late bool _isPM;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initializeTime();
  }

  void _initializeTime() {
    final now = TimeOfDay.now();
    final time = widget.selectedTime ?? now;
    _tempHour = time.hour;
    _tempMinute = time.minute;
    _tempSecond = 0;

    if (widget.format == AppTimePickerFormat.hour12) {
      _isPM = _tempHour >= 12;
      _tempHour = _tempHour > 12 ? _tempHour - 12 : (_tempHour == 0 ? 12 : _tempHour);
    } else {
      _isPM = false;
    }
  }

  @override
  void didUpdateWidget(AppTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTime != oldWidget.selectedTime) {
      _initializeTime();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _togglePicker() {
    if (widget.isDisabled) return;

    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
    setState(() => _isOpen = !_isOpen);
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => _TimePickerOverlay(
        link: _layerLink,
        format: widget.format,
        precision: widget.precision,
        minuteInterval: widget.minuteInterval,
        secondInterval: widget.secondInterval,
        hour: _tempHour,
        minute: _tempMinute,
        second: _tempSecond,
        isPM: _isPM,
        onHourChanged: (h) => setState(() => _tempHour = h),
        onMinuteChanged: (m) => setState(() => _tempMinute = m),
        onSecondChanged: (s) => setState(() => _tempSecond = s),
        onPeriodChanged: (pm) => setState(() => _isPM = pm),
        onClose: () {
          _removeOverlay();
          setState(() => _isOpen = false);
        },
        onConfirm: _handleConfirm,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleConfirm() {
    int hour = _tempHour;
    if (widget.format == AppTimePickerFormat.hour12) {
      if (_isPM && hour != 12) {
        hour += 12;
      } else if (!_isPM && hour == 12) {
        hour = 0;
      }
    }
    widget.onTimeSelected?.call(TimeOfDay(hour: hour, minute: _tempMinute));
    _removeOverlay();
    setState(() => _isOpen = false);
  }

  String _formatTime() {
    if (widget.selectedTime == null) {
      return widget.placeholder ?? '시간 선택';
    }

    final time = widget.selectedTime!;
    String hourStr;
    String periodStr = '';

    if (widget.format == AppTimePickerFormat.hour12) {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      hourStr = hour.toString().padLeft(2, '0');
      periodStr = time.period == DayPeriod.am ? ' AM' : ' PM';
    } else {
      hourStr = time.hour.toString().padLeft(2, '0');
    }

    final minuteStr = time.minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr$periodStr';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInline) {
      return _TimePickerContent(
        format: widget.format,
        precision: widget.precision,
        minuteInterval: widget.minuteInterval,
        secondInterval: widget.secondInterval,
        hour: _tempHour,
        minute: _tempMinute,
        second: _tempSecond,
        isPM: _isPM,
        onHourChanged: (h) {
          setState(() => _tempHour = h);
          _handleConfirm();
        },
        onMinuteChanged: (m) {
          setState(() => _tempMinute = m);
          _handleConfirm();
        },
        onSecondChanged: (s) {
          setState(() => _tempSecond = s);
          _handleConfirm();
        },
        onPeriodChanged: (pm) {
          setState(() => _isPM = pm);
          _handleConfirm();
        },
        isDisabled: widget.isDisabled,
      );
    }

    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;

    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? colorExt.stateErrorText
        : _isOpen
            ? colorExt.borderFocus
            : colorExt.borderPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: textTheme.bodySmall?.copyWith(
              color: colorExt.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: spacingExt.xs),
        ],

        // 트리거
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _togglePicker,
            child: AnimatedContainer(
              duration: AnimationTokens.durationQuick,
              height: ResponsiveTokens.inputHeight(width),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveTokens.inputPaddingH(width),
              ),
              decoration: BoxDecoration(
                color: widget.isDisabled
                    ? colorExt.surfaceTertiary
                    : colorExt.surfaceSecondary,
                border: Border.all(
                  color: widget.isDisabled
                      ? colorExt.borderPrimary.withValues(alpha: 0.5)
                      : borderColor,
                  width: _isOpen
                      ? BorderTokens.widthFocus
                      : BorderTokens.widthThin,
                ),
                borderRadius: BorderTokens.smallRadius(),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: ResponsiveTokens.iconSize(width),
                    color: widget.isDisabled
                        ? colorExt.textQuaternary
                        : colorExt.textTertiary,
                  ),
                  SizedBox(width: spacingExt.small),
                  Expanded(
                    child: Text(
                      _formatTime(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: widget.selectedTime != null
                            ? colorExt.textPrimary
                            : colorExt.textTertiary,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: ResponsiveTokens.iconSize(width),
                    color: colorExt.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 도움말/에러 텍스트
        if (widget.helperText != null || widget.errorText != null) ...[
          SizedBox(height: spacingExt.xs),
          Text(
            widget.errorText ?? widget.helperText!,
            style: textTheme.bodySmall?.copyWith(
              color: hasError ? colorExt.stateErrorText : colorExt.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

/// TimePicker 오버레이 (내부용)
class _TimePickerOverlay extends StatelessWidget {
  final LayerLink link;
  final AppTimePickerFormat format;
  final AppTimePickerPrecision precision;
  final int minuteInterval;
  final int secondInterval;
  final int hour;
  final int minute;
  final int second;
  final bool isPM;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final ValueChanged<int> onSecondChanged;
  final ValueChanged<bool> onPeriodChanged;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  const _TimePickerOverlay({
    required this.link,
    required this.format,
    required this.precision,
    required this.minuteInterval,
    required this.secondInterval,
    required this.hour,
    required this.minute,
    required this.second,
    required this.isPM,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onSecondChanged,
    required this.onPeriodChanged,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final width = MediaQuery.sizeOf(context).width;
    final colors = TimePickerColors.standard(colorExt);

    final pickerWidth = switch (ResponsiveTokens.getScreenSize(width)) {
      ScreenSize.xs => width - spacingExt.large,
      ScreenSize.sm => 280.0,
      ScreenSize.md => 300.0,
      ScreenSize.lg => 320.0,
      ScreenSize.xl => 340.0,
    };

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClose,
      child: Stack(
        children: [
          Positioned(
            width: pickerWidth,
            child: CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              offset: Offset(0, spacingExt.xs),
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {}, // Prevent close on picker tap
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.background,
                      border: Border.all(
                        color: colors.border,
                        width: BorderTokens.widthThin,
                      ),
                      borderRadius: BorderTokens.mediumRadius(),
                      boxShadow: [
                        BoxShadow(
                          color: colorExt.shadow,
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(spacingExt.medium),
                          child: _TimePickerContent(
                            format: format,
                            precision: precision,
                            minuteInterval: minuteInterval,
                            secondInterval: secondInterval,
                            hour: hour,
                            minute: minute,
                            second: second,
                            isPM: isPM,
                            onHourChanged: onHourChanged,
                            onMinuteChanged: onMinuteChanged,
                            onSecondChanged: onSecondChanged,
                            onPeriodChanged: onPeriodChanged,
                            isDisabled: false,
                          ),
                        ),
                        Divider(height: 1, color: colors.border),
                        Padding(
                          padding: EdgeInsets.all(spacingExt.small),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AppButton(
                                text: '취소',
                                variant: AppButtonVariant.ghost,
                                size: AppButtonSize.small,
                                onPressed: onClose,
                              ),
                              SizedBox(width: spacingExt.small),
                              AppButton(
                                text: '확인',
                                variant: AppButtonVariant.primary,
                                size: AppButtonSize.small,
                                onPressed: onConfirm,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// TimePicker 컨텐츠 (내부용)
class _TimePickerContent extends StatelessWidget {
  final AppTimePickerFormat format;
  final AppTimePickerPrecision precision;
  final int minuteInterval;
  final int secondInterval;
  final int hour;
  final int minute;
  final int second;
  final bool isPM;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final ValueChanged<int> onSecondChanged;
  final ValueChanged<bool> onPeriodChanged;
  final bool isDisabled;

  const _TimePickerContent({
    required this.format,
    required this.precision,
    required this.minuteInterval,
    required this.secondInterval,
    required this.hour,
    required this.minute,
    required this.second,
    required this.isPM,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onSecondChanged,
    required this.onPeriodChanged,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final colors = TimePickerColors.standard(colorExt);

    final maxHour = format == AppTimePickerFormat.hour12 ? 12 : 23;
    final minHour = format == AppTimePickerFormat.hour12 ? 1 : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 시간
        _TimeSpinner(
          value: hour,
          minValue: minHour,
          maxValue: maxHour,
          onChanged: onHourChanged,
          isDisabled: isDisabled,
          colors: colors,
        ),

        // 구분자
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacingExt.small),
          child: Text(
            ':',
            style: textTheme.headlineMedium?.copyWith(
              color: colors.separator,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 분
        _TimeSpinner(
          value: minute,
          minValue: 0,
          maxValue: 59,
          interval: minuteInterval,
          onChanged: onMinuteChanged,
          isDisabled: isDisabled,
          colors: colors,
        ),

        // 초 (precision이 second일 때만)
        if (precision == AppTimePickerPrecision.second) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacingExt.small),
            child: Text(
              ':',
              style: textTheme.headlineMedium?.copyWith(
                color: colors.separator,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _TimeSpinner(
            value: second,
            minValue: 0,
            maxValue: 59,
            interval: secondInterval,
            onChanged: onSecondChanged,
            isDisabled: isDisabled,
            colors: colors,
          ),
        ],

        // AM/PM (12시간제일 때만)
        if (format == AppTimePickerFormat.hour12) ...[
          SizedBox(width: spacingExt.medium),
          _PeriodToggle(
            isPM: isPM,
            onChanged: onPeriodChanged,
            isDisabled: isDisabled,
            colors: colors,
          ),
        ],
      ],
    );
  }
}

/// 시간 스피너 위젯 (내부용)
class _TimeSpinner extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final int interval;
  final ValueChanged<int> onChanged;
  final bool isDisabled;
  final TimePickerColors colors;

  const _TimeSpinner({
    required this.value,
    required this.minValue,
    required this.maxValue,
    this.interval = 1,
    required this.onChanged,
    required this.isDisabled,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final spacingExt = context.appSpacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 위로 버튼
        GestureDetector(
          onTap: isDisabled
              ? null
              : () {
                  int newValue = value + interval;
                  if (newValue > maxValue) newValue = minValue;
                  onChanged(newValue);
                },
          child: Container(
            padding: EdgeInsets.all(spacingExt.xs),
            child: Icon(
              Icons.keyboard_arrow_up,
              color: isDisabled ? colors.spinnerText.withValues(alpha: 0.5) : colors.spinnerText,
            ),
          ),
        ),

        // 값 표시
        Container(
          width: 56,
          height: 48,
          decoration: BoxDecoration(
            color: colors.spinnerSelectedBackground,
            borderRadius: BorderTokens.smallRadius(),
          ),
          alignment: Alignment.center,
          child: Text(
            value.toString().padLeft(2, '0'),
            style: textTheme.headlineMedium?.copyWith(
              color: colors.spinnerSelectedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 아래로 버튼
        GestureDetector(
          onTap: isDisabled
              ? null
              : () {
                  int newValue = value - interval;
                  if (newValue < minValue) newValue = maxValue;
                  onChanged(newValue);
                },
          child: Container(
            padding: EdgeInsets.all(spacingExt.xs),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: isDisabled ? colors.spinnerText.withValues(alpha: 0.5) : colors.spinnerText,
            ),
          ),
        ),
      ],
    );
  }
}

/// AM/PM 토글 위젯 (내부용)
class _PeriodToggle extends StatelessWidget {
  final bool isPM;
  final ValueChanged<bool> onChanged;
  final bool isDisabled;
  final TimePickerColors colors;

  const _PeriodToggle({
    required this.isPM,
    required this.onChanged,
    required this.isDisabled,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.periodBackground,
        borderRadius: BorderTokens.smallRadius(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AM
          GestureDetector(
            onTap: isDisabled ? null : () => onChanged(false),
            child: AnimatedContainer(
              duration: AnimationTokens.durationQuick,
              width: 48,
              height: 36,
              decoration: BoxDecoration(
                color: !isPM ? colors.periodSelectedBackground : Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: BorderTokens.smallRadius().topLeft,
                  topRight: BorderTokens.smallRadius().topRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'AM',
                style: textTheme.bodySmall?.copyWith(
                  color: !isPM ? colors.periodSelectedText : colors.periodText,
                  fontWeight: !isPM ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
          // PM
          GestureDetector(
            onTap: isDisabled ? null : () => onChanged(true),
            child: AnimatedContainer(
              duration: AnimationTokens.durationQuick,
              width: 48,
              height: 36,
              decoration: BoxDecoration(
                color: isPM ? colors.periodSelectedBackground : Colors.transparent,
                borderRadius: BorderRadius.only(
                  bottomLeft: BorderTokens.smallRadius().bottomLeft,
                  bottomRight: BorderTokens.smallRadius().bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'PM',
                style: textTheme.bodySmall?.copyWith(
                  color: isPM ? colors.periodSelectedText : colors.periodText,
                  fontWeight: isPM ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
