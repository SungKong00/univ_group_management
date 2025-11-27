import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/date_picker_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/responsive_tokens.dart';
import 'app_button.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppDatePickerMode, AppDatePickerView;

/// 날짜 선택을 위한 DatePicker 컴포넌트
///
/// **용도**: 날짜 입력, 기간 선택, 일정 등록
/// **접근성**: 키보드 네비게이션, 스크린 리더 지원
///
/// ```dart
/// // 단일 날짜 선택
/// AppDatePicker(
///   selectedDate: _selectedDate,
///   onDateSelected: (date) => setState(() => _selectedDate = date),
/// )
///
/// // 범위 선택
/// AppDatePicker.range(
///   startDate: _startDate,
///   endDate: _endDate,
///   onRangeSelected: (start, end) => setState(() {
///     _startDate = start;
///     _endDate = end;
///   }),
/// )
///
/// // 인라인 캘린더
/// AppDatePicker.inline(
///   selectedDate: _selectedDate,
///   onDateSelected: (date) => setState(() => _selectedDate = date),
/// )
/// ```
class AppDatePicker extends StatefulWidget {
  /// 선택된 날짜 (단일 모드)
  final DateTime? selectedDate;

  /// 범위 시작 날짜
  final DateTime? startDate;

  /// 범위 끝 날짜
  final DateTime? endDate;

  /// 다중 선택된 날짜들
  final List<DateTime>? selectedDates;

  /// 날짜 선택 콜백 (단일 모드)
  final ValueChanged<DateTime>? onDateSelected;

  /// 범위 선택 콜백
  final void Function(DateTime? start, DateTime? end)? onRangeSelected;

  /// 다중 선택 콜백
  final ValueChanged<List<DateTime>>? onMultipleSelected;

  /// 선택 모드
  final AppDatePickerMode mode;

  /// 최소 선택 가능 날짜
  final DateTime? minDate;

  /// 최대 선택 가능 날짜
  final DateTime? maxDate;

  /// 비활성화할 날짜 목록
  final List<DateTime>? disabledDates;

  /// 비활성화할 요일 (1=월요일 ~ 7=일요일)
  final List<int>? disabledWeekdays;

  /// 초기 표시 월
  final DateTime? initialDisplayMonth;

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

  /// 첫 번째 요일 (1=월요일, 7=일요일)
  final int firstDayOfWeek;

  /// 날짜 포맷 함수
  final String Function(DateTime)? dateFormat;

  const AppDatePicker({
    super.key,
    this.selectedDate,
    this.startDate,
    this.endDate,
    this.selectedDates,
    this.onDateSelected,
    this.onRangeSelected,
    this.onMultipleSelected,
    this.mode = AppDatePickerMode.single,
    this.minDate,
    this.maxDate,
    this.disabledDates,
    this.disabledWeekdays,
    this.initialDisplayMonth,
    this.isInline = false,
    this.placeholder,
    this.label,
    this.helperText,
    this.errorText,
    this.isDisabled = false,
    this.firstDayOfWeek = 7, // 일요일 시작
    this.dateFormat,
  });

  /// 범위 선택 팩토리
  factory AppDatePicker.range({
    Key? key,
    DateTime? startDate,
    DateTime? endDate,
    void Function(DateTime? start, DateTime? end)? onRangeSelected,
    DateTime? minDate,
    DateTime? maxDate,
    bool isInline = false,
    String? placeholder,
    String? label,
    bool isDisabled = false,
  }) {
    return AppDatePicker(
      key: key,
      startDate: startDate,
      endDate: endDate,
      onRangeSelected: onRangeSelected,
      mode: AppDatePickerMode.range,
      minDate: minDate,
      maxDate: maxDate,
      isInline: isInline,
      placeholder: placeholder ?? '시작일 ~ 종료일',
      label: label,
      isDisabled: isDisabled,
    );
  }

  /// 인라인 캘린더 팩토리
  factory AppDatePicker.inline({
    Key? key,
    DateTime? selectedDate,
    ValueChanged<DateTime>? onDateSelected,
    DateTime? minDate,
    DateTime? maxDate,
    bool isDisabled = false,
  }) {
    return AppDatePicker(
      key: key,
      selectedDate: selectedDate,
      onDateSelected: onDateSelected,
      minDate: minDate,
      maxDate: maxDate,
      isInline: true,
      isDisabled: isDisabled,
    );
  }

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  late DateTime _displayMonth;
  AppDatePickerView _currentView = AppDatePickerView.day;
  bool _isOpen = false;
  DateTime? _hoverDate;

