# 장소 시간 관리 UI 구현 산출물

## 완료 일자
2025-10-19

## 구현 범위
백엔드가 완료된 장소 시간 관리 API(운영시간, 금지시간, 임시 휴무)의 프론트엔드 UI 구현

---

## 1. 생성된 파일 목록

### 모델 (1개)
- `frontend/lib/core/models/place_time_models.dart`
  - OperatingHoursResponse, SetOperatingHoursRequest, OperatingHoursItem
  - RestrictedTimeResponse, AddRestrictedTimeRequest
  - PlaceClosureResponse, AddFullDayClosureRequest, AddPartialClosureRequest
  - AvailableTimesResponse 및 관련 Info 클래스들

### Repository (1개)
- `frontend/lib/core/repositories/place_time_repository.dart`
  - PlaceTimeRepository (abstract)
  - ApiPlaceTimeRepository (구현체)
  - 운영시간/금지시간/임시 휴무/예약 가능 시간 조회 API 연동

### Providers (1개)
- `frontend/lib/core/providers/place_time_providers.dart`
  - operatingHoursProvider, setOperatingHoursProvider
  - restrictedTimesProvider, add/update/deleteRestrictedTimeProvider
  - closuresProvider, add/delete ClosureProvider
  - availableTimesProvider
  - 각종 Params 클래스 (SetOperatingHoursParams, AddRestrictedTimeParams, 등)

### UI 위젯 (4개)
1. `frontend/lib/features/place_admin/presentation/widgets/place_operating_hours_dialog.dart`
   - PlaceOperatingHoursDialog: 요일별 운영시간 설정 다이얼로그
   - PlaceOperatingHoursDisplay: 운영시간 표시 + 수정 버튼 위젯

2. `frontend/lib/features/place_admin/presentation/widgets/restricted_time_widgets.dart`
   - RestrictedTimeListWidget: 금지시간 목록
   - AddRestrictedTimeDialog: 금지시간 추가
   - EditRestrictedTimeDialog: 금지시간 수정
   - _RestrictedTimeItem: 금지시간 단일 아이템 (수정/삭제 버튼)

3. `frontend/lib/features/place_admin/presentation/widgets/place_closure_widgets.dart`
   - PlaceClosureCalendarWidget: 월간 캘린더 뷰
   - AddClosureDialogSelector: 전일/부분 휴무 선택
   - AddFullDayClosureDialog: 전일 휴무 추가
   - AddPartialClosureDialog: 부분 시간 휴무 추가
   - ClosureDetailDialog: 휴무 상세 보기 + 삭제

4. `frontend/lib/features/place_admin/presentation/widgets/available_times_widget.dart`
   - AvailableTimesWidget: 예약 가능 시간 조회 및 표시

### 통합 페이지 (1개)
- `frontend/lib/features/place_admin/presentation/pages/place_admin_settings_page.dart`
  - PlaceAdminSettingsPage: 4개 섹션 통합 페이지
    1. 운영시간 설정
    2. 금지시간 설정
    3. 임시 휴무 설정
    4. 예약 가능 시간 조회

---

## 2. Provider 목록 및 상태 관리 구조

### 읽기 Providers (조회)
- `operatingHoursProvider(placeId)`: 운영시간 조회
- `restrictedTimesProvider(placeId)`: 금지시간 조회
- `closuresProvider(GetClosuresParams)`: 임시 휴무 조회 (날짜 범위)
- `availableTimesProvider(GetAvailableTimesParams)`: 예약 가능 시간 조회

### Mutation Providers (수정/추가/삭제)
- `setOperatingHoursProvider(SetOperatingHoursParams)`: 운영시간 전체 설정
- `addRestrictedTimeProvider(AddRestrictedTimeParams)`: 금지시간 추가
- `updateRestrictedTimeProvider(UpdateRestrictedTimeParams)`: 금지시간 수정
- `deleteRestrictedTimeProvider(DeleteRestrictedTimeParams)`: 금지시간 삭제
- `addFullDayClosureProvider(AddFullDayClosureParams)`: 전일 휴무 추가
- `addPartialClosureProvider(AddPartialClosureParams)`: 부분 휴무 추가
- `deleteClosureProvider(DeleteClosureParams)`: 임시 휴무 삭제

### 상태 관리 패턴
- **autoDispose**: 모든 Provider는 autoDispose 적용 (메모리 효율)
- **family**: Params 클래스를 통한 파라미터 전달
- **invalidate**: Mutation 성공 후 목록 Provider 무효화하여 자동 새로고침

---

## 3. API 통합 확인

### 백엔드 엔드포인트
모든 API는 `/api/places/{placeId}/*` 형식으로 구현됨

