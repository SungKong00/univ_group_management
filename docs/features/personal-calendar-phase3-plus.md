# 개인 캘린더 개발 Phase 1~5 작업 기록

> **작성일**: 2025-10-??
> **작성자**: Codex Agent
> **범위**: Phase 1 (시간표 백엔드) ~ Phase 5 (통합 및 테스트)

---

## 1. 개요

개인 일정 관리 MVP는 **시간표(Timetable)**와 **캘린더(Calendar)**를 분리된 도메인으로 설계합니다. 시간표는 “매주 반복되는 고정 일정”, 캘린더는 “단발성 이벤트”를 관리합니다. 단계별 우선순위는 다음과 같습니다.

| Phase | 목표 | 주요 산출물 |
|:--|:--|:--|
| **Phase 1** | 시간표 백엔드 구축 | `PersonalSchedule` 엔티티·Repository·Service·Controller, `/api/timetable` API, 통합 테스트 |
| **Phase 2** | 시간표 프론트엔드 | Weekly View UI, CRUD 폼, 겹침 경고, “수업 추가” CTA |
| **Phase 3** | 개인 캘린더 백엔드 | `PersonalEvent` 엔티티, `/api/calendar` CRUD, 기간 조회 |
| **Phase 4** | 개인 캘린더 프론트엔드 | 월/주/일 뷰, 이벤트 UI, 색상/종일 처리 |
| **Phase 5** | 통합 및 QA | 네비게이션 연동, 반응형 대응, E2E/성능 테스트 |

---

## 2. Phase 1 — 시간표(Timetable) 백엔드

### 2.1 요구사항
- 개인 주간 반복 일정 CRUD (`/api/timetable`).
- 초기 명세: docs/features/personal-calendar-mvp.md §3.1, §5.1 참조.
- 프론트 기대 DTO: `id`, `title`, `dayOfWeek`, `startTime`, `endTime`, `location`, `color`.

### 2.2 구현 현황
- **엔티티**: `PersonalSchedule` (DayOfWeek + LocalTime 기반, 반복 패턴 필드 제거).
- **Repository**: 사용자 ID 기준 요일/시간 정렬 조회.
- **Service**: 시간 검증(종료 > 시작), 색상 형식 체크, 소유권 확인.
- **Controller**: `/api/timetable` GET/POST/PUT/DELETE, 인증 사용자 전용.
- **예외 처리**: `PERSONAL_SCHEDULE_NOT_FOUND`, `PERSONAL_SCHEDULE_INVALID_TIME` 추가.
- **통합 테스트**: MockMvc로 리스트 정렬, 생성, 권한 위반, 삭제, 잘못된 입력 검증.

### 2.3 향후 과제
- 반복 패턴(seriesId, recurrenceRule 등)은 추후 Phase 2+에서 재도입.
- 주간 시작일/캘린더 locale 등 프론트 연동을 위한 정책 문서화 필요.

---

## 3. Phase 2 — 시간표 프론트엔드 (체크포인트)
- Weekly View(06:00~24:00, 30분 단위) 렌더링.
- “개인 일정 추가” 폼과 색상 팔레트; 시간 겹침은 경고 후 진행.
- “수업 추가” 버튼은 토스트로 비활성 상태 표시 (향후 Course 연동 예정).
- LocalStorage로 마지막 탭/주차 기억.

---

## 4. Phase 3 — 개인 캘린더 백엔드
- `PersonalEvent` 엔티티, 기간별 조회, CRUD.
- `GET /api/calendar?start=YYYY-MM-DD&end=YYYY-MM-DD`.
- 소유권 검증 및 색상/시간대 검증 포함.
- 통합 테스트로 성공/실패 시나리오 확인.

---

## 5. Phase 4 — 개인 캘린더 프론트엔드
- `table_calendar` 기반 월 뷰.
- 커스텀 주/일 뷰, 이벤트 카드/색상/종일 표시.
- 빠른 생성, 상세 bottom sheet, 편집/삭제 흐름.
- 시간표 탭과 동일한 에러 배너/스낵바 패턴 통일.

---

## 6. Phase 5 — 통합 및 품질 보증

### 6.1 네비게이션 & 상태
- 글로벌 네비게이션 “캘린더” 메뉴 연결 및 탭 상태 저장.
- 시간표↔캘린더 탭 간 공유 상태 점검.
- 반응형 레이아웃(데스크톱/태블릿/모바일) 대응.

### 6.2 테스트 전략
- **E2E**: 로그인 → 시간표/캘린더 CRUD 전 흐름.
- **성능**: 월간 50+ 이벤트 렌더링, 기간조회 API 응답 시간.
- **오류 처리**: 백엔드 장애/네트워크 문제에서 배너+재시도 동작 확인.

---

## 7. 후속 로드맵 & 오픈 이슈
- **반복 패턴 고도화**: seriesId/recurrenceRule 재도입, 예외 일정 관리.
- **캘린더 ←→ 그룹 일정**: 개인 캘린더에 참여 그룹 이벤트 오버레이.
- **알림**: 푸시 알림/리마인더.
- **권한**: 공유/위임 기능을 위한 세부 정책 설계.
- **모바일 UX**: 드래그/스와이프 UX 개선, 캘린더 뷰 전환 애니메이션.

---

### 참고 문서
- [개인 캘린더 MVP 명세](docs/features/personal-calendar-mvp.md)
- [캘린더 시스템 개념](docs/concepts/calendar-system.md)
- [백엔드 구현 가이드](docs/implementation/backend-guide.md)
- [프론트엔드 구현 가이드](docs/implementation/frontend-guide.md)

