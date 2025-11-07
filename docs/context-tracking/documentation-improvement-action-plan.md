# 📋 문서 개선 액션 플랜

**작성일**: 2025-10-24
**최종 업데이트**: 2025-10-24

## 📊 현재 상황 요약

### 발견된 문제점
1. **100줄 초과 문서**: 40개 (전체 79개 중 50.6%)
2. **깨진 링크**: 61개 (추정, 검증 필요)
3. **컨텍스트 추적 누락**: 31개 문서 (sync-status.md 미등록)

### 영향도 분석
- **심각도**: Medium-High
  - 문서 분할 원칙 위반으로 가독성 저하
  - 깨진 링크로 인한 네비게이션 장애
  - 컨텍스트 동기화 추적 불가능
- **긴급도**: Medium
  - 즉각적인 기능 장애는 없음
  - 장기적 유지보수성 악화
  - 신규 개발자 온보딩 어려움

---

## 🎯 Phase 1: 긴급 조치 (1-2일)

### ✅ Task 1-1: markdown-guidelines.md 업데이트 (완료)
- **상태**: ✅ 완료 (2025-10-24)
- **소요 시간**: 1시간
- **담당**: Context Manager (자동)
- **결과**:
  - 100줄 원칙 명확화
  - 백엔드 코드 참조 정책 추가
  - 문서 검증 체크리스트 강화

### 🔧 Task 1-2: 깨진 링크 자동 검증 스크립트 작성
- **상태**: ⏳ 대기 중
- **예상 시간**: 2시간
- **담당**: Context Manager
- **의존성**: 없음
- **작업 내용**:
  1. Bash 스크립트 작성 (`scripts/check-broken-links.sh`)
     - 모든 .md 파일에서 상대 경로 링크 추출
     - 파일 존재 여부 확인
     - 깨진 링크 목록 생성 (CSV 형식)
  2. 깨진 링크 리포트 자동 생성
     - 소스 파일 → 깨진 링크 → 대체 파일 제안
  3. GitHub Actions 또는 pre-commit hook 통합 고려
- **산출물**:
  - `scripts/check-broken-links.sh`
  - `docs/context-tracking/broken-links-report.md`

### 📊 Task 1-3: 깨진 링크 매핑 테이블 생성
- **상태**: ⏳ 대기 중
- **예상 시간**: 1시간
- **담당**: Context Manager (수동 검토)
- **의존성**: Task 1-2 완료
- **작업 내용**:
  1. 자동 검증 결과 분석
  2. 삭제된 파일 → 신규 파일 매핑
     - 예: `calendar-design-decisions.md` → `backend/calendar-core-design.md`
     - 예: `backend/README.md` → `implementation/backend/README.md`
  3. 링크 수정 우선순위 설정
     - P0: CLAUDE.md 링크 (네비게이션 허브)
     - P1: 개념 문서 → 구현 가이드 링크
     - P2: 기타 상호 참조 링크
- **산출물**:
  - `docs/context-tracking/link-mapping-table.md`

---

## ⚡ Phase 2: 우선 조치 (3-5일)

### 📝 Task 2-1: 긴급 문서 분할 (10개)
- **상태**: ⏳ 대기 중
- **예상 시간**: 8-10시간 (문서당 평균 1시간)
- **담당**: Context Manager + Sub-Agents
- **의존성**: Task 1-1 완료 (✅)
- **작업 대상**:

#### 우선순위 P0 (즉시 분할 필요, 3개, 3-4시간)
1. **database-reference.md** (1659줄 → 6개 파일)
   - 분할 구조:
     - `database-core-tables.md` (100줄): User, Group, Department, University
     - `database-permission-tables.md` (100줄): GroupRole, ChannelRoleBinding
     - `database-workspace-tables.md` (100줄): Workspace, Channel, Post, Comment
     - `database-recruitment-tables.md` (100줄): Recruitment, Application, Answer
     - `database-calendar-tables.md` (100줄): Calendar, Event, Place, Reservation
     - `database-reference.md` (100줄): 인덱스 + 각 파일 링크
   - 링크 업데이트: 15개 파일 예상

2. **api-reference.md** (874줄 → 4개 파일)
   - 분할 구조:
     - `api-authentication.md` (100줄): Google OAuth, JWT
     - `api-workspace.md` (100줄): Group, Channel, Post, Comment
     - `api-recruitment.md` (100줄): Recruitment, Application
     - `api-calendar.md` (100줄): Calendar, Event, Place, Reservation
     - `api-reference.md` (100줄): 인덱스 + API 설계 원칙
   - 링크 업데이트: 12개 파일 예상

