# 그룹 캘린더 Phase 2 프론트엔드 구현 가이드

> **작성일**: 2025-10-12
> **선행 작업**: Phase 1 백엔드 완료 (GroupEvent API)
> **예상 기간**: 8일 (Week 4-6)

---

## 📋 Phase 2 개요

Phase 1에서 구현한 백엔드 API를 Flutter 프론트엔드와 연동하여 사용자가 그룹 캘린더를 사용할 수 있도록 합니다.

### 🎯 목표
- 그룹 캘린더 UI 구현 (Day/Week/Month 뷰)
- 일정 CRUD 기능 (생성/수정/삭제)
- 반복 일정 UI (매일/요일 선택)
- 공식/비공식 일정 시각적 구분
- 기존 개인 캘린더와 통합 뷰

---

## 🗂️ 디렉토리 구조

```
frontend/lib/
├── models/
│   └── calendar/
│       ├── group_event.dart              # GroupEvent 모델
│       ├── recurrence_pattern.dart       # 반복 패턴 모델
│       └── update_scope.dart             # 수정 범위 enum
├── services/
│   └── group_calendar_service.dart       # API 클라이언트
├── providers/
│   └── group_calendar_provider.dart      # 상태 관리
└── pages/
    └── workspace/
        └── calendar/
            ├── group_calendar_page.dart          # 메인 페이지
            ├── widgets/
            │   ├── group_event_form_dialog.dart  # 일정 생성/수정 폼
            │   ├── recurrence_selector.dart      # 반복 패턴 선택
            │   └── event_detail_sheet.dart       # 일정 상세 보기
            └── views/
                ├── group_calendar_month_view.dart
                ├── group_calendar_week_view.dart
                └── group_calendar_day_view.dart
```

---

## 📦 Step 1: 모델 클래스 작성 (2일)

### 1.1 GroupEvent 모델
**파일**: `lib/models/calendar/group_event.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

part 'group_event.g.dart';

@JsonSerializable()
class GroupEvent {
  final int id;
  final int groupId;
  final String groupName;
  final int creatorId;
  final String creatorName;
  final String title;
  final String? description;
  final String? location;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAllDay;
  final bool isOfficial;
  final EventType eventType;
  final String? seriesId;
  final String? recurrenceRule;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupEvent({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    this.description,
    this.location,
    required this.startDate,
    required this.endDate,
    required this.isAllDay,
    required this.isOfficial,
    required this.eventType,
    this.seriesId,
    this.recurrenceRule,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupEvent.fromJson(Map<String, dynamic> json) =>
      _$GroupEventFromJson(json);

  Map<String, dynamic> toJson() => _$GroupEventToJson(this);

  // 헬퍼 메서드
  bool get isRecurring => seriesId != null;

  Duration get duration => endDate.difference(startDate);

  bool occursOn(DateTime date) {
    final eventDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final checkDate = DateTime(date.year, date.month, date.day);
    return eventDate == checkDate;
  }
}

enum EventType {
  @JsonValue('GENERAL')
  general,
  @JsonValue('TARGETED')
  targeted,
  @JsonValue('RSVP')
  rsvp,
}
```

---

### 1.2 RecurrencePattern 모델
**파일**: `lib/models/calendar/recurrence_pattern.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

part 'recurrence_pattern.g.dart';

@JsonSerializable()
class RecurrencePattern {
  final RecurrenceType type;
  final List<int>? daysOfWeek; // 1=Monday, 7=Sunday

  const RecurrencePattern({
    required this.type,
    this.daysOfWeek,
  });

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) =>
      _$RecurrencePatternFromJson(json);

  Map<String, dynamic> toJson() => _$RecurrencePatternToJson(this);

  // 헬퍼
  static RecurrencePattern daily() => const RecurrencePattern(
        type: RecurrenceType.daily,
      );

  static RecurrencePattern weekly(List<int> days) => RecurrencePattern(
        type: RecurrenceType.weekly,
        daysOfWeek: days,
      );
}

enum RecurrenceType {
  @JsonValue('DAILY')
  daily,
  @JsonValue('WEEKLY')
  weekly,
}
```

---

### 1.3 UpdateScope enum
**파일**: `lib/models/calendar/update_scope.dart`

```dart
enum UpdateScope {
  thisEvent('THIS_EVENT'),
  allEvents('ALL_EVENTS');

  final String value;
  const UpdateScope(this.value);
}
```

---

## 🌐 Step 2: API 서비스 구현 (2일)

**파일**: `lib/services/group_calendar_service.dart`

