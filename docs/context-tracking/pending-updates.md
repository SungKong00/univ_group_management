# 대기 중인 업데이트 목록 (Pending Updates)

이 파일은 코드 변경으로 인해 업데이트가 필요한 문서들을 추적하고 우선순위를 관리합니다.

## 🚨 우선순위 높음 (High Priority)

### 모집 시스템 문서 & API 문서 동기화
**상태**: 미완료
**변경 이유**: 모집 API 구현됨 (`0245646`) / 문서 세부 스펙 미반영
**예상 작업 시간**: 1~2시간
**업데이트 필요 파일:**
- `docs/implementation/api-reference.md` (모집 엔드포인트 상세: 경로, DTO, 권한 요구조건)
- `docs/concepts/recruitment-system.md` (현재 구현 범위 / 향후 계획 구분)

### 채널 권한 설정 UI/UX 문서화
**상태**: 신규
**변경 이유**: Permission-Centric 채널 권한 모델 적용 → UI 흐름 필요
**예상 작업 시간**: 1시간
**업데이트 필요 파일:**
- `docs/ui-ux/pages/` 내 채널 생성 & 설정 흐름 신규 페이지 (예: `channel-create.md`, `channel-permission-matrix.md`)
- 매트릭스 편집 패턴 / 저장 트랜잭션 / 에러(불완전 설정) 처리 UX

### CLAUDE.md 후속 점검
**상태**: 일부 완료 (개정 요약 추가됨)
**추가 필요**: 채널 권한 설정 UI 완료 후 레퍼런스 링크 추가 예정

---

## ⚠️ 우선순위 중간 (Medium Priority)

### 개발 워크플로우 문서 Git 전략 연동 검증
**상태**: 진행 필요
**파일:** `docs/workflows/development-flow.md`
**내용:** Git Flow 섹션에 PR 가이드/코드 리뷰 표준 상호 링크 추가

### UI/UX 전체 정합성 1차 패스
**상태**: 보류
**파일:** `docs/ui-ux/concepts/`, `docs/ui-ux/pages/`
**목표:** 용어(채널/워크스페이스/역할) 일관성, 중복 제거

---

## 📋 우선순위 낮음 (Low Priority)

### Permission 캐시 무효화 UX 힌트 추가
**파일:** `docs/ui-ux/pages/* (설정 관련)` (채널 권한 저장 후 토스트/재로딩 전략)

### 관리자 대시보드 개념 초안
**파일:** 신규 작성 예정 `docs/concepts/admin-dashboard.md`

---

## ✅ 완료/제거된 항목 (History)
- (완료) 권한 시스템 문서 검토 / 채널 자동 바인딩 제거 반영 (`2025-10-01` rev1~3)
- (완료) Database Reference: ChannelRoleBinding 스키마/JPA 추가
- (완료) Troubleshooting: 기본 바인딩 가정 제거

---

## 🔄 진행 중인 작업 (In Progress)
- 컨텍스트 추적 자동화 스크립트 (서브 에이전트) - 초기 버전

---

## 📊 통계 및 메트릭 (갱신 2025-10-01)
- **총 대기 항목**: 6개 (High 3 / Medium 2 / Low 1)
- **완료 처리(이번 개정)**: 3개
- **예상 총 작업 시간 잔여**: 5~8시간

---

## 🎯 다음 액션 아이템
### 오늘
1. 모집 API 스펙 섹션 초안 작성(api-reference)
2. 채널 권한 설정 UI 페이지 구조 초안 생성

### 이번 주
1. recruitment-system 개념 문서 최신화
2. development-flow Git 전략 상호 링크 보강

### 이번 달
1. UI/UX 전체 정합성 패스
2. 관리자 대시보드 개념 초안

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