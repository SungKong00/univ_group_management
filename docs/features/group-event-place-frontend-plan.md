# 그룹 일정-장소 예약 통합 프론트엔드 구현 계획

> **상위 문서**: [그룹 일정-장소 예약 통합 설계](group-event-place-integration.md)
> **관련 문서**: [프론트엔드 가이드](../implementation/frontend-guide.md) | [디자인 시스템](../ui-ux/concepts/design-system.md)
> **상태**: 🚀 구현 진행 중 (Phase 1 완료, Phase 2 진행 중)
> **예상 작업 시간**: 18-22시간

---

## 📌 진행 상황 요약 (2025-10-18)

- **Phase 1 (기본 컴포넌트 구현)**: ✅ **완료**
  - `LocationSelector`, `PlacePickerDialog` 등 핵심 컴포넌트 구현 완료.
  - `group_service.dart`에 `getAvailablePlaces` API 연동 완료.
- **Phase 2 (폼 통합 및 API 연동)**: 🚧 **진행 중**
  - `GroupEventFormDialog`에 `LocationSelector` 통합 완료.
  - `PlacePickerDialog` 렌더링 및 레이아웃 관련 버그 수정 진행 중.

---

## 📋 1. 개요

### 1.1. 목적 및 배경

**목적**: 그룹 일정 생성 시 장소 정보를 3가지 방식으로 설정할 수 있는 프론트엔드 UI 구현

**배경**:
- 백엔드 Phase 1-4 구현 완료 (2025-10-18)
- 3가지 장소 모드 (없음/수동 입력/장소 선택) 지원
- 장소 선택 시 자동 예약 생성 + 3단계 검증 (운영시간/차단/충돌)

### 1.2. 백엔드 구현 상태

**완료된 기능**:
- ✅ GroupEvent 엔티티 수정 (locationText, place 필드)
- ✅ PlaceReservation 자동 생성 로직
- ✅ 3단계 예약 검증 (운영시간 → 차단시간 → 충돌)
- ✅ 사용 권한 확인 (PlaceUsageGroup APPROVED)
- ✅ 반복 일정 지원
- ✅ API 엔드포인트 (GET /api/groups/{groupId}/available-places)

**구현된 API**:
- `GET /api/groups/{groupId}/available-places` - 사용 가능한 장소 목록 조회
- `POST /api/groups/{groupId}/events` - 일정 생성 (placeId 추가)
- `PATCH /api/groups/{groupId}/events/{eventId}` - 일정 수정 (장소 변경)

### 1.3. 프론트엔드 구현 범위

**핵심 컴포넌트**:
1. LocationSelector - 3가지 모드 선택 UI
2. PlaceSelector - 장소 검색 및 선택
3. GroupEventFormDialog - 일정 생성/수정 폼 통합

**주요 기능**:
- 장소 모드 선택 (없음/수동 입력/장소 선택)
- 사용 가능한 장소 목록 조회 및 필터링
- 실시간 예약 가능 여부 검증
- 에러 처리 및 사용자 피드백
- 반복 일정 + 장소 예약 처리

---

## 🏗️ 2. 컴포넌트 아키텍처

### 2.1. LocationSelector 컴포넌트

**역할**: 3가지 장소 모드 선택 UI 제공

**Props**:
```dart
class LocationSelector extends StatefulWidget {
  final LocationMode initialMode;           // 초기 모드 (기본: none)
  final String? initialLocationText;        // Mode B 초기값
  final Place? initialPlace;                // Mode C 초기값
  final int groupId;                         // 장소 조회용 그룹 ID
  final Function(LocationMode mode, String? text, Place? place) onChanged;

  const LocationSelector({
    Key? key,
    this.initialMode = LocationMode.none,
    this.initialLocationText,
    this.initialPlace,
    required this.groupId,
    required this.onChanged,
  }) : super(key: key);
}

enum LocationMode {
  none,   // Mode A: 장소 없음
  text,   // Mode B: 수동 입력
  place,  // Mode C: 장소 선택
}
```

**UI 구조**:
```
┌─────────────────────────────────────┐
│ 장소 설정                            │
├─────────────────────────────────────┤
│ [장소 없음] [직접 입력] [장소 선택]  │ ← SegmentedButton
├─────────────────────────────────────┤
│ [모드별 입력 필드 영역]              │
│                                      │
│ Mode A: (빈 공간)                    │
│ Mode B: TextField (장소명 입력)      │
│ Mode C: PlaceSelector 컴포넌트       │
└─────────────────────────────────────┘
```

