# 장소 캘린더 Phase 2: 프론트엔드 기본 구현

> **상태**: 계획 수립 완료, 구현 대기
> **예상 시간**: 6-8시간
> **우선순위**: P0 (필수)
> **의존성**: Phase 1 백엔드 완료 (✅)
> **관련 문서**: [장소 캘린더 명세](place-calendar-specification.md) | [통합 로드맵](calendar-integration-roadmap.md)

---

## 📋 개요

장소 캘린더의 기본 프론트엔드 UI를 구현합니다. 장소 목록 조회, 등록, 운영시간 설정 기능을 포함합니다.

### 목표
- 장소 목록 조회 화면 구현 (멀티 플레이스 뷰)
- 장소 등록 폼 구현 (새 장소 생성)
- 운영 시간 설정 UI 구현
- API 서비스 레이어 구현

---

## 🎯 작업 항목

### 1. 장소 목록 페이지 (2h)

#### 파일 위치
```
lib/presentation/pages/workspace/place/
  ├─ place_list_page.dart         # 메인 페이지
  └─ widgets/
      ├─ place_tree_view.dart     # 건물별 트리 구조
      ├─ place_card.dart          # 장소 카드
      └─ place_filter_bar.dart    # 필터링 바
```

#### 기능 요구사항
- **멀티 플레이스 뷰**: 여러 장소를 한 화면에서 선택 가능
- **드롭다운 구조**: 건물 → 장소 2단계
  ```dart
  // 예시 UI
  [건물 선택 드롭다운]
    60주년 기념관
    창의관

  [장소 선택 드롭다운] (건물 선택 후 활성화)
    18203 (AISC랩실)
    18204
  ```
- **검색 기능**: 건물명, 방 번호, 별칭으로 검색
- **필터링**: 건물, 수용 인원, 사용 가능 여부
- **권한별 액션 버튼 표시**:
  - **예약 권한 신청**: 모든 사용자 (CALENDAR_MANAGE 필요)
  - **새 장소 생성**: CALENDAR_MANAGE 보유자만
  - **장소 관리**: 관리 그룹 + CALENDAR_MANAGE 보유자만

#### API 연동
- `GET /api/places` - 장소 목록 조회
  - 필터링: `managingGroupId == currentGroupId OR PlaceUsageGroup.status == APPROVED`

#### UI 컴포넌트
```dart
class PlaceListPage extends ConsumerStatefulWidget {
  final String groupId;

  @override
  _PlaceListPageState createState() => _PlaceListPageState();
}

class _PlaceListPageState extends ConsumerState<PlaceListPage> {
  String? selectedBuilding;
  String? selectedPlace;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(placesProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: Text('장소 캘린더'),
        actions: [
          // 관리 그룹 표시
          if (selectedPlace != null)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Text('관리 그룹: ${place.managingGroupName}'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          PlaceFilterBar(
            onSearchChanged: (query) => setState(() => searchQuery = query),
          ),
          Row(
            children: [
              // 건물 선택 드롭다운
              Expanded(
                child: DropdownButton<String>(
                  hint: Text('건물 선택'),
                  value: selectedBuilding,
                  items: buildings.map((b) => DropdownMenuItem(
                    value: b,
                    child: Text(b),
                  )).toList(),
                  onChanged: (value) => setState(() {
                    selectedBuilding = value;
                    selectedPlace = null;
                  }),
                ),
              ),
              // 장소 선택 드롭다운
              Expanded(
                child: DropdownButton<String>(
                  hint: Text('장소 선택'),
                  value: selectedPlace,
                  items: filteredPlaces.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.roomNumber} ${p.alias ?? ''}'),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedPlace = value),
                ),
              ),
            ],
          ),
          // 액션 버튼 (한 줄에 모든 액션)
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (hasCalendarManage)
                  ElevatedButton.icon(
                    icon: Icon(Icons.add_location),
                    label: Text('예약 권한 신청'),
                    onPressed: _showUsageRequestDialog,
                  ),
                if (hasCalendarManage)
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('새 장소 생성'),
                    onPressed: _showPlaceCreateDialog,
                  ),
                if (isManagingGroup && hasCalendarManage)
                  ElevatedButton.icon(
                    icon: Icon(Icons.settings),
                    label: Text('장소 관리'),
                    onPressed: _navigateToPlaceManagement,
                  ),
              ],
            ),
          ),
          // 장소 캘린더 뷰
          Expanded(
            child: selectedPlace != null
              ? PlaceCalendarView(placeId: selectedPlace!)
              : Center(child: Text('장소를 선택하세요')),
          ),
        ],
      ),
    );
  }
}
```

