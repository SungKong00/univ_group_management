# 캘린더 시스템 통합 개발 로드맵

> **버전**: 1.0
> **작성일**: 2025-10-13
> **상태**: 계획 확정
> **관련 문서**: [그룹 캘린더 개발 계획](group-calendar-development-plan.md) | [장소 캘린더 명세](place-calendar-specification.md) | [캘린더 시스템](../concepts/calendar-system.md)

---

## 📋 개요

이 문서는 **그룹 캘린더**와 **장소 캘린더** 두 시스템의 통합 개발 로드맵을 제시합니다.

### 현재 상태 (2025-10-13)

**그룹 캘린더**:
- ✅ Phase 1-5: 백엔드 API + 생성 기능
- ✅ Phase 6: 수정/삭제 기능
- ✅ Phase 7: E2E 테스트 완료
- ⏳ Phase 8: 권한 통합 (다음 작업)
- 📝 Phase 9: UI 개선 (설계 완료, 구현 대기)

**장소 캘린더**:
- ✅ Phase 1: 백엔드 기본 구현 완료
- ⏳ Phase 2: 프론트엔드 기본 구현 (다음 작업)

---

## 🎯 개발 우선순위 및 전략

### 전략 A: 그룹 캘린더 완성 우선 (권장)

**목표**: 사용자에게 완전한 그룹 일정 관리 기능 제공

**장점**:
- 핵심 기능 조기 완성
- 장소 예약과의 통합 기반 마련
- 사용자 피드백 조기 수집

**단계**:
1. 그룹 캘린더 Phase 8 (권한 통합)
2. 장소 캘린더 Phase 2-3 (프론트엔드 + 사용 그룹)
3. 장소 캘린더 Phase 4 (예약 시스템 + 그룹 캘린더 통합)
4. 그룹 캘린더 Phase 9-10 (UI 개선 + 캘린더 뷰)

---

## 📅 상세 로드맵

### Week 1-2: 그룹 캘린더 권한 통합 + 장소 프론트엔드

#### 그룹 캘린더 Phase 8: 권한 시스템 통합 (2-3시간)
**목표**: 공식 일정 수정/삭제 권한 체크

**작업 내용**:
1. `_canModifyEvent()` 함수 수정 (권한 API 연동)
   ```dart
   bool _canModifyEvent(GroupEvent event) {
     if (event.isOfficial) {
       final permissions = ref.read(groupPermissionsProvider(widget.groupId));
       return permissions.maybeWhen(
         data: (perms) => perms.contains(GroupPermission.calendarManage),
         orElse: () => false,
       );
     }
     return event.creatorId == currentUser.id;
   }
   ```

2. 테스트 시나리오:
   - 일반 멤버가 공식 일정 수정 시도 → 권한 없음
   - CALENDAR_MANAGE 보유자가 공식 일정 수정 → 성공

**완료 조건**:
- ✅ 권한 체크 로직 구현
- ✅ 통합 테스트 통과 (3개 시나리오)
- ✅ 문서 업데이트

---

#### 장소 캘린더 Phase 2: 프론트엔드 기본 구현 (6-8시간)
**목표**: 장소 관리 UI 구현

**작업 내용**:
1. **장소 목록 페이지** (2h)
   - 건물별 트리 구조
   - 검색 기능
   - 필터링 (건물, 수용 인원)
   - 파일 위치: `lib/presentation/pages/workspace/place/place_list_page.dart`

2. **장소 등록 폼** (2h)
   - 건물명, 방 번호, 별칭 입력
   - 수용 인원 입력 (선택)
   - 중복 체크
   - 파일 위치: `lib/presentation/pages/workspace/place/place_form_dialog.dart`

3. **운영 시간 설정 UI** (2h)
   - 요일별 시간대 설정
   - 여러 시간대 추가 가능
   - 시각적 타임라인 표시
   - 파일 위치: `lib/presentation/pages/workspace/place/place_availability_settings.dart`

4. **API 서비스 레이어** (2h)
   - `PlaceService` 구현
   - `PlaceProvider` 설정
   - 파일 위치: `lib/core/services/place_service.dart`

**완료 조건**:
- ✅ 장소 목록 조회 기능
- ✅ 장소 등록 기능 (CALENDAR_MANAGE 권한 체크)
- ✅ 운영 시간 설정 기능
- ✅ API 연동 테스트

**예상 시간**: 6-8시간

---

