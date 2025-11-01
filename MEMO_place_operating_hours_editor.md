# 장소 운영시간 에디터 개발 명세서

## 1. 프로젝트 개요

### 1.1 목적 및 목표
- **목적**: 장소의 요일별 운영시간을 직관적으로 설정할 수 있는 비주얼 에디터 구현
- **목표**:
  - WeeklyScheduleEditor를 장소 운영시간 설정에 특화된 형태로 커스터마이징
  - 드래그 기반 시간 선택으로 UX 개선
  - 브레이크 타임(금지시간) 설정 지원
  - 백엔드 PlaceOperatingHours + PlaceRestrictedTime 모델과 완벽 호환

### 1.2 기대 효과
- **사용자 편의성**: 텍스트 입력 대신 시각적 드래그로 직관적 설정
- **설정 정확성**: 시간 충돌 방지 및 유효성 검증
- **개발 효율성**: WeeklyScheduleEditor 재사용으로 개발 시간 단축

### 1.3 제약사항
- 기존 WeeklyScheduleEditor의 핵심 로직 유지 (레이아웃 안정성 보장)
- 백엔드 모델 변경 없음 (DayOperatingHours + isClosed 방식)
- 모바일 최소 너비 이하에서 가로 스크롤로 대응
- 일괄 적용 기능 제외 (요일별 개별 설정만 지원)

## 2. 요구사항 정의

### 2.1 기능 요구사항

#### F1. 모드 전환 (토글 버튼)
- **설명**: 운영시간 설정 모드와 브레이크 타임 설정 모드 전환
- **UI**: 헤더에 토글 버튼 배치 (예: "운영시간 설정" ↔ "브레이크 타임 설정")
- **동작**:
  - 토글 시 즉시 모드 전환
  - 선택 중인 상태는 초기화
  - 각 모드의 블록은 다른 색상으로 구분

#### F2. 운영시간 선택 모드
- **설명**: 드래그로 운영 시간대 설정
- **색상**: 보라색 계열 (브랜드 컬러)
- **동작**:
  - 웹: 클릭 시작 → 드래그 → 클릭 완료
  - 모바일: 롱 프레스 시작 → 드래그 → 릴리즈
- **제약**:
  - 요일별 최대 1개 블록만 허용
  - 기존 블록이 있으면 교체 확인 다이얼로그
  - 브레이크 타임 블록과 겹침 허용 (나중에 브레이크 타임이 우선)

#### F3. 브레이크 타임 선택 모드
- **설명**: 드래그로 금지 시간대 설정
- **색상**: 노란색 (경고 색상)
- **동작**:
  - 웹: 클릭 시작 → 드래그 → 클릭 완료
  - 모바일: 롱 프레스 시작 → 드래그 → 릴리즈
- **제약**:
  - 요일별 여러 개 블록 허용
  - 운영시간 블록 내에만 설정 가능 (외부는 비활성화)
  - 브레이크 타임끼리 겹침 방지

#### F4. 블록 편집 및 삭제
- **삭제**: 블록 클릭 → 컨텍스트 메뉴 → "삭제" 선택
- **에러 처리**: 삭제 실패 시 스낵바 표시

#### F5. 데이터 변환 및 저장
- **프론트엔드 → 백엔드**:
  - 운영시간 블록 → `SetOperatingHoursRequest`
  - 브레이크 타임 블록 → `AddRestrictedTimeRequest` (복수)
- **저장 프로세스**:
  1. 변경 여부 확인 (dirty check)
  2. "저장" 버튼 클릭 시 API 호출
  3. 성공 시 스낵바 + 로컬 상태 업데이트
  4. 실패 시 에러 스낵바 + 롤백

#### F6. 반응형 레이아웃
- **데스크톱 (900px+)**: 표준 뷰 (7일 모두 표시)
- **모바일 (<900px)**: 가로 스크롤 활성화 (최소 너비 보장)

### 2.2 비기능 요구사항

#### NF1. 성능
- 초기 렌더링 시간 < 200ms
- 드래그 인터랙션 지연 < 50ms (60fps 유지)

#### NF2. 호환성
- 플랫폼: Flutter Web (Chrome, Safari, Firefox)
- 모바일: iOS Safari, Android Chrome

#### NF3. 접근성
- ARIA 라벨 제공
- 키보드 네비게이션 지원 (향후 개선)

### 2.3 데이터 요구사항

#### 백엔드 모델
- **PlaceOperatingHours**: 요일별 단일 시간대 (startTime, endTime, isClosed)
- **PlaceRestrictedTime**: 요일별 다중 금지 시간대 (dayOfWeek, startTime, endTime, reason)

