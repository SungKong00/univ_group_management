# 대기 중인 업데이트 목록 (Pending Updates)

이 파일은 코드 변경으로 인해 업데이트가 필요한 문서들을 추적하고 우선순위를 관리합니다.

## 🚨 우선순위 높음 (High Priority)

### 모집 시스템 문서 & API 문서 동기화
**상태**: 완료 (2025-10-01 rev5)
**적용 내용**: recruitment-system.md 구현 상태 표/권한/에러/DTO/API 매핑 반영, api-reference.md 상세 예시/에러 코드 확장.
**후속**: 통계 구현 시 stats 응답 확정 필요 (보류)

### 채널 권한 설정 UI/UX 문서화
**상태**: 완료 (rev5 하이브리드 정책 반영)
**적용 문서**: channel-pages.md, channel-permissions.md, permission-system.md, troubleshooting/permission-errors.md
**후속**: UI 컴포넌트 설계 세부 인터랙션(드래그 정렬, 배치 저장) 추가 (선택)

### CLAUDE.md 후속 점검
**상태**: 완료 (rev5 요약 반영)
**후속**: 권한 UI 실제 구현 후 스크린샷/워크플로 넣기 (예정)

---

## ⚠️ 우선순위 중간 (Medium Priority)

### 개발 워크플로우 문서 Git 전략 연동 검증
**상태**: 완료 (링크 삽입) / 재검토 예정
**추가 고려**: 문서 자동 검증 파이프라인 섹션 (추후)

### UI/UX 전체 정합성 1차 패스
**상태**: 보류
**파일:** `docs/ui-ux/concepts/`, `docs/ui-ux/pages/`
**목표:** 용어(채널/워크스페이스/역할) 일관성, 중복 제거

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
- (완료) 권한 시스템 문서 검토 / 채널 자동 바인딩 제거 반영 (`2025-10-01` rev1~3)
- (완료) Database Reference: ChannelRoleBinding 스키마/JPA 추가
- (완료) Troubleshooting: 기본 바인딩 가정 제거
- (완료) Hybrid Policy 문서화 (rev5 기본 2채널 템플릿 + 사용자 정의 0바인딩)
- (완료) Recruitment 문서/API 상세 확장
- (완료) Development Flow 상호 링크 삽입

---

## 🔄 진행 중인 작업 (In Progress)
- 컨텍스트 추적 자동화 스크립트 (서브 에이전트) - 초기 버전
- 통계(Recruitment Stats) 설계 대기

---

## 📊 통계 및 메트릭 (갱신 2025-10-01 rev5)
- **총 대기 항목**: 5개 (High 0 / Medium 1 / Low 4)
- **이번 라운드 완료**: 6개
- **예상 잔여 작업 시간**: 6~9시간 (선택 포함)

---

## 🎯 다음 액션 아이템
### 오늘
1. 통계(stats) 설계 초안 여부 결정
2. 채널 권한 UI 접근성 세부 요구 정의 (초안)

### 이번 주
1. UI/UX 정합성 1차 패스
2. 관리자 대시보드 요구사항 초안 작성

### 이번 달
1. Recruitment stats 구현 & 문서화
2. 권한 캐시 UX 개선안 문서화

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