**구현 예시**:
```dart
// presentation/widgets/calendar/location_selector.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/place_models.dart';
import 'place_selector.dart';

enum LocationMode { none, text, place }

class LocationSelector extends StatefulWidget {
  final LocationMode initialMode;
  final String? initialLocationText;
  final Place? initialPlace;
  final int groupId;
  final Function(LocationMode mode, String? text, Place? place) onChanged;

  const LocationSelector({
    Key? key,
    this.initialMode = LocationMode.none,
    this.initialLocationText,
    this.initialPlace,
    required this.groupId,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  late LocationMode _selectedMode;
  final TextEditingController _textController = TextEditingController();
  Place? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _textController.text = widget.initialLocationText ?? '';
    _selectedPlace = widget.initialPlace;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleModeChange(LocationMode mode) {
    setState(() {
      _selectedMode = mode;

      // 모드 전환 시 값 초기화
      if (mode != LocationMode.text) _textController.clear();
      if (mode != LocationMode.place) _selectedPlace = null;

      // 부모 컴포넌트에 변경 알림
      _notifyChange();
    });
  }

  void _notifyChange() {
    switch (_selectedMode) {
      case LocationMode.none:
        widget.onChanged(LocationMode.none, null, null);
        break;
      case LocationMode.text:
        widget.onChanged(LocationMode.text, _textController.text, null);
        break;
      case LocationMode.place:
        widget.onChanged(LocationMode.place, null, _selectedPlace);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 레이블
        Text('장소 설정', style: AppTypography.labelLarge),
        SizedBox(height: AppSpacing.xs),

        // 모드 선택 탭
        SegmentedButton<LocationMode>(
          segments: const [
            ButtonSegment(
              value: LocationMode.none,
              label: Text('장소 없음'),
              icon: Icon(Icons.not_interested, size: 18),
            ),
            ButtonSegment(
              value: LocationMode.text,
              label: Text('직접 입력'),
              icon: Icon(Icons.edit_location, size: 18),
            ),
            ButtonSegment(
              value: LocationMode.place,
              label: Text('장소 선택'),
              icon: Icon(Icons.place, size: 18),
            ),
          ],
          selected: {_selectedMode},
          onSelectionChanged: (Set<LocationMode> selected) {
            _handleModeChange(selected.first);
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return AppColors.actionTonalBg;
              }
              return Colors.transparent;
            }),
            foregroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return AppColors.actionPrimary;
              }
              return AppColors.neutral700;
            }),
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // 모드별 입력 필드
        AnimatedSwitcher(
          duration: Duration(milliseconds: AppMotion.standard),
          child: _buildInputField(),
        ),
      ],
    );
  }

  Widget _buildInputField() {
    switch (_selectedMode) {
      case LocationMode.none:
        return SizedBox.shrink(key: ValueKey('none'));

      case LocationMode.text:
        return TextField(
          key: ValueKey('text'),
          controller: _textController,
          decoration: InputDecoration(
            labelText: '장소명',
            hintText: '예: 학생회관 2층',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
          ),
          onChanged: (_) => _notifyChange(),
        );

      case LocationMode.place:
        return PlaceSelector(
          key: ValueKey('place'),
          groupId: widget.groupId,
          initialPlace: _selectedPlace,
          onPlaceSelected: (place) {
            setState(() {
              _selectedPlace = place;
              _notifyChange();
            });
          },
        );
    }
  }
}
```

### 2.2. PlaceSelector 컴포넌트

**역할**: 사용 가능한 장소 목록 표시 및 선택

**Props**:
```dart
class PlaceSelector extends ConsumerStatefulWidget {
  final int groupId;
  final Place? initialPlace;
  final Function(Place) onPlaceSelected;

  const PlaceSelector({
    Key? key,
    required this.groupId,
    this.initialPlace,
    required this.onPlaceSelected,
  }) : super(key: key);
}
```

**UI 구조**:
```
┌─────────────────────────────────────┐
│ 선택된 장소: AISC랩실 (60주년-18203) │
│ [변경]                               │
├─────────────────────────────────────┤
│ 또는 검색창...                       │
└─────────────────────────────────────┘

[장소 선택 다이얼로그]
┌─────────────────────────────────────┐
│ 🔍 장소 검색                         │
├─────────────────────────────────────┤
│ ▼ 60주년 기념관                      │
│   • AISC랩실 (18203) - 수용 30명     │
│   • AI/SW 세미나실 (18204) - 50명    │
├─────────────────────────────────────┤
│ ▼ 학생회관                           │
│   • 소회의실 (201) - 20명            │
└─────────────────────────────────────┘
```

**API 통합**:
```dart
// core/services/place_service.dart
class PlaceService {
  final Dio _dio;

  Future<List<Place>> getAvailablePlaces(int groupId) async {
    final response = await _dio.get(
      '/api/groups/$groupId/available-places',
    );

    if (response.data['success']) {
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Place.fromJson(json)).toList();
    }

    throw Exception(response.data['error']['message']);
  }
}

// core/models/place_models.dart
class Place {
  final int id;
  final int managingGroupId;
  final String managingGroupName;
  final String building;
  final String roomNumber;
  final String? alias;
  final String displayName;
  final int capacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Place({
    required this.id,
    required this.managingGroupId,
    required this.managingGroupName,
    required this.building,
    required this.roomNumber,
    this.alias,
    required this.displayName,
    required this.capacity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      managingGroupId: json['managingGroupId'],
      managingGroupName: json['managingGroupName'],
      building: json['building'],
      roomNumber: json['roomNumber'],
      alias: json['alias'],
      displayName: json['displayName'],
      capacity: json['capacity'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
```