#### API 엔드포인트
- `PUT /api/places/{placeId}/operating-hours`: 운영시간 전체 교체
- `POST /api/places/{placeId}/restricted-times`: 금지시간 추가
- `DELETE /api/places/{placeId}/restricted-times/{restrictedTimeId}`: 금지시간 삭제

## 3. UI/UX 설계

### 3.1 화면 구성

```
┌─────────────────────────────────────────────────┐
│ 장소 운영시간 설정                                │
│ [운영시간 설정 | 브레이크 타임 설정] (토글)        │
├─────────────────────────────────────────────────┤
│ 월  화  수  목  금  토  일                         │
├──┬──┬──┬──┬──┬──┬──┤                              │
│00│  │  │  │  │  │  │                              │
│01│  │  │  │  │  │  │                              │
│..│  │  │  │  │  │  │                              │
│09│██│██│██│██│██│  │  │ (보라색 = 운영시간)      │
│10│██│██│██│██│██│  │  │                          │
│11│██│██│██│██│██│  │  │                          │
│12│▓▓│▓▓│▓▓│▓▓│▓▓│  │  │ (노란색 = 브레이크 타임)  │
│13│██│██│██│██│██│  │  │                          │
│..│  │  │  │  │  │  │                              │
│24│  │  │  │  │  │  │                              │
└──┴──┴──┴──┴──┴──┴──┘                              │
│ [취소] [저장]                                      │
└─────────────────────────────────────────────────┘
```

### 3.2 사용자 플로우

#### 운영시간 설정 플로우
```
1. "운영시간 설정" 모드 선택 (기본값)
   ↓
2. 원하는 요일의 시작 시간을 클릭/롱프레스
   ↓
3. 종료 시간까지 드래그
   ↓
4. 클릭 릴리즈/손가락 떼기
   ↓
5. (기존 블록 있으면) 다이얼로그: "기존 운영시간을 변경하시겠습니까?"
   - 확인: 기존 블록 삭제 + 새 블록 생성
   - 취소: 선택 취소
   ↓
6. "저장" 버튼 클릭 → API 호출
   ↓
7. 성공: "운영시간이 저장되었습니다" 스낵바
   실패: "저장 실패" 스낵바 + 원래 상태 복원
```

#### 브레이크 타임 설정 플로우
```
1. "브레이크 타임 설정" 모드 선택
   ↓
2. 운영시간 블록 내부의 시작 시간을 클릭/롱프레스
   ↓
3. 종료 시간까지 드래그 (운영시간 범위 내로 제한)
   ↓
4. 클릭 릴리즈/손가락 떼기
   ↓
5. (겹치는 브레이크 타임 있으면) 에러 스낵바: "이미 설정된 시간대입니다"
   ↓
6. "저장" 버튼 클릭 → API 호출 (복수 POST)
   ↓
7. 성공: "브레이크 타임이 저장되었습니다" 스낵바
   실패: "저장 실패" 스낵바 + 원래 상태 복원
```

#### 블록 삭제 플로우
```
1. 블록 클릭 (운영시간 또는 브레이크 타임)
   ↓
2. 컨텍스트 메뉴 표시: [삭제] [취소]
   ↓
3. "삭제" 선택 시:
   - 운영시간: 해당 요일의 isClosed = true로 설정
   - 브레이크 타임: 즉시 삭제 (저장 버튼 누르면 DELETE API)
   ↓
4. "저장" 버튼 클릭 → API 호출
   ↓
5. 성공: "삭제되었습니다" 스낵바
   실패: "삭제 실패" 스낵바 + 원래 상태 복원
```

### 3.3 인터랙션 디자인

#### 드래그 피드백
- **시작**: 하프틱 피드백 (모바일) + 시작 셀 하이라이트
- **드래그 중**: 선택 영역 반투명 오버레이 표시
- **완료**: 하프틱 피드백 (모바일) + 블록 확정

#### 블록 시각화
- **운영시간**: 보라색 배경 (AppColors.brand.withOpacity(0.8))
- **브레이크 타임**: 노란색 배경 (Colors.amber.withOpacity(0.8))
- **비활성화 영역**: 회색 배경 (AppColors.neutral200)

#### 에러 처리
- **겹침 방지**: 드래그 중 겹치는 영역 빨간색 테두리
- **범위 제한**: 브레이크 타임은 운영시간 외부로 드래그 불가 (시각적으로 차단)