### Week 3-4: 장소 사용 그룹 관리

#### 장소 캘린더 Phase 3: 사용 그룹 관리 (4-6시간)
**목표**: 장소 사용 권한 신청/승인 UI

**작업 내용**:
1. **사용 신청 폼** (2h)
   - 그룹 관리자만 접근 (`CALENDAR_MANAGE`)
   - 장소 선택 (검색 가능)
   - 신청 사유 입력 (선택)
   - 파일 위치: `lib/presentation/pages/workspace/place/place_usage_request_dialog.dart`

2. **승인/거절 관리 페이지** (2h)
   - 관리 주체만 접근 (장소 소유자)
   - 대기 중인 신청 목록
   - 승인/거절 버튼 (사유 입력 가능)
   - 파일 위치: `lib/presentation/pages/workspace/place/place_usage_management_page.dart`

3. **사용 그룹 목록** (2h)
   - 승인된 그룹 목록
   - 권한 취소 기능 (경고 다이얼로그: "X개 예약이 취소됩니다")
   - 파일 위치: `lib/presentation/pages/workspace/place/place_usage_groups_list.dart`

**API 엔드포인트**:
```
POST   /api/places/{id}/usage-requests      # 사용 신청
PATCH  /api/places/{id}/usage-groups/{gid}  # 승인/거절
GET    /api/places/{id}/usage-groups        # 사용 그룹 목록
DELETE /api/places/{id}/usage-groups/{gid}  # 권한 취소
```

**완료 조건**:
- ✅ 사용 신청 기능
- ✅ 승인/거절 기능 (관리 주체만)
- ✅ 권한 취소 기능 (경고 포함)
- ✅ 권한 체크 (CALENDAR_MANAGE)

**예상 시간**: 4-6시간

---

### Week 5-6: 장소 예약 시스템 (그룹 캘린더 통합)

#### 장소 캘린더 Phase 4: 예약 시스템 (8-10시간)
**목표**: 장소 예약 생성/조회/취소 + 그룹 일정 통합

**작업 내용**:
1. **장소 캘린더 뷰** (3h)
   - 월간/주간/일간 뷰 (그룹 캘린더 컴포넌트 재사용)
   - 예약된 시간 블록 표시 (그룹명 표시)
   - 색상 코딩:
     - 회색: 운영 시간 외
     - 빨강: 예약됨 또는 차단됨
     - 초록: 예약 가능
   - 파일 위치: `lib/presentation/pages/workspace/place/place_calendar_page.dart`

2. **그룹 일정 생성 시 장소 선택** (3h)
   - `GroupEventFormDialog`에 장소 선택 필드 추가
   - 바텀시트 방식 장소 선택기
   - 승인된 장소만 필터링
   - 예약 가능 여부 실시간 표시
   - 파일 위치: `lib/presentation/pages/workspace/calendar/widgets/place_selector_sheet.dart`

3. **예약 가능 시간 조회** (2h)
   - API 연동: `GET /api/places/{id}/calendar?start=2025-11-01&end=2025-11-30`
   - 응답: 예약된 시간대 + 운영 시간 정보
   - 충돌 검증 로직
   - 파일 위치: `lib/core/services/place_calendar_service.dart`

4. **예약 취소** (2h)
   - 본인 그룹 예약 취소 (작성자 또는 CALENDAR_MANAGE)
   - 관리 주체의 강제 취소 (관리 그룹)
   - 확인 다이얼로그

**API 엔드포인트**:
```
POST   /api/places/{id}/reservations                # 예약 생성 (GroupEvent 생성 시)
GET    /api/places/{id}/reservations                # 예약 현황 조회
DELETE /api/reservations/{id}                       # 예약 취소
GET    /api/places/{id}/calendar?start=...&end=...  # 캘린더 데이터
```

**완료 조건**:
- ✅ 장소 캘린더 뷰 구현
- ✅ 그룹 일정 생성 시 장소 선택 기능
- ✅ 예약 가능 시간 조회 및 충돌 검증
- ✅ 예약 취소 기능
- ✅ 권한 체크 (PlaceUsageGroup APPROVED + 멤버십)

**예상 시간**: 8-10시간

---

### Week 7-8: 장소 차단 시간 + 그룹 캘린더 UI 개선

#### 장소 캘린더 Phase 5: 차단 시간 관리 (3-4시간)
**목표**: PlaceBlockedTime 관리 UI