**구현 예시**:
```dart
// presentation/widgets/calendar/place_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/place_models.dart';
import '../../../core/services/place_service.dart';
import '../../providers/place_provider.dart';

class PlaceSelector extends ConsumerStatefulWidget {
  final int groupId;
  final Place? initialPlace;
  final Function(Place) onPlaceSelected;

  const PlaceSelector({
    Key? key,
    required this.groupId,
    this.initialPlace,
    required this.onPlaceSelected,
  }) : super(key: key);

  @override
  ConsumerState<PlaceSelector> createState() => _PlaceSelectorState();
}

class _PlaceSelectorState extends ConsumerState<PlaceSelector> {
  Place? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _selectedPlace = widget.initialPlace;
  }

  Future<void> _showPlaceDialog() async {
    final selected = await showDialog<Place>(
      context: context,
      builder: (context) => PlacePickerDialog(groupId: widget.groupId),
    );

    if (selected != null) {
      setState(() {
        _selectedPlace = selected;
      });
      widget.onPlaceSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral300),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedPlace != null) ...[
            Text('선택된 장소', style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral600,
            )),
            SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Icon(Icons.place, color: AppColors.actionPrimary, size: 20),
                SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    _selectedPlace!.displayName,
                    style: AppTypography.bodyLarge,
                  ),
                ),
                TextButton(
                  onPressed: _showPlaceDialog,
                  child: Text('변경'),
                ),
              ],
            ),
            Text(
              '${_selectedPlace!.building} - 수용인원: ${_selectedPlace!.capacity}명',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ] else ...[
            Center(
              child: TextButton.icon(
                onPressed: _showPlaceDialog,
                icon: Icon(Icons.add_location),
                label: Text('장소 선택하기'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 장소 선택 다이얼로그
class PlacePickerDialog extends ConsumerStatefulWidget {
  final int groupId;

  const PlacePickerDialog({Key? key, required this.groupId}) : super(key: key);

  @override
  ConsumerState<PlacePickerDialog> createState() => _PlacePickerDialogState();
}

class _PlacePickerDialogState extends ConsumerState<PlacePickerDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(availablePlacesProvider(widget.groupId));

    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.search, color: AppColors.actionPrimary),
                SizedBox(width: AppSpacing.xs),
                Text('장소 선택', style: AppTypography.headlineLarge),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),

            // 검색 필드
            TextField(
              decoration: InputDecoration(
                hintText: '건물명, 호실 검색...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
            SizedBox(height: AppSpacing.sm),

            // 장소 목록
            Expanded(
              child: placesAsync.when(
                data: (places) {
                  // 검색 필터링
                  final filtered = places.where((place) {
                    if (_searchQuery.isEmpty) return true;
                    return place.building.toLowerCase().contains(_searchQuery) ||
                           place.roomNumber.toLowerCase().contains(_searchQuery) ||
                           (place.alias?.toLowerCase().contains(_searchQuery) ?? false);
                  }).toList();

                  // 건물별 그룹화
                  final grouped = <String, List<Place>>{};
                  for (final place in filtered) {
                    grouped.putIfAbsent(place.building, () => []).add(place);
                  }

                  return ListView(
                    children: grouped.entries.map((entry) {
                      return ExpansionTile(
                        title: Text(entry.key, style: AppTypography.titleLarge),
                        initiallyExpanded: true,
                        children: entry.value.map((place) {
                          return ListTile(
                            leading: Icon(Icons.meeting_room,
                              color: AppColors.actionPrimary),
                            title: Text(place.displayName),
                            subtitle: Text('수용인원: ${place.capacity}명'),
                            onTap: () => Navigator.pop(context, place),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('장소 목록을 불러올 수 없습니다: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2.3. GroupEventFormDialog 통합

**수정 포인트**:
- 기존 location 필드를 LocationSelector로 대체
- 일정 생성/수정 시 3가지 모드에 따라 요청 데이터 구성
- 에러 처리 강화 (409, 400, 403 에러 처리)

**통합 예시**:
```dart
// presentation/pages/workspace/group_event_form_dialog.dart

class GroupEventFormDialog extends ConsumerStatefulWidget {
  final int groupId;
  final GroupEvent? eventToEdit; // null이면 생성, 값이 있으면 수정

  // ...
}

class _GroupEventFormDialogState extends ConsumerState<GroupEventFormDialog> {
  // 장소 상태
  LocationMode _locationMode = LocationMode.none;
  String? _locationText;
  Place? _selectedPlace;

  @override
  void initState() {
    super.initState();

    // 수정 모드일 경우 기존 값 로드
    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      if (event.place != null) {
        _locationMode = LocationMode.place;
        _selectedPlace = event.place;
      } else if (event.locationText != null && event.locationText!.isNotEmpty) {
        _locationMode = LocationMode.text;
        _locationText = event.locationText;
      } else {
        _locationMode = LocationMode.none;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // ... 기존 필드 (제목, 설명, 날짜, 시간 등) ...

            // 장소 선택 컴포넌트
            LocationSelector(
              initialMode: _locationMode,
              initialLocationText: _locationText,
              initialPlace: _selectedPlace,
              groupId: widget.groupId,
              onChanged: (mode, text, place) {
                setState(() {
                  _locationMode = mode;
                  _locationText = text;
                  _selectedPlace = place;
                });
              },
            ),

            // ... 반복 일정 설정 ...

            // 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소'),
                ),
                SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: Text(widget.eventToEdit == null ? '생성' : '수정'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // 1. 요청 데이터 구성
    final requestData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      'startTime': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00',
      'endTime': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00',
      'isAllDay': _isAllDay,
      'isOfficial': _isOfficial,
      'color': _selectedColor,
    };

    // 2. 장소 정보 추가 (모드별)
    switch (_locationMode) {
      case LocationMode.none:
        // locationText, placeId 모두 null (생략)
        break;
      case LocationMode.text:
        requestData['locationText'] = _locationText;
        break;
      case LocationMode.place:
        requestData['placeId'] = _selectedPlace!.id;
        break;
    }

    // 3. 반복 일정 정보 (있을 경우)
    if (_isRecurring) {
      requestData['recurrence'] = {
        'type': _recurrenceType,
        'daysOfWeek': _selectedDaysOfWeek,
      };
    }

    // 4. API 호출
    try {
      if (widget.eventToEdit == null) {
        // 생성
        await ref.read(groupEventServiceProvider).createEvent(
          widget.groupId,
          requestData,
        );
      } else {
        // 수정
        await ref.read(groupEventServiceProvider).updateEvent(
          widget.groupId,
          widget.eventToEdit!.id,
          requestData,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // 성공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정이 저장되었습니다')),
        );
      }
    } on DioException catch (e) {
      _handleApiError(e);
    }
  }