### 3.4 반응형 동작 정의

#### 데스크톱 (900px 이상)
- 7일 전부 표시
- 각 요일 칼럼 최소 너비: 80px

#### 모바일 (<900px)
- 가로 스크롤 활성화
- 각 요일 칼럼 고정 너비: 60px
- 최소 전체 너비: 60px * 7 = 420px

## 4. 기술 스택 및 아키텍처

### 4.1 사용할 컴포넌트 목록

#### 재사용 컴포넌트
- **WeeklyScheduleEditor** (베이스 위젯):
  - TimeGridPainter: 시간 눈금 및 그리드
  - SelectionPainter: 드래그 선택 영역
  - HighlightPainter: 현재 셀 하이라이트
  - EventPainter: 블록 렌더링 (운영시간 및 브레이크 타임)

#### 신규 컴포넌트
- **PlaceOperatingHoursEditor**: WeeklyScheduleEditor를 감싸는 상태 관리 위젯
  - 모드 토글 UI
  - 저장/취소 버튼
  - 데이터 변환 로직

### 4.2 상태 관리 구조

```dart
// 로컬 상태 (Widget State)
class _PlaceOperatingHoursEditorState {
  // 편집 모드
  EditorMode _mode = EditorMode.operatingHours;

  // 운영시간 블록 (요일별 1개)
  Map<DayOfWeek, TimeBlock> _operatingHours = {};

  // 브레이크 타임 블록 (요일별 N개)
  Map<DayOfWeek, List<TimeBlock>> _breakTimes = {};

  // 변경 여부 (dirty check)
  bool _isDirty = false;

  // 초기 데이터 (롤백용)
  Map<DayOfWeek, TimeBlock> _initialOperatingHours = {};
  Map<DayOfWeek, List<TimeBlock>> _initialBreakTimes = {};
}

// 타임 블록 모델
class TimeBlock {
  final int day;       // 0 (월) ~ 6 (일)
  final int startSlot; // 15분 단위 (0 = 00:00, 96 = 24:00)
  final int endSlot;
  final Color color;   // 모드별 색상
}

// 에디터 모드
enum EditorMode {
  operatingHours,  // 운영시간 설정
  breakTime,       // 브레이크 타임 설정
}
```

### 4.3 데이터 흐름

```
[초기 로드]
API Response (PlaceOperatingHoursResponse + RestrictedTimeResponse[])
  ↓
백엔드 → 프론트엔드 변환 (_parseServerData)
  ↓
WeeklyScheduleEditor의 initialEvents로 전달
  ↓
블록 렌더링

[사용자 편집]
드래그 완료
  ↓
로컬 상태 업데이트 (_operatingHours / _breakTimes)
  ↓
WeeklyScheduleEditor 재렌더링 (initialEvents 업데이트)
  ↓
_isDirty = true (저장 버튼 활성화)

[저장]
"저장" 버튼 클릭
  ↓
프론트엔드 → 백엔드 변환 (_buildSaveRequest)
  ↓
API 호출 (PUT + POST[] + DELETE[])
  ↓
성공: _isDirty = false, _initialOperatingHours 업데이트
실패: 롤백 (_initialOperatingHours 복원)
```

## 5. 개발 Phase 상세 계획

### Phase 1: WeeklyScheduleEditor 복사 및 커스터마이징 (1.5시간)

#### 작업 내용
1. **파일 생성**:
   - `place_operating_hours_editor.dart` 생성
   - WeeklyScheduleEditor 코드 복사

2. **불필요한 기능 제거**:
   - 외부 이벤트 표시 기능 제거
   - 다중 일정 생성 기능 제거
   - 오버랩 뷰 토글 제거
   - 장소 선택 기능 제거

3. **기본 레이아웃 조정**:
   - 헤더에 모드 토글 버튼 추가
   - 하단에 저장/취소 버튼 추가
   - 시간 범위 고정 (00:00-24:00)

#### 완료 조건
- [ ] PlaceOperatingHoursEditor 위젯 생성 완료
- [ ] 토글 버튼 UI 추가 완료
- [ ] 저장/취소 버튼 UI 추가 완료
- [ ] 기본 렌더링 정상 동작 (빈 그리드 표시)

#### 의존성
- 없음 (독립 작업)

#### 산출물
- `place_operating_hours_editor.dart` (약 800줄)

### Phase 2: 운영시간 선택 모드 구현 (1.5시간)

#### 작업 내용
1. **드래그 로직 구현**:
   - 웹: 클릭 시작 → 드래그 → 클릭 완료
   - 모바일: 롱 프레스 → 드래그 → 릴리즈

