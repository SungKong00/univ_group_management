# 대기 중인 업데이트 목록 (Pending Updates)

이 파일은 코드 변경으로 인해 업데이트가 필요한 문서들을 추적하고 우선순위를 관리합니다.

## 🚨 우선순위 높음 (High Priority)

### 그룹 캘린더 Phase 8 구현 (권한 통합)
**상태**: ⏳ 대기 중
**적용 범위**: 프론트엔드 (group_calendar_page.dart)
**작업 내용**:
- `_canModifyEvent()` 함수 권한 API 연동
- 공식 일정 수정/삭제 시 CALENDAR_MANAGE 체크
- 통합 테스트 작성 (3개 시나리오)
**예상 시간**: 2-3시간
**우선순위**: P0 (즉시 진행 가능)
**의존성**: Phase 5 권한 API 완료 (✅)
**후속**: 장소 캘린더 Phase 2 진행

---

### 캘린더 시스템 설계 결정사항 문서화
**상태**: ✅ 완료 (2025-10-06)
**적용 문서**:
- calendar-system.md: 설계 결정사항 섹션 추가
- calendar-design-decisions.md: 신규 문서 생성 (7가지 DD)
- permission-system.md: RBAC 통합 확정
- calendar-place-management.md: 장소 권한 통합 방식 명시
- database-reference.md: 캘린더 테이블 섹션 추가
- backend-guide.md: 캘린더 구현 가이드 추가
- api-reference.md: 캘린더 API 계획 추가
**후속**: Phase 6 진입 시 엔티티 클래스 및 API 구현

### 게시글/댓글 시스템 문서 동기화
**상태**: ✅ 완료 (2025-10-05)
**적용 문서**:
- frontend-implementation-status.md: 구현 현황 추가
- api-reference.md: Post/Comment API 상세 추가
- workspace-pages.md: UI 컴포넌트 정보 추가
**후속**: 파일 업로드 기능 구현 시 문서 업데이트 필요

### 채널 권한 검증 시스템 문서화
**상태**: ✅ 완료 (2025-10-04)
**적용 문서**:
- permission-system.md: Spring Security 통합 가이드
- backend-guide.md: Security Layer 설계 결정
**후속**: 없음

---

## ⚠️ 우선순위 중간 (Medium Priority)

### 장소 캘린더 Phase 2 구현 (프론트엔드 기본)
**상태**: ⏳ 대기 중
**적용 범위**: 프론트엔드 (place_list_page.dart, place_form_dialog.dart, place_availability_settings.dart)
**작업 내용**:
- 장소 목록 조회 UI (건물별 트리 구조, 검색/필터)
- 장소 등록 폼 (건물명, 방 번호, 별칭, 수용 인원)
- 운영 시간 설정 UI (요일별 시간대)
- PlaceService 및 PlaceProvider 구현
**예상 시간**: 6-8시간
**우선순위**: P0 (필수)
**의존성**: 장소 캘린더 Phase 1 완료 (✅)
**후속**: 장소 캘린더 Phase 3 (사용 그룹 관리)

### CLAUDE.md 업데이트 (통합 로드맵 링크)
**상태**: ⏳ 대기 중
**적용 범위**: CLAUDE.md 네비게이션
**작업 내용**:
- "기능별 개발 계획" 섹션에 통합 로드맵 추가
- Phase 6 edit-delete 문서 링크 추가
- Phase 9 UI improvement 링크 업데이트
**예상 시간**: 10분
**우선순위**: P1 (권장)

---

## 📋 우선순위 낮음 (Low Priority)

### Permission 캐시 무효화 UX 힌트 추가
**파일:** `docs/ui-ux/pages/*` (권한 저장 후 피드백/리프레시 전략) – 보류

### 관리자 대시보드 개념 초안
**파일:** 신규 예정 `docs/concepts/admin-dashboard.md` – 보류

### 채널 권한 매트릭스 접근성 확장
**내용:** 키보드 내비/스크린리더 라벨 구체 예시 – 보류

---