```dart
import 'package:dio/dio.dart';
import '../models/calendar/group_event.dart';
import '../models/calendar/recurrence_pattern.dart';
import '../models/calendar/update_scope.dart';

class GroupCalendarService {
  final Dio _dio;

  GroupCalendarService(this._dio);

  /// 그룹 캘린더 일정 목록 조회
  Future<List<GroupEvent>> getEvents({
    required int groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _dio.get(
      '/groups/$groupId/events',
      queryParameters: {
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
      },
    );

    final data = response.data['data'] as List;
    return data.map((json) => GroupEvent.fromJson(json)).toList();
  }

  /// 그룹 일정 생성 (단일 or 반복)
  Future<List<GroupEvent>> createEvent({
    required int groupId,
    required String title,
    String? description,
    String? location,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    bool isOfficial = false,
    required String color,
    RecurrencePattern? recurrence,
  }) async {
    final response = await _dio.post(
      '/groups/$groupId/events',
      data: {
        'title': title,
        'description': description,
        'location': location,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isAllDay': isAllDay,
        'isOfficial': isOfficial,
        'color': color,
        'eventType': 'GENERAL',
        if (recurrence != null) 'recurrence': recurrence.toJson(),
      },
    );

    final data = response.data['data'] as List;
    return data.map((json) => GroupEvent.fromJson(json)).toList();
  }

  /// 그룹 일정 수정
  Future<List<GroupEvent>> updateEvent({
    required int groupId,
    required int eventId,
    required String title,
    String? description,
    String? location,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    required String color,
    UpdateScope updateScope = UpdateScope.thisEvent,
  }) async {
    final response = await _dio.put(
      '/groups/$groupId/events/$eventId',
      data: {
        'title': title,
        'description': description,
        'location': location,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isAllDay': isAllDay,
        'color': color,
        'updateScope': updateScope.value,
      },
    );

    final data = response.data['data'] as List;
    return data.map((json) => GroupEvent.fromJson(json)).toList();
  }

  /// 그룹 일정 삭제
  Future<void> deleteEvent({
    required int groupId,
    required int eventId,
    UpdateScope deleteScope = UpdateScope.thisEvent,
  }) async {
    await _dio.delete(
      '/groups/$groupId/events/$eventId',
      queryParameters: {
        'scope': deleteScope.value,
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
```

---

## 🔄 Step 3: 상태 관리 (Provider) (1일)

**파일**: `lib/providers/group_calendar_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import '../models/calendar/group_event.dart';
import '../services/group_calendar_service.dart';

class GroupCalendarProvider with ChangeNotifier {
  final GroupCalendarService _service;

  GroupCalendarProvider(this._service);

  // 상태
  List<GroupEvent> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<GroupEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 특정 날짜의 일정 조회
  List<GroupEvent> getEventsForDate(DateTime date) {
    return _events.where((event) => event.occursOn(date)).toList();
  }

  /// 특정 범위의 일정 로드
  Future<void> loadEvents({
    required int groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _service.getEvents(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 일정 생성
  Future<void> createEvent({
    required int groupId,
    required String title,
    String? description,
    String? location,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    bool isOfficial = false,
    required String color,
    RecurrencePattern? recurrence,
  }) async {
    try {
      final newEvents = await _service.createEvent(
        groupId: groupId,
        title: title,
        description: description,
        location: location,
        startDate: startDate,
        endDate: endDate,
        isAllDay: isAllDay,
        isOfficial: isOfficial,
        color: color,
        recurrence: recurrence,
      );

      _events.addAll(newEvents);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 일정 수정
  Future<void> updateEvent({
    required int groupId,
    required int eventId,
    required String title,
    String? description,
    String? location,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    required String color,
    UpdateScope updateScope = UpdateScope.thisEvent,
  }) async {
    try {
      final updatedEvents = await _service.updateEvent(
        groupId: groupId,
        eventId: eventId,
        title: title,
        description: description,
        location: location,
        startDate: startDate,
        endDate: endDate,
        isAllDay: isAllDay,
        color: color,
        updateScope: updateScope,
      );

      // 기존 일정 제거 후 업데이트된 일정 추가
      _events.removeWhere((e) => e.id == eventId);
      _events.addAll(updatedEvents);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 일정 삭제
  Future<void> deleteEvent({
    required int groupId,
    required int eventId,
    UpdateScope deleteScope = UpdateScope.thisEvent,
  }) async {
    try {
      await _service.deleteEvent(
        groupId: groupId,
        eventId: eventId,
        deleteScope: deleteScope,
      );

      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
```

---