  void _handleApiError(DioException e) {
    final errorCode = e.response?.data['error']?['code'];
    final errorMessage = e.response?.data['error']?['message'];

    String userMessage = errorMessage ?? '일정 저장 실패';

    switch (errorCode) {
      case 'INVALID_LOCATION_COMBINATION':
        userMessage = '장소는 텍스트 입력 또는 선택 중 하나만 가능합니다.';
        break;
      case 'PLACE_USAGE_NOT_APPROVED':
        userMessage = '이 장소는 아직 사용 승인이 되지 않았습니다. 관리자에게 문의하세요.';
        break;
      case 'OUTSIDE_OPERATING_HOURS':
        userMessage = '운영 시간 외입니다. 다른 시간대를 선택해주세요.';
        break;
      case 'PLACE_BLOCKED_TIME':
        userMessage = '해당 시간대는 예약이 불가능합니다.';
        break;
      case 'RESERVATION_CONFLICT':
        userMessage = '이미 예약된 시간대입니다. 다른 시간을 선택해주세요.';
        break;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('오류'),
          content: Text(userMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            ),
          ],
        ),
      );
    }
  }
}
```

---

## 🔄 3. 상태 관리

### 3.1. Riverpod Provider 구조

**장소 목록 조회 Provider**:
```dart
// presentation/providers/place_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/place_models.dart';
import '../../core/services/place_service.dart';

final placeServiceProvider = Provider<PlaceService>((ref) {
  return PlaceService(ref.read(dioProvider));
});

final availablePlacesProvider = FutureProvider.autoDispose.family<List<Place>, int>(
  (ref, groupId) async {
    final placeService = ref.read(placeServiceProvider);
    return await placeService.getAvailablePlaces(groupId);
  },
);
```

**일정 생성/수정 Provider**:
```dart
// presentation/providers/group_event_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_event_provider.freezed.dart';

@freezed
class CreateEventParams with _$CreateEventParams {
  const factory CreateEventParams({
    required int groupId,
    required Map<String, dynamic> eventData,
  }) = _CreateEventParams;
}

final createGroupEventProvider = FutureProvider.autoDispose.family<void, CreateEventParams>(
  (ref, params) async {
    final eventService = ref.read(groupEventServiceProvider);
    await eventService.createEvent(params.groupId, params.eventData);

    // 성공 후 캘린더 새로고침
    ref.invalidate(groupCalendarEventsProvider(params.groupId));
  },
);
```

### 3.2. 상태 변수

**LocationSelector 내부 상태**:
```dart
class _LocationSelectorState extends State<LocationSelector> {
  late LocationMode _selectedMode;        // 현재 선택된 모드
  late TextEditingController _textController; // Mode B 입력값
  Place? _selectedPlace;                  // Mode C 선택된 장소
}
```

**PlaceSelector 내부 상태**:
```dart
class _PlaceSelectorState extends ConsumerState<PlaceSelector> {
  Place? _selectedPlace;                  // 현재 선택된 장소
}

class _PlacePickerDialogState extends ConsumerState<PlacePickerDialog> {
  String _searchQuery = '';               // 검색 쿼리
}
```

### 3.3. 상태 전이 다이어그램

```
[초기 상태: Mode A - 장소 없음]
           |
           | 사용자가 "직접 입력" 선택
           v
[Mode B - 수동 입력]
  - locationText: String?
  - TextField 활성화
           |
           | 사용자가 "장소 선택" 선택
           v
[Mode C - 장소 선택]
  - selectedPlace: Place?
  - PlaceSelector 표시
  - API 호출: GET /api/groups/{groupId}/available-places
           |
           | 장소 선택 완료
           v
[Place 객체 저장]
  - Place 정보 표시
  - "변경" 버튼 활성화
           |
           | 사용자가 "저장" 버튼 클릭
           v
[일정 생성 API 호출]
  - POST /api/groups/{groupId}/events
  - placeId 포함
           |
           | 3단계 검증
           v
[검증 성공] → [PlaceReservation 자동 생성] → [완료]
[검증 실패] → [에러 메시지 표시] → [사용자 수정]
```

---

## 🔌 4. API 통합

### 4.1. Service 레이어 수정

**PlaceService 추가**:
```dart
// core/services/place_service.dart
import 'package:dio/dio.dart';
import '../models/place_models.dart';

class PlaceService {
  final Dio _dio;

  PlaceService(this._dio);

  /// 그룹이 사용 가능한 장소 목록 조회
  Future<List<Place>> getAvailablePlaces(int groupId) async {
    try {
      final response = await _dio.get(
        '/api/groups/$groupId/available-places',
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => Place.fromJson(json)).toList();
      }

      throw Exception(response.data['error']?['message'] ?? 'Unknown error');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('그룹 멤버만 장소 목록을 조회할 수 있습니다');
      }
      rethrow;
    }
  }
}
```

**GroupEventService 확장**:
```dart
// core/services/group_event_service.dart

class GroupEventService {
  final Dio _dio;

  GroupEventService(this._dio);

  /// 그룹 일정 생성 (장소 통합 버전)
  Future<GroupEvent> createEvent(int groupId, Map<String, dynamic> eventData) async {
    try {
      final response = await _dio.post(
        '/api/groups/$groupId/events',
        data: eventData,
      );

      if (response.data['success'] == true) {
        return GroupEvent.fromJson(response.data['data']);
      }

      throw Exception(response.data['error']?['message'] ?? 'Unknown error');
    } on DioException catch (e) {
      _handleEventCreationError(e);
      rethrow;
    }
  }

  /// 그룹 일정 수정 (장소 변경 지원)
  Future<GroupEvent> updateEvent(
    int groupId,
    int eventId,
    Map<String, dynamic> eventData,
  ) async {
    try {
      final response = await _dio.patch(
        '/api/groups/$groupId/events/$eventId',
        data: eventData,
      );

      if (response.data['success'] == true) {
        return GroupEvent.fromJson(response.data['data']);
      }

      throw Exception(response.data['error']?['message'] ?? 'Unknown error');
    } on DioException catch (e) {
      _handleEventCreationError(e);
      rethrow;
    }
  }