2. **제약 조건 구현**:
   - 요일별 1개 블록만 허용
   - 기존 블록 있으면 교체 확인 다이얼로그

3. **블록 렌더링**:
   - 보라색 블록 표시 (EventPainter 재사용)
   - 시간 라벨 표시 (예: "09:00 - 18:00")

4. **상태 관리**:
   - `_operatingHours` Map 업데이트
   - `_isDirty` 플래그 설정

#### 완료 조건
- [ ] 드래그로 운영시간 블록 생성 가능
- [ ] 요일별 1개 블록 제약 동작
- [ ] 기존 블록 교체 확인 다이얼로그 표시
- [ ] 블록 시각화 정상 표시

#### 의존성
- Phase 1 완료 필요

#### 산출물
- 운영시간 선택 로직 추가 (200줄)
- 교체 확인 다이얼로그 (50줄)

### Phase 3: 브레이크 타임 선택 모드 구현 (2시간)

#### 작업 내용
1. **모드 전환 로직**:
   - 토글 버튼 클릭 시 `_mode` 변경
   - 선택 상태 초기화

2. **브레이크 타임 드래그 로직**:
   - 운영시간 블록 외부는 비활성화 (회색 표시)
   - 운영시간 내부만 선택 가능
   - 브레이크 타임끼리 겹침 방지

3. **블록 렌더링**:
   - 노란색 블록 표시 (EventPainter 재사용)
   - 시간 라벨 표시

4. **상태 관리**:
   - `_breakTimes` Map 업데이트 (List<TimeBlock>)
   - `_isDirty` 플래그 설정

#### 완료 조건
- [ ] 모드 토글 버튼 동작
- [ ] 브레이크 타임 드래그 선택 가능
- [ ] 운영시간 외부 비활성화 (회색 표시)
- [ ] 브레이크 타임 겹침 방지 동작
- [ ] 노란색 블록 시각화 정상 표시

#### 의존성
- Phase 2 완료 필요

#### 산출물
- 브레이크 타임 선택 로직 추가 (250줄)
- 비활성화 영역 렌더러 (50줄)

### Phase 4: 데이터 변환 로직 및 백엔드 연동 (1.5시간)

#### 작업 내용
1. **초기 데이터 파싱**:
   - `OperatingHoursResponse[]` → `_operatingHours`
   - `RestrictedTimeResponse[]` → `_breakTimes`

2. **저장 데이터 변환**:
   - `_operatingHours` → `SetOperatingHoursRequest`
   - `_breakTimes` → `AddRestrictedTimeRequest[]`

3. **API 연동**:
   - PUT `/api/places/{placeId}/operating-hours`
   - POST `/api/places/{placeId}/restricted-times` (복수)
   - DELETE `/api/places/{placeId}/restricted-times/{id}` (삭제된 항목)

4. **에러 처리**:
   - 네트워크 에러 스낵바
   - 롤백 로직 (초기 상태 복원)

#### 완료 조건
- [ ] 초기 데이터 파싱 정상 동작
- [ ] 저장 시 API 호출 성공
- [ ] 에러 발생 시 롤백 동작
- [ ] 스낵바 메시지 표시 (성공/실패)

#### 의존성
- Phase 3 완료 필요
- 백엔드 API 엔드포인트 존재

#### 산출물
- 데이터 변환 함수 (150줄)
- API 연동 로직 (100줄)

### Phase 5: 반응형 및 UX 폴리싱 (1.5시간)

#### 작업 내용
1. **반응형 레이아웃**:
   - 900px 브레이크포인트 적용
   - 모바일: 가로 스크롤 활성화

2. **UX 개선**:
   - 하프틱 피드백 추가 (모바일)
   - 로딩 인디케이터 추가 (저장 중)
   - 더티 체크 (변경 없으면 저장 버튼 비활성화)

3. **블록 삭제 기능**:
   - 블록 클릭 → 컨텍스트 메뉴
   - 삭제 확인 다이얼로그

4. **최종 테스트**:
   - 모든 시나리오 수동 테스트
   - 버그 수정

#### 완료 조건
- [ ] 반응형 레이아웃 정상 동작
- [ ] 하프틱 피드백 동작 (모바일)
- [ ] 블록 삭제 기능 동작
- [ ] 저장 버튼 상태 관리 (더티 체크)
- [ ] 모든 수동 테스트 통과

#### 의존성
- Phase 4 완료 필요

