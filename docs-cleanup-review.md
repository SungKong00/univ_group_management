# 📋 @docs/ 문서 검토 결과

**검토일**: 2025-10-24
**총 문서 수**: 66개
**검토 기준**: 일반 참고 문서(유지) vs 임시 개발 메모/스크래치(삭제 후보)

---

## ✅ 유지할 문서 (37개)

### 📚 개념 문서 (concepts/) - 10개 유지
모든 개념 문서는 시스템의 핵심 설계를 설명하는 정리된 문서로 **유지 필요**.

- `calendar-design-decisions.md` - 캘린더 시스템 설계 결정사항 아카이브
- `calendar-place-management.md` - 장소 관리 시스템 개념 정의
- `calendar-system.md` - 캘린더 통합 개념 설계 (v1.3)
- `channel-permissions.md` - Permission-Centric 권한 모델 설명
- `domain-overview.md` - 전체 시스템 개요 (진입점 문서)
- `group-hierarchy.md` - 그룹 계층 구조 설명
- `permission-system.md` - RBAC 권한 시스템 핵심 개념
- `recruitment-system.md` - 모집 시스템 개념
- `user-lifecycle.md` - 사용자 여정 안내
- `workspace-channel.md` - 워크스페이스와 채널 개념

### 🛠️ 구현 가이드 (implementation/) - 10개 유지
현재 및 향후 개발에 필요한 참조 가이드.

- `api-reference.md` - API 설계 규칙 및 엔드포인트 참조
- `backend-guide.md` - 백엔드 3레이어 아키텍처 가이드
- `component-reusability-guide.md` - 컴포넌트 재사용 패턴
- `database-reference.md` - 데이터베이스 스키마 및 엔티티 참조
- `frontend-guide.md` - 프론트엔드 아키텍처 가이드
- `frontend-workspace-guide.md` - 워크스페이스 프론트엔드 설계 (간결)
- `row-column-layout-checklist.md` - Flutter 레이아웃 제약 에러 방지 체크리스트
- `workspace-level-navigation-guide.md` - WorkspaceView 기반 상태 관리 설계
- `workspace-page-implementation-guide.md` - 워크스페이스 페이지 추가 메인 가이드
- `workspace-page-implementation-guide-part2.md` - Part 2: 브레드크럼 설정
- `workspace-page-implementation-guide-part3.md` - Part 3: 실수 방지 TOP 10
- `workspace-page-implementation-guide-part4.md` - Part 4: 설계 고려사항

### 🎨 UI/UX 문서 (ui-ux/) - 11개 유지
디자인 시스템 및 페이지 설계 명세.