---

### 2. 장소 등록 폼 (2h)

#### 파일 위치
```
lib/presentation/pages/workspace/place/
  └─ dialogs/
      └─ place_form_dialog.dart
```

#### 기능 요구사항
- **권한 체크**: CALENDAR_MANAGE 보유자만 접근
- **입력 필드**:
  - 건물명 (드롭다운 또는 입력)
  - 방 번호 (필수)
  - 별칭 (선택)
  - 수용 인원 (선택)
- **중복 체크**: 동일한 건물-방 번호 조합 검증
- **자동 설정**: `managingGroupId`는 현재 그룹으로 자동 설정
- **플로우**: 장소 생성 후 바로 운영시간 설정 화면으로 전환

#### API 연동
- `POST /api/places` - 장소 등록

#### UI 컴포넌트
```dart
class PlaceFormDialog extends ConsumerStatefulWidget {
  final String groupId;
  final Place? place; // 수정 시 기존 데이터

  @override
  _PlaceFormDialogState createState() => _PlaceFormDialogState();
}

class _PlaceFormDialogState extends ConsumerState<PlaceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? building;
  String? roomNumber;
  String? alias;
  int? capacity;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.place == null ? '새 장소 생성' : '장소 수정'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 건물명 (드롭다운 + 입력 병행)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: '건물명'),
                value: building,
                items: ['60주년 기념관', '창의관', '기타']
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
                onChanged: (value) => setState(() => building = value),
                validator: (value) => value == null ? '건물을 선택하세요' : null,
              ),
              if (building == '기타')
                TextFormField(
                  decoration: InputDecoration(labelText: '건물명 입력'),
                  onChanged: (value) => building = value,
                ),
              // 방 번호
              TextFormField(
                decoration: InputDecoration(labelText: '방 번호'),
                onChanged: (value) => roomNumber = value,
                validator: (value) => value?.isEmpty ?? true ? '방 번호를 입력하세요' : null,
              ),
              // 별칭 (선택)
              TextFormField(
                decoration: InputDecoration(
                  labelText: '별칭 (선택)',
                  hintText: '예: AISC랩실',
                ),
                onChanged: (value) => alias = value,
              ),
              // 수용 인원 (선택)
              TextFormField(
                decoration: InputDecoration(labelText: '수용 인원 (선택)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => capacity = int.tryParse(value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('취소'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: Text('저장 후 운영시간 설정'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // 중복 체크
      final exists = await ref.read(placeServiceProvider).checkDuplicate(
        building: building!,
        roomNumber: roomNumber!,
      );

      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미 등록된 장소입니다')),
        );
        return;
      }

      // 장소 생성
      final place = await ref.read(placeServiceProvider).createPlace(
        groupId: widget.groupId,
        building: building!,
        roomNumber: roomNumber!,
        alias: alias,
        capacity: capacity,
      );

      Navigator.pop(context);

      // 운영시간 설정 화면으로 전환
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaceAvailabilitySettingsPage(placeId: place.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('장소 생성 실패: $e')),
      );
    }
  }
}
```

---

### 3. 운영 시간 설정 UI (2h)

#### 파일 위치
```
lib/presentation/pages/workspace/place/
  └─ place_availability_settings_page.dart
```

#### 기능 요구사항
- **요일별 시간대 설정**: 월~일 각 요일별로 여러 시간대 추가 가능
- **시각적 타임라인 표시**: 설정된 시간대를 시각적으로 표시
- **여러 시간대 추가**: 09:00-12:00, 14:00-18:00 등 여러 시간대 지원
- **삭제 기능**: 설정된 시간대 삭제

#### API 연동
- `POST /api/places/{id}/availability` - 운영 시간 추가
- `DELETE /api/places/{id}/availability/{availId}` - 운영 시간 삭제

