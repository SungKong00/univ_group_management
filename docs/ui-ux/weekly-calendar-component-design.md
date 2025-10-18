# 주간 뷰 캘린더 UI 컴포넌트 설계

> **작성일**: 2025-10-17
> **최종 수정**: 2025-10-17
> **상태**: 설계 확정 (논의사항 11개 모두 결정 완료)
> **관련 문서**: [디자인 시스템](concepts/design-system.md), [캘린더 시스템](../concepts/calendar-system.md), [장소 캘린더 명세](../features/place-calendar-specification.md)

## 📌 주요 결정사항 요약

| 항목 | 결정 내용 |
|------|----------|
| **드래그 스크롤** | 자동 스크롤 + 마우스 휠 병행 |
| **간격 모드** | 15분 모드만 우선 구현 (5분은 Phase 3 이후) |
| **렌더링** | 하이브리드 (Canvas 그리드 + Widget 일정) |
| **히트맵 색상** | 투명도 기반 (1개: 0.7, 겹칠수록 진해짐) |
| **겹침 표시** | 크기 기반 (≥44px: 텍스트, <44px: 도트) |
| **일정 입력** | 드래그 후 모달 표시 |
| **충돌 방지** | 유연 모드 (경고 표시, 추가 허용) |
| **운영시간** | 단일 시간대 + 차단시간 (Phase 2 리팩터링) |
| **모바일 핸들** | 12x60px, 오른쪽 돌출 (가장자리는 왼쪽) |
| **핸들 스냅** | 실시간 스냅 (15분 단위) + 햅틱 피드백 |
| **플랫폼 분기** | 화면 크기 (<600px) + 플랫폼 (iOS/Android) |

## 📋 목차