#### 산출물
- 반응형 로직 추가 (100줄)
- 블록 삭제 UI/로직 (80줄)
- 최종 버그 수정 (50줄)

## 6. 데이터 구조 설계

### 6.1 상태 모델 정의

```dart
/// 운영시간 블록 모델
class OperatingHoursBlock {
  final DayOfWeek dayOfWeek;
  final int startSlot;  // 0 (00:00) ~ 96 (24:00), 15분 단위
  final int endSlot;

  OperatingHoursBlock({
    required this.dayOfWeek,
    required this.startSlot,
    required this.endSlot,
  });

  // LocalTime 변환 헬퍼
  LocalTime get startTime => _slotToTime(startSlot);
  LocalTime get endTime => _slotToTime(endSlot);

  static LocalTime _slotToTime(int slot) {
    final hour = slot ~/ 4;
    final minute = (slot % 4) * 15;
    return LocalTime(hour, minute);
  }

  // 슬롯 변환 헬퍼
  static int timeToSlot(LocalTime time) {
    return time.hour * 4 + (time.minute ~/ 15);
  }
}

/// 브레이크 타임 블록 모델
class BreakTimeBlock {
  final int? id;  // 서버에서 받은 ID (null이면 신규)
  final DayOfWeek dayOfWeek;
  final int startSlot;
  final int endSlot;
  final String? reason;

  BreakTimeBlock({
    this.id,
    required this.dayOfWeek,
    required this.startSlot,
    required this.endSlot,
    this.reason,
  });

  LocalTime get startTime => OperatingHoursBlock._slotToTime(startSlot);
  LocalTime get endTime => OperatingHoursBlock._slotToTime(endSlot);
}
```

### 6.2 백엔드 API 인터페이스

#### GET 초기 데이터
```http
GET /api/places/{placeId}/operating-hours

Response 200 OK:
{
  "success": true,
  "data": {
    "operatingHours": [
      {
        "id": 1,
        "dayOfWeek": "MONDAY",
        "startTime": "09:00:00",
        "endTime": "18:00:00",
        "isClosed": false
      },
      ...
    ],
    "restrictedTimes": [
      {
        "id": 1,
        "dayOfWeek": "MONDAY",
        "startTime": "12:00:00",
        "endTime": "13:00:00",
        "reason": "점심시간",
        "displayOrder": 0
      },
      ...
    ]
  }
}
```

#### PUT 운영시간 저장
```http
PUT /api/places/{placeId}/operating-hours

Request:
{
  "operatingHours": [
    {
      "dayOfWeek": "MONDAY",
      "startTime": "09:00:00",
      "endTime": "18:00:00",
      "isClosed": false
    },
    ...
  ]
}

Response 200 OK:
{
  "success": true,
  "data": { ... }
}
```

#### POST 브레이크 타임 추가
```http
POST /api/places/{placeId}/restricted-times

Request:
{
  "dayOfWeek": "MONDAY",
  "startTime": "12:00:00",
  "endTime": "13:00:00",
  "reason": "점심시간"
}

Response 201 Created:
{
  "success": true,
  "data": {
    "id": 10,
    ...
  }
}
```

#### DELETE 브레이크 타임 삭제
```http
DELETE /api/places/{placeId}/restricted-times/{restrictedTimeId}

Response 204 No Content
```

### 6.3 데이터 변환 로직 설명

#### 서버 → 프론트엔드
```dart
// OperatingHoursResponse → OperatingHoursBlock
OperatingHoursBlock _parseOperatingHours(OperatingHoursResponse response) {
  return OperatingHoursBlock(
    dayOfWeek: response.dayOfWeek,
    startSlot: OperatingHoursBlock.timeToSlot(response.startTime),
    endSlot: OperatingHoursBlock.timeToSlot(response.endTime),
  );
}

// RestrictedTimeResponse → BreakTimeBlock
BreakTimeBlock _parseRestrictedTime(RestrictedTimeResponse response) {
  return BreakTimeBlock(
    id: response.id,
    dayOfWeek: response.dayOfWeek,
    startSlot: OperatingHoursBlock.timeToSlot(response.startTime),
    endSlot: OperatingHoursBlock.timeToSlot(response.endTime),
    reason: response.reason,
  );
}
```

