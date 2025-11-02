import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../../../core/models/place_time_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snack_bar_helper.dart';
import '../../../../presentation/widgets/buttons/primary_button.dart';
import '../../../../presentation/widgets/buttons/neutral_outlined_button.dart';
import '../../../../presentation/widgets/weekly_calendar/time_grid_painter.dart';
import '../../../../presentation/widgets/weekly_calendar/highlight_painter.dart';
import '../../../../presentation/widgets/weekly_calendar/selection_painter.dart';

/// 에디터 모드 (운영시간 또는 브레이크 타임)
enum EditorMode {
  operatingHours,  // 운영시간 설정 (보라색)
  breakTime,       // 브레이크 타임 설정 (노란색)
}

/// 시간 블록 모델 (운영시간 또는 브레이크 타임)
class TimeBlock {
  final int day;       // 0 (월) ~ 6 (일)
  final int startSlot; // 15분 단위 (0 = 00:00, 96 = 24:00)
  final int endSlot;
  final Color color;
  final int? id;       // 서버 ID (브레이크 타임용, null이면 신규)

  TimeBlock({
    required this.day,
    required this.startSlot,
    required this.endSlot,
    required this.color,
    this.id,
  });

  /// 슬롯을 "HH:mm" 형식으로 변환
  static String slotToTimeString(int slot) {
    final hour = slot ~/ 4;
    final minute = (slot % 4) * 15;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// "HH:mm" 형식을 슬롯으로 변환
  static int timeStringToSlot(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 4 + (minute ~/ 15);
  }

  String get startTime => slotToTimeString(startSlot);
  String get endTime => slotToTimeString(endSlot);
}

/// 장소 운영시간 에디터
///
/// WeeklyScheduleEditor 기반으로 장소의 운영시간과 브레이크 타임을 설정합니다.
/// - 운영시간 모드: 요일별 1개 블록 (보라색)
/// - 브레이크 타임 모드: 요일별 N개 블록 (노란색)
class PlaceOperatingHoursEditor extends StatefulWidget {
  final int placeId;
  final List<OperatingHoursResponse> initialOperatingHours;
  final List<RestrictedTimeResponse> initialRestrictedTimes;
  final Future<bool> Function(List<OperatingHoursItem> operatingHours) onSaveOperatingHours;
  final Future<bool> Function(String dayOfWeek, String startTime, String endTime, String? reason) onAddRestrictedTime;
  final Future<bool> Function(int restrictedTimeId) onDeleteRestrictedTime;
  final VoidCallback? onSaveCompleted;
  final VoidCallback? onCancel;

  const PlaceOperatingHoursEditor({
    super.key,
    required this.placeId,
    required this.initialOperatingHours,
    required this.initialRestrictedTimes,
    required this.onSaveOperatingHours,
    required this.onAddRestrictedTime,
    required this.onDeleteRestrictedTime,
    this.onSaveCompleted,
    this.onCancel,
  });

  @override
  State<PlaceOperatingHoursEditor> createState() => _PlaceOperatingHoursEditorState();
}

class _PlaceOperatingHoursEditorState extends State<PlaceOperatingHoursEditor> {
  // Grid Geometry
  final double _timeColumnWidth = 50.0;
  final double _dayRowHeight = 50.0;
  final int _startHour = 0;
  final int _endHour = 24;
  final int _daysInWeek = 7;
  final double _minSlotHeight = 20.0;

  // State
  EditorMode _mode = EditorMode.operatingHours;
  Map<int, TimeBlock> _operatingHours = {};      // 요일별 1개
  Map<int, List<TimeBlock>> _breakTimes = {};    // 요일별 N개

  bool _isDirty = false;
  bool _isSaving = false;

  // Initial data (for rollback)
  late Map<int, TimeBlock> _initialOperatingHours;
  late Map<int, List<TimeBlock>> _initialBreakTimes;

  // Selection state
  bool _isSelecting = false;
  ({int day, int slot})? _startCell;
  ({int day, int slot})? _endCell;
  Rect? _selectionRect;
  Rect? _highlightRect;
  Offset? _activePointerGlobalPosition;