3. **group-calendar-development-plan.md** (1303줄 → 5개 파일)
   - 분할 구조:
     - `group-calendar-phase-1-3.md` (100줄): Phase 1-3 (기본 CRUD)
     - `group-calendar-phase-4-6.md` (100줄): Phase 4-6 (반복 일정, 수정/삭제)
     - `group-calendar-phase-7-9.md` (100줄): Phase 7-9 (권한, UI)
     - `group-calendar-phase-10.md` (100줄): Phase 10 (최종 테스트)
     - `group-calendar-development-plan.md` (100줄): 로드맵 + 링크
   - 링크 업데이트: 8개 파일 예상

#### 우선순위 P1 (중요, 7개, 5-6시간)
4. **testing-strategy.md** (889줄 → 4개 파일)
   - `testing-unit-tests.md` (100줄)
   - `testing-integration-tests.md` (100줄)
   - `testing-security-tests.md` (100줄)
   - `testing-strategy.md` (100줄): 인덱스

5. **personal-calendar-mvp.md** (779줄 → 3개 파일)
   - `personal-calendar-backend.md` (100줄)
   - `personal-calendar-frontend.md` (100줄)
   - `personal-calendar-mvp.md` (100줄): 개요 + 링크

6. **common-errors.md** (645줄 → 3개 파일)
   - `errors-backend.md` (100줄)
   - `errors-frontend.md` (100줄)
   - `common-errors.md` (100줄): 인덱스

7. **frontend-development-agent.md** (514줄 → 2개 파일)
   - `frontend-development-workflow.md` (100줄)
   - `frontend-development-agent.md` (100줄): 에이전트 설정

8. **calendar-integration-roadmap.md** (414줄 → 2개 파일)
   - `calendar-integration-timeline.md` (100줄)
   - `calendar-integration-roadmap.md` (100줄): 개요

9. **context-sync-agent.md** (374줄 → 2개 파일)
   - `context-sync-workflow.md` (100줄)
   - `context-sync-agent.md` (100줄): 에이전트 설정

10. **test-data-reference.md** (364줄 → 2개 파일)
    - `test-data-users-groups.md` (100줄)
    - `test-data-reference.md` (100줄): 인덱스

### 🔗 Task 2-2: 분할 후 링크 일괄 업데이트
- **상태**: ⏳ 대기 중
- **예상 시간**: 3-4시간
- **담당**: Context Manager (자동화 + 수동 검증)
- **의존성**: Task 2-1 완료, Task 1-3 완료
- **작업 내용**:
  1. 분할된 문서 링크 자동 업데이트 스크립트 작성
  2. CLAUDE.md 네비게이션 재구성
  3. 모든 문서의 "관련 문서" 섹션 업데이트
  4. 링크 검증 재실행
- **산출물**:
  - `scripts/update-links.sh`
  - CLAUDE.md 업데이트
  - 40+ 문서 링크 수정

---

## 🔧 Phase 3: 장기 개선 (1주)

### 📊 Task 3-1: sync-status.md 재구축
- **상태**: ⏳ 대기 중
- **예상 시간**: 4-6시간
- **담당**: Context Manager
- **의존성**: Task 2-1, 2-2 완료
- **작업 내용**:
  1. 신규 79개 문서 전수 조사
  2. 디렉토리별 분류 재정리
     - `/docs/backend/` 섹션 추가 (6개 파일)
     - `/docs/implementation/backend/` 섹션 추가 (9개 파일)
     - `/docs/implementation/frontend/` 섹션 추가 (8개 파일)
  3. 각 문서의 마지막 업데이트 날짜 추적
  4. 관련 커밋 해시 매핑
  5. 업데이트 필요 문서 식별 (❌ 표시)
- **산출물**:
  - `docs/context-tracking/sync-status.md` (전면 재작성)
  - 누락된 31개 문서 추가

