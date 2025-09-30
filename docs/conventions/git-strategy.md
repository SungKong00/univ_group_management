# Git 전략 가이드 (Git Strategy Guide)

## GitHub Flow 채택

우리 프로젝트는 **GitHub Flow**를 기본 Git 전략으로 사용합니다. 이는 단순하고 효과적인 브랜치 전략으로, 지속적인 배포와 협업에 최적화되어 있습니다.

## 브랜치 전략

### 메인 브랜치
- **`main`**: 항상 배포 가능한 상태를 유지하는 기본 브랜치
  - 모든 코드는 테스트를 통과한 상태여야 함
  - 직접 푸시 금지, 반드시 Pull Request를 통해서만 병합

### 작업 브랜치
- **기능 브랜치**: `feature/기능명` 형태로 생성
- **버그 수정**: `fix/버그명` 형태로 생성
- **문서 작업**: `docs/문서명` 형태로 생성
- **리팩토링**: `refactor/범위명` 형태로 생성

## 브랜치 네이밍 컨벤션

### 기본 패턴
```
{타입}/{설명}
```

### 타입별 규칙

#### 기능 개발 (feature)
```bash
feature/user-authentication
feature/group-management
feature/workspace-ui
```

#### 버그 수정 (fix)
```bash
fix/login-validation
fix/permission-check
fix/ui-responsive
```

#### 문서 작업 (docs)
```bash
docs/api-reference
docs/user-guide
docs/architecture-guide
```

#### 리팩토링 (refactor)
```bash
refactor/backend-structure
refactor/frontend-components
refactor/database-schema
```

#### 핫픽스 (hotfix)
```bash
hotfix/critical-security-patch
hotfix/production-bug
```

### 설명 작성 규칙
- **케밥 케이스** 사용 (하이픈으로 단어 구분)
- **영문 소문자** 사용
- **간결하고 명확한** 설명
- **최대 50자** 제한

## GitHub Flow 워크플로우

### 1. 브랜치 생성
```bash
# main에서 최신 상태로 업데이트
git checkout main
git pull origin main

# 새 작업 브랜치 생성
git checkout -b feature/new-feature
```

### 2. 개발 및 커밋
```bash
# 변경사항 확인
git status
git diff

# 스테이징 및 커밋
git add .
git commit -m "feat: 새로운 기능 구현"

# 정기적으로 푸시
git push origin feature/new-feature
```

### 3. Pull Request 생성
- GitHub에서 Pull Request 생성
- 명확한 제목과 설명 작성
- 관련 이슈 연결
- 리뷰어 지정

### 4. 코드 리뷰
- 최소 1명 이상의 승인 필요
- CI/CD 검사 통과 필수
- 컨플릭트 해결 완료

### 5. 병합 및 정리
```bash
# GitHub에서 Squash and Merge 사용
# 병합 후 로컬 브랜치 정리
git checkout main
git pull origin main
git branch -d feature/new-feature
```

## 커밋 정책

### 빈도
- **자주, 작은 단위로** 커밋
- 논리적으로 완결된 단위로 커밋
- 하나의 커밋은 하나의 관심사만 다룸

### 품질
- 빌드가 깨지지 않는 상태로 커밋
- 테스트가 통과하는 상태로 커밋
- 린터/포맷터 규칙 준수

### 메시지
- [Conventional Commits](commit-conventions.md) 규칙 준수
- 명확하고 간결한 설명
- 영문 사용 권장

## Pull Request 가이드라인

### 크기
- **작고 집중된** PR 권장
- 최대 400줄 변경사항 권장
- 큰 변경사항은 여러 PR로 분할

### 설명
- **무엇을**, **왜** 변경했는지 명시
- 스크린샷 첨부 (UI 변경 시)
- 테스트 방법 안내

### 체크리스트
- [ ] 빌드 성공
- [ ] 테스트 통과
- [ ] 문서 업데이트 완료
- [ ] 컨텍스트 파일 동기화 확인

## 태그 및 릴리즈

### 버전 태그
```bash
# Semantic Versioning 사용
v1.0.0, v1.1.0, v1.1.1
```

### 릴리즈 브랜치 (필요시)
```bash
release/v1.0.0
```

## 협업 규칙

### main 브랜치 보호
- 직접 푸시 금지
- PR 리뷰 필수
- CI 통과 필수
- 최신 상태로 업데이트 필수

### 충돌 해결
- 작업자가 직접 해결
- `git rebase`를 통한 히스토리 정리 권장
- 복잡한 충돌은 팀원과 상의

### 커뮤니케이션
- PR에서 충분한 설명과 토론
- 이슈를 통한 작업 계획 공유
- 팀 회의에서 주요 변경사항 논의

## 도구 및 자동화

### Git Hooks
- pre-commit: 린팅, 포맷팅 검사
- commit-msg: 커밋 메시지 검증
- pre-push: 테스트 실행

### CI/CD
- GitHub Actions를 통한 자동 검증
- 테스트, 빌드, 배포 자동화
- 코드 품질 검사

## 관련 문서

- **커밋 컨벤션**: [commit-conventions.md](commit-conventions.md)
- **PR 가이드라인**: [pr-guidelines.md](pr-guidelines.md)
- **코드 리뷰 기준**: [code-review-standards.md](code-review-standards.md)
- **개발 워크플로우**: [../workflows/development-flow.md](../workflows/development-flow.md)