  // 범위 선택 임시 상태
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _displayMonth = widget.initialDisplayMonth ??
        widget.selectedDate ??
        widget.startDate ??
        DateTime.now();
    _tempStartDate = widget.startDate;
    _tempEndDate = widget.endDate;
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
      builder: (context) => _DatePickerOverlay(
        link: _layerLink,
        displayMonth: _displayMonth,
        currentView: _currentView,
        mode: widget.mode,
        selectedDate: widget.selectedDate,
        startDate: _tempStartDate,
        endDate: _tempEndDate,
        selectedDates: widget.selectedDates,
        minDate: widget.minDate,
        maxDate: widget.maxDate,
        disabledDates: widget.disabledDates,
        disabledWeekdays: widget.disabledWeekdays,
        firstDayOfWeek: widget.firstDayOfWeek,
        hoverDate: _hoverDate,
        onDateTap: _handleDateTap,
        onDateHover: (date) => setState(() => _hoverDate = date),
        onMonthChange: (month) => setState(() => _displayMonth = month),
        onViewChange: (view) => setState(() => _currentView = view),
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

  void _handleDateTap(DateTime date) {
    switch (widget.mode) {
      case AppDatePickerMode.single:
        widget.onDateSelected?.call(date);
        _removeOverlay();
        setState(() => _isOpen = false);
        break;

      case AppDatePickerMode.range:
        if (_tempStartDate == null || _tempEndDate != null) {
          setState(() {
            _tempStartDate = date;
            _tempEndDate = null;
          });
        } else {
          final start = date.isBefore(_tempStartDate!) ? date : _tempStartDate!;
          final end = date.isBefore(_tempStartDate!) ? _tempStartDate! : date;
          setState(() {
            _tempStartDate = start;
            _tempEndDate = end;
          });
        }
        break;

      case AppDatePickerMode.multiple:
        final dates = List<DateTime>.from(widget.selectedDates ?? []);
        final exists = dates.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
        if (exists) {
          dates.removeWhere((d) =>
              d.year == date.year && d.month == date.month && d.day == date.day);
        } else {
          dates.add(date);
        }
        widget.onMultipleSelected?.call(dates);
        break;
    }
  }

  void _handleConfirm() {
    if (widget.mode == AppDatePickerMode.range) {
      widget.onRangeSelected?.call(_tempStartDate, _tempEndDate);
    }
    _removeOverlay();
    setState(() => _isOpen = false);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    if (widget.dateFormat != null) return widget.dateFormat!(date);
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _getDisplayText() {
    switch (widget.mode) {
      case AppDatePickerMode.single:
        return widget.selectedDate != null
            ? _formatDate(widget.selectedDate)
            : (widget.placeholder ?? '날짜 선택');
      case AppDatePickerMode.range:
        if (widget.startDate != null && widget.endDate != null) {
          return '${_formatDate(widget.startDate)} ~ ${_formatDate(widget.endDate)}';
        }
        return widget.placeholder ?? '기간 선택';
      case AppDatePickerMode.multiple:
        final count = widget.selectedDates?.length ?? 0;
        return count > 0 ? '$count개 선택됨' : (widget.placeholder ?? '날짜 선택');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInline) {
      return _DatePickerCalendar(
        displayMonth: _displayMonth,
        currentView: _currentView,
        mode: widget.mode,
        selectedDate: widget.selectedDate,
        startDate: widget.startDate,
        endDate: widget.endDate,
        selectedDates: widget.selectedDates,
        minDate: widget.minDate,
        maxDate: widget.maxDate,
        disabledDates: widget.disabledDates,
        disabledWeekdays: widget.disabledWeekdays,
        firstDayOfWeek: widget.firstDayOfWeek,
        hoverDate: _hoverDate,
        onDateTap: _handleDateTap,
        onDateHover: (date) => setState(() => _hoverDate = date),
        onMonthChange: (month) => setState(() => _displayMonth = month),
        onViewChange: (view) => setState(() => _currentView = view),
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
                    Icons.calendar_today_outlined,
                    size: ResponsiveTokens.iconSize(width),
                    color: widget.isDisabled
                        ? colorExt.textQuaternary
                        : colorExt.textTertiary,
                  ),
                  SizedBox(width: spacingExt.small),
                  Expanded(
                    child: Text(
                      _getDisplayText(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: widget.selectedDate != null ||
                                widget.startDate != null ||
                                (widget.selectedDates?.isNotEmpty ?? false)
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

/// DatePicker 오버레이 (내부용)
class _DatePickerOverlay extends StatelessWidget {
  final LayerLink link;
  final DateTime displayMonth;
  final AppDatePickerView currentView;
  final AppDatePickerMode mode;
  final DateTime? selectedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<DateTime>? selectedDates;
  final DateTime? minDate;
  final DateTime? maxDate;
  final List<DateTime>? disabledDates;
  final List<int>? disabledWeekdays;
  final int firstDayOfWeek;
  final DateTime? hoverDate;
  final ValueChanged<DateTime> onDateTap;
  final ValueChanged<DateTime?> onDateHover;
  final ValueChanged<DateTime> onMonthChange;
  final ValueChanged<AppDatePickerView> onViewChange;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  const _DatePickerOverlay({
    required this.link,
    required this.displayMonth,
    required this.currentView,
    required this.mode,
    required this.selectedDate,
    required this.startDate,
    required this.endDate,
    required this.selectedDates,
    required this.minDate,
    required this.maxDate,
    required this.disabledDates,
    required this.disabledWeekdays,
    required this.firstDayOfWeek,
    required this.hoverDate,
    required this.onDateTap,
    required this.onDateHover,
    required this.onMonthChange,
    required this.onViewChange,
    required this.onClose,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final width = MediaQuery.sizeOf(context).width;
    final colors = DatePickerColors.standard(colorExt);

    final calendarWidth = switch (ResponsiveTokens.getScreenSize(width)) {
      ScreenSize.xs => width - spacingExt.large,
      ScreenSize.sm => 320.0,
      ScreenSize.md => 340.0,
      ScreenSize.lg => 360.0,
      ScreenSize.xl => 380.0,
    };

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClose,
      child: Stack(
        children: [
          Positioned(
            width: calendarWidth,
            child: CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              offset: Offset(0, spacingExt.xs),
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {}, // Prevent close on calendar tap
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
                        _DatePickerCalendar(
                          displayMonth: displayMonth,
                          currentView: currentView,
                          mode: mode,
                          selectedDate: selectedDate,
                          startDate: startDate,
                          endDate: endDate,
                          selectedDates: selectedDates,
                          minDate: minDate,
                          maxDate: maxDate,
                          disabledDates: disabledDates,
                          disabledWeekdays: disabledWeekdays,
                          firstDayOfWeek: firstDayOfWeek,
                          hoverDate: hoverDate,
                          onDateTap: onDateTap,
                          onDateHover: onDateHover,
                          onMonthChange: onMonthChange,
                          onViewChange: onViewChange,
                          isDisabled: false,
                        ),
                        if (mode == AppDatePickerMode.range) ...[
                          Divider(height: 1, color: colors.footerDivider),
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

/// DatePicker 캘린더 본체 (내부용)
class _DatePickerCalendar extends StatelessWidget {
  final DateTime displayMonth;
  final AppDatePickerView currentView;
  final AppDatePickerMode mode;
  final DateTime? selectedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<DateTime>? selectedDates;
  final DateTime? minDate;
  final DateTime? maxDate;
  final List<DateTime>? disabledDates;
  final List<int>? disabledWeekdays;
  final int firstDayOfWeek;
  final DateTime? hoverDate;
  final ValueChanged<DateTime> onDateTap;
  final ValueChanged<DateTime?> onDateHover;
  final ValueChanged<DateTime> onMonthChange;
  final ValueChanged<AppDatePickerView> onViewChange;
  final bool isDisabled;

  const _DatePickerCalendar({
    required this.displayMonth,
    required this.currentView,
    required this.mode,
    required this.selectedDate,
    required this.startDate,
    required this.endDate,
    required this.selectedDates,
    required this.minDate,
    required this.maxDate,
    required this.disabledDates,
    required this.disabledWeekdays,
    required this.firstDayOfWeek,
    required this.hoverDate,
    required this.onDateTap,
    required this.onDateHover,
    required this.onMonthChange,
    required this.onViewChange,
    required this.isDisabled,
  });

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];
  static const _months = [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월'
  ];

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final colors = DatePickerColors.standard(colorExt);

    return Padding(
      padding: EdgeInsets.all(spacingExt.medium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          _buildHeader(context, colors, spacingExt, textTheme),
          SizedBox(height: spacingExt.medium),

          // 본문
          switch (currentView) {
            AppDatePickerView.day => _buildDayView(context, colors, spacingExt, textTheme),
            AppDatePickerView.month => _buildMonthView(context, colors, spacingExt, textTheme),
            AppDatePickerView.year => _buildYearView(context, colors, spacingExt, textTheme),
          },
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DatePickerColors colors,
    AppSpacingExtension spacingExt,
    TextTheme textTheme,
  ) {
    final width = MediaQuery.sizeOf(context).width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 이전 버튼
        IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: colors.navigationArrow,
            size: ResponsiveTokens.iconSize(width),
          ),
          onPressed: isDisabled ? null : () => _navigatePrevious(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),

        // 월/년 선택
        GestureDetector(
          onTap: isDisabled
              ? null
              : () {
                  onViewChange(
                    currentView == AppDatePickerView.day
                        ? AppDatePickerView.month
                        : currentView == AppDatePickerView.month
                            ? AppDatePickerView.year
                            : AppDatePickerView.day,
                  );
                },
          child: Text(
            switch (currentView) {
              AppDatePickerView.day => '${displayMonth.year}년 ${_months[displayMonth.month - 1]}',
              AppDatePickerView.month => '${displayMonth.year}년',
              AppDatePickerView.year => '${(displayMonth.year ~/ 10) * 10} - ${(displayMonth.year ~/ 10) * 10 + 9}',
            },
            style: textTheme.titleSmall?.copyWith(
              color: colors.headerText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 다음 버튼
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: colors.navigationArrow,
            size: ResponsiveTokens.iconSize(width),
          ),
          onPressed: isDisabled ? null : () => _navigateNext(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _navigatePrevious() {
    switch (currentView) {
      case AppDatePickerView.day:
        onMonthChange(DateTime(displayMonth.year, displayMonth.month - 1));
        break;
      case AppDatePickerView.month:
        onMonthChange(DateTime(displayMonth.year - 1, displayMonth.month));
        break;
      case AppDatePickerView.year:
        onMonthChange(DateTime(displayMonth.year - 10, displayMonth.month));
        break;
    }
  }

  void _navigateNext() {
    switch (currentView) {
      case AppDatePickerView.day:
        onMonthChange(DateTime(displayMonth.year, displayMonth.month + 1));
        break;
      case AppDatePickerView.month:
        onMonthChange(DateTime(displayMonth.year + 1, displayMonth.month));
        break;
      case AppDatePickerView.year:
        onMonthChange(DateTime(displayMonth.year + 10, displayMonth.month));
        break;
    }
  }

  Widget _buildDayView(
    BuildContext context,
    DatePickerColors colors,
    AppSpacingExtension spacingExt,
    TextTheme textTheme,
  ) {
    // 요일 헤더 순서 조정
    final orderedWeekdays = <String>[];
    for (int i = 0; i < 7; i++) {
      orderedWeekdays.add(_weekdays[(firstDayOfWeek - 1 + i) % 7]);
    }

    // 달력 날짜 계산
    final firstOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final lastOfMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0);
    final daysInMonth = lastOfMonth.day;

    // 첫 날의 요일 (firstDayOfWeek 기준)
    int startWeekday = firstOfMonth.weekday; // 1=월 ~ 7=일
    if (firstDayOfWeek == 7) {
      // 일요일 시작
      startWeekday = startWeekday % 7;
    } else {
      startWeekday = (startWeekday - firstDayOfWeek + 7) % 7;
    }

    final today = DateTime.now();
    final cells = <Widget>[];

    // 빈 셀 (이전 달)
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    // 날짜 셀
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(displayMonth.year, displayMonth.month, day);
      final isToday =
          date.year == today.year && date.month == today.month && date.day == today.day;
      final isSelected = _isDateSelected(date);
      final isInRange = _isDateInRange(date);
      final isRangeStart = _isRangeStart(date);
      final isRangeEnd = _isRangeEnd(date);
      final isDisabledDate = _isDateDisabled(date);

      cells.add(
        _DayCell(
          date: date,
          isToday: isToday,
          isSelected: isSelected,
          isInRange: isInRange,
          isRangeStart: isRangeStart,
          isRangeEnd: isRangeEnd,
          isDisabled: isDisabled || isDisabledDate,
          colors: colors,
          onTap: () => onDateTap(date),
          onHover: (hovering) => onDateHover(hovering ? date : null),
        ),
      );
    }

    return Column(
      children: [
        // 요일 헤더
        Row(
          children: orderedWeekdays
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.weekdayText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: spacingExt.small),
        // 날짜 그리드
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: cells,
        ),
      ],
    );
  }

  Widget _buildMonthView(
    BuildContext context,
    DatePickerColors colors,
    AppSpacingExtension spacingExt,
    TextTheme textTheme,
  ) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      mainAxisSpacing: spacingExt.small,
      crossAxisSpacing: spacingExt.small,
      children: List.generate(12, (index) {
        final month = index + 1;
        final isSelected = selectedDate?.month == month && selectedDate?.year == displayMonth.year;

        return GestureDetector(
          onTap: isDisabled
              ? null
              : () {
                  onMonthChange(DateTime(displayMonth.year, month));
                  onViewChange(AppDatePickerView.day);
                },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? colors.selectedBackground : colors.hoverBackground.withValues(alpha: 0),
              borderRadius: BorderTokens.smallRadius(),
            ),
            alignment: Alignment.center,
            child: Text(
              _months[index],
              style: textTheme.bodyMedium?.copyWith(
                color: isSelected ? colors.selectedText : colors.dayText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildYearView(
    BuildContext context,
    DatePickerColors colors,
    AppSpacingExtension spacingExt,
    TextTheme textTheme,
  ) {
    final startYear = (displayMonth.year ~/ 10) * 10;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      mainAxisSpacing: spacingExt.small,
      crossAxisSpacing: spacingExt.small,
      children: List.generate(12, (index) {
        final year = startYear + index - 1;
        final isSelected = selectedDate?.year == year;
        final isOutOfRange = index == 0 || index == 11;

        return GestureDetector(
          onTap: isDisabled
              ? null
              : () {
                  onMonthChange(DateTime(year, displayMonth.month));
                  onViewChange(AppDatePickerView.month);
                },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? colors.selectedBackground : colors.hoverBackground.withValues(alpha: 0),
              borderRadius: BorderTokens.smallRadius(),
            ),
            alignment: Alignment.center,
            child: Text(
              year.toString(),
              style: textTheme.bodyMedium?.copyWith(
                color: isOutOfRange
                    ? colors.dayTextDisabled
                    : isSelected
                        ? colors.selectedText
                        : colors.dayText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  bool _isDateSelected(DateTime date) {
    if (mode == AppDatePickerMode.single) {
      return selectedDate?.year == date.year &&
          selectedDate?.month == date.month &&
          selectedDate?.day == date.day;
    }
    if (mode == AppDatePickerMode.range) {
      return _isRangeStart(date) || _isRangeEnd(date);
    }
    if (mode == AppDatePickerMode.multiple) {
      return selectedDates?.any((d) =>
              d.year == date.year && d.month == date.month && d.day == date.day) ??
          false;
    }
    return false;
  }

  bool _isDateInRange(DateTime date) {
    if (mode != AppDatePickerMode.range) return false;
    if (startDate == null) return false;
    final end = endDate ?? hoverDate;
    if (end == null) return false;

    final effectiveStart = startDate!.isBefore(end) ? startDate! : end;
    final effectiveEnd = startDate!.isBefore(end) ? end : startDate!;

    return date.isAfter(effectiveStart) && date.isBefore(effectiveEnd);
  }

  bool _isRangeStart(DateTime date) {
    if (mode != AppDatePickerMode.range || startDate == null) return false;
    return startDate!.year == date.year &&
        startDate!.month == date.month &&
        startDate!.day == date.day;
  }

  bool _isRangeEnd(DateTime date) {
    if (mode != AppDatePickerMode.range || endDate == null) return false;
    return endDate!.year == date.year &&
        endDate!.month == date.month &&
        endDate!.day == date.day;
  }

  bool _isDateDisabled(DateTime date) {
    if (minDate != null && date.isBefore(minDate!)) return true;
    if (maxDate != null && date.isAfter(maxDate!)) return true;
    if (disabledWeekdays?.contains(date.weekday) ?? false) return true;
    if (disabledDates?.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day) ??
        false) {
      return true;
    }
    return false;
  }
}

/// 날짜 셀 위젯 (내부용)
class _DayCell extends StatefulWidget {
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool isInRange;
  final bool isRangeStart;
  final bool isRangeEnd;
  final bool isDisabled;
  final DatePickerColors colors;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.isInRange,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.isDisabled,
    required this.colors,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isSelected
        ? widget.colors.selectedBackground
        : widget.isInRange
            ? widget.colors.rangeBackground
            : _isHovered && !widget.isDisabled
                ? widget.colors.hoverBackground
                : Colors.transparent;

    final textColor = widget.isDisabled
        ? widget.colors.dayTextDisabled
        : widget.isSelected
            ? widget.colors.selectedText
            : widget.isToday
                ? widget.colors.todayText
                : widget.colors.dayText;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHover(false);
      },
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: widget.isToday && !widget.isSelected
                ? Border.all(
                    color: widget.colors.todayBorder,
                    width: BorderTokens.widthThin,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.date.day.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: widget.isSelected || widget.isToday
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