### 🤖 Task 3-2: 자동화 시스템 구축
- **상태**: ⏳ 대기 중
- **예상 시간**: 6-8시간
- **담당**: Context Manager + Backend Architect
- **의존성**: Task 3-1 완료
- **작업 내용**:
  1. **문서 길이 검증 자동화**
     - pre-commit hook: 100줄 초과 문서 경고
     - GitHub Actions: PR 시 자동 검사
  2. **링크 검증 자동화**
     - CI/CD 파이프라인 통합
     - 깨진 링크 자동 리포트
  3. **컨텍스트 동기화 알림**
     - 커밋 메시지에서 영향 받는 문서 자동 추출
     - pending-updates.md 자동 업데이트 제안
  4. **문서 통계 대시보드**
     - 총 문서 수, 평균 길이, 최신 업데이트
     - 100줄 준수율, 링크 정합성 점수
- **산출물**:
  - `.github/workflows/docs-validation.yml`
  - `.git/hooks/pre-commit`
  - `scripts/doc-stats.sh`
  - `docs/context-tracking/doc-statistics.md`

### 📝 Task 3-3: 문서 품질 가이드라인 강화
- **상태**: ⏳ 대기 중
- **예상 시간**: 2시간
- **담당**: Context Manager
- **의존성**: Task 3-1, 3-2 완료
- **작업 내용**:
  1. markdown-guidelines.md 추가 개선
     - 문서 분할 전략 상세화
     - 링크 작성 규칙 명확화
     - 자동화 도구 사용 가이드
  2. 문서 템플릿 제공
     - 개념 문서 템플릿
     - 구현 가이드 템플릿
     - API/DB 참조 문서 템플릿
  3. 에이전트 가이드에 문서 작성 규칙 추가
- **산출물**:
  - `markdown-guidelines.md` 업데이트
  - `docs/templates/` 디렉토리 생성
  - 각 에이전트 가이드 업데이트

---

## 🗺️ 깨진 링크 수정 전략 (61개)

### 자동화 접근법
1. **링크 추출 및 검증** (Task 1-2)
   - 정규 표현식으로 모든 마크다운 링크 추출
   - 상대 경로 해석 및 파일 존재 확인
   - 깨진 링크 목록 생성

2. **삭제된 파일 → 신규 파일 매핑** (Task 1-3)
   - git 이력 분석: `git log --follow --diff-filter=D`
   - 파일명 유사도 기반 자동 제안
   - 수동 검토 및 확정

3. **일괄 수정 스크립트** (Task 2-2)
   - `sed` 또는 `awk` 기반 일괄 치환
   - 백업 생성 후 실행
   - 수정 후 링크 검증 재실행

### 수동 수정 필요 부분
1. **컨텍스트 의존적 링크** (20개 예상)
   - 문서 분할로 인한 섹션 링크 변경
   - 새로운 인덱스 파일로 리다이렉트
   - 관련 문서 재평가 필요

2. **삭제된 개념 문서** (10개 예상)
   - `calendar-design-decisions.md` → 새로운 백엔드 설계 문서 2개
   - `calendar-place-management.md` → `place-calendar-system.md`
   - 내용 통합 및 링크 재매핑

3. **구조 변경 링크** (15개 예상)
   - `/docs/implementation/` → `/docs/implementation/backend/` or `/frontend/`
   - 디렉토리 구조 변경에 따른 상대 경로 조정

### 삭제된 파일 → 신규 파일 매핑 테이블 (초안)

| 삭제된 파일 | 신규 파일 | 비고 |
|------------|----------|------|
| `calendar-design-decisions.md` | `backend/calendar-core-design.md` | 권한, 반복 설계 |
| `calendar-design-decisions.md` | `backend/calendar-specialized-design.md` | 시간표, 장소 설계 |
| `calendar-place-management.md` | `concepts/place-calendar-system.md` | 장소 캘린더 개념 |
| `backend/README.md` | `implementation/backend/README.md` | 백엔드 인덱스 |
| `component-reusability-guide.md` | `implementation/frontend/components.md` | 컴포넌트 가이드 |
| `frontend-guide.md` | `implementation/frontend/README.md` | 프론트엔드 인덱스 |
| `frontend-workspace-guide.md` | `implementation/workspace-page-implementation-guide.md` | 워크스페이스 구현 |
| `workspace-level-navigation-guide.md` | `implementation/workspace-state-management.md` | 상태 관리 |
| `workspace-page-implementation-guide-part2.md` | `implementation/workspace-page-checklist.md` | 체크리스트 통합 |
| `workspace-page-implementation-guide-part3.md` | `implementation/workspace-state-management.md` | 상태 관리 통합 |
| `workspace-page-implementation-guide-part4.md` | `implementation/workspace-troubleshooting.md` | 트러블슈팅 통합 |