## 🎨 Step 4: UI 컴포넌트 구현 (4일)

### 4.1 반복 패턴 선택 위젯
**파일**: `lib/pages/workspace/calendar/widgets/recurrence_selector.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../models/calendar/recurrence_pattern.dart';

class RecurrenceSelector extends StatefulWidget {
  final RecurrencePattern? initialPattern;
  final Function(RecurrencePattern?) onChanged;

  const RecurrenceSelector({
    Key? key,
    this.initialPattern,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RecurrenceSelector> createState() => _RecurrenceSelectorState();
}

class _RecurrenceSelectorState extends State<RecurrenceSelector> {
  bool _isRecurring = false;
  RecurrenceType _type = RecurrenceType.daily;
  Set<int> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialPattern != null) {
      _isRecurring = true;
      _type = widget.initialPattern!.type;
      _selectedDays = widget.initialPattern!.daysOfWeek?.toSet() ?? {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('반복 일정'),
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
              _notifyChange();
            });
          },
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 16),
          SegmentedButton<RecurrenceType>(
            segments: const [
              ButtonSegment(
                value: RecurrenceType.daily,
                label: Text('매일'),
              ),
              ButtonSegment(
                value: RecurrenceType.weekly,
                label: Text('요일 선택'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (Set<RecurrenceType> newSelection) {
              setState(() {
                _type = newSelection.first;
                _notifyChange();
              });
            },
          ),
          if (_type == RecurrenceType.weekly) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (int day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(_getDayLabel(day)),
                    selected: _selectedDays.contains(day),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                        _notifyChange();
                      });
                    },
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  void _notifyChange() {
    if (!_isRecurring) {
      widget.onChanged(null);
      return;
    }

    RecurrencePattern? pattern;
    if (_type == RecurrenceType.daily) {
      pattern = RecurrencePattern.daily();
    } else if (_type == RecurrenceType.weekly && _selectedDays.isNotEmpty) {
      pattern = RecurrencePattern.weekly(_selectedDays.toList()..sort());
    }

    widget.onChanged(pattern);
  }

  String _getDayLabel(int day) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[day - 1];
  }
}
```

---

### 4.2 일정 생성/수정 폼
**파일**: `lib/pages/workspace/calendar/widgets/group_event_form_dialog.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../models/calendar/group_event.dart';
import '../../../../models/calendar/recurrence_pattern.dart';
import 'recurrence_selector.dart';

class GroupEventFormDialog extends StatefulWidget {
  final int groupId;
  final GroupEvent? event; // null이면 생성 모드
  final bool canCreateOfficial; // CALENDAR_MANAGE 권한 여부

  const GroupEventFormDialog({
    Key? key,
    required this.groupId,
    this.event,
    required this.canCreateOfficial,
  }) : super(key: key);

  @override
  State<GroupEventFormDialog> createState() => _GroupEventFormDialogState();
}

class _GroupEventFormDialogState extends State<GroupEventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isAllDay = false;
  bool _isOfficial = false;
  String _color = '#3B82F6';
  RecurrencePattern? _recurrence;

  @override
  void initState() {
    super.initState();
    final event = widget.event;

    _titleController = TextEditingController(text: event?.title);
    _descriptionController = TextEditingController(text: event?.description);
    _locationController = TextEditingController(text: event?.location);

    _startDate = event?.startDate ?? DateTime.now();
    _endDate = event?.endDate ?? DateTime.now().add(const Duration(hours: 1));
    _isAllDay = event?.isAllDay ?? false;
    _isOfficial = event?.isOfficial ?? false;
    _color = event?.color ?? '#3B82F6';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event == null ? '일정 생성' : '일정 수정',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // 제목
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '제목 *'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? '제목을 입력하세요' : null,
                ),
                const SizedBox(height: 16),

                // 설명
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: '설명'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // 장소
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: '장소'),
                ),
                const SizedBox(height: 16),

                // 시작일/종료일
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimePicker(
                        label: '시작',
                        dateTime: _startDate,
                        onChanged: (value) => setState(() => _startDate = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateTimePicker(
                        label: '종료',
                        dateTime: _endDate,
                        onChanged: (value) => setState(() => _endDate = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 종일 이벤트
                SwitchListTile(
                  title: const Text('종일 이벤트'),
                  value: _isAllDay,
                  onChanged: (value) => setState(() => _isAllDay = value),
                ),

                // 공식 일정 (권한 있을 때만)
                if (widget.canCreateOfficial)
                  SwitchListTile(
                    title: const Text('공식 일정'),
                    subtitle: const Text('그룹 전체에 공지됩니다'),
                    value: _isOfficial,
                    onChanged: (value) => setState(() => _isOfficial = value),
                  ),

                // 색상 선택
                const Text('색상'),
                const SizedBox(height: 8),
                _buildColorPicker(),
                const SizedBox(height: 16),

                // 반복 설정 (생성 모드에서만)
                if (widget.event == null) ...[
                  const Divider(),
                  RecurrenceSelector(
                    onChanged: (pattern) => setState(() => _recurrence = pattern),
                  ),
                ],

                const SizedBox(height: 24),

                // 액션 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(widget.event == null ? '생성' : '수정'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime dateTime,
    required Function(DateTime) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: dateTime,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(dateTime),
          );
          if (time != null) {
            onChanged(DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            ));
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    const colors = [
      '#EF4444', // Red
      '#F59E0B', // Amber
      '#10B981', // Green
      '#3B82F6', // Blue
      '#8B5CF6', // Purple
    ];

    return Wrap(
      spacing: 8,
      children: colors.map((color) {
        final isSelected = _color == color;
        return GestureDetector(
          onTap: () => setState(() => _color = color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF${color.substring(1)}')),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black, width: 3)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'startDate': _startDate,
        'endDate': _endDate,
        'isAllDay': _isAllDay,
        'isOfficial': _isOfficial,
        'color': _color,
        'recurrence': _recurrence,
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
```