**concepts/**:
- `color-guide.md` - 색상 팔레트 및 사용 규칙
- `design-system.md` - 전체 디자인 시스템 정의
- `responsive-design-guide.md` - 반응형 디자인 가이드

**pages/**:
- `authentication-pages.md` - 로그인/가입 페이지 UI/UX
- `channel-pages.md` - 채널 페이지 UI/UX
- `group-admin-page.md` - 그룹 관리 페이지 UI/UX
- `home-page.md` - 홈 페이지 UI/UX
- `my-activity-page.md` - 내 활동 페이지 UI/UX
- `navigation-and-page-flow.md` - 네비게이션 구조 UI/UX
- `recruitment-pages.md` - 모집 페이지 UI/UX
- `workspace-pages.md` - 워크스페이스 콘텐츠 페이지 UI/UX

### 🔧 워크플로우 & 컨벤션 (workflows/, conventions/) - 6개 유지
개발 프로세스 및 규칙.

**workflows/**:
- `development-flow.md` - 개발 프로세스 정의
- `testing-strategy.md` - 테스트 전략 및 정책

**conventions/**:
- `code-review-standards.md` - 코드 리뷰 기준
- `commit-conventions.md` - Conventional Commits 규칙
- `git-strategy.md` - GitHub Flow 브랜치 전략
- `pr-guidelines.md` - Pull Request 작성 규칙

### 📊 컨텍스트 추적 & 관리 (context-tracking/, agents/, maintenance/, testing/) - 7개 유지
문서 관리 시스템 및 서브 에이전트 정의.

**context-tracking/**:
- `context-update-log.md` - 문서 업데이트 이력
- `pending-updates.md` - 업데이트 대기 목록
- `sync-status.md` - 문서 동기화 상태

**agents/**:
- `commit-management-agent.md` - 커밋 관리 에이전트
- `context-sync-agent.md` - 컨텍스트 동기화 에이전트
- `frontend-development-agent.md` - 프론트엔드 개발 에이전트

**maintenance/**:
- `group-management-permissions.md` - 권한 추가 시 체크리스트

**testing/**:
- `test-data-reference.md` - TestDataRunner 구조 및 테스트 데이터

### 🐛 문제 해결 (troubleshooting/) - 2개 유지
현재 유효한 트러블슈팅 가이드.

- `common-errors.md` - 일반적인 에러 및 해결책
- `permission-errors.md` - 권한 관련 에러 트러블슈팅

### 🚀 기능 명세 (features/) - 4개 유지
완성도 높은 기능 명세서 및 로드맵.

- `calendar-integration-roadmap.md` - 그룹+장소 캘린더 통합 로드맵 (6-8주 계획)
- `group-calendar-development-plan.md` - 그룹 캘린더 Phase 1-10 상세 계획
- `personal-calendar-mvp.md` - 개인 캘린더 MVP 명세서 (완료)
- `place-calendar-specification.md` - 장소 캘린더 명세서 (Phase 1 완료)

---

## ❌ 삭제 후보 (26개)

### 📝 임시 개발 메모 & 스크래치 (features/) - 9개 삭제 추천

#### 1. `calendar-place-integration.md` (945줄)
- **이유**: 데모 캘린더에 장소 예약 통합 기능의 **초기 설계 스크래치**
- **상세**:
  - 작성일 2025-10-20, "Phase 1 완료 (문서화)" 상태
  - UI 레이아웃 스케치, 사용자 플로우 초안 포함
  - 이후 `demo-calendar-place-integration.md`로 더 상세하게 재작성됨
  - 내용이 `demo-calendar-place-integration.md`와 80% 중복
- **대체 문서**: `demo-calendar-place-integration.md` (더 완성도 높음)

#### 2. `demo-calendar-place-integration.md` (1,629줄)
- **이유**: 데모 캘린더-장소 통합 기능의 **매우 상세한 구현 명세 노트**
- **상세**:
  - 100줄 원칙 위반 (1,629줄)
  - API 명세, 데이터 모델, 알고리즘 상세, UI 와이어프레임 등 모든 개발 노트 포함
  - "Phase 1 완료 (문서화)" 상태로, 구현 과정 기록용
  - 핵심 개념은 이미 `calendar-place-management.md`에 정리됨
- **대체 문서**: `calendar-place-management.md` (개념), `place-calendar-specification.md` (명세)

#### 3. `group-event-place-frontend-plan.md` (1,666줄)
- **이유**: 그룹 일정-장소 통합 프론트엔드의 **구현 진행 중 작업 로그**
- **상세**:
  - 100줄 원칙 심각 위반 (1,666줄)
  - "Phase 1 완료, Phase 2 진행 중" 상태 (2025-10-18)
  - 컴포넌트 구현 체크리스트, API 연동 노트, 버그 수정 이력 포함
  - 구현이 완료되면 핵심 내용만 가이드 문서로 재정리 필요
- **권장**: 구현 완료 후 핵심 패턴만 추출하여 implementation 가이드로 통합

#### 4. `group-event-place-integration.md` (1,192줄)
- **이유**: 그룹 일정-장소 통합의 **백엔드 설계 및 구현 완료 노트**
- **상세**:
  - "완료 (2025-10-18)" 상태, palce_callendar 브랜치
  - 데이터 모델 Before/After, API 설계 초안, 비즈니스 규칙 검토 과정 포함
  - 완료된 기능의 구현 과정 기록으로, 현재는 코드 자체가 정답
  - 핵심 설계 결정사항은 `calendar-design-decisions.md`에 이미 정리됨

#### 5. `place-time-management-redesign.md` (1,182줄)
- **이유**: 장소 시간 관리 시스템의 **재설계 제안서** (논의용 문서)
- **상세**:
  - "설계 검토 중" 상태 (2025-10-19)
  - 현재 시스템 분석 → 변경 요청 → 새 모델 제안 → 마이그레이션 전략 → 의논사항
  - 최종 결정 전의 브레인스토밍/RFC 문서 성격
  - 결정이 확정되면 `calendar-place-management.md`에 반영하고 삭제 권장

#### 6. `personal-calendar-phase3-plus.md` (96줄)
- **이유**: 개인 캘린더 Phase 1~5 작업 **구현 기록**
- **상세**:
  - Phase별 구현 현황, 향후 과제 메모
  - "Phase 1~5 작업 기록" 제목으로, 개발 중 작성된 진행 노트
  - 완료된 내용은 `personal-calendar-mvp.md`에 이미 통합됨
  - 현재는 히스토리 로그 성격

#### 7. `group-calendar-official-events-roadmap.md` (895줄)
- **이유**: 공식 일정 추가 기능의 **로드맵 및 설계 노트**
- **상세**:
  - "설계 확정" 상태 (2025-10-12)
  - Phase 1-6 완료 상태 분석, 미완성 기능 체크리스트
  - GroupEvent 엔티티 필드 추가 계획, isOfficial 플래그 설계
  - 구현 완료 후 `group-calendar-development-plan.md`에 통합 가능

#### 8. `place-calendar-phase2-frontend-basic.md` (727줄)
- **이유**: 장소 캘린더 Phase 2 프론트엔드 구현 **세부 작업 계획**
- **상세**:
  - "계획 수립 완료, 구현 대기" 상태
  - 파일 위치, 컴포넌트 구조, 작업 항목 체크리스트
  - Phase 1 완료 후 다음 단계 작업 계획서
  - 구현 시작 전 참조용, 완료 후 삭제 예정

#### 9. `place-calendar-phase3-usage-permission.md` (883줄)
- **이유**: 장소 캘린더 Phase 3 예약 권한 시스템 **구현 계획**
- **상세**:
  - "계획 수립 완료, 구현 대기" 상태
  - Phase 2 의존성, 백엔드 API 개선 계획, UI 플로우 설계
  - 작업 항목 세부 체크리스트 포함
  - 구현 시작 전 참조용, 완료 후 삭제 예정

---

### 🔍 임시 분석 문서 (implementation/) - 1개 삭제 추천

#### 10. `state-persistence-pattern-analysis.md` (800줄)
- **이유**: 워크스페이스 상태 관리 **패턴 분석 노트** (연구 목적)
- **상세**:
  - "워크스페이스 vs 홈/캘린더" 상태 관리 비교 분석
  - 3계층 상태 관리 시스템 코드 예시 및 분석
  - 작성 목적: "홈/캘린더에 적용하기 위한 설계 문서"
  - 분석 결과는 이미 `frontend-guide.md`, `workspace-level-navigation-guide.md`에 반영됨
- **권장**: 핵심 패턴만 `frontend-guide.md`에 통합 후 삭제

---

### 🐛 DEPRECATED 문서 (troubleshooting/) - 2개 삭제 필수

#### 11. `recruitment-filter-validation.md` (약 200줄 추정)
- **이유**: **DEPRECATED (2025-10-11)** - 완전히 제거된 필드 관련 문서
- **상세**:
  - 문서 첫 줄에 명시: "is_recruiting / isRecruiting 필드는 프로젝트에서 완전히 제거됨"
  - 과거 모집 중 필터 검증 결과 및 문제점 분석
  - "과거 문제 해결 기록으로만 보관" 상태
- **삭제 권장**: 현재 시스템과 무관, 히스토리 가치 낮음

#### 12. `recruitment-status-issue.md` (약 200줄 추정)
- **이유**: **DEPRECATED (2025-10-11)** - 완전히 제거된 필드 관련 문서
- **상세**:
  - 문서 첫 줄에 명시: "is_recruiting / isRecruiting 필드는 프로젝트에서 완전히 제거됨"
  - 과거 잘못된 구현 방식 및 수정 과정 기록
  - "과거 문제 해결 기록으로만 보관" 상태
- **삭제 권장**: 현재 시스템과 무관, 혼란 방지를 위해 삭제 필요

---

### 🎨 임시 UI 설계 노트 (ui-ux/) - 1개 삭제 추천

#### 13. `weekly-calendar-component-design.md` (약 800줄 추정)
- **이유**: 주간 뷰 캘린더 UI 컴포넌트 **설계 논의 및 결정사항 아카이브**
- **상세**:
  - "설계 확정 (논의사항 11개 모두 결정 완료)" 상태 (2025-10-17)
  - 드래그 스크롤, 간격 모드, 렌더링 방식 등 상세 기술 결정사항
  - 주요 결정사항 요약 테이블 포함 (매우 상세함)
  - 설계 완료 후 구현 참조용으로 작성된 문서
- **판단 근거**:
  - ✅ 유지: 구현 시 참조할 기술 결정사항 상세 문서로 가치 있음
  - ❌ 삭제: 설계 확정 후 구현 가이드로 재정리하고 삭제
- **권장**: **검토 필요** - 구현 완료 여부 확인 후, 핵심 패턴만 `design-system.md`에 통합하고 삭제

---

## 🔄 검토 필요 (3개)

### 논의가 필요한 문서들

#### 1. `weekly-calendar-component-design.md`
- **상태**: 설계 확정 (2025-10-17)
- **질문**: 이미 구현되었는가? 구현 완료 시 핵심 패턴만 `design-system.md`에 통합 후 삭제 권장
- **유지 조건**: 아직 구현 전이고 참조가 필요한 경우

#### 2. `place-time-management-redesign.md`
- **상태**: 설계 검토 중 (2025-10-19)
- **질문**: 재설계 제안이 최종 승인되었는가?
- **삭제 조건**: 승인 시 `calendar-place-management.md`에 반영 후 삭제
- **유지 조건**: 아직 논의 중이고 RFC 문서로 활용 중인 경우

#### 3. `state-persistence-pattern-analysis.md`
- **상태**: 분석 완료 (2025-10-12)
- **질문**: 분석 결과가 이미 다른 가이드에 반영되었는가?
- **삭제 조건**: 핵심 패턴이 `frontend-guide.md`에 통합되어 있으면 삭제
- **유지 조건**: 아직 반영 전이거나 독립 참조 가치가 있는 경우

---

## 📊 삭제 후보 요약표

| 파일명 | 줄 수 | 상태 | 삭제 이유 | 우선순위 |
|--------|------|------|-----------|---------|
| `recruitment-filter-validation.md` | ~200 | DEPRECATED | 제거된 필드 관련, 현재 무관 | **P0 (즉시)** |
| `recruitment-status-issue.md` | ~200 | DEPRECATED | 제거된 필드 관련, 현재 무관 | **P0 (즉시)** |
| `demo-calendar-place-integration.md` | 1,629 | Phase 1 완료 | 구현 노트, 100줄 위반, 개념 문서로 대체됨 | P1 (높음) |
| `group-event-place-frontend-plan.md` | 1,666 | Phase 2 진행중 | 작업 로그, 100줄 위반, 완료 후 통합 필요 | P2 (중간) |
| `group-event-place-integration.md` | 1,192 | 완료 | 백엔드 구현 노트, 코드가 정답 | P1 (높음) |
| `calendar-place-integration.md` | 945 | Phase 1 완료 | 초기 스크래치, demo- 문서로 대체됨 | P1 (높음) |
| `place-time-management-redesign.md` | 1,182 | 검토중 | RFC 제안서, 결정 후 반영 예정 | P2 (중간) |
| `personal-calendar-phase3-plus.md` | 96 | 완료 | Phase 1~5 작업 기록, MVP 문서로 통합됨 | P1 (높음) |
| `group-calendar-official-events-roadmap.md` | 895 | 설계 확정 | 공식 일정 로드맵, 개발 계획 문서로 통합 가능 | P2 (중간) |
| `place-calendar-phase2-frontend-basic.md` | 727 | 구현 대기 | Phase 2 작업 계획, 구현 후 삭제 | P3 (낮음) |
| `place-calendar-phase3-usage-permission.md` | 883 | 구현 대기 | Phase 3 작업 계획, 구현 후 삭제 | P3 (낮음) |
| `state-persistence-pattern-analysis.md` | 800 | 분석 완료 | 패턴 분석 노트, 가이드 반영 후 삭제 | P2 (중간) |
| `weekly-calendar-component-design.md` | ~800 | 설계 확정 | UI 설계 논의 아카이브, 구현 후 통합 권장 | 검토 필요 |

**총 삭제 후보**: 13개 (DEPRECATED 2개 + 구현 노트 9개 + 분석 문서 2개)

---

## 🎯 권장 조치 사항

### 즉시 삭제 권장 (P0)
1. `recruitment-filter-validation.md` - DEPRECATED, 혼란 방지
2. `recruitment-status-issue.md` - DEPRECATED, 혼란 방지

### 우선 삭제 권장 (P1) - 구현 완료 확인 후
3. `demo-calendar-place-integration.md` - 핵심 내용은 개념 문서에 이미 반영됨
4. `group-event-place-integration.md` - 백엔드 완료, 코드가 정답
5. `calendar-place-integration.md` - 초기 스크래치, 대체 문서 있음
6. `personal-calendar-phase3-plus.md` - MVP 문서로 통합됨

### 조건부 삭제 권장 (P2) - 구현/논의 완료 후
7. `group-event-place-frontend-plan.md` - Phase 2 완료 후 핵심만 가이드로 통합
8. `place-time-management-redesign.md` - 재설계 결정 확정 후 개념 문서에 반영
9. `group-calendar-official-events-roadmap.md` - 구현 완료 후 개발 계획 문서에 통합
10. `state-persistence-pattern-analysis.md` - 프론트엔드 가이드에 패턴 반영 후 삭제

### 보류 (P3) - 향후 구현 완료 시
11. `place-calendar-phase2-frontend-basic.md` - Phase 2 구현 참조 후 삭제
12. `place-calendar-phase3-usage-permission.md` - Phase 3 구현 참조 후 삭제

### 추가 검토 필요
13. `weekly-calendar-component-design.md` - 구현 완료 여부 확인 필요

---

## 📈 문서 정리 효과

### 현재 상태
- **총 문서**: 66개
- **100줄 위반**: 최소 5개 (1,000줄 이상)
- **중복/임시 문서**: 13개

### 정리 후 예상
- **총 문서**: 53개 (-13개, -20%)
- **100줄 위반**: 0개
- **문서 품질**: 정리된 참조 문서만 유지
- **네비게이션**: CLAUDE.md 링크 정확도 향상

### 이점
1. **컨텍스트 효율성**: AI 에이전트가 핵심 문서만 참조
2. **유지보수성**: 중복 제거로 업데이트 부담 감소
3. **신규 개발자 온보딩**: 명확한 문서 구조
4. **100줄 원칙 준수**: 문서 표준 강화

---

## 🔍 다음 단계

1. **즉시 조치**: DEPRECATED 문서 2개 삭제
2. **1차 정리**: 완료된 구현 노트 6개 검토 후 삭제
3. **2차 정리**: 진행 중 프로젝트 완료 시 Phase 문서 삭제
4. **문서 통합**: 삭제 전 핵심 내용을 유지할 문서에 반영
5. **CLAUDE.md 업데이트**: 삭제된 문서 링크 제거 및 구조 정리

---

**검토자**: Context Manager (AI Agent)
**최종 승인**: 사용자 확인 필요