  // Scroll
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  static const double _edgeScrollThreshold = 50.0;
  static const double _scrollSpeed = 5.0;
  int _autoScrollDirection = 0;
  double _autoScrollDayColumnWidth = 0;

  double _currentDayColumnWidth = 0;
  double _currentContentHeight = 0;
  double _currentViewportHeight = 0;

  final GlobalKey _gestureContentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _parseInitialData();
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  /// 서버 데이터 파싱
  void _parseInitialData() {
    // 운영시간 파싱
    for (final oh in widget.initialOperatingHours) {
      if (oh.isClosed || oh.startTime == null || oh.endTime == null) continue;

      final day = _dayOfWeekToIndex(oh.dayOfWeek);
      if (day == -1) continue;

      _operatingHours[day] = TimeBlock(
        day: day,
        startSlot: TimeBlock.timeStringToSlot(oh.startTime!),
        endSlot: TimeBlock.timeStringToSlot(oh.endTime!),
        color: AppColors.brand.withOpacity(0.8),
      );
    }

    // 브레이크 타임 파싱
    for (final rt in widget.initialRestrictedTimes) {
      final day = _dayOfWeekToIndex(rt.dayOfWeek);
      if (day == -1) continue;

      _breakTimes.putIfAbsent(day, () => []);
      _breakTimes[day]!.add(TimeBlock(
        day: day,
        startSlot: TimeBlock.timeStringToSlot(rt.startTime),
        endSlot: TimeBlock.timeStringToSlot(rt.endTime),
        color: Colors.amber.withOpacity(0.8),
        id: rt.id,
      ));
    }

    // 초기 데이터 백업 (롤백용)
    _initialOperatingHours = Map.from(_operatingHours);
    _initialBreakTimes = Map.from(_breakTimes.map((k, v) => MapEntry(k, List.from(v))));
  }

  /// 요일 문자열을 인덱스로 변환
  int _dayOfWeekToIndex(String dayOfWeek) {
    const dayMap = {
      'MONDAY': 0,
      'TUESDAY': 1,
      'WEDNESDAY': 2,
      'THURSDAY': 3,
      'FRIDAY': 4,
      'SATURDAY': 5,
      'SUNDAY': 6,
    };
    return dayMap[dayOfWeek] ?? -1;
  }

  /// 인덱스를 요일 문자열로 변환
  String _indexToDayOfWeek(int index) {
    const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    return days[index];
  }

  // --- Auto-scroll ---

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollDirection = 0;
  }

  void _performAutoScrollTick() {
    if (!_scrollController.hasClients || _autoScrollDirection == 0) {
      _stopAutoScroll();
      return;
    }

    final double maxExtent = _scrollController.position.maxScrollExtent;
    final double targetOffset = (_scrollController.offset + _autoScrollDirection * _scrollSpeed)
        .clamp(0.0, maxExtent);

    if (targetOffset == _scrollController.offset) {
      _stopAutoScroll();
      return;
    }

    _scrollController.jumpTo(targetOffset);

    if (_activePointerGlobalPosition != null) {
      _updateSelectionFromPointer(
        _activePointerGlobalPosition!,
        _autoScrollDayColumnWidth,
        checkAutoScroll: false,
      );
    }
  }

