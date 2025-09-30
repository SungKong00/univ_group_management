# 커밋 메시지 컨벤션 (Commit Message Conventions)

## Conventional Commits 기반

우리 프로젝트는 [Conventional Commits](https://www.conventionalcommits.org/) 표준을 기반으로 한 커밋 메시지 컨벤션을 사용합니다.

## 기본 형식

```
<타입>[선택적 범위]: <설명>

[선택적 본문]

[선택적 푸터]
```

## 커밋 타입

### 주요 타입

#### `feat`: 새로운 기능
```bash
feat: 사용자 로그인 기능 추가
feat(auth): Google OAuth 연동 구현
feat: 그룹 생성 API 엔드포인트 추가
```

#### `fix`: 버그 수정
```bash
fix: 로그인 시 validation 오류 수정
fix(ui): 모바일에서 버튼 클릭 안 되는 문제 해결
fix: 권한 체크 로직 오류 수정
```

#### `docs`: 문서 변경
```bash
docs: README 파일 업데이트
docs(api): API 레퍼런스 문서 추가
docs: 설치 가이드 개선
```

#### `style`: 코드 스타일 변경
```bash
style: 코드 포맷팅 적용
style(frontend): ESLint 규칙 적용
style: 불필요한 공백 제거
```

#### `refactor`: 리팩토링
```bash
refactor: 사용자 서비스 클래스 구조 개선
refactor(backend): 컨트롤러 레이어 정리
refactor: 중복 코드 제거
```

#### `test`: 테스트 관련
```bash
test: 로그인 기능 단위 테스트 추가
test(integration): 그룹 관리 통합 테스트 작성
test: 테스트 케이스 누락 보완
```

#### `chore`: 기타 변경사항
```bash
chore: 의존성 버전 업데이트
chore(config): 빌드 설정 수정
chore: .gitignore 파일 업데이트
```

### 추가 타입

#### `perf`: 성능 개선
```bash
perf: 데이터베이스 쿼리 최적화
perf(frontend): 이미지 로딩 성능 개선
```

#### `ci`: CI/CD 관련
```bash
ci: GitHub Actions 워크플로우 추가
ci: 배포 스크립트 수정
```

#### `build`: 빌드 시스템 변경
```bash
build: Gradle 설정 업데이트
build(docker): Dockerfile 개선
```

#### `revert`: 커밋 되돌리기
```bash
revert: "feat: 실험적 기능 추가"
```

## 범위 (Scope)

### 백엔드 범위
```bash
feat(auth): 인증 관련 기능
feat(group): 그룹 관리 기능
feat(permission): 권한 시스템
feat(api): API 엔드포인트
feat(db): 데이터베이스 관련
```

### 프론트엔드 범위
```bash
feat(ui): UI 컴포넌트
feat(page): 페이지 구현
feat(state): 상태 관리
feat(service): 서비스 레이어
feat(router): 라우팅 관련
```

### 공통 범위
```bash
feat(config): 설정 관련
feat(docs): 문서 관련
feat(test): 테스트 관련
feat(deploy): 배포 관련
```

## 설명 작성 규칙

### 기본 원칙
- **명령형, 현재 시제** 사용
- **첫 글자 소문자**
- **마침표 없음**
- **50자 이내** 권장

### 좋은 예시
```bash
feat: 사용자 프로필 편집 기능 추가
fix: 로그인 시 세션 만료 문제 해결
docs: API 문서에 인증 방법 추가
refactor: 중복된 권한 체크 로직 통합
```

### 나쁜 예시
```bash
feat: Added user profile editing feature.  # 과거형, 마침표
Fix: Login session issue                   # 첫 글자 대문자
docs: updated docs                         # 과거형, 너무 모호함
refactor: code cleanup                     # 너무 모호함
```

## 본문 (Body)

### 작성 시기
- 변경 이유가 복잡한 경우
- 해결 방법이 특별한 경우
- 부작용이나 주의사항이 있는 경우

### 작성 규칙
- 설명 줄과 **한 줄 공백**으로 구분
- **72자마다 줄바꿈**
- **왜** 변경했는지에 집중
- **어떻게** 구현했는지 설명

### 예시
```bash
feat(auth): JWT 토큰 갱신 기능 추가

기존 토큰이 만료되기 전에 자동으로 갱신하는 기능을 구현했습니다.
이를 통해 사용자가 로그인 상태를 유지할 수 있으며,
보안성도 향상됩니다.

- 토큰 만료 5분 전 자동 갱신 시도
- 갱신 실패 시 로그아웃 처리
- 백그라운드에서 조용히 처리
```

## 푸터 (Footer)

### Breaking Changes
```bash
feat(api): 사용자 API 응답 형식 변경

BREAKING CHANGE: 사용자 정보 API의 응답 형식이 변경되었습니다.
기존 'name' 필드가 'fullName'으로 변경되었습니다.
```

### 이슈 연결
```bash
fix(auth): 로그인 validation 오류 수정

Closes #123
Fixes #456
Resolves #789
```

### 공동 작업자
```bash
feat: 새로운 UI 컴포넌트 추가

Co-authored-by: 김개발 <kim@example.com>
Co-authored-by: 이디자인 <lee@example.com>
```

## 특별한 상황

### 머지 커밋
```bash
Merge pull request #123 from feature/user-auth

feat(auth): 사용자 인증 시스템 구현
```

### 초기 커밋
```bash
chore: 프로젝트 초기 설정

- Spring Boot 프로젝트 생성
- 기본 의존성 설정
- 디렉토리 구조 생성
```

### 설정 파일 변경
```bash
chore(config): 데이터베이스 설정 업데이트

개발 환경에서 H2 데이터베이스 사용하도록 설정 변경
```

## 자동화 도구

### 커밋 메시지 검증
```bash
# Git hook으로 커밋 메시지 형식 검증
npm install --save-dev @commitlint/cli @commitlint/config-conventional
```

### 자동 생성 도구
```bash
# Commitizen 사용
npm install -g commitizen cz-conventional-changelog
git cz  # 대화형 커밋 메시지 생성
```

## 프로젝트별 예시

### 백엔드 개발
```bash
feat(group): 그룹 멤버 초대 API 구현
fix(permission): 그룹 관리자 권한 체크 오류 수정
refactor(service): 그룹 서비스 레이어 정리
test(group): 그룹 생성 통합 테스트 추가
```

### 프론트엔드 개발
```bash
feat(ui): 워크스페이스 레이아웃 컴포넌트 추가
fix(page): 모바일에서 네비게이션 메뉴 안 보이는 문제 해결
style(component): 버튼 컴포넌트 스타일 통일
refactor(state): 사용자 상태 관리 로직 개선
```

### 문서 작업
```bash
docs(api): 그룹 관리 API 문서 추가
docs(guide): 설치 및 실행 가이드 업데이트
docs(concept): 권한 시스템 개념 설명 추가
```

## 점검 체크리스트

커밋 전 다음 사항을 확인하세요:

- [ ] 커밋 타입이 적절한가?
- [ ] 범위가 명확한가?
- [ ] 설명이 명령형 현재시제인가?
- [ ] 설명이 50자 이내인가?
- [ ] 복잡한 변경사항에 본문을 작성했는가?
- [ ] 관련 이슈를 연결했는가?
- [ ] Breaking Change가 있다면 명시했는가?

## 관련 문서

- **Git 전략**: [git-strategy.md](git-strategy.md)
- **PR 가이드라인**: [pr-guidelines.md](pr-guidelines.md)
- **개발 워크플로우**: [../workflows/development-flow.md](../workflows/development-flow.md)