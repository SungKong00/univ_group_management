# 캘린더 핵심 설계 (Calendar Core Design)

## 개요

그룹 캘린더의 기본 데이터 모델, 권한 시스템, 반복 일정 처리를 다루는 핵심 설계 결정사항입니다. 이 문서는 그룹 캘린더의 Phase 1-7 구현 기반이 됩니다.

---

## DD-CAL-001: 권한 통합 및 단순화

**결정**: 그룹 레벨 권한 `CALENDAR_MANAGE` 추가 (채널/그룹 권한 중복 제거)
- 구현: `GroupPermission` Enum + `PermissionService`
- 사용: `@PreAuthorize("@security.hasGroupPerm(..., 'CALENDAR_MANAGE')")`

---

## DD-CAL-002: 반복 일정 저장 방식

**결정**: 명시적 인스턴스 저장 (패턴 저장 X)
- 각 반복 인스턴스를 개별 레코드로 저장 (예: 12주 회의 = 12개 레코드)
- 장점: 쿼리 단순, 예외 처리 용이
- 생성: 미리 생성 또는 지연 생성 (선택 가능)

---

## DD-CAL-003: 반복 일정 예외 처리

**결정**: 별도 엔티티 `EventException` 추가 (1:N 관계)
- 예외 유형: MODIFIED, DELETED, RESCHEDULED
- 구현: `EventException` 엔티티 (groupEvent, occurredDate, type, modifiedData)

---

## DD-CAL-004: 참여자 관리 방식

**결정**: 독립 엔티티 `EventParticipant` 분리 (1:N 관계)
- 상태: PENDING, ACCEPTED, DECLINED, TENTATIVE
- 구현: `EventParticipant` 엔티티 + `EventParticipantService` (RSVP 처리)

---

## 코드 참조

- **Entity**: `GroupEvent`, `EventException`, `EventParticipant` (backend/src/main/kotlin/org/castlekong/backend/entity/)
- **Service**: `GroupEventService`, `PermissionService` (backend/src/main/kotlin/org/castlekong/backend/service/)

---

## 관련 문서

- **기능 설명**: [그룹 캘린더 시스템](../concepts/group-calendar-system.md)
- **특수 기능**: [캘린더 특수 설계](./calendar-specialized-design.md) - 시간표, 장소, 최적화
- **통합 플로우**: [캘린더 통합](../concepts/calendar-integration.md)
- **API 명세**: [API 참조](../implementation/api-reference.md#캘린더)
- **스키마**: [DB 참조](../implementation/database-reference.md#GroupEvent)
