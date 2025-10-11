# 개인 캘린더 개발 Phase 3~5 작업 기록

> **작성일**: 2025-10-??
> **작성자**: Codex Agent
> **범위**: Phase 3 (캘린더 백엔드) ~ Phase 5 (통합 및 테스트)

---

## 1. 개요

Phase 1, Phase 2 작업(개인 시간표 백엔드·프론트엔드)이 진행된 이후 남은 단계는 아래와 같다.

| Phase | 목표 | 주요 산출물 |
|:--|:--|:--|
| Phase 3 | PersonalEvent 백엔드 구축 | Entity, Repository, Service, Controller, 통합 테스트 |
| Phase 4 | 개인 캘린더 UI 구축 | 월간/주간/일간 뷰, 이벤트 CRUD UI, 색상 및 종일 표시 |
| Phase 5 | 전사 통합 및 품질 확보 | 네비게이션 통합, 반응형 대응, E2E/성능 점검 |

---

## 2. Phase 3 — 캘린더 백엔드 작업 계획

### 2.1 요구사항 정리
- 단일/기간 이벤트 저장을 위한 `personal_events` 테이블 정의 (spec ref. docs/features/personal-calendar-mvp.md §3.2, §5.2).
- 조회 API는 `start`, `end` 기간 쿼리 파라미터 기반.
- 인증 사용자 전용이며, 이벤트는 오너만 수정/삭제 가능.

### 2.2 구현 계획
1. **Entity & Schema**
   - Kotlin JPA 엔티티 `PersonalEvent` 작성 (`LocalDateTime` 필드, `isAllDay` 지원).
   - Flyway/Hibernate 스키마 반영 여부 확인.
2. **Repository**
   - 기간 조회용 메서드 (`findByUserAndPeriod(userId, start, end)`), Pageable 미적용.
3. **Service**
   - 생성/수정 시 파라미터 검증 (시작 < 종료 등).
   - 소유권 검증 및 예외 (`NotFoundException`, `ForbiddenException`).
4. **Controller**
   - `/api/calendar` CRUD 엔드포인트.
   - `ApiResponse<T>` 사용 및 `@PreAuthorize` 패턴 준수.
5. **Integration Test**
   - 성공 케이스: 생성→조회→수정→삭제.
   - 실패 케이스: 타 사용자 접근, 잘못된 기간, 404 확인.

### 2.3 리스크 및 확인사항
- 타임존: `Asia/Seoul` 고정 저장 및 프론트와 동일 포맷 사용.
- 대량 이벤트 대비 성능 검토 (인덱스: `user_id`, `start_date`, `end_date`).

---

## 3. Phase 4 — 개인 캘린더 프론트엔드 작업 계획

### 3.1 화면 구조
- **탭 구성**: 시간표/캘린더 (이미 구현 완료 - Phase2).
- **뷰 구분**: 월(Month) / 주(Week) / 일(Day) 전환.
- **이벤트 카드**: 색상, 종일, 기간 이벤트 시각화.

### 3.2 세부 작업
1. **상태 관리**
   - 새로운 Riverpod 프로바이더 (`calendarStateProvider`)로 PersonalEvent 목록 관리.
   - 기간 조회 시 `start`~`end`를 뷰 타입에 맞게 계산 (월: 1달, 주: 1주, 일: 1일).
2. **뷰별 UI**
   - `table_calendar` 이용한 월 뷰 (버튼/날짜 헤더 커스터마이징).
   - 커스텀 주/일 뷰 (시간축, drag-over UI 가능성 검토).
3. **CRUD 인터랙션**
   - Floating action button 또는 헤더 CTA로 “이벤트 추가”.
   - 카드 클릭 시 수정/삭제 bottom sheet (시간표 UI와 유사 패턴 재사용).
4. **상호작용**
   - 날짜 클릭 시 Day View로 이동.
   - 월/주 뷰에서 스와이프로 기간 이동.
5. **에러 처리**
   - 초기 로딩 실패 시 배너 + 재시도 (시간표 탭과 동일 패턴).
   - API 실패 시 토스트/스낵바.

### 3.3 검증 계획
- Unit 테스트: 이벤트 상태 변환·기간 계산.
- Golden 테스트: 월/주/일 레이아웃.
- Interaction 테스트: 이벤트 생성→UI 반영→삭제.

---

## 4. Phase 5 — 통합 및 테스트 계획

### 4.1 기능 통합
- 글로벌 네비게이션에 “캘린더” 메뉴 연결 (이미 라우팅 존재 − RouterListener 연동 확인).
- 시간표 ↔ 캘린더 탭간 상태 유지 (마지막 탭 LocalStorage 저장).
- 반응형 레이아웃: 데스크톱/태블릿/모바일에서 레이아웃 검증.

### 4.2 품질 보증
- **E2E 테스트**
  - 로그인 → 캘린더 접속 → 이벤트 생성/수정/삭제.
  - 시간표 이벤트도 포함한 전체 흐름.
- **성능**
  - 월 뷰 렌더링 시 50+ 이벤트 성능 체크.
  - 기간 조회 API latency 측정 및 캐싱 필요성 판단.
- **에러 시나리오**
  - 백엔드 장애 (500) → 사용자 메시지 (배너) 확인.
  - 오프라인/네트워크 에러: 재시도 동작 확인.

### 4.3 배포 전 체크리스트
- Swagger / API 문서 업데이트.
- 프론트엔드 문서 (docs/ui-ux, docs/implementation) 갱신.
- QA ToDo: 실제 데이터 기반 수동 테스트 항목 작성.

---

## 5. 후속 과제 & 오픈 이슈

1. **이벤트 반복 지원** (Phase 2+ 로드맵) → PersonalEvent 반복 규칙 도입.
2. **그룹 일정 오버레이**: 개인 캘린더에 그룹 이벤트 표시 토글.
3. **알림 연동**: 푸시 알림 및 알림 시점 설정.
4. **권한 정책 상세화**: PersonalEvent 공유 기능 여부 논의.
5. **모바일 UX**: Day/Week 뷰에서 스와이프/드래그 UX 고도화.

---

### 참고 문서
- `docs/features/personal-calendar-mvp.md`
- `docs/implementation/backend-guide.md`
- `docs/implementation/frontend-guide.md`
- `docs/concepts/calendar-system.md`