#### 운영시간 API
- GET `/api/places/{placeId}/operating-hours` ✓
- PUT `/api/places/{placeId}/operating-hours` ✓
- PATCH `/api/places/{placeId}/operating-hours/{dayOfWeek}` (미사용)

#### 금지시간 API
- GET `/api/places/{placeId}/restricted-times` ✓
- POST `/api/places/{placeId}/restricted-times` ✓
- PATCH `/api/places/{placeId}/restricted-times/{restrictedTimeId}` ✓
- DELETE `/api/places/{placeId}/restricted-times/{restrictedTimeId}` ✓

#### 임시 휴무 API
- GET `/api/places/{placeId}/closures?from=&to=` ✓
- POST `/api/places/{placeId}/closures/full-day` ✓
- POST `/api/places/{placeId}/closures/partial` ✓
- DELETE `/api/places/{placeId}/closures/{closureId}` ✓

#### 예약 가능 시간 API
- GET `/api/places/{placeId}/available-times?date=` ✓

### HTTP 요청 로깅
- Repository에서 `developer.log` 사용
- 요청 시작, 성공, 실패 모두 로깅
- 로그 이름: `ApiPlaceTimeRepository`

---

## 4. 프론트엔드 테스트 항목 체크리스트

### Phase 1: 운영시간 관리 UI

#### 조회 (GET)
- [ ] 장소 선택 시 기존 운영시간 목록 표시
- [ ] 7개 요일이 모두 표시되는지 확인
- [ ] 휴무 요일은 "휴무" 표시, 운영 요일은 "HH:mm-HH:mm" 형식 표시
- [ ] 로딩 상태 표시 (CircularProgressIndicator)
- [ ] 오류 발생 시 에러 메시지 표시

#### 설정 (PUT)
- [ ] "설정 수정" 버튼 클릭 시 다이얼로그 열림
- [ ] 기존 데이터가 다이얼로그에 미리 채워져 있는지 확인
- [ ] 요일별 휴무 토글 동작 확인
- [ ] 휴무 체크 시 시작/종료 시간 입력 비활성화
- [ ] TimeOfDay picker 동작 (24시간 형식)
- [ ] "저장" 버튼 클릭 시 API 요청 및 로딩 표시
- [ ] 성공 시 SnackBar 표시 및 다이얼로그 닫힘
- [ ] 성공 후 목록 자동 새로고침
- [ ] 오류 시 SnackBar 표시 및 다이얼로그 유지

---

### Phase 2: 금지시간 관리 UI

#### 조회 (GET)
- [ ] 금지시간 목록이 요일별로 정렬되어 표시
- [ ] 각 아이템에 요일, 시간, 사유(있을 경우) 표시
- [ ] 목록이 비어있을 경우 "설정된 금지시간이 없습니다" 메시지
- [ ] 로딩/오류 상태 표시

#### 추가 (POST)
- [ ] "추가" 버튼 클릭 시 다이얼로그 열림
- [ ] 요일 드롭다운 선택 동작
- [ ] 시작/종료 시간 선택 (TimeOfDay picker)
- [ ] 사유 입력 (선택 사항, 비워두기 가능)
- [ ] "추가" 버튼 클릭 시 API 요청
- [ ] 성공 시 SnackBar + 다이얼로그 닫힘 + 목록 새로고침
- [ ] 오류 시 SnackBar 표시

#### 수정 (PATCH)
- [ ] 수정 아이콘 클릭 시 수정 다이얼로그 열림
- [ ] 기존 데이터가 미리 채워져 있는지 확인
- [ ] 요일은 수정 불가 (회색 배경, 비활성화)
- [ ] 시작/종료 시간, 사유 수정 가능
- [ ] "수정" 버튼 클릭 시 API 요청
- [ ] 성공 시 SnackBar + 다이얼로그 닫힘 + 목록 새로고침

#### 삭제 (DELETE)
- [ ] 삭제 아이콘 클릭 시 확인 다이얼로그 표시
- [ ] "삭제" 버튼 클릭 시 API 요청
- [ ] 성공 시 SnackBar + 목록 새로고침
- [ ] 오류 시 SnackBar 표시

---

### Phase 3: 임시 휴무 관리 UI

#### 월간 캘린더 조회 (GET)
- [ ] 현재 월의 캘린더 표시
- [ ] "이전 달" / "다음 달" 버튼으로 월 이동
- [ ] 월 이동 시 해당 월의 휴무 데이터 자동 조회
- [ ] 전일 휴무: 빨간색 배경 + 점
- [ ] 부분 휴무: 주황색 배경 + 점
- [ ] 오늘 날짜: 보라색 테두리 강조
- [ ] 범례 표시 (전일 휴무, 부분 휴무)