1. [개요](#개요)
2. [컴포넌트 구조](#컴포넌트-구조)
3. [기술적 구현 방법](#기술적-구현-방법)
4. [상태 관리 전략](#상태-관리-전략)
5. [성능 고려사항](#성능-고려사항)
6. [접근성 이슈](#접근성-이슈)
7. [논의사항 및 모호한 점](#논의사항-및-모호한-점)
8. [개선 아이디어](#개선-아이디어)

---

## 개요

### 목적
주간 단위 타임라인에서 직관적인 드래그 앤 드롭으로 일정을 생성/편집하고, 여러 대상(사용자/그룹/장소)의 일정을 한눈에 비교할 수 있는 통합 캘린더 UI 컴포넌트 설계

### 사용처
- **PlaceAvailability 운영시간 설정** (현재 TimePicker 다이얼로그 대체)
- **개인/그룹 일정 추가**
- **최적 시간 추천 시각화**
- **장소 예약 시간 선택**

### 기존 구현 분석
- `CalendarWeekGridView<T>`: 주간 타임라인 뷰 이미 구현됨
  - 시간 범위: 동적 계산 (기본 9-18시)
  - 30분 슬롯 × 44px 높이
  - 종일 일정 별도 영역
  - 제네릭 구조로 재사용 가능
- **개선 필요**: 읽기 전용 → 편집 가능 모드 추가

---

## 컴포넌트 구조

### 1. WeeklyScheduleEditor (주간 뷰 일정 편집 컴포넌트)

#### 1.1 핵심 기능

**데스크톱 플로우**:
```
[ 일정 추가 모드 ] 버튼
  ↓ (모드 진입)
타임라인이 15분(또는 5분) 간격으로 분할
  ↓
마우스 호버 → 셀 하이라이트
  ↓
드래그 앤 드롭으로 시간 범위 선택
  1. 셀 클릭 (시작점)
  2. 마우스 드래그 → 아래로 늘어나는 셀 생성 (잔상 표시)
  3. 화면 바깥 → 마우스 휠 스크롤로 더 아래 시간 선택 가능
  4. 원하는 위치에서 마우스 릴리즈 → 셀 고정
  ↓
일정 정보 입력 모달/다이얼로그 표시
```

**모바일 플로우** (터치 최적화):
```
[ 일정 추가 모드 ] 버튼
  ↓ (모드 진입)
타임라인이 15분(또는 5분) 간격으로 분할
  ↓
셀 탭 → 30분 기본 일정 블록 생성
  ↓
시작/끝 부분에 핸들 표시 (옆으로 튀어나온 막대)
  - 상단 핸들: 시작 시간 조정용
  - 하단 핸들: 종료 시간 조정용
  - 핸들 크기: 최소 44x44px 터치 영역 보장
  ↓
핸들 드래그로 시간 범위 조정
  - 위/아래로 드래그하여 시간 밀고 당기기
  - 15분/5분 단위 스냅 (Snap-to-grid)
  ↓
"확인" 버튼 탭 → 일정 확정
  ↓
일정 정보 입력 모달/다이얼로그 표시
```

#### 1.2 UI 구조
```dart
WeeklyScheduleEditor(
  mode: ScheduleEditorMode.create, // create | edit
  slotInterval: Duration(minutes: 15), // 15분 또는 5분
  timeRange: (start: 6, end: 24),
  existingEvents: [...], // 사용자가 직접 생성/편집하는 일정
  
  // 외부에서 주입되는 읽기 전용 그룹 일정
  externalEvents: List<GroupEvent>?, 
  weekStart: DateTime?, // 외부 일정 필터링 기준
  groupColors: Map<int, Color>?, // 그룹별 색상
  
  onEventCreated: (TimeRange range) {
    // 모달 열어서 제목, 설명 등 입력받기
  },
  onEventUpdated: (id, TimeRange range) {},
)
```

**외부 일정 처리 로직**:
- `externalEvents`로 `GroupEvent` 리스트가 전달되면, `weekStart`를 기준으로 현재 주에 해당하는 일정만 필터링합니다.
- 필터링된 `GroupEvent`는 내부 `Event` 모델로 변환되어 캘린더에 렌더링됩니다.
- 이 과정에서 `groupColors` 맵을 참조하여 각 그룹 일정에 맞는 색상을 적용합니다.
- 외부 일정은 **읽기 전용**으로 취급되며, 클릭 시 상세 정보 다이얼로그가 표시되지만 수정/삭제는 불가능합니다.
- 다이얼로그에는 "(그룹 일정 - 읽기 전용)"과 같은 문구를 표시하여 사용자가 명확히 인지할 수 있도록 합니다.

#### 1.3 시각적 상태
| 상태 | 색상 | 설명 |
|------|------|------|
| **기본 셀** | `neutral100` 배경, `neutral300` 보더 | 비활성 |
| **호버 셀** | `brand.withOpacity(0.08)` 배경 | 마우스 오버 (데스크톱) |
| **드래그 중** | `brand.withOpacity(0.2)` 배경, `brand` 보더 2px | 선택 범위 잔상 |
| **고정됨** | `brand.withOpacity(0.88)` 배경, `white` 텍스트 | 확정된 이벤트 |
| **겹침 방지** | `error.withOpacity(0.1)` 배경, 클릭 불가 | 기존 일정과 충돌 |
| **핸들 (모바일)** | `brand` 배경, 8px 너비 막대 | 시간 조정 핸들 |
| **핸들 드래그 중** | `brandStrong` 배경, 그림자 효과 | 활성 핸들 |

#### 1.4 드래그 중 스크롤 처리
```dart
// Drag gesture detector
onPanUpdate: (details) {
  // 1. 현재 마우스 위치 → 셀 인덱스 계산
  // 2. 화면 하단 영역(50px) 진입 시 자동 스크롤 트리거
  if (details.localPosition.dy > viewportHeight - 50) {
    _scrollController.animateTo(
      _scrollController.offset + 10,
      duration: Duration(milliseconds: 50),
      curve: Curves.linear,
    );
  }
  // 3. 마우스 휠 이벤트 감지하여 수동 스크롤 허용
}
```

#### 1.5 설계 원칙

이 컴포넌트는 다양한 사용 상황(PlaceAvailability 설정, 개인 일정 추가, 그룹 일정 추가, 장소 예약 등)에서 재사용됩니다. 따라서 **확장 가능한 기본 동작 우선** 원칙을 따릅니다.

**핵심 원칙**:

1. **YAGNI (You Aren't Gonna Need It)**
   - 핵심 기능만 먼저 구현 (드래그, 셀 선택, 일정 생성)
   - 고급 기능은 실제 요구사항 발생 시 추가
   - 예: 반복 일정, 스마트 추천 → Phase 3 이후

2. **Open/Closed Principle**
   - 확장에 열려있고, 수정에 닫혀있는 구조
   - 콜백 패턴으로 외부에서 동작 커스터마이징
   ```dart
   WeeklyScheduleEditor(
     // 확장 포인트: 셀 선택 가능 여부 판단
     canSelectSlot: (DateTime start, DateTime end) {
       // 사용처마다 다른 로직 주입 가능
       // 예: PlaceAvailability → 중첩 허용
       //     그룹 일정 → 기존 일정과 충돌 방지
       return myCustomValidation(start, end);
     },

     // 확장 포인트: 일정 생성 후 처리
     onEventCreated: (TimeRange range) async {
       // 사용처마다 다른 후처리
       // 예: PlaceAvailability → API 호출
       //     개인 일정 → 로컬 Provider 업데이트
     },
   )
   ```

3. **제네릭 타입 활용**
   ```dart
   class WeeklyScheduleEditor<T extends CalendarEventBase> {
     final List<T> existingEvents;
     final Future<T> Function(TimeRange) createEvent;

     // T 타입을 통해 다양한 이벤트 타입 지원
     // - PlaceAvailability
     // - PersonalSchedule
     // - GroupEvent
     // - PlaceReservation
   }
   ```

4. **컴포넌트 조합 (Composition over Inheritance)**
   - 작은 재사용 가능한 위젯들의 조합
   ```dart
   WeeklyScheduleEditor(
     grid: TimeGridWidget(),           // 시간 그리드만 담당
     eventRenderer: EventCardWidget(), // 이벤트 렌더링만 담당
     dragHandler: DragGestureHandler(), // 드래그 로직만 담당
   )
   ```

---

### 2. WeeklyScheduleViewer (주간 뷰 통합 조회 컴포넌트)

#### 2.1 핵심 기능
```
상단: 대상 추가/제거 칩 (사용자, 그룹, 장소)
  ↓
날짜 네비게이션 (< 이전 주 | 현재 주 | 다음 주 >)
  ↓
히트맵 스타일 일정 표시
  - 1개 일정: 제목 표시
  - 2개 이상 겹침: 진한 색 + "n개의 일정" 표시
  ↓
셀 클릭 → 해당 시간대의 모든 일정 세부정보 모달/팝업
```

#### 2.2 UI 구조
```dart
WeeklyScheduleViewer<T>(
  targets: [
    ScheduleTarget(type: 'user', id: 'user1', name: '홍길동', color: Colors.blue),
    ScheduleTarget(type: 'place', id: 'place1', name: 'AI랩실', color: Colors.green),
  ],
  events: [...],
  onEventTap: (List<T> events) {
    // 겹친 일정 리스트를 팝업/바텀시트로 표시
  },
)
```

#### 2.3 히트맵 로직
```dart
// 각 셀(30분 슬롯)에 대한 일정 개수 계산
Map<CellKey, List<Event>> _buildHeatmap() {
  final heatmap = <CellKey, List<Event>>{};

  for (final event in events) {
    for (final slot in event.overlappingSlots) {
      heatmap.putIfAbsent(slot, () => []).add(event);
    }
  }

  return heatmap;
}

// 셀 렌더링
Widget _buildCell(CellKey key, List<Event> events) {
  if (events.isEmpty) return EmptyCell();
  if (events.length == 1) return SingleEventCell(events.first);

  // 2개 이상 겹침
  return OverlappedCell(
    count: events.length,
    color: _blendColors(events.map((e) => e.color).toList()),
    label: '${events.length}개의 일정',
  );
}
```

#### 2.4 색상 블렌딩 전략
```dart
Color _blendColors(List<Color> colors) {
  // 옵션 1: 평균값 계산
  final avgR = colors.map((c) => c.red).reduce((a, b) => a + b) ~/ colors.length;
  final avgG = colors.map((c) => c.green).reduce((a, b) => a + b) ~/ colors.length;
  final avgB = colors.map((c) => c.blue).reduce((a, b) => a + b) ~/ colors.length;
  return Color.fromARGB(255, avgR, avgG, avgB).withOpacity(0.7);

  // 옵션 2: 가장 진한 색 선택 (우선순위 높은 일정)
  // return colors.reduce((a, b) => a.computeLuminance() < b.computeLuminance() ? a : b);
}
```

---

### 3. HybridWeeklyCalendar (하이브리드 컴포넌트)

#### 3.1 통합 조회 + 편집 모드
```dart
HybridWeeklyCalendar(
  mode: CalendarMode.view, // view | edit
  targets: [...], // 조회 대상
  existingEvents: [...],
  onModeSwitch: () {
    // 조회 모드 ↔ 편집 모드 전환
  },
  onEventCreate: (range) {
    // 편집 모드에서 일정 추가
  },
)
```

#### 3.2 편집 모드 제약
```dart
// 편집 모드 진입 시
// 1. 기존 일정과 겹치지 않는 시간만 선택 가능
bool _canSelectSlot(CellKey key) {
  final overlappingEvents = _heatmap[key] ?? [];
  return overlappingEvents.isEmpty;
}

// 2. 시각적 피드백
Widget _buildEditableCell(CellKey key) {
  if (!_canSelectSlot(key)) {
    return DisabledCell(
      color: AppColors.error.withOpacity(0.1),
      tooltip: '이미 일정이 있는 시간대입니다',
    );
  }

  return SelectableCell(/* ... */);
}
```

---

## 기술적 구현 방법

### 1. 드래그 앤 드롭 핵심 로직

```dart
class _WeeklyScheduleEditorState extends State<WeeklyScheduleEditor> {
  // 드래그 상태
  int? _dragStartSlot;
  int? _dragEndSlot;
  int? _dragDayColumn;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        final slot = _calculateSlotFromPosition(details.localPosition);
        setState(() {
          _dragStartSlot = slot.slotIndex;
          _dragDayColumn = slot.dayColumn;
        });
      },

      onPanUpdate: (details) {
        final slot = _calculateSlotFromPosition(details.localPosition);

        // 같은 날짜 컬럼 내에서만 드래그 허용
        if (slot.dayColumn != _dragDayColumn) return;

        setState(() {
          _dragEndSlot = slot.slotIndex;
        });

        // 화면 하단 진입 시 자동 스크롤
        _handleEdgeScroll(details.localPosition);
      },

      onPanEnd: (details) {
        if (_dragStartSlot != null && _dragEndSlot != null) {
          _showEventInputDialog(
            startSlot: min(_dragStartSlot!, _dragEndSlot!),
            endSlot: max(_dragStartSlot!, _dragEndSlot!),
            dayColumn: _dragDayColumn!,
          );
        }

        setState(() {
          _dragStartSlot = null;
          _dragEndSlot = null;
          _dragDayColumn = null;
        });
      },

      child: _buildGrid(),
    );
  }

  SlotPosition _calculateSlotFromPosition(Offset position) {
    final dayColumn = ((position.dx - _timeColumnWidth) / _dayColumnWidth).floor();
    final slotIndex = (position.dy / _slotHeight).floor();
    return SlotPosition(dayColumn: dayColumn, slotIndex: slotIndex);
  }

  void _handleEdgeScroll(Offset position) {
    const edgeThreshold = 50.0;
    final viewportHeight = MediaQuery.of(context).size.height;

    if (position.dy > viewportHeight - edgeThreshold) {
      _scrollController.animateTo(
        _scrollController.offset + 10,
        duration: Duration(milliseconds: 50),
        curve: Curves.linear,
      );
    }
  }
}
```

### 2. 간격 조정 (15분 vs 5분 모드)

```dart
enum SlotInterval {
  fifteen(Duration(minutes: 15)),
  five(Duration(minutes: 5));

  const SlotInterval(this.duration);
  final Duration duration;
}

class WeeklyScheduleEditor extends StatelessWidget {
  final SlotInterval slotInterval;

  double get _slotHeight {
    switch (slotInterval) {
      case SlotInterval.fifteen:
        return 44.0; // 기존과 동일
      case SlotInterval.five:
        return 20.0; // 더 작은 셀
    }
  }

  Widget _buildModeToggle() {
    return SegmentedButton<SlotInterval>(
      segments: [
        ButtonSegment(value: SlotInterval.fifteen, label: Text('15분')),
        ButtonSegment(value: SlotInterval.five, label: Text('5분')),
      ],
      selected: {slotInterval},
      onSelectionChanged: (Set<SlotInterval> newSelection) {
        // 상태 업데이트
      },
    );
  }
}
```

### 3. 캘린더 기반 클래스 재사용

```dart
// 기존 CalendarWeekGridView를 확장
class EditableWeekGridView<T extends CalendarEventBase>
    extends CalendarWeekGridView<T> {

  final bool editMode;
  final Function(TimeRange)? onRangeSelected;

  @override
  Widget _buildDayColumn(...) {
    if (!editMode) {
      return super._buildDayColumn(...); // 기존 읽기 전용
    }

    // 편집 모드: GestureDetector 래핑
    return GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: super._buildDayColumn(...),
    );
  }
}
```

### 4. 모바일 핸들 드래그 구현

```dart
class _MobileScheduleEditorState extends State<MobileScheduleEditor> {
  TimeRange? _selectedRange;
  bool _isDraggingStartHandle = false;
  bool _isDraggingEndHandle = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 타임라인 그리드
        _buildGrid(),

        // 선택된 일정 블록 + 핸들
        if (_selectedRange != null)
          _buildSelectedBlock(_selectedRange!),
      ],
    );
  }

  Widget _buildSelectedBlock(TimeRange range) {
    return Positioned(
      top: _calculateTopPosition(range.start),
      left: _dayColumnX,
      width: _dayColumnWidth,
      height: _calculateHeight(range.duration),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.brand.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.brand, width: 2),
        ),
        child: Stack(
          children: [
            // 상단 핸들 (시작 시간 조정)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _selectedRange = _adjustStartTime(
                      range,
                      details.delta.dy,
                    );
                  });
                },
                child: Container(
                  height: 44, // 터치 영역
                  alignment: Alignment.center,
                  child: Container(
                    height: 8, // 시각적 막대 높이
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // 하단 핸들 (종료 시간 조정)
            Positioned(
              bottom: -8,
              left: 0,
              right: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _selectedRange = _adjustEndTime(
                      range,
                      details.delta.dy,
                    );
                  });
                },
                child: Container(
                  height: 44, // 터치 영역
                  alignment: Alignment.center,
                  child: Container(
                    height: 8, // 시각적 막대 높이
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // 확인 버튼
            Positioned(
              bottom: 8,
              right: 8,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  minimumSize: Size(60, 36),
                ),
                onPressed: () {
                  widget.onEventCreated?.call(_selectedRange!);
                  setState(() => _selectedRange = null);
                },
                child: Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TimeRange _adjustStartTime(TimeRange range, double deltaY) {
    // 1. deltaY를 시간 변화량으로 변환
    final slotHeight = widget.slotInterval == SlotInterval.fifteen ? 44.0 : 20.0;
    final slotsChanged = (deltaY / slotHeight).round();

    // 2. 스냅: 15분 또는 5분 단위로 정렬
    final newStart = range.start.add(
      Duration(minutes: slotsChanged * widget.slotInterval.duration.inMinutes),
    );

    // 3. 최소 길이 보장 (15분 이상)
    if (newStart.isBefore(range.end.subtract(Duration(minutes: 15)))) {
      return TimeRange(start: newStart, end: range.end);
    }

    return range; // 변경 불가
  }

  TimeRange _adjustEndTime(TimeRange range, double deltaY) {
    final slotHeight = widget.slotInterval == SlotInterval.fifteen ? 44.0 : 20.0;
    final slotsChanged = (deltaY / slotHeight).round();

    final newEnd = range.end.add(
      Duration(minutes: slotsChanged * widget.slotInterval.duration.inMinutes),
    );

    // 최소 길이 보장
    if (newEnd.isAfter(range.start.add(Duration(minutes: 15)))) {
      return TimeRange(start: range.start, end: newEnd);
    }

    return range;
  }

  void _onCellTap(DateTime startTime) {
    // 셀 탭 → 30분 기본 블록 생성
    setState(() {
      _selectedRange = TimeRange(
        start: startTime,
        end: startTime.add(Duration(minutes: 30)),
      );
    });

    // 햅틱 피드백 (모바일)
    HapticFeedback.mediumImpact();
  }
}
```

---

## 상태 관리 전략

### 1. Provider 구조

```dart
// 편집 상태 Provider
final scheduleEditorProvider = StateNotifierProvider.autoDispose
    .family<ScheduleEditorNotifier, ScheduleEditorState, ScheduleEditorParams>(
  (ref, params) => ScheduleEditorNotifier(params),
);

class ScheduleEditorState {
  final SlotInterval interval;
  final bool isEditMode;
  final DragState? dragState;
  final List<TimeSlot> selectedSlots;

  ScheduleEditorState({
    this.interval = SlotInterval.fifteen,
    this.isEditMode = false,
    this.dragState,
    this.selectedSlots = const [],
  });
}

class DragState {
  final int startSlot;
  final int? currentSlot;
  final int dayColumn;

  DragState({
    required this.startSlot,
    this.currentSlot,
    required this.dayColumn,
  });

  TimeRange? get timeRange {
    if (currentSlot == null) return null;
    return TimeRange(
      start: min(startSlot, currentSlot!),
      end: max(startSlot, currentSlot!),
    );
  }
}
```

### 2. 통합 조회 상태

```dart
// 히트맵 데이터 Provider
final scheduleHeatmapProvider = Provider.autoDispose
    .family<Map<CellKey, List<CalendarEvent>>, HeatmapParams>(
  (ref, params) {
    final events = <CalendarEvent>[];

    // 각 대상별로 일정 수집
    for (final target in params.targets) {
      final targetEvents = ref.watch(
        eventsProvider(target.type, target.id)
      );
      events.addAll(targetEvents);
    }

    // 히트맵 생성
    return _buildHeatmap(events);
  },
);

// 셀 클릭 시 일정 목록 Provider
final cellEventsProvider = Provider.autoDispose
    .family<List<CalendarEvent>, CellKey>(
  (ref, cellKey) {
    final heatmap = ref.watch(scheduleHeatmapProvider(/* params */));
    return heatmap[cellKey] ?? [];
  },
);
```

### 3. 메모리 최적화

```dart
// autoDispose 활용
final weeklyScheduleProvider = StateNotifierProvider.autoDispose
    .family<WeeklyScheduleNotifier, WeeklyScheduleState, DateTime>(
  (ref, weekStart) {
    final notifier = WeeklyScheduleNotifier(weekStart);

    // 컴포넌트 dispose 시 자동으로 상태 정리
    ref.onDispose(() {
      notifier.dispose();
    });

    return notifier;
  },
);
```

---

## 성능 고려사항

### 1. 렌더링 최적화

#### 문제점
- 7일 × 18시간 × (60/15)분 = **504개 셀** 동시 렌더링
- 드래그 중 초당 60프레임 업데이트 → 과부하 위험

#### 해결 방안

**A. Lazy Rendering (뷰포트 기반)**
```dart
// CustomScrollView + SliverList 활용
SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) => _buildTimeSlot(index),
    childCount: totalSlots,
  ),
)

// 뷰포트 내 셀만 렌더링
// 스크롤 시 동적으로 위젯 생성/파괴
```

**B. RepaintBoundary 분리**
```dart
Widget _buildDayColumn(...) {
  return RepaintBoundary(
    child: Column(
      children: slots.map((slot) =>
        RepaintBoundary(child: _buildSlot(slot))
      ).toList(),
    ),
  );
}

// 각 날짜 컬럼을 독립적인 Paint Layer로 분리
// 드래그 중 변경된 컬럼만 리페인트
```

**C. Canvas 기반 커스텀 페인터**
```dart
class WeekGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 격자선 한 번에 그리기
    for (int i = 0; i < totalSlots; i++) {
      canvas.drawLine(/* ... */);
    }

    // 이벤트 블록 그리기
    for (final event in events) {
      canvas.drawRRect(/* ... */);
    }
  }

  @override
  bool shouldRepaint(WeekGridPainter oldDelegate) {
    return events != oldDelegate.events;
  }
}

// 위젯 트리 깊이 감소 → 빌드 속도 향상
```

### 2. 드래그 성능

```dart
// Throttle: 드래그 이벤트 처리 빈도 제한
Timer? _dragUpdateTimer;

onPanUpdate: (details) {
  _dragUpdateTimer?.cancel();
  _dragUpdateTimer = Timer(Duration(milliseconds: 16), () {
    // 60fps 기준 약 16ms마다 한 번씩만 업데이트
    _handleDragUpdate(details);
  });
}
```

### 3. 히트맵 계산 최적화

```dart
// 메모이제이션: 동일 입력에 대해 결과 캐싱
final _heatmapCache = <String, Map<CellKey, List<Event>>>{};

Map<CellKey, List<Event>> _buildHeatmap(List<Event> events) {
  final cacheKey = events.map((e) => e.id).join(',');

  if (_heatmapCache.containsKey(cacheKey)) {
    return _heatmapCache[cacheKey]!;
  }

  final heatmap = <CellKey, List<Event>>{};
  // ... 계산 로직

  _heatmapCache[cacheKey] = heatmap;
  return heatmap;
}
```

---

## 접근성 이슈

### 1. 키보드 네비게이션

```dart
// Focus traversal order
FocusScope(
  child: Column(
    children: [
      // 1. 모드 전환 버튼
      Focus(
        autofocus: true,
        child: ModeToggleButton(),
      ),

      // 2. 날짜 네비게이션
      Focus(
        child: DateNavigator(),
      ),

      // 3. 타임라인 셀 (방향키로 이동)
      GridView.builder(
        itemBuilder: (context, index) {
          return Focus(
            onKey: (node, event) {
              if (event is RawKeyDownEvent) {
                // 방향키 처리
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  // 다음 슬롯으로 이동
                }
                // ...
              }
              return KeyEventResult.handled;
            },
            child: TimeSlotCell(index),
          );
        },
      ),
    ],
  ),
)
```

### 2. 스크린 리더 지원

```dart
Semantics(
  label: '${day.displayName} ${_formatTime(slot.startTime)}부터 ${_formatTime(slot.endTime)}까지',
  hint: events.isEmpty
      ? '비어있음. 탭하여 일정 추가'
      : '${events.length}개의 일정 있음. 탭하여 확인',
  child: TimeSlotCell(/* ... */),
)
```

### 3. 드래그 대안 (터치/키보드)

```dart
// 옵션 1: 시작/종료 시간 별도 선택
Widget _buildAccessibleTimeSelector() {
  return Column(
    children: [
      // 시작 시간 선택
      DropdownButton<TimeOfDay>(
        items: _generateTimeSlots(),
        onChanged: (time) => setState(() => _startTime = time),
      ),

      // 종료 시간 선택
      DropdownButton<TimeOfDay>(
        items: _generateTimeSlots(),
        onChanged: (time) => setState(() => _endTime = time),
      ),
    ],
  );
}

// 옵션 2: 길게 누르기 → 컨텍스트 메뉴
onLongPress: () {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('일정 추가'),
      content: _buildAccessibleTimeSelector(),
    ),
  );
}
```

---

## 논의사항 및 모호한 점

### 1. 기술적 구현

#### Q1. 드래그 중 스크롤 방식 ✅ **결정됨**
- **결정**: 두 방식 병행
  - 자동 스크롤 (Edge Detection): 화면 하단 50px 진입 시 자동 스크롤
  - 마우스 휠 스크롤: `Listener` 위젯으로 `PointerScrollEvent` 감지

**구현 예시**:
```dart
Listener(
  onPointerSignal: (event) {
    if (event is PointerScrollEvent && _isDragging) {
      _scrollController.jumpTo(
        _scrollController.offset + event.scrollDelta.dy,
      );
    }
  },
  child: GestureDetector(/* ... */),
)
```

#### Q2. 간격 모드 ✅ **결정됨**
- **결정**: 15분 모드만 우선 구현
  - MVP에서는 15분 단위만 지원
  - 5분 모드는 Phase 3 이후 추가 (사용자 피드백 후)
- **이유**: 구현 단순화, 대부분의 사용 케이스 커버 (PlaceAvailability, 일정 추가)

#### Q3. Canvas vs Widget Tree ✅ **결정됨**
- **결정**: 하이브리드 접근 (Canvas + Widget Tree)
  ```dart
  Stack(
    children: [
      CustomPaint(  // 배경 그리드 (Canvas) - 성능 최적화
        painter: TimeGridPainter(),
      ),
      Positioned.fill(
        child: GestureDetector( // 선택 드래그 처리
          onPanStart: _onStart,
          onPanUpdate: _onDrag,
          onPanEnd: _onEnd,
          child: CustomPaint( // 선택 영역 오버레이 (Canvas) - 빠른 리페인트
            painter: SelectionPainter(selectedRange),
          ),
        ),
      ),
      ...eventWidgets, // 실제 일정 위젯들 (Widget Tree) - 복잡한 인터랙션
    ],
  )
  ```
- **장점**:
  - **Canvas**: 정적 그리드, 선택 오버레이 → 60fps 보장
  - **Widget Tree**: 일정 카드 → 탭, 롱프레스 등 제스처 처리 용이
  - 최적의 성능과 개발 편의성 균형

### 2. UX/디자인

#### Q4. 히트맵 색상 블렌딩 방식 ✅ **결정됨**
- **결정**: 투명도 기반 깊이 시각화
  - **1개 일정**: 기본 색상 (`color.withOpacity(0.7)`)
  - **2개 이상**: 투명도 증가 (`color.withOpacity(0.7 + (count - 1) * 0.1)`)
  - **최대 투명도**: 0.95 (완전 불투명에 가깝게)
  ```dart
  Color _getHeatmapColor(List<Event> events) {
    if (events.isEmpty) return Colors.transparent;
    if (events.length == 1) return events.first.color.withOpacity(0.7);

    // 가장 연한 기본색 → 겹칠수록 진해짐
    final baseColor = AppColors.brand; // 또는 혼합 색상
    final opacity = min(0.95, 0.7 + (events.length - 1) * 0.1);
    return baseColor.withOpacity(opacity);
  }
  ```
- **장점**: 겹침 정도를 직관적으로 인식, 구현 간단

#### Q5. 겹친 일정 표시 방식 ✅ **결정됨**
- **결정**: 셀 크기 기반 적응형 표시
  - **충분한 공간** (높이 ≥ 44px): "n개의 일정" 텍스트 표시
  - **작은 공간** (높이 < 44px, 예: 5분 겹침): 도트 인디케이터로 대체
  ```dart
  Widget _buildOverlapIndicator(int count, double cellHeight) {
    if (cellHeight >= 44) {
      // 텍스트 표시
      return Text('$count개의 일정', style: AppTheme.bodySmall);
    } else {
      // 도트 표시
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          min(count, 3), // 최대 3개 도트
          (index) => Container(
            width: 6,
            height: 6,
            margin: EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
  }
  ```
- **장점**: 공간 활용 최적화, 작은 겹침도 시각적으로 표현

#### Q6. 일정 입력 모달 vs 인라인 편집 ✅ **결정됨**
- **결정**: 드래그 후 모달 표시
- **플로우**: 시간 선택 → 모달 열림 → 제목/설명 입력 → 저장
- **이유**: 플로우 명확성, 집중도 향상, 검증 로직 중앙화

### 3. 비즈니스 로직

#### Q7. 충돌 방지 로직 범위 ✅ **결정됨**
- **결정**: 유연 모드 채택
- **동작**: 모든 일정 충돌 감지하되, 추가는 허용 + 경고 표시
  ```dart
  if (hasConflict) {
    showSnackBar('다른 일정과 겹칩니다', backgroundColor: AppColors.warning);
  }
  // 그래도 일정 생성 진행
  ```
- **이유**: 사용자 자율성 존중, 의도적 겹침 허용

#### Q8. PlaceAvailability 운영시간 구조 ✅ **결정됨 (리팩터링 예정)**
- **결정**: 단일 시간대 + 차단 시간 조합 방식으로 리팩터링
- **새로운 구조**:
  - **PlaceAvailability**: 1개만 저장 (시작 시간 ~ 마감 시간)
    - 예: 월요일 09:00-18:00
  - **PlaceBlockedTime**: 여러 개 추가 가능 (브레이크 타임 등)
    - 예: 월요일 12:00-13:00 (점심시간)
    - 예: 월요일 15:00-15:15 (휴식시간)
- **장점**:
  - UI 단순화 (하나의 큰 블록 선택 + 차단 영역 추가)
  - 비즈니스 로직 명확화 (운영시간 내에서 차단)
  - 중첩 검증 불필요
- **마이그레이션**: Phase 2에서 백엔드 API + UI 함께 수정

#### Q9. 모바일 핸들 크기 및 스타일 ✅ **결정됨**
- **결정**: 옵션 B 채택 + 위치 최적화
  - **터치 영역**: 44x44px
  - **시각적 막대**: 12px(높이) × 60px(너비)
  - **위치**: 일정 블록 바깥 튀어나옴 (top: -8, bottom: -8)
  - **방향**: 기본 오른쪽 돌출, **가장 오른쪽 칸에서는 왼쪽으로 돌출**
  ```dart
  Widget _buildHandle({required bool isStart, required bool isRightmostColumn}) {
    return Positioned(
      top: isStart ? -8 : null,
      bottom: isStart ? null : -8,
      left: isRightmostColumn ? -8 : null, // 오른쪽 칸: 왼쪽으로
      right: isRightmostColumn ? null : -8, // 일반: 오른쪽으로
      child: GestureDetector(
        onPanUpdate: _onHandleDrag,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
  ```
- **장점**: 가시성 향상, 화면 가장자리에서도 조작 편리

#### Q10. 핸들 드래그 스냅 동작 ✅ **결정됨**
- **결정**: 실시간 스냅 채택
- **동작**: 핸들 드래그 중 15분 단위로 즉시 정렬
  ```dart
  onPanUpdate: (details) {
    final rawTime = _calculateTimeFromDelta(details.delta.dy);
    final snappedTime = _snapTo15Minutes(rawTime); // 실시간 스냅

    setState(() {
      _selectedRange = TimeRange(
        start: isStartHandle ? snappedTime : _selectedRange.start,
        end: isStartHandle ? _selectedRange.end : snappedTime,
      );
    });

    // 스냅 시 가벼운 햅틱 피드백
    if (_previousSnappedTime != snappedTime) {
      HapticFeedback.selectionClick();
      _previousSnappedTime = snappedTime;
    }
  }

  DateTime _snapTo15Minutes(DateTime time) {
    final minutes = time.minute;
    final snappedMinutes = (minutes / 15).round() * 15;
    return DateTime(time.year, time.month, time.day, time.hour, snappedMinutes);
  }
  ```
- **장점**: 명확한 시간 단위 인식, 햅틱 피드백으로 스냅 알림

#### Q11. 데스크톱/모바일 분기 기준 ✅ **결정됨**
- **결정**: 화면 크기 기준 + 플랫폼 감지 병행
  ```dart
  final isMobile = MediaQuery.of(context).size.width < 600 ||
                   Theme.of(context).platform == TargetPlatform.iOS ||
                   Theme.of(context).platform == TargetPlatform.android;

  return isMobile
      ? MobileScheduleEditor(...) // 핸들 드래그
      : DesktopScheduleEditor(...); // 마우스 드래그 앤 드롭
  ```
- **장점**: 단순하면서도 대부분의 케이스 커버, 태블릿은 화면 크기로 자동 분기

---

## 개선 아이디어

### 1. 스마트 시간 제안

```dart
// AI 기반 최적 시간 추천
class SmartTimeRecommender {
  List<TimeSlot> recommend({
    required List<User> participants,
    required Duration duration,
    required DateTimeRange searchRange,
  }) {
    // 1. 각 참여자의 시간표 + 기존 일정 분석
    final busySlots = _analyzeBusySlots(participants);

    // 2. 공통 빈 시간 탐색
    final freeSlots = _findFreeSlots(busySlots, searchRange);

    // 3. 선호 시간대 가중치 적용 (예: 오전 선호, 점심시간 제외)
    final scored = freeSlots.map((slot) =>
      (slot: slot, score: _calculateScore(slot, participants))
    ).toList();

    // 4. 상위 3개 추천
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(3).map((e) => e.slot).toList();
  }
}

// UI 통합
Widget _buildRecommendationChips(List<TimeSlot> recommendations) {
  return Wrap(
    spacing: 8,
    children: recommendations.map((slot) =>
      ActionChip(
        label: Text('${_formatTime(slot.start)} (추천)'),
        avatar: Icon(Icons.lightbulb, size: 16),
        onPressed: () => _applyRecommendation(slot),
      )
    ).toList(),
  );
}
```

### 2. 드래그 중 미리보기

```dart
// 드래그 중 임시 이벤트 카드 표시
Widget _buildDragPreview(DragState dragState) {
  if (dragState.timeRange == null) return SizedBox.shrink();

  return Positioned(
    // ... 위치 계산
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.brand.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.brand,
          width: 2,
          style: BorderStyle.dashed, // 점선 테두리
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.drag_indicator, color: AppColors.brand),
          Text(
            '${_formatDuration(dragState.timeRange!.duration)}',
            style: AppTheme.bodySmall.copyWith(color: AppColors.brand),
          ),
        ],
      ),
    ),
  );
}
```

### 3. 햅틱 피드백 (모바일)

```dart
import 'package:flutter/services.dart';

onPanUpdate: (details) {
  final newSlot = _calculateSlotFromPosition(details.localPosition);

  if (newSlot != _previousSlot) {
    // 셀 경계 넘을 때 가벼운 진동
    HapticFeedback.selectionClick();
    _previousSlot = newSlot;
  }
}

onPanEnd: (details) {
  // 일정 생성 완료 시 중간 강도 진동
  HapticFeedback.mediumImpact();
}
```

### 4. 일정 템플릿 (빠른 추가)

```dart
// 자주 사용하는 시간 패턴 저장
class ScheduleTemplate {
  final String name;
  final Duration duration;
  final TimeOfDay preferredStart;
  final List<DayOfWeek> daysOfWeek;

  // 예: "주간 회의" → 매주 월요일 14:00-15:00
}

Widget _buildTemplateSelector() {
  return ListView(
    children: templates.map((template) =>
      ListTile(
        title: Text(template.name),
        subtitle: Text('${template.duration.inMinutes}분'),
        onTap: () => _applyTemplate(template),
      )
    ).toList(),
  );
}
```

### 5. 다중 일정 일괄 추가

```dart
// 반복 일정 패턴 설정
class RecurrenceDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('반복 일정 설정'),
      content: Column(
        children: [
          // 패턴 선택 (매일, 매주, 격주, 매월)
          DropdownButton<RecurrencePattern>(/* ... */),

          // 종료 조건 (날짜 또는 횟수)
          RadioGroup(
            options: ['특정 날짜까지', 'N회 반복'],
          ),

          // 요일 선택 (주간 반복 시)
          WeekdayCheckboxes(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // 백엔드 API 호출: recurrence_rule JSON 생성
            final rule = {
              "type": "WEEKLY",
              "daysOfWeek": ["MONDAY", "WEDNESDAY", "FRIDAY"],
              "until": "2025-12-31"
            };
            _createRecurringEvent(rule);
          },
          child: Text('생성'),
        ),
      ],
    );
  }
}
```

### 6. 실시간 협업 (미래 확장)

```dart
// WebSocket 연동하여 다른 사용자의 드래그 상태 실시간 표시
class CollaborativeDragIndicator extends StatelessWidget {
  final String userId;
  final String userName;
  final DragState dragState;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // ... 드래그 범위 위치
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _getUserColor(userId),
            width: 2,
            style: BorderStyle.dotted,
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Chip(
            label: Text(userName),
            avatar: Icon(Icons.edit, size: 16),
          ),
        ),
      ),
    );
  }
}
```

---

## 다음 단계

### Phase 1: 기본 편집 컴포넌트 (1주)
**데스크톱 우선 구현**:
- [ ] `EditableWeekGridView` 위젯 구현
- [ ] 드래그 앤 드롭 기본 로직 (데스크톱)
- [ ] 15분 간격 모드
- [ ] 일정 입력 모달

**모바일 인터랙션 추가**:
- [ ] `MobileScheduleEditor` 위젯
- [ ] 셀 탭 → 30분 블록 생성
- [ ] 상단/하단 핸들 UI
- [ ] 핸들 드래그 로직 (스냅 포함)
- [ ] 확인 버튼 플로우
- [ ] 데스크톱/모바일 분기 로직

### Phase 2: 통합 조회 컴포넌트 (1주)
- [ ] `WeeklyScheduleViewer` 위젯
- [ ] 히트맵 계산 로직
- [ ] 겹친 일정 팝업/바텀시트
- [ ] 색상 블렌딩
- [ ] 반응형 디자인 (모바일 최적화)

### Phase 3: 하이브리드 & 고급 기능 (1주)
- [ ] `HybridWeeklyCalendar` 통합
- [ ] 5분 간격 모드
- [ ] 충돌 방지 로직
- [ ] 키보드 네비게이션 (데스크톱)
- [ ] 확장 가능한 콜백 API 정리

### Phase 4: 성능 최적화 (0.5주)
- [ ] Canvas 기반 렌더링 검토
- [ ] Lazy loading 적용
- [ ] 메모이제이션
- [ ] 모바일 성능 프로파일링

### Phase 5: 접근성 & 폴리싱 (0.5주)
- [ ] 스크린 리더 테스트
- [ ] 햅틱 피드백 (모바일)
- [ ] 애니메이션 개선 (핸들 드래그 시 부드러운 전환)
- [ ] 사용자 테스트 및 피드백 반영

---

## 참조

- [디자인 시스템](concepts/design-system.md)
- [캘린더 시스템 개념](../concepts/calendar-system.md)
- [장소 캘린더 명세](../features/place-calendar-specification.md)
- [기존 CalendarWeekGridView 구현](/Users/nohsungbeen/univ/2025-2/project/personal_project/univ_group_management/frontend/lib/presentation/pages/calendar/calendar_week_grid_view.dart)
- [Flutter GestureDetector 문서](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)
- [Riverpod 상태 관리 가이드](https://riverpod.dev)