#### 프론트엔드 → 서버
```dart
// OperatingHoursBlock → SetOperatingHoursRequest
SetOperatingHoursRequest _buildOperatingHoursRequest() {
  return SetOperatingHoursRequest(
    operatingHours: _operatingHours.entries.map((entry) {
      final block = entry.value;
      return OperatingHoursItem(
        dayOfWeek: block.dayOfWeek,
        startTime: block.startTime,
        endTime: block.endTime,
        isClosed: false,
      );
    }).toList(),
  );
}

// BreakTimeBlock → AddRestrictedTimeRequest
AddRestrictedTimeRequest _buildRestrictedTimeRequest(BreakTimeBlock block) {
  return AddRestrictedTimeRequest(
    dayOfWeek: block.dayOfWeek,
    startTime: block.startTime,
    endTime: block.endTime,
    reason: block.reason,
  );
}
```

## 7. 파일 구조

### 생성할 파일
```
frontend/lib/
├── presentation/
│   └── pages/
│       └── workspace/
│           └── place/
│               ├── place_operating_hours_editor.dart (신규, 1200줄)
│               └── dialogs/
│                   ├── confirm_replace_operating_hours_dialog.dart (신규, 80줄)
│                   └── delete_block_dialog.dart (신규, 70줄)
└── core/
    └── models/
        └── place_time_models.dart (수정, +50줄)
```

### 각 파일의 역할 및 책임

#### `place_operating_hours_editor.dart`
- **역할**: 메인 에디터 위젯
- **책임**:
  - WeeklyScheduleEditor 래핑 및 상태 관리
  - 모드 토글 UI
  - 드래그 이벤트 처리
  - API 연동 및 데이터 변환
  - 저장/취소 버튼 처리

#### `confirm_replace_operating_hours_dialog.dart`
- **역할**: 운영시간 교체 확인 다이얼로그
- **책임**:
  - 기존 블록이 있을 때 교체 확인
  - 확인/취소 버튼 처리

#### `delete_block_dialog.dart`
- **역할**: 블록 삭제 확인 다이얼로그
- **책임**:
  - 블록 클릭 시 표시
  - 삭제/취소 버튼 처리

#### `place_time_models.dart` (수정)
- **역할**: 장소 시간 관련 모델 추가
- **책임**:
  - `OperatingHoursBlock` 클래스 추가
  - `BreakTimeBlock` 클래스 추가

## 8. 테스트 계획

### 8.1 단위 테스트 항목

#### 데이터 변환 로직
- [ ] `timeToSlot()`: LocalTime → 슬롯 변환 정확성
- [ ] `_slotToTime()`: 슬롯 → LocalTime 변환 정확성
- [ ] `_parseOperatingHours()`: 서버 응답 → 모델 변환
- [ ] `_parseRestrictedTime()`: 서버 응답 → 모델 변환
- [ ] `_buildOperatingHoursRequest()`: 모델 → 서버 요청
- [ ] `_buildRestrictedTimeRequest()`: 모델 → 서버 요청

#### 제약 조건 검증
- [ ] 요일별 1개 운영시간 블록만 허용
- [ ] 브레이크 타임은 운영시간 내부에만 허용
- [ ] 브레이크 타임끼리 겹침 방지

### 8.2 통합 테스트 시나리오

#### 시나리오 1: 운영시간 설정
```
1. 에디터 로드 (초기 데이터 없음)
2. 월요일 09:00-18:00 드래그 선택
3. "저장" 버튼 클릭
4. API 호출 성공 확인
5. 스낵바 "저장되었습니다" 표시 확인
```

#### 시나리오 2: 운영시간 교체
```
1. 에디터 로드 (월요일 09:00-18:00 이미 설정됨)
2. 월요일 10:00-20:00 드래그 선택
3. 교체 확인 다이얼로그 표시
4. "확인" 클릭
5. 기존 블록 삭제 + 새 블록 생성
6. "저장" 버튼 클릭
7. API 호출 성공 확인
```

#### 시나리오 3: 브레이크 타임 설정
```
1. 에디터 로드 (월요일 09:00-18:00 설정됨)
2. "브레이크 타임 설정" 모드 선택
3. 월요일 12:00-13:00 드래그 선택
4. 노란색 블록 표시 확인
5. "저장" 버튼 클릭
6. API 호출 성공 확인
```

#### 시나리오 4: 브레이크 타임 겹침 방지
```
1. 에디터 로드 (월요일 12:00-13:00 브레이크 타임 설정됨)
2. "브레이크 타임 설정" 모드
3. 월요일 12:30-13:30 드래그 선택
4. 에러 스낵바 "이미 설정된 시간대입니다" 표시
5. 블록 생성 안됨 확인
```