  void _handleEdgeScrolling(Offset globalPosition, double dayColumnWidth) {
    if (!_scrollController.hasClients) return;
    if (_currentViewportHeight <= 0) return;

    final localPosition = _globalToGestureLocal(globalPosition);
    final scrollOffset = _scrollController.offset;
    final viewportY = localPosition.dy - scrollOffset;

    const double topThreshold = _edgeScrollThreshold;
    final double bottomThreshold = _currentViewportHeight - _edgeScrollThreshold;

    int direction = 0;

    if (viewportY <= topThreshold) {
      direction = -1;
    } else if (viewportY >= bottomThreshold) {
      direction = 1;
    }

    if (direction == 0) {
      _stopAutoScroll();
    } else {
      _autoScrollDirection = direction;
      _autoScrollDayColumnWidth = dayColumnWidth;
      _autoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
        _performAutoScrollTick();
      });
    }
  }

  // --- Haptic ---

  Future<void> _triggerHaptic() async {
    if (kIsWeb) return;

    try {
      HapticFeedback.mediumImpact();
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
        if (hasAmplitudeControl == false) {
          Vibration.vibrate(duration: 100);
        }
      }
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  // --- Coordinate Conversion ---

  RenderBox? get _gestureRenderBox =>
      _gestureContentKey.currentContext?.findRenderObject() as RenderBox?;

  Offset _globalToGestureLocal(Offset globalPosition) {
    final renderBox = _gestureRenderBox;
    if (renderBox == null) return Offset.zero;
    return renderBox.globalToLocal(globalPosition);
  }

  Offset _clampLocalToContent(Offset position, double dayColumnWidth) {
    final double maxWidth = math.max(
      _timeColumnWidth + dayColumnWidth * _daysInWeek,
      _timeColumnWidth + 1,
    );
    final double maxHeight = math.max(_currentContentHeight, 1.0);

    final double clampedX = position.dx.clamp(0.0, maxWidth);
    final double clampedY = position.dy.clamp(0.0, maxHeight - 1);
    return Offset(clampedX, clampedY);
  }

  ({int day, int slot}) _pixelToCell(Offset position, double dayColumnWidth) {
    final double slotHeight = _minSlotHeight;
    final int visibleSlots = (_endHour - _startHour) * 4;

    int day = ((position.dx - _timeColumnWidth) / dayColumnWidth).floor();
    day = day.clamp(0, _daysInWeek - 1);

    int slotOffset = (position.dy / slotHeight).floor();
    slotOffset = slotOffset.clamp(0, visibleSlots - 1);

    return (day: day, slot: slotOffset);
  }

  Rect _cellToRect(({int day, int slot}) start, ({int day, int slot}) end, double dayColumnWidth) {
    final double slotHeight = _minSlotHeight;

    final startDay = start.day < end.day ? start.day : end.day;
    final endDay = start.day > end.day ? start.day : end.day;
    final startSlot = start.slot < end.slot ? start.slot : end.slot;
    final endSlot = start.slot > end.slot ? start.slot : end.slot;

    return Rect.fromLTRB(
      _timeColumnWidth + startDay * dayColumnWidth,
      startSlot * slotHeight,
      _timeColumnWidth + (endDay + 1) * dayColumnWidth,
      (endSlot + 1) * slotHeight,
    );
  }

  // --- Selection Handlers ---

  void _updateSelectionCell(
    Offset position,
    double dayColumnWidth, {
    bool enableHaptics = false,
  }) {
    if (_startCell == null) return;

    final clampedPosition = _clampLocalToContent(position, dayColumnWidth);
    var currentCell = _pixelToCell(clampedPosition, dayColumnWidth);

    // 같은 요일 내에서만 선택
    currentCell = (day: _startCell!.day, slot: currentCell.slot);

    // 하프틱 피드백
    if (enableHaptics && _endCell != null && currentCell != _endCell) {
      _triggerHaptic();
    }

    // 역방향 선택 방지
    if (currentCell.slot < _startCell!.slot) {
      setState(() {
        _endCell = currentCell;
        _selectionRect = null;
        _highlightRect = _cellToRect(currentCell, currentCell, dayColumnWidth);
      });
    } else if (currentCell != _endCell) {
      setState(() {
        _endCell = currentCell;
        _selectionRect = _cellToRect(_startCell!, currentCell, dayColumnWidth);
        _highlightRect = _cellToRect(currentCell, currentCell, dayColumnWidth);
      });
    }
  }

  void _completeSelection() {
    final finalStartCell = _startCell;
    final finalEndCell = _endCell;

    _activePointerGlobalPosition = null;
    _stopAutoScroll();

    setState(() {
      _isSelecting = false;
      _startCell = null;
      _endCell = null;
      _selectionRect = null;
      _highlightRect = null;
    });

    if (finalStartCell != null && finalEndCell != null && finalEndCell.slot >= finalStartCell.slot) {
      _handleBlockCreation(finalStartCell, finalEndCell);
    }
  }

  /// 블록 생성 처리 (모드별로 분기)
  void _handleBlockCreation(({int day, int slot}) startCell, ({int day, int slot}) endCell) {
    if (_mode == EditorMode.operatingHours) {
      _handleOperatingHoursCreation(startCell, endCell);
    } else {
      _handleBreakTimeCreation(startCell, endCell);
    }
  }

  /// 운영시간 블록 생성 (요일별 1개 제약)
  void _handleOperatingHoursCreation(({int day, int slot}) startCell, ({int day, int slot}) endCell) {
    final day = startCell.day;

    // 기존 블록이 있으면 교체 확인 다이얼로그
    if (_operatingHours.containsKey(day)) {
      _showReplaceConfirmDialog(day, startCell, endCell);
    } else {
      _createOperatingHoursBlock(day, startCell, endCell);
    }
  }

  /// 운영시간 블록 생성
  void _createOperatingHoursBlock(int day, ({int day, int slot}) startCell, ({int day, int slot}) endCell) {
    setState(() {
      _operatingHours[day] = TimeBlock(
        day: day,
        startSlot: startCell.slot,
        endSlot: endCell.slot,
        color: AppColors.brand.withOpacity(0.8),
      );
      _isDirty = true;
    });
  }

  /// 브레이크 타임 블록 생성 (운영시간 내부만 허용, 겹침 방지)
  void _handleBreakTimeCreation(({int day, int slot}) startCell, ({int day, int slot}) endCell) {
    final day = startCell.day;

    // 1. 운영시간 블록이 있는지 확인
    if (!_operatingHours.containsKey(day)) {
      AppSnackBar.info(context, '운영시간이 설정되지 않은 요일입니다');
      return;
    }

    final operatingBlock = _operatingHours[day]!;

    // 2. 브레이크 타임이 운영시간 내부에 있는지 확인
    if (startCell.slot < operatingBlock.startSlot || endCell.slot > operatingBlock.endSlot) {
      AppSnackBar.info(context, '브레이크 타임은 운영시간 내에만 설정할 수 있습니다');
      return;
    }

    // 3. 기존 브레이크 타임과 겹침 확인
    if (_breakTimes.containsKey(day)) {
      for (final block in _breakTimes[day]!) {
        if (_isOverlapping(startCell.slot, endCell.slot, block.startSlot, block.endSlot)) {
          AppSnackBar.info(context, '이미 설정된 시간대입니다');
          return;
        }
      }
    }

    // 4. 브레이크 타임 생성
    setState(() {
      _breakTimes.putIfAbsent(day, () => []);
      _breakTimes[day]!.add(TimeBlock(
        day: day,
        startSlot: startCell.slot,
        endSlot: endCell.slot,
        color: Colors.amber.withOpacity(0.8),
      ));
      _isDirty = true;
    });
  }

  /// 시간 겹침 확인
  bool _isOverlapping(int start1, int end1, int start2, int end2) {
    return start1 <= end2 && end1 >= start2;
  }

  /// 교체 확인 다이얼로그
  void _showReplaceConfirmDialog(int day, ({int day, int slot}) startCell, ({int day, int slot}) endCell) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: Text('기존 운영시간 변경', style: AppTheme.headlineSmall),
        content: Text(
          '이 요일에 이미 운영시간이 설정되어 있습니다.\n기존 운영시간을 변경하시겠습니까?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          Flexible(
            child: NeutralOutlinedButton(
              text: '취소',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: PrimaryButton(
              text: '변경',
              onPressed: () {
                Navigator.of(context).pop();
                _createOperatingHoursBlock(day, startCell, endCell);
              },
              variant: PrimaryButtonVariant.brand,
            ),
          ),
        ],
      ),
    );
  }

  /// 블록 삭제 다이얼로그
  void _showDeleteConfirmDialog(TimeBlock block, bool isOperatingHours) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: Text('삭제 확인', style: AppTheme.headlineSmall),
        content: Text(
          '${isOperatingHours ? "운영시간" : "브레이크 타임"}을 삭제하시겠습니까?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          Flexible(
            child: NeutralOutlinedButton(
              text: '취소',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: PrimaryButton(
              text: '삭제',
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBlock(block, isOperatingHours);
              },
              variant: PrimaryButtonVariant.error,
            ),
          ),
        ],
      ),
    );
  }

  /// 블록 삭제
  void _deleteBlock(TimeBlock block, bool isOperatingHours) {
    setState(() {
      if (isOperatingHours) {
        _operatingHours.remove(block.day);
      } else {
        _breakTimes[block.day]?.removeWhere((b) => b.startSlot == block.startSlot && b.endSlot == block.endSlot);
      }
      _isDirty = true;
    });
  }

  // --- Tap Handlers ---

  void _handleTap(Offset position, double dayColumnWidth) {
    final clampedPosition = _clampLocalToContent(position, dayColumnWidth);
    final cell = _pixelToCell(clampedPosition, dayColumnWidth);

    // 블록 클릭 확인
    final tappedBlock = _findBlockAtCell(cell);
    if (tappedBlock != null) {
      final isOperatingHours = tappedBlock.$2;
      _showDeleteConfirmDialog(tappedBlock.$1, isOperatingHours);
      return;
    }

    // 새 블록 생성 시작
    if (!_isSelecting) {
      setState(() {
        _isSelecting = true;
        _startCell = _pixelToCell(clampedPosition, dayColumnWidth);
        _endCell = _startCell;
        _selectionRect = _cellToRect(_startCell!, _endCell!, dayColumnWidth);
      });
    } else {
      _completeSelection();
    }
  }

  void _handleLongPressStart(LongPressStartDetails details, double dayColumnWidth) {
    final localPosition =
        _clampLocalToContent(_globalToGestureLocal(details.globalPosition), dayColumnWidth);
    final cell = _pixelToCell(localPosition, dayColumnWidth);

    _triggerHaptic();
    _activePointerGlobalPosition = details.globalPosition;
    setState(() {
      _isSelecting = true;
      _startCell = cell;
      _endCell = _startCell;
      _selectionRect = _cellToRect(_startCell!, _endCell!, dayColumnWidth);
      _highlightRect = _cellToRect(cell, cell, dayColumnWidth);
    });
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _activePointerGlobalPosition = null;
    _stopAutoScroll();
  }

  void _updateSelectionFromPointer(
    Offset globalPosition,
    double dayColumnWidth, {
    bool checkAutoScroll = true,
  }) {
    if (_startCell == null) return;

    _activePointerGlobalPosition = globalPosition;
    final localPosition =
        _clampLocalToContent(_globalToGestureLocal(globalPosition), dayColumnWidth);

    _updateSelectionCell(
      localPosition,
      dayColumnWidth,
      enableHaptics: true,
    );

    if (checkAutoScroll) {
      _handleEdgeScrolling(globalPosition, dayColumnWidth);
    }
  }

  void _handleMobileTap(Offset globalPosition, double dayColumnWidth) {
    final localPosition =
        _clampLocalToContent(_globalToGestureLocal(globalPosition), dayColumnWidth);
    final cell = _pixelToCell(localPosition, dayColumnWidth);

    // 블록 클릭 확인
    final tappedBlock = _findBlockAtCell(cell);
    if (tappedBlock != null) {
      final isOperatingHours = tappedBlock.$2;
      _showDeleteConfirmDialog(tappedBlock.$1, isOperatingHours);
    }
  }

  /// 셀에 있는 블록 찾기 (운영시간 또는 브레이크 타임)
  /// Returns (TimeBlock, isOperatingHours)
  (TimeBlock, bool)? _findBlockAtCell(({int day, int slot}) cell) {
    final day = cell.day;

    // 운영시간 확인
    if (_operatingHours.containsKey(day)) {
      final block = _operatingHours[day]!;
      if (cell.slot >= block.startSlot && cell.slot <= block.endSlot) {
        return (block, true);
      }
    }

    // 브레이크 타임 확인
    if (_breakTimes.containsKey(day)) {
      for (final block in _breakTimes[day]!) {
        if (cell.slot >= block.startSlot && cell.slot <= block.endSlot) {
          return (block, false);
        }
      }
    }

    return null;
  }

  // --- Save/Cancel ---

  Future<void> _handleSave() async {
    if (!_isDirty) {
      AppSnackBar.info(context, '변경사항이 없습니다');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. 운영시간 저장 (전체 교체)
      final operatingHoursItems = _buildOperatingHoursItems();
      final saveSuccess = await widget.onSaveOperatingHours(operatingHoursItems);

      if (!saveSuccess) {
        if (!mounted) return;
        AppSnackBar.error(context, '운영시간 저장 실패');
        _rollback();
        return;
      }

      // 2. 브레이크 타임 저장 (추가/삭제)
      final breakTimeSuccess = await _saveBreakTimes();

      if (!breakTimeSuccess) {
        if (!mounted) return;
        AppSnackBar.error(context, '브레이크 타임 저장 실패');
        // 운영시간은 이미 저장됨, 롤백하지 않음
        return;
      }

      if (!mounted) return;
      AppSnackBar.success(context, '저장되었습니다');
      setState(() {
        _isDirty = false;
        _initialOperatingHours = Map.from(_operatingHours);
        _initialBreakTimes = Map.from(_breakTimes.map((k, v) => MapEntry(k, List.from(v))));
      });
      widget.onSaveCompleted?.call();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, '저장 실패: $e');
      _rollback();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 브레이크 타임 저장 (추가/삭제)
  Future<bool> _saveBreakTimes() async {
    try {
      // 1. 삭제할 브레이크 타임 찾기 (초기에 있었지만 현재 없는 것들)
      for (final entry in _initialBreakTimes.entries) {
        final day = entry.key;
        final initialBlocks = entry.value;

        for (final initialBlock in initialBlocks) {
          // ID가 있고 (서버에 저장된 것) + 현재 상태에 없으면 삭제
          if (initialBlock.id != null) {
            final stillExists = _breakTimes[day]?.any((b) =>
                b.startSlot == initialBlock.startSlot && b.endSlot == initialBlock.endSlot) ?? false;

            if (!stillExists) {
              final deleteSuccess = await widget.onDeleteRestrictedTime(initialBlock.id!);
              if (!deleteSuccess) {
                return false;
              }
            }
          }
        }
      }

      // 2. 추가할 브레이크 타임 찾기 (현재 있지만 초기에 없었던 것들)
      for (final entry in _breakTimes.entries) {
        final day = entry.key;
        final currentBlocks = entry.value;

        for (final currentBlock in currentBlocks) {
          // ID가 없으면 (신규) 추가
          if (currentBlock.id == null) {
            final dayOfWeek = _indexToDayOfWeek(day);
            final addSuccess = await widget.onAddRestrictedTime(
              dayOfWeek,
              currentBlock.startTime,
              currentBlock.endTime,
              null, // reason은 선택사항
            );

            if (!addSuccess) {
              return false;
            }
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error saving break times: $e');
      return false;
    }
  }

  /// 운영시간 아이템 빌드 (7일 전부)
  List<OperatingHoursItem> _buildOperatingHoursItems() {
    final items = <OperatingHoursItem>[];

    for (int day = 0; day < 7; day++) {
      final dayOfWeek = _indexToDayOfWeek(day);

      if (_operatingHours.containsKey(day)) {
        final block = _operatingHours[day]!;
        items.add(OperatingHoursItem(
          dayOfWeek: dayOfWeek,
          startTime: block.startTime,
          endTime: block.endTime,
          isClosed: false,
        ));
      } else {
        items.add(OperatingHoursItem(
          dayOfWeek: dayOfWeek,
          startTime: null,
          endTime: null,
          isClosed: true,
        ));
      }
    }

    return items;
  }

  void _rollback() {
    setState(() {
      _operatingHours = Map.from(_initialOperatingHours);
      _breakTimes = Map.from(_initialBreakTimes.map((k, v) => MapEntry(k, List.from(v))));
      _isDirty = false;
    });
  }

  void _handleCancel() {
    if (_isDirty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
          title: Text('취소 확인', style: AppTheme.headlineSmall),
          content: Text(
            '변경사항이 저장되지 않았습니다.\n취소하시겠습니까?',
            style: AppTheme.bodyMedium,
          ),
          actions: [
            Flexible(
              child: NeutralOutlinedButton(
                text: '돌아가기',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: PrimaryButton(
                text: '취소',
                onPressed: () {
                  Navigator.of(context).pop();
                  _rollback();
                  widget.onCancel?.call();
                },
                variant: PrimaryButtonVariant.error,
              ),
            ),
          ],
        ),
      );
    } else {
      widget.onCancel?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header: 모드 토글 버튼
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            border: Border(bottom: BorderSide(color: AppColors.lightOutline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '장소 운영시간 설정',
                  style: AppTheme.headlineSmall,
                ),
              ),
              SegmentedButton<EditorMode>(
                segments: const [
                  ButtonSegment(
                    value: EditorMode.operatingHours,
                    label: Text('운영시간'),
                    icon: Icon(Icons.schedule, size: 18),
                  ),
                  ButtonSegment(
                    value: EditorMode.breakTime,
                    label: Text('브레이크 타임'),
                    icon: Icon(Icons.free_breakfast, size: 18),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (Set<EditorMode> newSelection) {
                  setState(() {
                    _mode = newSelection.first;
                    _isSelecting = false;
                    _startCell = null;
                    _endCell = null;
                    _selectionRect = null;
                    _highlightRect = null;
                  });
                },
              ),
            ],
          ),
        ),

        // Mode indicator banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: _mode == EditorMode.operatingHours
              ? AppColors.brand.withOpacity(0.1)
              : Colors.amber.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                _mode == EditorMode.operatingHours ? Icons.schedule : Icons.free_breakfast,
                size: 18,
                color: _mode == EditorMode.operatingHours ? AppColors.brand : Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                _mode == EditorMode.operatingHours
                    ? '운영시간을 드래그하여 설정하세요 (요일별 1개)'
                    : '브레이크 타임을 드래그하여 설정하세요 (운영시간 내부만 가능)',
                style: AppTheme.bodySmall.copyWith(
                  color: _mode == EditorMode.operatingHours ? AppColors.brand : Colors.amber.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Calendar Grid
        Column(
          children: [
            // Day names header
            SizedBox(
              height: _dayRowHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, _dayRowHeight),
                    painter: TimeGridPainter(
                      startHour: _startHour,
                      endHour: _endHour,
                      timeColumnWidth: _timeColumnWidth,
                      weekStart: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
                      paintHeader: true,
                      paintGrid: false,
                    ),
                  );
                },
              ),
            ),

            // Full-size grid (no scroll)
            LayoutBuilder(
              builder: (context, constraints) {
                final double dayColumnWidth = (constraints.maxWidth - _timeColumnWidth) / _daysInWeek;
                final double contentHeight = (_endHour - _startHour) * 4 * _minSlotHeight;

                _currentDayColumnWidth = dayColumnWidth;
                _currentContentHeight = contentHeight;
                _currentViewportHeight = contentHeight; // 전체 크기 표시

                return SizedBox(
                  height: contentHeight,
                  child: kIsWeb
                      ? _buildWebGestureHandler(dayColumnWidth, contentHeight)
                      : _buildMobileGestureHandler(dayColumnWidth, contentHeight),
                );
              },
            ),
          ],
        ),

        // Footer: Save/Cancel buttons
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            border: Border(top: BorderSide(color: AppColors.lightOutline)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: NeutralOutlinedButton(
                  text: '취소',
                  onPressed: _isSaving ? null : _handleCancel,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: PrimaryButton(
                  text: _isSaving ? '저장 중...' : '저장',
                  onPressed: (_isSaving || !_isDirty) ? null : _handleSave,
                  variant: PrimaryButtonVariant.brand,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Gesture Handlers ---

  Widget _buildWebGestureHandler(double dayColumnWidth, double contentHeight) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (event) {
        if (_isSelecting) {
          _updateSelectionCell(event.localPosition, dayColumnWidth);
        } else {
          final currentCell = _pixelToCell(event.localPosition, dayColumnWidth);
          setState(() {
            _highlightRect = _cellToRect(currentCell, currentCell, dayColumnWidth);
          });
        }
      },
      onExit: (event) {
        setState(() {
          _highlightRect = null;
        });
      },
      child: GestureDetector(
        onTapDown: (details) {
          _handleTap(details.localPosition, dayColumnWidth);
        },
        behavior: HitTestBehavior.opaque,
        child: _buildCalendarStack(dayColumnWidth, contentHeight),
      ),
    );
  }

  Widget _buildMobileGestureHandler(double dayColumnWidth, double contentHeight) {
    return GestureDetector(
      key: _gestureContentKey,
      onTapDown: (details) {
        final localPosition =
            _clampLocalToContent(_globalToGestureLocal(details.globalPosition), dayColumnWidth);
        final touchedCell = _pixelToCell(localPosition, dayColumnWidth);

        setState(() {
          _highlightRect = _cellToRect(touchedCell, touchedCell, dayColumnWidth);
        });

        _handleMobileTap(details.globalPosition, dayColumnWidth);
      },
      onTapUp: (details) {
        if (!_isSelecting) {
          setState(() {
            _highlightRect = null;
          });
        }
      },
      onTapCancel: () {
        if (!_isSelecting) {
          setState(() {
            _highlightRect = null;
          });
        }
      },
      onLongPressStart: (details) {
        _handleLongPressStart(details, dayColumnWidth);
      },
      onLongPressMoveUpdate: (details) {
        if (_isSelecting) {
          _updateSelectionFromPointer(details.globalPosition, dayColumnWidth);
        }
      },
      onLongPressEnd: (details) {
        if (_isSelecting) {
          _triggerHaptic();
          _updateSelectionFromPointer(details.globalPosition, dayColumnWidth, checkAutoScroll: false);
          _completeSelection();
          _handleLongPressEnd(details);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: _buildCalendarStack(dayColumnWidth, contentHeight),
    );
  }

  Widget _buildCalendarStack(double dayColumnWidth, double contentHeight) {
    return SizedBox(
      height: contentHeight,
      child: Stack(
        children: [
          // 1. Grid lines
          Positioned.fill(
            child: CustomPaint(
              painter: TimeGridPainter(
                startHour: _startHour,
                endHour: _endHour,
                timeColumnWidth: _timeColumnWidth,
                weekStart: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
                paintHeader: false,
                paintGrid: true,
              ),
            ),
          ),

          // 2. Operating hours blocks
          ..._buildOperatingHoursBlocks(dayColumnWidth),

          // 3. Break time blocks
          ..._buildBreakTimeBlocks(dayColumnWidth),

          // 4. Highlight
          if (_highlightRect != null)
            Positioned.fill(
              child: CustomPaint(
                painter: HighlightPainter(highlightRect: _highlightRect),
              ),
            ),

          // 5. Selection
          if (_selectionRect != null)
            Positioned.fill(
              child: CustomPaint(
                painter: SelectionPainter(selection: _selectionRect),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildOperatingHoursBlocks(double dayColumnWidth) {
    final blocks = <Widget>[];

    for (final entry in _operatingHours.entries) {
      final block = entry.value;
      final rect = _cellToRect(
        (day: block.day, slot: block.startSlot),
        (day: block.day, slot: block.endSlot),
        dayColumnWidth,
      );

      blocks.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: Container(
            decoration: BoxDecoration(
              color: block.color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.brand, width: 1.5),
            ),
            padding: const EdgeInsets.all(4),
            child: Center(
              child: Text(
                '${block.startTime}\n-\n${block.endTime}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return blocks;
  }

  List<Widget> _buildBreakTimeBlocks(double dayColumnWidth) {
    final blocks = <Widget>[];

    for (final entry in _breakTimes.entries) {
      for (final block in entry.value) {
        final rect = _cellToRect(
          (day: block.day, slot: block.startSlot),
          (day: block.day, slot: block.endSlot),
          dayColumnWidth,
        );

        blocks.add(
          Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            child: Container(
              decoration: BoxDecoration(
                color: block.color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber, width: 1.5),
              ),
              padding: const EdgeInsets.all(4),
              child: Center(
                child: Text(
                  '${block.startTime}\n-\n${block.endTime}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return blocks;
  }
}
