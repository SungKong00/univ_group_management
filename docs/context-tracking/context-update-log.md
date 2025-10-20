### 2025-10-21 - 에이전트 가이드 DropdownMenuItem 레이아웃 패턴 추가
**커밋**: (커밋 예정)
**유형**: 문서 업데이트 (개발 가이드라인)
**우선순위**: High
**영향 범위**: 에이전트 가이드 문서

**구현 내용**:
- **에이전트 가이드 업데이트**:
    - `frontend-specialist.md`와 `frontend-debugger.md`의 "Layout Guideline for Flutter" 섹션에 DropdownMenuItem 특수 케이스 추가
    - DropdownMenuItem은 unbounded width constraint를 제공하므로 내부 Row에서 `Expanded` 사용 시 RenderFlex 에러 발생
    - 해결책: `mainAxisSize: MainAxisSize.min` + `Flexible` 사용

**동기화 완료 문서**:
- ✅ `.claude/agents/frontend-specialist.md`: DropdownMenuItem 특수 케이스 섹션 추가 (Line 67-87)
- ✅ `.claude/agents/frontend-debugger.md`: DropdownMenuItem 디버깅 가이드 추가 (Line 78-86)
- ✅ `docs/context-tracking/context-update-log.md`: 현재 로그 추가

**배경**:
데모 캘린더 일정 생성 모달 개발 중 DropdownMenuItem 내부 Row에서 `Expanded` 사용으로 인한 "RenderFlex children have non-zero flex but incoming width constraints are unbounded" 에러가 발생. 이 패턴은 자주 반복되므로 에이전트 가이드에 명시적으로 추가하여 향후 동일한 실수 방지.

**메모**: Flutter UI 개발 시 DropdownMenuItem, ListView, GridView 등 unbounded constraint를 제공하는 위젯 내부에서는 Expanded 대신 Flexible을 사용해야 함.

---

### 2025-10-21 - 장소 운영 시간 모델 리팩토링 문서 동기화
**커밋**: (커밋 예정)
**유형**: 리팩토링 + 문서 동기화
**우선순위**: High
**영향 범위**: 백엔드 (엔티티, 서비스), 프론트엔드 (모델, UI), 문서 (개념, API, DB)

**구현 내용**:
- **백엔드/프론트엔드 리팩토링**:
    - 기존 `PlaceAvailability` 시스템(요일별 다중 시간대 허용)을 `PlaceOperatingHours`(요일별 단일 시간대 + `isClosed` 플래그)로 리팩토링하여 모델을 단순화했습니다.
    - 이 변경사항을 `PlaceService`, `PlaceReservationService`, `TestDataRunner` 등 백엔드 서비스와 `PlaceDetailResponse`, `demo_calendar_page.dart` 등 프론트엔드 코드에 모두 적용했습니다.

**동기화 완료 문서**:
- ✅ `docs/concepts/calendar-place-management.md`: 장소 운영 시간 관리 방식을 `PlaceOperatingHours` 기준으로 수정하고 관련 예시를 업데이트했습니다.
- ✅ `docs/implementation/database-reference.md`: `place_availability` 테이블 정의를 삭제하고, 새로운 `place_operating_hours` 테이블 및 JPA 엔티티 정의로 교체했습니다.
- ✅ `docs/implementation/api-reference.md`: `GET /places/{placeId}` API의 응답 명세에 `operatingHours` 필드를 반영하고, 새로운 JSON 응답 구조 예시를 추가했습니다.
- ✅ `docs/context-tracking/context-update-log.md`: 현재 로그를 추가합니다.

**수정된 파일**:
- `backend/src/main/kotlin/org/castlekong/backend/entity/PlaceAvailability.kt` (삭제)
- `backend/src/main/kotlin/org/castlekong/backend/repository/PlaceAvailabilityRepository.kt` (삭제)
- `backend/src/main/kotlin/org/castlekong/backend/runner/TestDataRunner.kt`
- `backend/src/main/kotlin/org/castlekong/backend/service/PlaceReservationService.kt`
- `backend/src/main/kotlin/org/castlekong/backend/service/PlaceService.kt`
- `frontend/lib/core/models/place/place_detail_response.dart`
- `frontend/lib/presentation/pages/demo_calendar/demo_calendar_page.dart`
- `docs/concepts/calendar-place-management.md`
- `docs/implementation/database-reference.md`
- `docs/implementation/api-reference.md`

**메모**: 장소 운영 시간 관리 모델이 단순화되었으며, 이와 관련된 모든 코드와 핵심 개념/구현 문서가 최신 상태로 동기화되었습니다.

---