**작업 내용**:
1. **차단 시간 추가 폼** (2h)
   - 시작/종료 일시 선택 (DateTimePicker)
   - 차단 유형 선택 (MAINTENANCE/EMERGENCY/HOLIDAY/OTHER)
   - 차단 사유 입력 (선택)
   - 관리 주체만 접근
   - 파일 위치: `lib/presentation/pages/workspace/place/place_blocked_time_dialog.dart`

2. **차단 시간 목록** (1h)
   - 관리 주체만 조회/수정/삭제
   - 날짜 범위 필터링
   - 파일 위치: `lib/presentation/pages/workspace/place/place_blocked_times_list.dart`

3. **캘린더 뷰 통합** (1h)
   - 차단 시간 시각화 (빨간색 블록 + 사유 표시)
   - 예약 불가 표시

**API 엔드포인트**:
```
POST   /api/places/{id}/blocked-times          # 차단 시간 추가
GET    /api/places/{id}/blocked-times          # 차단 시간 조회
DELETE /api/places/{id}/blocked-times/{bid}    # 차단 시간 삭제
```

**완료 조건**:
- ✅ 차단 시간 추가 기능 (관리 주체만)
- ✅ 차단 시간 목록 조회
- ✅ 캘린더 뷰에 차단 시간 표시
- ✅ 예약 시 차단 시간 검증

**예상 시간**: 3-4시간

---

#### 그룹 캘린더 Phase 9: UI 개선 (선택, 9-13시간)
**목표**: 다단계 카드 선택 UI 구현

**참고 문서**: [Phase 9 UI 개선 계획](group-calendar-phase9-ui-improvement.md)

**작업 내용**:
1. Atoms 구현 (2-3h): SelectableOptionCard
2. Molecules 구현 (1-2h): OptionCardGroup, StepHeader
3. Organisms 구현 (3-4h): SingleStepSelector, MultiStepSelector
4. 그룹 일정 다이얼로그 적용 (2h)
5. 문서화 및 예제 (1-2h)

**재사용 시나리오**:
- 캘린더 일정 유형 선택 (공식/비공식)
- 채널 권한 역할 선택
- **장소 예약 시간 선택** (장소 캘린더 Phase 4 통합)

**우선순위**: P1 (권장, 필수 아님)

**예상 시간**: 9-13시간

---

### Week 9-10: 캘린더 뷰 개선 + 통합 테스트

#### 그룹 캘린더 Phase 10: 캘린더 뷰 개선 (선택, 8-12시간)
**목표**: 월간/주간/일간 캘린더 뷰 추가

**작업 내용**:
1. **월간 캘린더 뷰** (3h)
   - `table_calendar` 패키지 활용
   - 일정 마커 표시
   - 날짜 선택 시 상세 보기

2. **주간 캘린더 뷰** (3h)
   - WeekView 컴포넌트 (기존 시간표 컴포넌트 재사용)
   - 시간대별 일정 표시
   - 드래그 앤 드롭 지원 (향후 확장)

3. **일간 캘린더 뷰** (2h)
   - DayView 컴포넌트
   - 세부 시간대 표시 (30분 단위)

4. **탭 전환** (2h)
   - 월/주/일 탭 (상단 버튼)
   - 상태 유지 (날짜 선택 동기화)

**완료 조건**:
- ✅ 월간/주간/일간 뷰 모두 구현
- ✅ 뷰 간 전환 기능
- ✅ 날짜 선택 동기화
- ✅ 성능 최적화 (큰 데이터셋)

**우선순위**: P2 (선택)

**예상 시간**: 8-12시간

---

#### 통합 테스트 및 최적화 (4-6시간)
**목표**: 그룹 캘린더 + 장소 캘린더 통합 시나리오 검증

**테스트 시나리오**:
1. **장소 예약 플로우**
   - 장소 등록 → 사용 신청 → 승인 → 그룹 일정 생성 (장소 선택) → 예약 확인

2. **권한 검증**
   - CALENDAR_MANAGE 없는 사용자: 장소 등록 실패, 사용 신청 실패
   - 승인되지 않은 그룹: 장소 선택 불가
   - 관리 주체: 모든 예약 조회 및 강제 취소 가능

3. **예약 충돌 검증**
   - 동일 시간대 중복 예약 시도 → 409 CONFLICT
   - 운영 시간 외 예약 시도 → 400 BAD_REQUEST
   - 차단 시간 예약 시도 → 400 BAD_REQUEST

