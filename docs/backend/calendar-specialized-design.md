# 캘린더 특수 설계 (Calendar Specialized Design)

## 개요

시간표 데이터 관리, 장소 예약 시스템 통합, 최적 시간 추천 알고리즘, 동시성 제어 등 고급 기능의 설계 결정사항입니다. 이 문서는 개인 캘린더(Phase 3), 장소 캘린더(Phase 9-10), 최적화 기능의 구현 기반이 됩니다.

---

## DD-CAL-005: 시간표 데이터 정규화

**결정**: 2단계 정규화 (User:Course:CourseTimetable = 1:N:N)
- `CourseTimetable`: dayOfWeek, startTime, endTime, classroom, professor
- 이점: 다반 처리, 개인/그룹 캘린더 충돌 감지, 최적 시간 추천 기반

---

## DD-CAL-006: 장소 예약 통합 방식

**결정**: 1:1 바인딩 (GroupEvent:PlaceReservation = 1:1)
- 제약: 행사 수정 시 자동 업데이트, 삭제 시 자동 취소
- 구현 시점: Phase 9-10 (장소 캘린더 완전 구현 후)
- 성능: 예약 불가능 → 행사 생성 실패 (트랜잭션)

---

## DD-CAL-007: 최적 시간 추천 알고리즘

**결정**: 그리디 알고리즘 (가용 시간 교집합)
- 프로세스: 참여자 조회 → 타임테이블/개인 일정 조회 → 1시간 단위 계산 → 상위 5개 추천
- 최적화: DD-005 정규화 활용 + 캐시 (1주일 단위)
- 성격: 선택적 기능 (필수 아님)

---

## DD-CAL-008: 동시성 제어 전략

**결정**: 낙관적 락 (`GroupEvent.version` 컬럼)
- 구현: JPA `@Version` 어노테이션 + 자동 증가
- 충돌 처리: `OptimisticLockingFailureException` → 클라이언트 재시도
- 격리 레벨: REPEATABLE_READ 이상 (MySQL 기본값 사용)

---

## 코드 참조

- **시간표**: `Course`, `CourseTimetable` (backend/src/main/kotlin/org/castlekong/backend/entity/)
- **장소**: `PlaceReservation`, `PlaceReservationService` (backend/src/main/kotlin/org/castlekong/backend/)
- **알고리즘**: `OptimalTimeRecommendationService`, `TimeSlotAnalyzer`
- **동시성**: `GroupEvent` (version 필드 포함)

---

## 관련 문서

- **기본 설계**: [캘린더 핵심 설계](./calendar-core-design.md) - 권한, 반복, 참여
- **개인 캘린더**: [개인 캘린더 시스템](../concepts/personal-calendar-system.md) - 시간표 활용
- **장소 캘린더**: [장소 캘린더 시스템](../concepts/place-calendar-system.md) - 예약 관리
- **통합 플로우**: [캘린더 통합](../concepts/calendar-integration.md)
- **API 명세**: [API 참조](../implementation/api-reference.md#캘린더)
- **스키마**: [DB 참조](../implementation/database-reference.md#Course)