  void _handleEventCreationError(DioException e) {
    final errorCode = e.response?.data['error']?['code'];

    // 에러 코드별 처리는 UI 레이어에서 수행
    // 여기서는 로깅만 수행
    print('Event creation/update error: $errorCode');
  }
}
```

### 4.2. DTO 모델

**Place 모델**:
```dart
// core/models/place_models.dart
class Place {
  final int id;
  final int managingGroupId;
  final String managingGroupName;
  final String building;
  final String roomNumber;
  final String? alias;
  final String displayName;
  final int capacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Place({
    required this.id,
    required this.managingGroupId,
    required this.managingGroupName,
    required this.building,
    required this.roomNumber,
    this.alias,
    required this.displayName,
    required this.capacity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as int,
      managingGroupId: json['managingGroupId'] as int,
      managingGroupName: json['managingGroupName'] as String,
      building: json['building'] as String,
      roomNumber: json['roomNumber'] as String,
      alias: json['alias'] as String?,
      displayName: json['displayName'] as String,
      capacity: json['capacity'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'managingGroupId': managingGroupId,
      'managingGroupName': managingGroupName,
      'building': building,
      'roomNumber': roomNumber,
      'alias': alias,
      'displayName': displayName,
      'capacity': capacity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
```

**GroupEventRequest 확장**:
```dart
// core/models/group_event_models.dart

class CreateGroupEventRequest {
  final String title;
  final String? description;

  // 장소 필드 (3가지 모드)
  final String? locationText;  // Mode B
  final int? placeId;          // Mode C

  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final String endTime;
  final bool isAllDay;
  final bool isOfficial;
  final String color;
  final RecurrencePattern? recurrence;

  CreateGroupEventRequest({
    required this.title,
    this.description,
    this.locationText,
    this.placeId,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.isOfficial = false,
    required this.color,
    this.recurrence,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'startTime': startTime,
      'endTime': endTime,
      'isAllDay': isAllDay,
      'isOfficial': isOfficial,
      'color': color,
    };

    // 장소 정보 추가 (null이 아닐 경우만)
    if (locationText != null) {
      json['locationText'] = locationText;
    }
    if (placeId != null) {
      json['placeId'] = placeId;
    }

    // 반복 일정 정보
    if (recurrence != null) {
      json['recurrence'] = recurrence!.toJson();
    }

    return json;
  }
}
```

### 4.3. 에러 처리 전략

**에러 코드 매핑**:
```dart
// core/utils/event_error_handler.dart

class EventErrorHandler {
  static String getUserMessage(String? errorCode, String? defaultMessage) {
    switch (errorCode) {
      case 'INVALID_LOCATION_COMBINATION':
        return '장소는 텍스트 입력 또는 선택 중 하나만 가능합니다.';

      case 'PLACE_NOT_FOUND':
        return '선택한 장소를 찾을 수 없습니다. 장소 목록을 새로고침하세요.';

      case 'PLACE_USAGE_NOT_APPROVED':
        return '이 장소는 아직 사용 승인이 되지 않았습니다.\n관리자에게 문의하세요.';

      case 'OUTSIDE_OPERATING_HOURS':
        return '운영 시간 외입니다. 운영 시간을 확인하고 다른 시간대를 선택해주세요.';

      case 'PLACE_BLOCKED_TIME':
        return '해당 시간대는 예약이 불가능합니다.\n다른 시간을 선택해주세요.';

      case 'RESERVATION_CONFLICT':
        return '이미 예약된 시간대입니다.\n다른 시간 또는 다른 장소를 선택해주세요.';

      case 'FORBIDDEN':
        return '권한이 없습니다. 그룹 멤버만 일정을 생성할 수 있습니다.';

      default:
        return defaultMessage ?? '일정 저장에 실패했습니다.';
    }
  }

  static String getActionHint(String? errorCode) {
    switch (errorCode) {
      case 'RESERVATION_CONFLICT':
        return '💡 다른 시간대를 선택하거나, 다른 장소를 검색해보세요.';

      case 'OUTSIDE_OPERATING_HOURS':
        return '💡 장소 상세 정보에서 운영 시간을 확인하세요.';

      case 'PLACE_USAGE_NOT_APPROVED':
        return '💡 그룹 관리자가 장소 사용 신청을 먼저 해야 합니다.';

      default:
        return '';
    }
  }
}
```

---

## 📱 5. UI/UX 플로우

### 5.1. 일정 생성 플로우

#### 시나리오 1: Mode A (장소 없음)
```
1. 사용자가 "일정 추가" 버튼 클릭
2. GroupEventFormDialog 표시
3. 제목, 날짜, 시간 입력
4. 장소 설정 섹션에서 "장소 없음" 선택 (기본값)
5. "생성" 버튼 클릭
6. API 호출: POST /api/groups/{groupId}/events
   - locationText: null
   - placeId: null
7. 성공 → 다이얼로그 닫기 + 스낵바 표시
```

#### 시나리오 2: Mode B (수동 입력)
```
1-3. [동일]
4. 장소 설정 섹션에서 "직접 입력" 선택
5. TextField에 "학생회관 2층" 입력
6. "생성" 버튼 클릭
7. API 호출:
   - locationText: "학생회관 2층"
   - placeId: null
8. 성공 → 완료
```

#### 시나리오 3: Mode C (장소 선택)
```
1-3. [동일]
4. 장소 설정 섹션에서 "장소 선택" 클릭
5. PlaceSelector 표시
6. "장소 선택하기" 버튼 클릭
7. PlacePickerDialog 표시
8. API 호출: GET /api/groups/{groupId}/available-places
9. 장소 목록 표시 (건물별 그룹화)
10. "AISC랩실 (60주년-18203)" 선택
11. 다이얼로그 닫기, 선택된 장소 표시
12. "생성" 버튼 클릭
13. API 호출:
    - locationText: null
    - placeId: 1
14. 백엔드 검증:
    a. 권한 확인 (PlaceUsageGroup APPROVED)
    b. 운영 시간 확인
    c. 차단 시간 확인
    d. 예약 충돌 확인
15. 검증 성공 → PlaceReservation 자동 생성 → 완료
```

### 5.2. 일정 수정 플로우

```
1. 사용자가 기존 일정 클릭
2. GroupEventFormDialog 표시 (수정 모드)
3. 기존 값 로드:
   - event.place != null → Mode C 초기화
   - event.locationText != null → Mode B 초기화
   - 둘 다 null → Mode A 초기화
4. 사용자가 장소 모드 변경 (예: Mode C → Mode B)
5. 새로운 장소 정보 입력
6. "수정" 버튼 클릭
7. API 호출: PATCH /api/groups/{groupId}/events/{eventId}
8. 백엔드 처리:
   - 기존 PlaceReservation 삭제 (Mode C → Mode A/B)
   - 새 PlaceReservation 생성 (Mode A/B → Mode C)
9. 성공 → 캘린더 새로고침
```

### 5.3. 에러 발생 시 플로우

```
[예약 충돌 발생]
1. 사용자가 일정 생성 시도 (Mode C)
2. API 호출: POST /api/groups/{groupId}/events
3. 백엔드 응답: 409 Conflict
   {
     "success": false,
     "error": {
       "code": "RESERVATION_CONFLICT",
       "message": "이미 예약된 시간대입니다."
     }
   }
4. 프론트엔드 에러 핸들러:
   - EventErrorHandler.getUserMessage() 호출
   - AlertDialog 표시:
     제목: "예약 실패"
     내용: "이미 예약된 시간대입니다.\n다른 시간 또는 다른 장소를 선택해주세요."
     힌트: "💡 다른 시간대를 선택하거나, 다른 장소를 검색해보세요."
5. 사용자 액션:
   - "확인" → 다이얼로그 닫기, 폼 유지 (수정 가능)
   - 시간 변경 또는 다른 장소 선택 후 재시도
```

### 5.4. 플로우 다이어그램

```
┌─────────────────────────────────────────────────────────────┐
│                    일정 생성 플로우                          │
└─────────────────────────────────────────────────────────────┘

[사용자] → "일정 추가" 버튼 클릭
              ↓
    [GroupEventFormDialog 표시]
              ↓
    ┌─────────────────────────┐
    │ 제목, 날짜, 시간 입력    │
    └─────────────────────────┘
              ↓
    ┌─────────────────────────┐
    │  LocationSelector 표시   │
    │  ┌─────────────────┐    │
    │  │ ○ 장소 없음     │    │
    │  │ ○ 직접 입력     │    │
    │  │ ● 장소 선택     │←──┐│
    │  └─────────────────┘    ││
    └─────────────────────────┘│
              ↓                │
    [장소 선택 클릭]           │
              ↓                │
    ┌─────────────────────────┐│
    │ PlacePickerDialog       ││
    │                         ││
    │ GET /api/groups/{id}/   ││
    │   available-places      ││
    │         ↓               ││
    │ ┌─────────────────────┐ ││
    │ │ 60주년 기념관       │ ││
    │ │  • AISC랩실 ←──────┼─┘│
    │ │  • 세미나실         │  │
    │ │ 학생회관            │  │
    │ │  • 소회의실         │  │
    │ └─────────────────────┘  │
    └─────────────────────────┘
              ↓
    [장소 선택 완료]
              ↓
    ┌─────────────────────────┐
    │ 선택된 장소: AISC랩실    │
    │ 60주년 기념관-18203      │
    │ 수용인원: 30명           │
    │ [변경]                   │
    └─────────────────────────┘
              ↓
    [생성 버튼 클릭]
              ↓
    POST /api/groups/{groupId}/events
    { placeId: 1, ... }
              ↓
    ┌─────────────────────────┐
    │ 백엔드 3단계 검증        │
    │ 1. 권한 확인            │
    │ 2. 운영 시간            │
    │ 3. 차단 시간            │
    │ 4. 예약 충돌            │
    └─────────────────────────┘
         ↓              ↓
    [성공]          [실패: 409]
         ↓              ↓
   PlaceReservation  AlertDialog
   자동 생성         "이미 예약됨"
         ↓              ↓
    [완료]         [사용자 수정]
```

---

## 📅 6. Phase별 구현 계획

### Phase 1: 기본 컴포넌트 구현 (4-5시간)

**목표**: LocationSelector, PlaceSelector 컴포넌트 기본 구조 완성

**작업 내용**:

1. **LocationSelector 구현** (2시간)
   - [✅] LocationMode enum 정의
   - [✅] SegmentedButton UI 구현
   - [✅] 모드 전환 로직 구현
   - [✅] Mode B: TextField 통합
   - [✅] 상태 변경 콜백 구현

2. **PlaceSelector 기본 UI** (2시간)
   - [✅] PlaceSelector 위젯 구조 생성
   - [✅] 선택된 장소 표시 UI
   - [✅] "장소 선택하기" 버튼
   - [✅] PlacePickerDialog 기본 레이아웃

3. **모델 정의** (1시간)
   - [✅] Place 모델 (core/models/place_models.dart)
   - [✅] CreateGroupEventRequest 확장
   - [✅] UpdateGroupEventRequest 확장

**결과물**:
- `presentation/widgets/calendar/location_selector.dart`
- `presentation/widgets/calendar/place_selector.dart`
- `core/models/place_models.dart`
- `core/models/group_event_models.dart` (수정)

**체크리스트**:
- [✅] LocationSelector가 3가지 모드를 올바르게 표시하는가?
- [✅] 모드 전환 시 이전 입력값이 초기화되는가?
- [✅] onChanged 콜백이 올바른 값을 전달하는가?
- [✅] PlaceSelector UI가 디자인 시스템을 따르는가?

### Phase 2: 폼 통합 및 API 연동 (6-7시간)

**목표**: GroupEventFormDialog 통합, API 연동, 장소 목록 조회

**작업 내용**:

1. **PlaceService 구현** (2시간)
   - [✅] PlaceService 클래스 생성
   - [✅] getAvailablePlaces() 메서드 구현
   - [✅] 에러 처리 (403 Forbidden)
   - [✅] Riverpod Provider 정의

2. **PlacePickerDialog 완성** (2시간)
   - [🚧] API 호출 통합 (availablePlacesProvider)
   - [🚧] 건물별 그룹화 로직
   - [🚧] 검색 기능 구현
   - [🚧] 장소 선택 처리

3. **GroupEventFormDialog 수정** (2-3시간)
   - [✅] 기존 location 필드 제거
   - [✅] LocationSelector 통합
   - [🚧] 수정 모드 시 기존 값 로드
   - [ ] 일정 생성/수정 API 호출 수정
   - [ ] 요청 데이터 구성 로직 (3가지 모드)

**결과물**:
- `core/services/place_service.dart`
- `presentation/providers/place_provider.dart`
- `presentation/widgets/calendar/place_picker_dialog.dart`
- `presentation/pages/workspace/group_event_form_dialog.dart` (수정)

**체크리스트**:
- [ ] GET /api/groups/{groupId}/available-places 호출이 정상 동작하는가?
- [ ] 장소 목록이 건물별로 그룹화되어 표시되는가?
- [ ] 검색 기능이 건물명, 호실, 별칭을 모두 검색하는가?
- [ ] 장소 선택 후 폼에 올바르게 반영되는가?
- [ ] 일정 생성 시 placeId가 요청에 포함되는가?

### Phase 3: 에러 처리 및 검증 (4-5시간)

**목표**: 3단계 검증 에러 처리, 사용자 피드백 강화

**작업 내용**:

1. **에러 핸들러 구현** (2시간)
   - [ ] EventErrorHandler 클래스 생성
   - [ ] 에러 코드별 사용자 메시지 매핑
   - [ ] 액션 힌트 메시지 추가
   - [ ] 에러 다이얼로그 공통 컴포넌트

2. **GroupEventService 수정** (2시간)
   - [ ] createEvent() 메서드 수정
   - [ ] updateEvent() 메서드 수정
   - [ ] DioException 에러 처리
   - [ ] 에러 로깅

3. **UI 에러 처리 통합** (1-2시간)
   - [ ] GroupEventFormDialog에 에러 핸들러 통합
   - [ ] 로딩 상태 표시 (CircularProgressIndicator)
   - [ ] 성공 스낵바
   - [ ] 에러 AlertDialog

**결과물**:
- `core/utils/event_error_handler.dart`
- `core/services/group_event_service.dart` (수정)
- `presentation/widgets/common/error_dialog.dart`

**체크리스트**:
- [ ] RESERVATION_CONFLICT 에러 시 적절한 메시지가 표시되는가?
- [ ] OUTSIDE_OPERATING_HOURS 에러 시 힌트가 표시되는가?
- [ ] 로딩 중에 버튼이 비활성화되는가?
- [ ] 성공 시 스낵바가 표시되는가?
- [ ] 에러 메시지가 사용자 친화적인가?

### Phase 4: UI/UX 개선 및 테스트 (4-5시간)

**목표**: 반응형 디자인, 접근성, 사용자 경험 개선

**작업 내용**:

1. **반응형 디자인** (2시간)
   - [ ] 모바일 레이아웃 최적화
   - [ ] 데스크톱 레이아웃 최적화
   - [ ] PlacePickerDialog 크기 조정
   - [ ] 브레이크포인트별 패딩 조정

2. **접근성 개선** (1시간)
   - [ ] Semantics 레이블 추가
   - [ ] 포커스 링 스타일 적용
   - [ ] 키보드 네비게이션 지원

3. **애니메이션 및 전환** (1시간)
   - [ ] 모드 전환 애니메이션
   - [ ] 다이얼로그 진입 효과
   - [ ] 로딩 인디케이터 스무스 전환

4. **테스트 및 디버깅** (1-2시간)
   - [ ] 3가지 모드 시나리오 테스트
   - [ ] 에러 시나리오 테스트 (409, 400, 403)
   - [ ] 반복 일정 + 장소 예약 테스트
   - [ ] 일정 수정 시 장소 변경 테스트

**결과물**:
- 반응형 디자인 적용된 모든 컴포넌트
- 접근성 향상된 UI
- 부드러운 애니메이션

**체크리스트**:
- [ ] 모바일에서 PlacePickerDialog가 전체 화면으로 표시되는가?
- [ ] 데스크톱에서 다이얼로그 크기가 적절한가?
- [ ] 포커스 링이 모든 인터랙티브 요소에 표시되는가?
- [ ] 애니메이션이 120-160ms 내에 완료되는가?
- [ ] 모든 시나리오에서 정상 동작하는가?

---

## 🛠️ 7. 기술 스택 및 라이브러리

### 7.1. 핵심 기술

```yaml
dependencies:
  flutter: 3.x
  flutter_riverpod: ^2.4.0  # 상태 관리
  dio: ^5.4.0               # HTTP 클라이언트
  freezed_annotation: ^2.4.0 # 불변 모델
  json_annotation: ^4.8.0   # JSON 직렬화

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

### 7.2. 프로젝트별 패키지

**이미 설치된 패키지**:
- `google_sign_in` - 인증
- `go_router` - 라우팅
- `responsive_framework` - 반응형 레이아웃

**새로 추가 필요**:
- 없음 (기존 스택으로 충분)

### 7.3. 디자인 시스템 활용

**AppColors** (core/theme/app_colors.dart):
```dart
actionPrimary: #1D4ED8  // 장소 선택 버튼
actionTonalBg: #EAF2FF  // 선택된 모드 배경
neutral600: #64748B     // 보조 텍스트
error: #E63946          // 에러 메시지
```

**AppTypography** (core/theme/app_typography.dart):
```dart
headlineLarge: 22px/600  // 다이얼로그 제목
titleLarge: 16px/600     // 장소명
bodyLarge: 16px/400      // 설명 텍스트
labelLarge: 14px/600     // 폼 레이블
```

**AppSpacing** (core/theme/app_spacing.dart):
```dart
sm: 16px   // 컴포넌트 내부 여백
md: 24px   // 컴포넌트 간 여백
lg: 32px   // 다이얼로그 패딩
```

---

## ⏱️ 8. 예상 작업 시간

| Phase | 작업 내용 | 예상 시간 | 우선순위 |
|-------|-----------|-----------|----------|
| **Phase 1** | 기본 컴포넌트 구현 | 4-5시간 | 높음 |
| **Phase 2** | 폼 통합 및 API 연동 | 6-7시간 | 높음 |
| **Phase 3** | 에러 처리 및 검증 | 4-5시간 | 중간 |
| **Phase 4** | UI/UX 개선 및 테스트 | 4-5시간 | 중간 |
| **총 예상 시간** | | **18-22시간** | |

**세부 시간 배분**:

1. **컴포넌트 개발** (10-12시간)
   - LocationSelector: 2시간
   - PlaceSelector: 2시간
   - PlacePickerDialog: 2시간
   - GroupEventFormDialog 수정: 2-3시간
   - 에러 다이얼로그: 1시간
   - 반응형 조정: 2시간

2. **API 통합** (4-5시간)
   - PlaceService: 2시간
   - GroupEventService 수정: 2시간
   - Provider 설정: 1시간

3. **테스트 및 디버깅** (4-5시간)
   - 시나리오 테스트: 2시간
   - 에러 처리 테스트: 1-2시간
   - UI/UX 개선: 1-2시간

**병렬 작업 가능**:
- Phase 1 완료 후 Phase 2와 Phase 3 일부 병렬 가능
- UI 개선은 Phase 4로 분리하여 독립적으로 진행 가능

---

## 📚 9. 참조 및 링크

### 백엔드 설계
- [그룹 일정-장소 예약 통합 설계](group-event-place-integration.md) - 백엔드 Phase 1-4 완료
- [API 참조](../implementation/api-reference.md) - GET /api/groups/{groupId}/available-places
- [데이터베이스 참조](../implementation/database-reference.md) - GroupEvent, Place, PlaceReservation

### 도메인 개념
- [캘린더 시스템](../concepts/calendar-system.md) - 전체 캘린더 아키텍처
- [장소 관리](../concepts/calendar-place-management.md) - 장소 예약 시스템
- [캘린더 설계 결정사항](../concepts/calendar-design-decisions.md) - DD-CAL-009

### 프론트엔드 가이드
- [프론트엔드 구현 가이드](../implementation/frontend-guide.md) - 아키텍처 패턴
- [디자인 시스템](../ui-ux/concepts/design-system.md) - 색상, 타이포그래피, 간격
- [워크스페이스 페이지 추가 가이드](../implementation/workspace-page-implementation-guide.md) - 완전 체크리스트

### 에러 처리
- [권한 에러](../troubleshooting/permission-errors.md) - 권한 관련 에러 가이드
- [일반적 에러](../troubleshooting/common-errors.md) - 공통 에러 처리

---

## ✅ 10. 구현 완료 기준

### 10.1. 기능 요구사항

- [ ] 3가지 장소 모드 (없음/수동/선택) 선택 가능
- [ ] 사용 가능한 장소 목록 조회 (GET /api/groups/{groupId}/available-places)
- [ ] 건물별 그룹화 및 검색 기능
- [ ] 장소 선택 시 상세 정보 표시
- [ ] 일정 생성 시 placeId 전송
- [ ] 일정 수정 시 장소 변경 지원
- [ ] 반복 일정 + 장소 예약 처리

### 10.2. 에러 처리

- [ ] INVALID_LOCATION_COMBINATION (400) - 사용자 메시지 표시
- [ ] PLACE_USAGE_NOT_APPROVED (403) - 권한 안내
- [ ] OUTSIDE_OPERATING_HOURS (400) - 운영 시간 안내
- [ ] PLACE_BLOCKED_TIME (400) - 차단 시간 안내
- [ ] RESERVATION_CONFLICT (409) - 충돌 안내 + 힌트
- [ ] FORBIDDEN (403) - 멤버십 확인

### 10.3. UI/UX 요구사항

- [ ] 디자인 시스템 준수 (AppColors, AppTypography, AppSpacing)
- [ ] 반응형 디자인 (모바일/데스크톱)
- [ ] 접근성 (Semantics, 포커스 링, 키보드 네비게이션)
- [ ] 로딩 상태 표시
- [ ] 성공/실패 피드백 (스낵바/다이얼로그)
- [ ] 부드러운 애니메이션 (120-160ms)

### 10.4. 테스트 요구사항

- [ ] Mode A: 장소 없음 일정 생성 성공
- [ ] Mode B: 수동 입력 일정 생성 성공
- [ ] Mode C: 장소 선택 일정 생성 성공
- [ ] Mode C: 예약 충돌 시 에러 처리
- [ ] Mode C: 운영 시간 외 에러 처리
- [ ] 반복 일정 + 장소 예약 성공
- [ ] 일정 수정 시 장소 변경 성공

---

**작성일**: 2025-10-18
**최종 업데이트**: 2025-10-18
**작성자**: Frontend Development Specialist
**검토 대상**: 백엔드 설계(group-event-place-integration.md), API 문서, 디자인 시스템