---

## 📊 100줄 초과 문서 분할 계획 (상세)

### 분할 전략 원칙
1. **논리적 단위 기준 분할**
   - 기능별, Phase별, 도메인별
   - 각 파일은 독립적으로 이해 가능
   - 명확한 인덱스 파일 유지

2. **계층 구조 유지**
   - 부모 문서 (인덱스): 개요 + 하위 문서 링크
   - 자식 문서: 구체적 내용
   - 최대 2단계 깊이 권장

3. **링크 무결성 보장**
   - 분할 전 링크 목록 추출
   - 분할 후 자동 링크 업데이트
   - 검증 스크립트 실행

### 우선순위별 분할 계획

#### P0: 참조 문서 (3개) - 즉시 분할 필요
이 문서들은 자주 참조되며, 길이가 매우 길어 가독성이 심각하게 저하됨.

**1. database-reference.md (1659줄 → 6개 파일)**
- **분할 이유**:
  - 모든 테이블 스키마를 단일 파일에 포함
  - 특정 도메인 검색 시 스크롤 과다
  - 100줄 원칙 위반 정도: 1559줄 초과 (심각)
- **분할 구조**:
  ```
  docs/implementation/database/
  ├── database-reference.md (100줄) - 인덱스 + ERD + 공통 규칙
  ├── core-tables.md (100줄) - User, Group, Department, University
  ├── permission-tables.md (100줄) - GroupRole, ChannelRoleBinding, Permission
  ├── workspace-tables.md (100줄) - Workspace, Channel, Post, Comment, File
  ├── recruitment-tables.md (100줄) - Recruitment, Application, Question, Answer
  └── calendar-tables.md (100줄) - Calendar, Event, Place, Reservation, PlaceUsageGroup
  ```
- **링크 영향**: 15개 파일 (모든 백엔드 가이드, API 참조)
- **분할 후 이점**:
  - 도메인별 빠른 검색
  - 테이블 추가 시 영향 범위 최소화
  - 각 서브 에이전트가 관련 도메인만 참조 가능

**2. api-reference.md (874줄 → 4개 파일)**
- **분할 이유**:
  - 모든 API 엔드포인트를 단일 파일에 포함
  - 특정 API 검색 시 비효율적
  - 100줄 원칙 위반 정도: 774줄 초과 (심각)
- **분할 구조**:
  ```
  docs/implementation/api/
  ├── api-reference.md (100줄) - 인덱스 + API 설계 원칙 + 공통 응답 구조
  ├── authentication-api.md (100줄) - Google OAuth, JWT, Login, Logout
  ├── workspace-api.md (100줄) - Group, Channel, Post, Comment API
  ├── recruitment-api.md (100줄) - Recruitment, Application API
  └── calendar-api.md (100줄) - Calendar, Event, Place, Reservation API
  ```
- **링크 영향**: 12개 파일 (프론트엔드 가이드, 워크플로우)
- **분할 후 이점**:
  - API 도메인별 독립적 관리
  - 프론트엔드 개발자가 필요한 API만 참조
  - API 버전 관리 용이

**3. group-calendar-development-plan.md (1303줄 → 5개 파일)**
- **분할 이유**:
  - 10개 Phase를 단일 파일에 포함
  - 현재 진행 중인 Phase 확인 어려움
  - 100줄 원칙 위반 정도: 1203줄 초과 (매우 심각)
- **분할 구조**:
  ```
  docs/features/group-calendar/
  ├── development-plan.md (100줄) - 로드맵 + 전체 Phase 링크
  ├── phase-1-3-crud.md (100줄) - Phase 1-3 (기본 CRUD, 조회, 캐싱)
  ├── phase-4-6-recurrence.md (100줄) - Phase 4-6 (반복 일정, 수정/삭제)
  ├── phase-7-9-permission-ui.md (100줄) - Phase 7-9 (권한 통합, UI)
  └── phase-10-testing.md (100줄) - Phase 10 (최종 통합 테스트)
  ```
- **링크 영향**: 8개 파일 (개념 문서, UI/UX 명세)
- **분할 후 이점**:
  - Phase별 진행 상황 명확히 추적
  - 각 Phase 완료 시 해당 문서만 업데이트
  - 현재 작업 중인 Phase에 집중 가능

#### P1: 가이드 문서 (7개) - 3일 내 분할 권장

