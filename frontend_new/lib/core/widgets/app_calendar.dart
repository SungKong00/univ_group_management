import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/calendar_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppCalendarView, AppCalendarStyle;

/// 캘린더 컴포넌트
///
/// **용도**: 일정 선택, 이벤트 표시, 날짜 탐색
/// **접근성**: 키보드 네비게이션 지원
///
/// ```dart
/// // 기본 사용
/// AppCalendar(
///   selectedDate: DateTime.now(),
///   onDateSelected: (date) => print(date),
/// )
///
/// // 이벤트 표시
/// AppCalendar(
///   events: {
///     DateTime(2024, 1, 15): [Event('Meeting')],
///     DateTime(2024, 1, 20): [Event('Birthday')],
///   },
///   onDateSelected: (date) => print(date),
/// )
/// ```
class AppCalendar extends StatefulWidget {
  /// 선택된 날짜
  final DateTime? selectedDate;

  /// 선택 가능한 시작 날짜
  final DateTime? firstDate;

  /// 선택 가능한 끝 날짜
  final DateTime? lastDate;

  /// 날짜 선택 콜백
  final ValueChanged<DateTime>? onDateSelected;

  /// 월 변경 콜백
  final ValueChanged<DateTime>? onMonthChanged;

  /// 이벤트 맵 (날짜 -> 이벤트 리스트)
  final Map<DateTime, List<dynamic>>? events;

  /// 뷰 타입
  final AppCalendarView view;

  /// 스타일
  final AppCalendarStyle style;

  /// 주 시작 요일 (1 = 월요일, 7 = 일요일)
  final int firstDayOfWeek;

  /// 오늘 강조 표시
  final bool highlightToday;

  /// 날짜 비활성화 로직
  final bool Function(DateTime)? disabledDatePredicate;

  const AppCalendar({
    super.key,
    this.selectedDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.onMonthChanged,
    this.events,
    this.view = AppCalendarView.month,
    this.style = AppCalendarStyle.standard,
    this.firstDayOfWeek = 7, // 일요일
    this.highlightToday = true,
    this.disabledDatePredicate,
  });

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _focusedMonth = widget.selectedDate ?? DateTime.now();
  }

  @override
  void didUpdateWidget(AppCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _selectedDate = widget.selectedDate;
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    widget.onMonthChanged?.call(_focusedMonth);
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    widget.onMonthChanged?.call(_focusedMonth);
  }

  void _selectDate(DateTime date) {
    if (_isDisabled(date)) return;
    setState(() {
      _selectedDate = date;
    });
    widget.onDateSelected?.call(date);
  }

  bool _isDisabled(DateTime date) {
    if (widget.disabledDatePredicate?.call(date) == true) return true;
    if (widget.firstDate != null && date.isBefore(widget.firstDate!)) {
      return true;
    }
    if (widget.lastDate != null && date.isAfter(widget.lastDate!)) return true;
    return false;
  }

  bool _hasEvents(DateTime date) {
    if (widget.events == null) return false;
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return widget.events!.containsKey(normalizedDate) &&
        widget.events![normalizedDate]!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = CalendarColors.from(colorExt);

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: colors.border,
          width: BorderTokens.widthThin,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CalendarHeader(
            focusedMonth: _focusedMonth,
            colors: colors,
            style: widget.style,
            onPreviousMonth: _goToPreviousMonth,
            onNextMonth: _goToNextMonth,
          ),
          _CalendarGrid(
            focusedMonth: _focusedMonth,
            selectedDate: _selectedDate,
            colors: colors,
            style: widget.style,
            firstDayOfWeek: widget.firstDayOfWeek,
            highlightToday: widget.highlightToday,
            hasEvents: _hasEvents,
            isDisabled: _isDisabled,
            onDateSelected: _selectDate,
          ),
        ],
      ),
    );
  }
}

/// 캘린더 헤더
class _CalendarHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final CalendarColors colors;
  final AppCalendarStyle style;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _CalendarHeader({
    required this.focusedMonth,
    required this.colors,
    required this.style,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  String get _monthYearText {
    const months = [
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월',
    ];
    return '${focusedMonth.year}년 ${months[focusedMonth.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;
    final isCompact = style == AppCalendarStyle.compact ||
        style == AppCalendarStyle.mini;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacingExt.medium,
        vertical: isCompact ? spacingExt.small : spacingExt.medium,
      ),
      decoration: BoxDecoration(
        color: colors.headerBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BorderTokens.radiusMedium),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: Icons.chevron_left,
            onPressed: onPreviousMonth,
            colors: colors,
          ),
          Text(
            _monthYearText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.headerText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          _NavButton(
            icon: Icons.chevron_right,
            onPressed: onNextMonth,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

/// 네비게이션 버튼
class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final CalendarColors colors;

  const _NavButton({
    required this.icon,
    required this.onPressed,
    required this.colors,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered ? widget.colors.hoverBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
          ),
          child: Icon(
            widget.icon,
            size: ComponentSizeTokens.iconMedium,
            color: widget.colors.headerText,
          ),
        ),
      ),
    );
  }
}