---

### 4.3 그룹 캘린더 메인 페이지
**파일**: `lib/pages/workspace/calendar/group_calendar_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/group_calendar_provider.dart';
import 'widgets/group_event_form_dialog.dart';

class GroupCalendarPage extends StatefulWidget {
  final int groupId;

  const GroupCalendarPage({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  State<GroupCalendarPage> createState() => _GroupCalendarPageState();
}

class _GroupCalendarPageState extends State<GroupCalendarPage> {
  DateTime _focusedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final provider = context.read<GroupCalendarProvider>();
    final startOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final endOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);

    await provider.loadEvents(
      groupId: widget.groupId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹 캘린더'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: Consumer<GroupCalendarProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('오류: ${provider.errorMessage}'));
          }

          // TODO: 실제 캘린더 뷰 구현
          return ListView.builder(
            itemCount: provider.events.length,
            itemBuilder: (context, index) {
              final event = provider.events[index];
              return ListTile(
                title: Text(event.title),
                subtitle: Text(
                  '${event.startDate.toString().substring(0, 16)} - '
                  '${event.endDate.toString().substring(11, 16)}',
                ),
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${event.color.substring(1)}')),
                    shape: BoxShape.circle,
                  ),
                ),
                trailing: event.isOfficial
                    ? const Chip(label: Text('공식'))
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => GroupEventFormDialog(
        groupId: widget.groupId,
        canCreateOfficial: true, // TODO: 실제 권한 확인
      ),
    );

    if (result != null) {
      final provider = context.read<GroupCalendarProvider>();
      await provider.createEvent(
        groupId: widget.groupId,
        title: result['title'],
        description: result['description'],
        location: result['location'],
        startDate: result['startDate'],
        endDate: result['endDate'],
        isAllDay: result['isAllDay'],
        isOfficial: result['isOfficial'],
        color: result['color'],
        recurrence: result['recurrence'],
      );
    }
  }
}
```

---

## ✅ 완료 체크리스트

### Step 1: 모델 클래스
- [ ] GroupEvent 모델 + JSON 직렬화
- [ ] RecurrencePattern 모델
- [ ] UpdateScope enum
- [ ] `flutter pub run build_runner build` 실행

### Step 2: API 서비스
- [ ] GroupCalendarService 구현
- [ ] 5개 API 메서드 (조회/생성/수정/삭제)
- [ ] 에러 처리

### Step 3: 상태 관리
- [ ] GroupCalendarProvider 구현
- [ ] ChangeNotifier 패턴
- [ ] 로딩/에러 상태 관리

### Step 4: UI 컴포넌트
- [ ] RecurrenceSelector (반복 패턴 선택)
- [ ] GroupEventFormDialog (일정 폼)
- [ ] GroupCalendarPage (메인 페이지)
- [ ] Month/Week/Day 뷰 (선택)

---

## 📚 참고 파일

- **기존 개인 캘린더**: `lib/pages/calendar/*`
- **TimetableWeeklyView**: 주간 뷰 재사용 가능
- **table_calendar 라이브러리**: 월간 뷰에 사용

---

**예상 작업 시간**: 8일 (Week 4-6)