## ✅ 완료/제거된 항목 (History)
- (완료 2025-10-13) **캘린더 시스템 통합 로드맵 문서화**: calendar-integration-roadmap.md 신규 생성
- (완료 2025-10-13) **Phase 번호 충돌 해결**: group-calendar-phase6-ui-improvement.md → phase9로 변경
- (완료 2025-10-13) **장소 캘린더 Phase 1 완료 반영**: place-calendar-specification.md 업데이트
- (완료 2025-10-13) **그룹 캘린더 Phase 6 문서화**: group-calendar-phase6-edit-delete.md 신규 생성
- (완료 2025-10-09) UI/UX 전체 정합성 1차 패스 완료. color-guide와 design-system의 색상/Breakpoint 정의를 일원화하여 중복 및 불일치 해결.
- (완료 2025-10-09) 개발 워크플로우 문서와 Git 전략 연동 검증 완료. 두 문서 간 내용 일관성 확인.
- (완료 2025-10-06) 워크스페이스 모바일 반응형 및 브레드크럼 구현 (frontend-guide.md, responsive-design-guide.md, workspace-pages.md 등)
- (완료 2025-10-06) 캘린더 시스템 설계 결정사항 문서화 (7개 문서 업데이트, 1개 신규 생성)
- (완료 2025-10-06) 모집/워크스페이스 구현 동기화 (recruitment-system.md, frontend-implementation-status.md, workspace-pages.md)
- (완료 2025-10-06) 컨트롤러 통합 테스트 패턴 문서화
- (완료 2025-10-05) 게시글/댓글 시스템 문서 동기화
- (완료 2025-10-04) 채널 권한 검증 시스템 문서화
- (완료 2025-10-01) 권한 시스템 문서 검토 / 채널 자동 바인딩 제거 반영 (rev1~3)
- (완료 2025-10-01) Database Reference: ChannelRoleBinding 스키마/JPA 추가
- (완료 2025-10-01) Troubleshooting: 기본 바인딩 가정 제거
- (완료 2025-10-01) Hybrid Policy 문서화 (rev5 기본 2채널 템플릿 + 사용자 정의 0바인딩)
- (완료 2025-10-01) Recruitment 문서/API 상세 확장
- (완료 2024-09-29) Development Flow 상호 링크 삽입

---

## 🔄 진행 중인 작업 (In Progress)
- 컨텍스트 추적 자동화 스크립트 (서브 에이전트) - 초기 버전
- 통계(Recruitment Stats) 설계 대기

---

## 📊 통계 및 메트릭 (갱신 2025-10-13)
- **총 대기 항목**: 5개 (High 1 / Medium 2 / Low 2)
- **이번 라운드 완료**: 4개 (통합 로드맵 문서화, Phase 번호 정리, 장소 Phase 1 반영, Phase 6 문서화)
- **신규 추가**: 2개 (Phase 8 구현, Phase 2 구현)
- **예상 잔여 작업 시간**: 8~11시간 (필수) + 선택 작업

---

## 🎯 다음 액션 아이템
### 즉시 (Next 1-2 days)
1. **그룹 캘린더 Phase 8 구현** (권한 통합) - 2-3시간
2. **CLAUDE.md 업데이트** (통합 로드맵 링크 추가) - 10분

### 이번 주 (This Week)
1. **장소 캘린더 Phase 2 구현** (프론트엔드 기본) - 6-8시간
2. 통계(stats) 설계 초안 여부 결정 (보류)

### 다음 주 (Next Week)
1. **장소 캘린더 Phase 3 구현** (사용 그룹 관리) - 4-6시간
2. 채널 권한 UI 접근성 세부 요구 정의 (선택)

### 이번 달 (This Month)
1. **장소 캘린더 Phase 4-5 완료** (예약 시스템 + 차단 시간) - 11-14시간
2. **그룹 캘린더 Phase 9 검토** (UI 개선 진행 여부 결정)
3. Recruitment stats 구현 & 문서화 (선택)

---

## 📝 업데이트 완료 시 체크리스트
- [ ] 관련 문서 내용 업데이트 완료
- [ ] 상호 참조 링크 확인 및 수정
- [ ] 다른 문서 영향 검토
- [ ] context-update-log.md 반영
- [ ] sync-status.md 갱신
- [ ] 이 파일에서 제거 또는 히스토리 이동

---

## 🔗 관련 문서
- [컨텍스트 업데이트 로그](context-update-log.md)
- [동기화 상태](sync-status.md)
- [Git 전략](../conventions/git-strategy.md)