#### UI 컴포넌트
```dart
class PlaceAvailabilitySettingsPage extends ConsumerStatefulWidget {
  final String placeId;

  @override
  _PlaceAvailabilitySettingsPageState createState() => _PlaceAvailabilitySettingsPageState();
}

class _PlaceAvailabilitySettingsPageState extends ConsumerState<PlaceAvailabilitySettingsPage> {
  @override
  Widget build(BuildContext context) {
    final availabilities = ref.watch(placeAvailabilitiesProvider(widget.placeId));

    return Scaffold(
      appBar: AppBar(
        title: Text('운영 시간 설정'),
      ),
      body: availabilities.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('에러: $e')),
        data: (availList) => ListView(
          children: [
            for (var day in DayOfWeek.values)
              _buildDaySection(
                day: day,
                availabilities: availList.where((a) => a.dayOfWeek == day).toList(),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAvailability,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildDaySection({
    required DayOfWeek day,
    required List<PlaceAvailability> availabilities,
  }) {
    return ExpansionTile(
      title: Text(_getDayName(day)),
      children: [
        for (var avail in availabilities)
          ListTile(
            title: Text('${avail.startTime} - ${avail.endTime}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteAvailability(avail.id),
            ),
          ),
        ListTile(
          leading: Icon(Icons.add_circle_outline),
          title: Text('시간대 추가'),
          onTap: () => _showAddTimeDialog(day),
        ),
      ],
    );
  }

  Future<void> _showAddTimeDialog(DayOfWeek day) async {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('시간대 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('시작 시간'),
              subtitle: Text(startTime?.format(context) ?? '선택 안됨'),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => startTime = time);
                }
              },
            ),
            ListTile(
              title: Text('종료 시간'),
              subtitle: Text(endTime?.format(context) ?? '선택 안됨'),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => endTime = time);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (startTime != null && endTime != null) {
                await _addAvailability(day, startTime!, endTime!);
                Navigator.pop(context);
              }
            },
            child: Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAvailability(DayOfWeek day, TimeOfDay start, TimeOfDay end) async {
    try {
      await ref.read(placeServiceProvider).addAvailability(
        placeId: widget.placeId,
        dayOfWeek: day,
        startTime: _timeOfDayToLocalTime(start),
        endTime: _timeOfDayToLocalTime(end),
      );
      ref.invalidate(placeAvailabilitiesProvider(widget.placeId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시간대 추가 실패: $e')),
      );
    }
  }

  Future<void> _deleteAvailability(String availId) async {
    try {
      await ref.read(placeServiceProvider).deleteAvailability(
        placeId: widget.placeId,
        availId: availId,
      );
      ref.invalidate(placeAvailabilitiesProvider(widget.placeId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시간대 삭제 실패: $e')),
      );
    }
  }
}
```

---

### 4. API 서비스 레이어 (2h)

#### 파일 위치
```
lib/core/services/
  └─ place_service.dart

lib/core/providers/
  └─ place_provider.dart

lib/core/models/
  └─ place_models.dart
```

#### 모델 정의
```dart
// lib/core/models/place_models.dart
class Place {
  final String id;
  final String managingGroupId;
  final String managingGroupName;
  final String building;
  final String roomNumber;
  final String? alias;
  final int? capacity;
  final DateTime? deletedAt;

  const Place({
    required this.id,
    required this.managingGroupId,
    required this.managingGroupName,
    required this.building,
    required this.roomNumber,
    this.alias,
    this.capacity,
    this.deletedAt,
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['id'] as String,
    managingGroupId: json['managingGroupId'] as String,
    managingGroupName: json['managingGroupName'] as String,
    building: json['building'] as String,
    roomNumber: json['roomNumber'] as String,
    alias: json['alias'] as String?,
    capacity: json['capacity'] as int?,
    deletedAt: json['deletedAt'] != null
      ? DateTime.parse(json['deletedAt'] as String)
      : null,
  );

  String get displayName => alias != null ? '$alias ($roomNumber)' : '$building-$roomNumber';
}

class PlaceAvailability {
  final String id;
  final String placeId;
  final DayOfWeek dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const PlaceAvailability({
    required this.id,
    required this.placeId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory PlaceAvailability.fromJson(Map<String, dynamic> json) => PlaceAvailability(
    id: json['id'] as String,
    placeId: json['placeId'] as String,
    dayOfWeek: DayOfWeek.values.byName(json['dayOfWeek'] as String),
    startTime: _parseTimeOfDay(json['startTime'] as String),
    endTime: _parseTimeOfDay(json['endTime'] as String),
  );

  static TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

enum DayOfWeek { MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY }
```