#### 시나리오 5: 블록 삭제
```
1. 에디터 로드 (월요일 12:00-13:00 브레이크 타임 설정됨)
2. 브레이크 타임 블록 클릭
3. 삭제 확인 다이얼로그 표시
4. "삭제" 클릭
5. 블록 즉시 삭제 (UI에서만)
6. "저장" 버튼 클릭
7. DELETE API 호출 성공 확인
```

#### 시나리오 6: 롤백
```
1. 에디터 로드 (월요일 09:00-18:00 설정됨)
2. 월요일 10:00-20:00로 변경
3. "저장" 버튼 클릭
4. API 호출 실패 (네트워크 에러)
5. 에러 스낵바 표시
6. 원래 상태 (09:00-18:00)로 롤백 확인
```

### 8.3 수동 테스트 체크리스트

#### 기능 테스트
- [ ] 운영시간 드래그 선택 (웹)
- [ ] 운영시간 드래그 선택 (모바일)
- [ ] 브레이크 타임 드래그 선택 (웹)
- [ ] 브레이크 타임 드래그 선택 (모바일)
- [ ] 모드 토글 버튼 동작
- [ ] 블록 삭제 기능
- [ ] 저장 버튼 활성화/비활성화 (더티 체크)
- [ ] 취소 버튼 (변경 취소)

#### UI/UX 테스트
- [ ] 보라색 블록 시각화 (운영시간)
- [ ] 노란색 블록 시각화 (브레이크 타임)
- [ ] 비활성화 영역 회색 표시
- [ ] 하프틱 피드백 (모바일)
- [ ] 로딩 인디케이터 (저장 중)
- [ ] 스낵바 메시지 (성공/실패)

#### 반응형 테스트
- [ ] 데스크톱 (1200px): 7일 모두 표시
- [ ] 태블릿 (900px): 7일 모두 표시
- [ ] 모바일 (600px): 가로 스크롤 동작
- [ ] 모바일 (400px): 가로 스크롤 동작 + 최소 너비 유지

#### 에러 처리 테스트
- [ ] 네트워크 에러 시 스낵바 표시
- [ ] 롤백 동작 (API 실패 시)
- [ ] 겹침 방지 에러 스낵바
- [ ] 범위 제한 에러 스낵바

## 9. 위험 요소 및 대응 방안

### 9.1 기술적 위험

#### 위험 1: WeeklyScheduleEditor의 복잡한 로직
- **위험도**: 높음
- **영향**: 수정 시 예상치 못한 버그 발생
- **대응**:
  - 핵심 로직 최소 수정 (드래그, 렌더링)
  - 신규 기능은 별도 함수로 분리
  - 단계별 테스트로 버그 조기 발견

#### 위험 2: 데이터 변환 로직의 엣지 케이스
- **위험도**: 중간
- **영향**: 저장 시 데이터 손실 또는 불일치
- **대응**:
  - 단위 테스트 작성 (시간 변환 함수)
  - 경계값 테스트 (00:00, 24:00, 23:59)
  - 서버 응답 검증 로직 추가

#### 위험 3: 반응형 레이아웃 깨짐
- **위험도**: 중간
- **영향**: 특정 디바이스에서 UI 깨짐
- **대응**:
  - 900px 브레이크포인트 명확히 정의
  - 모바일 최소 너비 설정 (420px)
  - 다양한 디바이스에서 수동 테스트

### 9.2 일정 위험

#### 위험 1: WeeklyScheduleEditor 커스터마이징 시간 초과
- **위험도**: 중간
- **영향**: Phase 1 지연 → 전체 일정 지연
- **대응**:
  - Phase 1 완료 후 중간 리뷰 (1.5시간 시점)
  - 필요 시 Phase 2와 병행 작업
  - 우선순위 낮은 기능 Phase 5로 미룸

#### 위험 2: 백엔드 API 준비 지연
- **위험도**: 낮음 (이미 구현됨)
- **영향**: Phase 4 진행 불가
- **대응**:
  - Phase 4 전에 API 엔드포인트 확인
  - Mock 데이터로 먼저 개발 진행
  - API 준비되면 즉시 통합

### 9.3 품질 위험

#### 위험 1: 브레이크 타임 겹침 방지 로직 버그
- **위험도**: 중간
- **영향**: 사용자가 잘못된 시간대 설정
- **대응**:
  - Phase 3에서 집중 테스트
  - 겹침 검증 로직 단위 테스트 작성
  - 시각적 피드백 강화 (빨간색 테두리)

#### 위험 2: 롤백 로직 실패
- **위험도**: 낮음
- **영향**: API 실패 시 데이터 손실
- **대응**:
  - 초기 데이터 복사본 유지
  - 롤백 로직 단위 테스트
  - 저장 전 변경 사항 검증