4. **성능 최적화**
   - JPA N+1 문제 해결 (`@EntityGraph`)
   - 권한 캐싱 (Redis)
   - 프론트엔드 렌더링 최적화 (ListView.builder)

**완료 조건**:
- ✅ E2E 테스트 통과 (모든 시나리오)
- ✅ 성능 벤치마크 (1000개 일정 로딩 < 2초)
- ✅ 문서 업데이트

**예상 시간**: 4-6시간

---

## 📊 타임라인 요약

| Week | 작업 내용 | 예상 시간 | 우선순위 |
|------|----------|----------|---------|
| Week 1-2 | 그룹 캘린더 Phase 8 (권한 통합) | 2-3h | P0 (필수) |
| Week 1-2 | 장소 캘린더 Phase 2 (프론트엔드) | 6-8h | P0 (필수) |
| Week 3-4 | 장소 캘린더 Phase 3 (사용 그룹) | 4-6h | P0 (필수) |
| Week 5-6 | 장소 캘린더 Phase 4 (예약 시스템) | 8-10h | P0 (필수) |
| Week 7-8 | 장소 캘린더 Phase 5 (차단 시간) | 3-4h | P0 (필수) |
| Week 7-8 | 그룹 캘린더 Phase 9 (UI 개선) | 9-13h | P1 (권장) |
| Week 9-10 | 그룹 캘린더 Phase 10 (캘린더 뷰) | 8-12h | P2 (선택) |
| Week 9-10 | 통합 테스트 및 최적화 | 4-6h | P0 (필수) |

**총 예상 시간**: 44-62시간 (약 6-8주, 주당 8-10시간 작업 기준)

---

## 🚀 즉시 착수 가능한 작업 (Next Actions)

### 1. 그룹 캘린더 Phase 8: 권한 통합 (2-3시간)
- ✅ 백엔드 API 완료
- ⏳ 프론트엔드 권한 체크 구현
- ⏳ 테스트 작성

### 2. 장소 캘린더 Phase 2: 프론트엔드 기본 구현 (6-8시간)
- ✅ 백엔드 API 완료
- ⏳ 장소 목록 페이지
- ⏳ 장소 등록 폼
- ⏳ 운영 시간 설정 UI

**권장 순서**: Phase 8 (2-3h) → Phase 2 (6-8h)

---

## 🎯 마일스톤 (Milestones)

### M1: 그룹 캘린더 완성 (Week 2)
- ✅ Phase 1-7 완료
- ⏳ Phase 8 권한 통합 완료
- **결과**: 완전한 그룹 일정 관리 기능 제공

### M2: 장소 관리 기능 완성 (Week 4)
- ⏳ Phase 2-3 완료
- **결과**: 장소 등록, 사용 그룹 관리 기능 제공

### M3: 장소 예약 시스템 완성 (Week 6)
- ⏳ Phase 4 완료
- **결과**: 그룹 일정과 장소 예약 통합 기능 제공

### M4: 전체 시스템 완성 (Week 10)
- ⏳ Phase 5, 9, 10 완료 (선택 포함)
- ⏳ 통합 테스트 완료
- **결과**: 완전한 캘린더 시스템 (그룹 + 장소 + 개인)

---

## 📝 관련 문서

### 개념 문서
- [캘린더 시스템](../concepts/calendar-system.md) - 전체 시스템 개요
- [장소 관리](../concepts/calendar-place-management.md) - 장소 권한 및 예약
- [권한 시스템](../concepts/permission-system.md) - CALENDAR_MANAGE 권한

### 구현 가이드
- [그룹 캘린더 개발 계획](group-calendar-development-plan.md) - Phase 1-10 상세 계획
- [장소 캘린더 명세](place-calendar-specification.md) - 장소 시스템 상세 설계
- [백엔드 가이드](../implementation/backend-guide.md) - 3레이어 아키텍처
- [프론트엔드 가이드](../implementation/frontend-guide.md) - Flutter 구조

### Phase별 상세 문서
- [Phase 5 API 연동](group-calendar-phase5-api-integration.md)
- [Phase 6 수정/삭제](group-calendar-phase6-edit-delete.md)
- [Phase 7 E2E 테스트](group-calendar-phase7-e2e-tests.md)
- [Phase 9 UI 개선](group-calendar-phase9-ui-improvement.md)

---

**다음 단계**: 그룹 캘린더 Phase 8 권한 통합 착수
