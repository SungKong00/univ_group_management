# 개발 워크플로우 (Development Flow)

## 1. 기본 원칙
- **컨텍스트 우선**: 개발 시작 전, `CLAUDE.md`의 '컨텍스트 가이드'를 통해 작업에 필요한 문서를 먼저 확인합니다.
- **작은 단위 진행**: 큰 기능은 여러 개의 작은 PR로 나누어 점진적으로 개발하고 리뷰 받습니다.
- **문서 동기화**: 코드 변경이 발생하면, 관련된 모든 컨텍스트 문서를 함께 수정하는 것을 원칙으로 합니다.

---

## 2. 개발 프로세스 5단계

### Step 1: 계획 (Plan)
- **요구사항 분석**: `CLAUDE.md`의 '작업 유형별 추천 가이드'를 참고하여, 본인의 작업과 관련된 개념/구현/정책 문서를 숙지합니다.
- **작업 계획 수립**: 구현할 기능의 범위와 순서를 정하고, 예상되는 기술적 제약을 파악합니다.
- **브랜치 생성**: `main` 브랜치에서 `feature/기능명` 또는 `fix/이슈명` 형태의 작업 브랜치를 생성합니다.

### Step 2: 구현 (Implement)
- **기술 가이드 준수**:
    - **백엔드**: [백엔드 구현 가이드](../implementation/backend-guide.md)에 명시된 아키텍처와 패턴을 따릅니다.
    - **프론트엔드**: [프론트엔드 구현 가이드](../implementation/frontend-guide.md)에 명시된 아키텍처와 UI 패턴을 따릅니다.
- **커밋**: [커밋 컨벤션](../conventions/commit-conventions.md)에 따라 작업 단위를 명확히 하여 자주 커밋합니다.

### Step 3: 테스트 (Test)
- **테스트 전략 준수**: [테스트 전략](./testing-strategy.md)에 따라, 특히 통합 테스트 중심으로 테스트 코드를 작성합니다.
- **로컬 검증**: 모든 테스트가 로컬 환경에서 통과하는지 확인합니다.

### Step 4: 문서화 (Document)
- **문서 동기화**: 코드 변경으로 인해 내용이 달라진 모든 문서를 수정합니다.
- **작성 규칙 준수**: 문서 수정 시에는 [마크다운 관리 규칙](../../markdown-guidelines.md)을 따릅니다.
- **추적 시스템 업데이트**: `context-update-log.md`와 `sync-status.md`를 최신 상태로 업데이트합니다.

### Step 5: 리뷰 및 병합 (Review & Merge)
- **PR 생성**: [PR 가이드라인](../conventions/pr-guidelines.md)에 따라 Pull Request를 작성합니다.
- **코드 리뷰**: [코드 리뷰 기준](../conventions/code-review-standards.md)에 따라 동료의 리뷰를 받고, 피드백을 반영합니다.
- **병합**: 모든 CI 검사를 통과하고 최소 1명 이상의 승인을 받으면, `Squash and Merge`를 통해 `main` 브랜치에 병합합니다.

---

## 3. 관련 문서
- **최상위 가이드**: [CLAUDE.md](../../CLAUDE.md)
- **테스트 전략**: [testing-strategy.md](./testing-strategy.md)
- **각종 컨벤션**: [../conventions/](../conventions/)