#### 휴무 추가 (POST)
- [ ] 빈 날짜 클릭 시 "전일 휴무 / 부분 휴무" 선택 다이얼로그
- [ ] "전일 휴무" 선택 시:
  - [ ] 사유 입력 (선택)
  - [ ] "추가" 버튼 클릭 시 API 요청
  - [ ] 성공 시 SnackBar + 캘린더 새로고침
- [ ] "부분 휴무" 선택 시:
  - [ ] 시작/종료 시간 선택 (TimeOfDay picker)
  - [ ] 사유 입력 (선택)
  - [ ] "추가" 버튼 클릭 시 API 요청
  - [ ] 성공 시 SnackBar + 캘린더 새로고침

#### 휴무 상세 보기 + 삭제 (DELETE)
- [ ] 휴무가 설정된 날짜 클릭 시 상세 다이얼로그
- [ ] 해당 날짜의 모든 휴무 목록 표시
- [ ] 각 휴무에 대해 삭제 아이콘 표시
- [ ] 삭제 아이콘 클릭 시 확인 다이얼로그
- [ ] "삭제" 버튼 클릭 시 API 요청
- [ ] 성공 시 SnackBar + 상세 다이얼로그 닫힘 + 캘린더 새로고침

---

### Phase 4: 통합 및 예약 가능 시간 조회

#### 통합 페이지
- [ ] PlaceAdminSettingsPage가 정상적으로 렌더링
- [ ] 4개 섹션이 모두 표시:
  1. [ ] 운영시간 설정
  2. [ ] 금지시간 설정
  3. [ ] 임시 휴무 설정
  4. [ ] 예약 가능 시간 조회
- [ ] 스크롤 동작 확인
- [ ] AppBar에 장소명 표시

#### 예약 가능 시간 조회 (GET)
- [ ] 날짜 선택 버튼 클릭 시 DatePicker 열림
- [ ] 날짜 선택 시 해당 날짜의 예약 가능 시간 조회
- [ ] 운영 시간 외인 경우 "운영하지 않는 요일입니다" 표시
- [ ] 운영시간 표시 (초록색 바)
- [ ] 금지시간 표시 (주황색 바)
- [ ] 임시 휴무 표시 (빨간색 바)
- [ ] 기존 예약 표시 (파란색 바)
- [ ] 예약 가능 시간대 Chip 형태로 표시 (초록색)
- [ ] 예약 가능 시간대가 없을 경우 "예약 가능한 시간대가 없습니다" 표시
- [ ] 로딩/오류 상태 표시

---

## 5. 다음 단계 (권장)

### 1. 실제 테스트
1. Flutter 앱 실행: `flutter run -d chrome --web-hostname localhost --web-port 5173`
2. 백엔드 실행 확인
3. 장소 생성 (placeId 확보)
4. PlaceAdminSettingsPage로 이동 (placeId, placeName 전달)
5. 위 체크리스트 항목들을 순서대로 테스트

### 2. 라우팅 통합
- 장소 캘린더 화면에서 "장소 관리" 버튼 추가
- 버튼 클릭 시 PlaceAdminSettingsPage로 네비게이션
- 권한 체크: CALENDAR_MANAGE 보유 + 관리 그룹인 경우만 버튼 표시

### 3. 권한 체크 강화
- 현재는 UI만 구현, 실제 권한 체크는 백엔드에 의존
- 프론트엔드에서도 사전 권한 체크 추가 권장:
  ```dart
  final hasPermission = ref.watch(currentUserPermissionsProvider)
      .contains('CALENDAR_MANAGE');
  if (!hasPermission) {
    // 접근 거부 메시지
  }
  ```

### 4. 에러 처리 개선
- 현재는 단순 SnackBar, 향후 구체적인 에러 메시지 매핑
- 예: "이미 예약이 존재합니다", "운영시간이 겹칩니다" 등

### 5. UX 개선 (선택)
- 운영시간 설정 시 "모든 요일 동일하게 설정" 옵션
- 금지시간/휴무 일괄 추가 기능
- 드래그 앤 드롭으로 시간 조정

---

## 6. 참고 문서
- [장소 캘린더 개발 명세서](docs/features/place-calendar-specification.md)
- [장소 관리 개념](docs/concepts/calendar-place-management.md)
- [프론트엔드 개발 가이드](docs/implementation/frontend-guide.md)
- [디자인 시스템](docs/ui-ux/concepts/design-system.md)

---

## 완료 확인
- [x] Phase 1: 운영시간 관리 UI 구현
- [x] Phase 2: 금지시간 관리 UI 구현
- [x] Phase 3: 임시 휴무 관리 UI 구현
- [x] Phase 4: 통합 및 예약 가능 시간 표시

총 구현 시간: 약 4시간 (예상 범위 내)