#### 서비스 구현
```dart
// lib/core/services/place_service.dart
class PlaceService {
  final Dio _dio;

  PlaceService(this._dio);

  // 장소 목록 조회 (필터링 적용)
  Future<List<Place>> getPlaces(String groupId) async {
    final response = await _dio.get(
      '/api/places',
      queryParameters: {'groupId': groupId},
    );
    return (response.data as List)
      .map((json) => Place.fromJson(json))
      .toList();
  }

  // 장소 상세 조회
  Future<Place> getPlace(String placeId) async {
    final response = await _dio.get('/api/places/$placeId');
    return Place.fromJson(response.data);
  }

  // 장소 생성
  Future<Place> createPlace({
    required String groupId,
    required String building,
    required String roomNumber,
    String? alias,
    int? capacity,
  }) async {
    final response = await _dio.post(
      '/api/places',
      data: {
        'managingGroupId': groupId,
        'building': building,
        'roomNumber': roomNumber,
        if (alias != null) 'alias': alias,
        if (capacity != null) 'capacity': capacity,
      },
    );
    return Place.fromJson(response.data);
  }

  // 중복 체크
  Future<bool> checkDuplicate({
    required String building,
    required String roomNumber,
  }) async {
    try {
      final response = await _dio.get(
        '/api/places/check-duplicate',
        queryParameters: {
          'building': building,
          'roomNumber': roomNumber,
        },
      );
      return response.data['exists'] as bool;
    } catch (e) {
      return false;
    }
  }

  // 운영 시간 추가
  Future<PlaceAvailability> addAvailability({
    required String placeId,
    required DayOfWeek dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final response = await _dio.post(
      '/api/places/$placeId/availability',
      data: {
        'dayOfWeek': dayOfWeek.name,
        'startTime': startTime,
        'endTime': endTime,
      },
    );
    return PlaceAvailability.fromJson(response.data);
  }

  // 운영 시간 삭제
  Future<void> deleteAvailability({
    required String placeId,
    required String availId,
  }) async {
    await _dio.delete('/api/places/$placeId/availability/$availId');
  }

  // 운영 시간 목록 조회
  Future<List<PlaceAvailability>> getAvailabilities(String placeId) async {
    final response = await _dio.get('/api/places/$placeId/availability');
    return (response.data as List)
      .map((json) => PlaceAvailability.fromJson(json))
      .toList();
  }
}
```

#### Provider 설정
```dart
// lib/core/providers/place_provider.dart
final placeServiceProvider = Provider<PlaceService>((ref) {
  final dio = ref.watch(dioProvider);
  return PlaceService(dio);
});

final placesProvider = FutureProvider.family<List<Place>, String>((ref, groupId) async {
  final service = ref.watch(placeServiceProvider);
  return service.getPlaces(groupId);
});

final placeProvider = FutureProvider.family<Place, String>((ref, placeId) async {
  final service = ref.watch(placeServiceProvider);
  return service.getPlace(placeId);
});

final placeAvailabilitiesProvider = FutureProvider.family<List<PlaceAvailability>, String>(
  (ref, placeId) async {
    final service = ref.watch(placeServiceProvider);
    return service.getAvailabilities(placeId);
  },
);
```

---

## ✅ 완료 조건

- [ ] 장소 목록 조회 기능 구현 및 테스트
- [ ] 장소 등록 기능 구현 및 테스트 (CALENDAR_MANAGE 권한 체크)
- [ ] 운영 시간 설정 기능 구현 및 테스트
- [ ] API 연동 테스트 (모든 엔드포인트)
- [ ] 에러 핸들링 구현 (네트워크 에러, 권한 에러 등)
- [ ] 권한 체크 로직 구현 (장소 관리 버튼 표시 조건)
- [ ] 장소 필터링 로직 테스트 (관리 OR 승인된 사용권한)

---

## 🔗 관련 문서

- [장소 캘린더 명세](place-calendar-specification.md)
- [통합 로드맵](calendar-integration-roadmap.md)
- [프론트엔드 가이드](../implementation/frontend-guide.md)
- [디자인 시스템](../ui-ux/concepts/design-system.md)

---

**다음 단계**: Phase 3 - 예약 권한 신청 UI 구현