/// 캘린더 그리드
class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final CalendarColors colors;
  final AppCalendarStyle style;
  final int firstDayOfWeek;
  final bool highlightToday;
  final bool Function(DateTime) hasEvents;
  final bool Function(DateTime) isDisabled;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.colors,
    required this.style,
    required this.firstDayOfWeek,
    required this.highlightToday,
    required this.hasEvents,
    required this.isDisabled,
    required this.onDateSelected,
  });

  List<String> get _weekdayLabels {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    final result = <String>[];
    for (var i = 0; i < 7; i++) {
      result.add(labels[(firstDayOfWeek - 1 + i) % 7]);
    }
    return result;
  }

  List<DateTime?> get _calendarDays {
    final firstOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastOfMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);

    // 첫 번째 주의 시작 요일 계산
    var startWeekday = firstOfMonth.weekday % 7;
    if (firstDayOfWeek == 1) {
      // 월요일 시작
      startWeekday = (firstOfMonth.weekday - 1) % 7;
    }

    final days = <DateTime?>[];

    // 이전 달의 빈 칸
    for (var i = 0; i < startWeekday; i++) {
      days.add(null);
    }

    // 현재 달의 날짜들
    for (var i = 1; i <= lastOfMonth.day; i++) {
      days.add(DateTime(focusedMonth.year, focusedMonth.month, i));
    }

    // 다음 달의 빈 칸 (6주 완성)
    while (days.length < 42) {
      days.add(null);
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;
    final isCompact = style == AppCalendarStyle.compact ||
        style == AppCalendarStyle.mini;
    final cellSize = isCompact ? 32.0 : 40.0;

    return Padding(
      padding: EdgeInsets.all(spacingExt.small),
      child: Column(
        children: [
          // 요일 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekdayLabels.map((label) {
              return SizedBox(
                width: cellSize,
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.weekdayText,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: spacingExt.small),
          // 날짜 그리드
          ...List.generate(6, (weekIndex) {
            final weekDays = _calendarDays.sublist(weekIndex * 7, (weekIndex + 1) * 7);
            return Padding(
              padding: EdgeInsets.only(bottom: spacingExt.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekDays.map((date) {
                  if (date == null) {
                    return SizedBox(width: cellSize, height: cellSize);
                  }
                  return _DayCell(
                    date: date,
                    colors: colors,
                    size: cellSize,
                    isSelected: selectedDate != null &&
                        date.year == selectedDate!.year &&
                        date.month == selectedDate!.month &&
                        date.day == selectedDate!.day,
                    isToday: highlightToday && _isToday(date),
                    isDisabled: isDisabled(date),
                    hasEvent: hasEvents(date),
                    onTap: () => onDateSelected(date),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// 날짜 셀
class _DayCell extends StatefulWidget {
  final DateTime date;
  final CalendarColors colors;
  final double size;
  final bool isSelected;
  final bool isToday;
  final bool isDisabled;
  final bool hasEvent;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.colors,
    required this.size,
    required this.isSelected,
    required this.isToday,
    required this.isDisabled,
    required this.hasEvent,
    required this.onTap,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _isHovered = false;

  Color get _backgroundColor {
    if (widget.isSelected) return widget.colors.selectedBackground;
    if (widget.isToday) return widget.colors.todayBackground;
    if (_isHovered && !widget.isDisabled) return widget.colors.hoverBackground;
    return Colors.transparent;
  }

  Color get _textColor {
    if (widget.isDisabled) return widget.colors.disabledText;
    if (widget.isSelected) return widget.colors.selectedText;
    if (widget.isToday) return widget.colors.todayText;
    return widget.colors.dayText;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${widget.date.day}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _textColor,
                      fontWeight: widget.isToday || widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
              ),
              if (widget.hasEvent)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? widget.colors.selectedText
                          : widget.colors.eventDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