## 10. 체크리스트

### 10.1 개발 전 준비사항
- [ ] WeeklyScheduleEditor 코드 숙지 (1시간)
- [ ] 백엔드 API 엔드포인트 확인 (10분)
- [ ] 디자인 시스템 색상 확인 (AppColors.brand, Colors.amber)
- [ ] 모바일 테스트 디바이스 준비
- [ ] 개발 환경 설정 (Flutter 5173 포트)

### 10.2 개발 중 확인사항

#### Phase 1 체크리스트
- [ ] PlaceOperatingHoursEditor 위젯 생성
- [ ] 토글 버튼 UI 추가
- [ ] 저장/취소 버튼 UI 추가
- [ ] 빈 그리드 렌더링 정상 동작
- [ ] 코드 리뷰 (중간 점검)

#### Phase 2 체크리스트
- [ ] 웹 드래그 로직 동작
- [ ] 모바일 롱프레스 + 드래그 동작
- [ ] 요일별 1개 블록 제약 동작
- [ ] 교체 확인 다이얼로그 표시
- [ ] 보라색 블록 시각화 정상

#### Phase 3 체크리스트
- [ ] 모드 토글 버튼 동작
- [ ] 브레이크 타임 드래그 동작
- [ ] 운영시간 외부 비활성화 (회색)
- [ ] 브레이크 타임 겹침 방지 동작
- [ ] 노란색 블록 시각화 정상

#### Phase 4 체크리스트
- [ ] 초기 데이터 파싱 정상 동작
- [ ] 저장 시 API 호출 성공
- [ ] 에러 발생 시 롤백 동작
- [ ] 스낵바 메시지 표시 (성공/실패)

#### Phase 5 체크리스트
- [ ] 반응형 레이아웃 정상 동작
- [ ] 하프틱 피드백 동작 (모바일)
- [ ] 블록 삭제 기능 동작
- [ ] 저장 버튼 상태 관리 (더티 체크)
- [ ] 모든 수동 테스트 통과

### 10.3 개발 완료 기준
- [ ] 모든 Phase 완료 (Phase 1-5)
- [ ] 모든 단위 테스트 통과 (데이터 변환 로직)
- [ ] 모든 통합 테스트 시나리오 통과 (6개 시나리오)
- [ ] 모든 수동 테스트 체크리스트 통과 (기능, UI/UX, 반응형, 에러)
- [ ] 백엔드 API 통합 완료 (PUT, POST, DELETE)
- [ ] 코드 리뷰 완료 및 승인
- [ ] 문서 업데이트 완료 (CLAUDE.md, docs/features/)

---

## 부록: 참고 자료

### A. 사용자 결정사항 (요구사항 출처)
1. **모드 전환 UI**: 토글 버튼
2. **브레이크 타임 색상**: 노란색
3. **백엔드 모델**: 원래 설계를 따른다 (DayOperatingHours + isClosed)
4. **모바일 대응**: 가로 스크롤 (최소 크기 이하에서)
5. **일괄 적용 기능**: 필요 없음
6. **구현 범위**: 전부 구현 (Phase 1-5)
7. **시간 투자**: 8시간

### B. 관련 문서
- [장소 캘린더 시스템](docs/concepts/place-calendar-system.md)
- [장소 캘린더 명세](docs/features/place-calendar-specification.md)
- [프론트엔드 개발 가이드](docs/implementation/frontend/README.md)
- [디자인 시스템](docs/ui-ux/concepts/design-system.md)

### C. 백엔드 모델 참조
- **PlaceOperatingHours**: 요일별 단일 시간대 (startTime, endTime, isClosed)
- **PlaceRestrictedTime**: 요일별 다중 금지 시간대 (dayOfWeek, startTime, endTime, reason, displayOrder)

### D. WeeklyScheduleEditor 주요 기능
- TimeGridPainter: 시간 눈금 및 그리드 라인
- SelectionPainter: 드래그 선택 영역 렌더링
- HighlightPainter: 현재 셀 하이라이트
- EventPainter: 이벤트 블록 렌더링 (색상, 레이아웃 지원)
- 웹/모바일 플랫폼별 제스처 처리
- 자동 스크롤 (드래그 시 화면 끝 감지)

---

**작성일**: 2025-11-02
**작성자**: Frontend Development Agent
**예상 소요 시간**: 8시간 (Phase 1-5)
**상태**: 명세서 작성 완료, 구현 대기