**4. testing-strategy.md (889줄 → 4개 파일)**
- **분할 구조**:
  ```
  docs/workflows/testing/
  ├── testing-strategy.md (100줄) - 테스트 전략 개요
  ├── unit-tests.md (100줄) - 단위 테스트 가이드
  ├── integration-tests.md (100줄) - 통합 테스트 가이드
  └── security-tests.md (100줄) - 보안 테스트 가이드
  ```

**5. personal-calendar-mvp.md (779줄 → 3개 파일)**
- **분할 구조**:
  ```
  docs/features/personal-calendar/
  ├── mvp-summary.md (100줄) - MVP 개요 + 구현 완료 요약
  ├── backend-implementation.md (100줄) - 백엔드 구현 상세
  └── frontend-implementation.md (100줄) - 프론트엔드 구현 상세
  ```

**6. common-errors.md (645줄 → 3개 파일)**
- **분할 구조**:
  ```
  docs/troubleshooting/
  ├── common-errors.md (100줄) - 에러 인덱스 + 빠른 참조
  ├── backend-errors.md (100줄) - 백엔드 에러 (DB, JWT, 권한)
  └── frontend-errors.md (100줄) - 프론트엔드 에러 (레이아웃, 상태)
  ```

**7-10. 에이전트 및 기타 문서**
- 유사한 패턴으로 분할 (생략)

---

## ✅ 최종 체크리스트

### Phase 1 완료 기준
- [x] markdown-guidelines.md 업데이트 완료
- [ ] 깨진 링크 자동 검증 스크립트 작성
- [ ] 깨진 링크 매핑 테이블 생성
- [ ] 긴급 조치 완료 리포트 작성

### Phase 2 완료 기준
- [ ] 10개 우선 문서 분할 완료
- [ ] 분할된 문서 링크 일괄 업데이트
- [ ] CLAUDE.md 네비게이션 재구성
- [ ] 링크 검증 100% 통과
- [ ] 100줄 준수율 80% 이상 달성

### Phase 3 완료 기준
- [ ] sync-status.md 79개 문서 전수 등록
- [ ] 자동화 시스템 3종 구축 (길이/링크/동기화)
- [ ] CI/CD 파이프라인 통합
- [ ] 문서 통계 대시보드 구축
- [ ] 문서 품질 가이드라인 강화

### 전체 개선 완료 기준
- [ ] 깨진 링크 0개
- [ ] 100줄 초과 문서 0개 (참조 문서 제외)
- [ ] sync-status.md 등록률 100%
- [ ] 자동화 시스템 정상 작동
- [ ] 모든 에이전트가 새로운 문서 구조 인지

---

## 📈 진행 상황 추적

### 완료 항목
- [x] Phase 1 - Task 1-1: markdown-guidelines.md 업데이트 (2025-10-24)

### 진행 중 항목
- [ ] 없음

### 대기 항목 (우선순위 순)
1. Phase 1 - Task 1-2: 깨진 링크 자동 검증 스크립트
2. Phase 1 - Task 1-3: 깨진 링크 매핑 테이블
3. Phase 2 - Task 2-1: 긴급 문서 분할 (P0 3개)
4. Phase 2 - Task 2-2: 링크 일괄 업데이트
5. Phase 2 - Task 2-1: 우선 문서 분할 (P1 7개)
6. Phase 3 - Task 3-1: sync-status.md 재구축
7. Phase 3 - Task 3-2: 자동화 시스템 구축
8. Phase 3 - Task 3-3: 문서 품질 가이드라인 강화

---

## 🎯 다음 액션 (Next Actions)

### 즉시 실행 (Today)
1. **Task 1-2 시작**: 깨진 링크 자동 검증 스크립트 작성
   - 예상 시간: 2시간
   - 책임자: Context Manager

### 내일 (Tomorrow)
1. **Task 1-3 완료**: 깨진 링크 매핑 테이블 생성
2. **Task 2-1 시작**: database-reference.md 분할

### 이번 주 (This Week)
1. **Phase 2 완료**: 10개 문서 분할 + 링크 업데이트
2. **Phase 1 검증**: 모든 깨진 링크 수정 완료

---

## 🔗 관련 문서
- [Markdown Guidelines](../../markdown-guidelines.md)
- [Context Update Log](context-update-log.md)
- [Sync Status](sync-status.md)
- [Pending Updates](pending-updates.md)
