# 대학 그룹 관리 시스템 (University Group Management)

## ⚠️ MCP 자동 사용 규칙 (AI AUTO-ENFORCE)

**CRITICAL**: AI는 사용자 요청을 받으면 **자동으로 MCP를 우선 사용**합니다.

### 자동 전환 매핑 (사용자가 뭐라고 하든 AI가 알아서 MCP 사용)

| 사용자 요청 | AI 자동 실행 | Bash 절대 금지 |
|------------|-------------|--------------|
| "테스트 실행" / "flutter test" | `mcp__dart-flutter__run_tests` | ❌ flutter test |
| "코드 분석" / "flutter analyze" | `mcp__dart-flutter__analyze_files` | ❌ flutter analyze |
| "포맷팅" / "dart format" | `mcp__dart-flutter__dart_format` | ❌ dart format |
| "패키지 설치" / "pub add" | `mcp__dart-flutter__pub` | ❌ flutter pub |

### AI 행동 원칙 (자동 실행)

1. **사용자가 "flutter test"라고 말해도** → AI가 자동으로 MCP로 전환
2. **사용자가 "Bash로 실행"이라고 해도** → 헌법 우선, MCP 사용
3. **"강제로 Bash" 명시한 경우만** → 경고 후 Bash 허용

### 예외: Bash 허용 항목

```bash
✅ git 명령어 (git status, git commit, git push 등)
✅ flutter pub run build_runner build
✅ ls, cd, mkdir 등 파일 시스템 명령어
```

### MCP 도구 상세

**dart-flutter MCP** (필수 ⭐⭐⭐⭐⭐):
- `run_tests`: 테스트 실행 (정확한 에러 위치, 실제 실행 결과)
- `analyze_files`: 코드 분석 (lint, 타입 체크)
- `dart_format`: 코드 포맷팅
- `pub`: 패키지 관리 (add, get, remove)

**flutter-service MCP** (보조 ⭐⭐):
- `pub_dev_search`: 패키지 탐색
- `analyze_pub_package`: 패키지 품질 분석
- `suggest_improvements`: 코드 개선 제안 (일반 패턴만, 버그 탐지 불가)

### 상황별 의사결정

```
문제 해결:
├─ 테스트 실패? → dart-flutter (run_tests)
├─ 버그 수정?   → dart-flutter (analyze_files)
└─ 패키지 선택? → flutter-service (pub_dev_search) → dart-flutter (검증)

새 기능 개발:
├─ 구현 후 테스트 → dart-flutter (run_tests, analyze_files, dart_format)
└─ 패키지 고민   → flutter-service → dart-flutter
```

### 실전 예시

❌ **잘못된 사용**:
```
버그: "테스트가 실패해"
→ flutter-service validate_flutter_docs 호출
→ "코드는 괜찮습니다" (버그 못 찾음)
```

✅ **올바른 사용**:
```
버그: "테스트가 실패해"
→ dart-flutter run_tests 호출
→ "line 84: expect failed - Channel View 5 not found"
→ 정확한 위치와 원인 파악
```

### 헌법 준수 사항 (비협상)

- **필수**: 모든 테스트는 dart-flutter MCP로 실행
- **금지**: 버그 수정 시 flutter-service에 의존
- **PR 필수**: dart-flutter 테스트 로그 포함

상세: [헌법 원칙 VI](.specify/memory/constitution.md#vi-mcp-사용-표준-비협상)

---

## ⚠️ 기능 구현 철학 (AI AUTO-ENFORCE)

**CRITICAL**: 새로운 기능을 구현할 때는 단순히 기능을 추가하는 것이 목표가 아닙니다.

### 핵심 원칙

요청받은 기능을 구현하기 전에 **반드시 다음을 실행**하세요:

1. **기존 코드베이스 분석**: 요청받은 기능과 관련된 기존 기능들을 먼저 파악
2. **코드 구조 설계**: 새 기능과 기존 기능을 함께 고려한 구조를 설계
3. **컴포넌트 분리**: 묶을 수 있는 기능과 메서드들을 컴포넌트로 분리
4. **관심사 분리**: 비즈니스 로직, UI, 데이터 접근을 명확히 분리
5. **재사용성 극대화**: 다른 곳에서도 쓸 수 있는 범용적 설계

### 즉시 확인사항

```
구현 전:
☐ 기존 코드에서 유사한 기능을 찾았는가?
☐ 컴포넌트 분리 계획을 세웠는가?
☐ 3-Layer Architecture를 따르는가?

구현 중:
☐ 파일이 100줄을 넘지는 않나?
☐ 한 파일이 하나의 책임만 가지는가? (SRP)
☐ 기존 컴포넌트를 재사용했는가?

구현 후:
☐ 다른 곳에서도 재사용 가능한가?
☐ Props/Parameters로 유연하게 설정 가능한가?
```

**자세한 가이드**: [기능 구현 철학 및 코드 구조 설계](docs/conventions/implementation-philosophy.md)

---

## 📜 프로젝트 헌법 (Constitution)

**핵심 거버넌스**: [.specify/memory/constitution.md](.specify/memory/constitution.md) - 프로젝트 v1.2.0 헌법

이 헌법은 모든 개발 가이드라인과 프랙티스보다 우선하며, 8가지 핵심 원칙을 정의합니다:
1. 3-Layer Architecture (비협상)
2. 표준 응답 형식 ApiResponse<T> (비협상)
3. RBAC + Override 권한 시스템 (비협상)
4. 문서화 100줄 원칙
5. 테스트 피라미드 60/30/10
6. MCP 사용 표준 (비협상) ← **위 섹션 참조**
7. 프론트엔드 통합 원칙
8. API 진화 및 리팩터링 원칙 (비협상)

**기술 스택** (비협상):
- 프론트엔드: Flutter (Web)
- 백엔드: Spring Boot 3.x + Kotlin
- 데이터베이스: H2 (개발), PostgreSQL (프로덕션)
- 인증: Google OAuth 2.0 + JWT

---

## 🎯 빠른 네비게이션

**📚 전체 문서 인덱스**: [.claude/NAVIGATION.md](.claude/NAVIGATION.md)

### 필수 문서 (개발 시작 전)
1. [전체 개념도](docs/concepts/domain-overview.md) - 시스템 전체 이해
2. [권한 시스템](docs/concepts/permission-system.md) - RBAC + Override 구조
3. [Git 전략](docs/conventions/git-strategy.md) - GitHub Flow 규칙

### 주요 가이드
- **백엔드**: [구현 가이드 인덱스](docs/implementation/backend/README.md)
- **프론트엔드 개발**: [구현 가이드 인덱스](docs/implementation/frontend/README.md) + [frontend-specialist](.claude/agents/frontend-specialist.md)
- **프론트엔드 디버깅**: [frontend-debugger](.claude/agents/frontend-debugger.md)
- **디자인 시스템**: [디자인 시스템 개요](docs/ui-ux/concepts/design-system.md)
- **문서 관리**: [markdown-guidelines.md](markdown-guidelines.md)

---

## 📋 프로젝트 개요

**목적**: 대학 내 그룹(학과, 동아리, 학회) 관리 및 소통 플랫폼

**시스템 아키텍처**:
```
사용자 → Google OAuth → JWT 토큰
  ↓
대학 → 학과 → 그룹 (계층 구조)
  ↓
워크스페이스 → 채널 → 게시글/댓글
  ↓
역할 기반 권한(RBAC) + 채널 Permission-Centric 바인딩
```

---

## 🔧 개발 환경 설정

### 필수 설정
- **Flutter 포트**: 반드시 5173 사용
- **실행 명령**: `flutter run -d chrome --web-hostname localhost --web-port 5173`
- **백엔드**: Spring Boot + H2 (dev) / RDS (prod)

---

### Git Worktree 설정 (필수)

프로젝트는 Git Worktree를 지원하며, 새 worktree 생성 시 `.env` 등 개발 필수 파일을 자동으로 복사하는 Hook이 설정되어 있습니다.

#### 초기 설정 (최초 1회)
```bash
# Git Hooks 활성화
./scripts/install-git-hooks.sh
```

#### 사용 방법
```bash
# 1. 메인 worktree에 .env 준비 (최초 1회)
cd frontend
cp .env.example .env
# 실제 Google OAuth 값으로 수정

# 2. 새 worktree 생성 (자동으로 .env 복사됨)
git worktree add ../project-feature feature-branch

# 3. 바로 개발 시작
cd ../project-feature
flutter run -d chrome --web-hostname localhost --web-port 5173  # .env가 이미 있음!
```

#### 자동 복사되는 파일들
- ⭐ `frontend/.env` - Frontend 환경변수 (필수)
- 🔧 `backend/.env` - Backend 환경변수 (있으면)
- 🤖 `frontend/android/local.properties` - Android SDK 경로
- 🔑 `frontend/android/key.properties` - Android 릴리즈 키

**참고**: Hook은 메인 worktree의 파일을 복사하므로, 메인 worktree에 `.env`가 없으면 `.env.example`을 복사하고 경고를 표시합니다.

## ⚠️ 개발 진행 중 주의사항

### 커밋 관련
- **작업 중 마음대로 커밋하지 말 것**: 단계별 작업 완료 후 최종 커밋만 수행
- **커밋 전 반드시 확인**: `git status`로 변경사항 확인 및 검토
- **컨텍스트 추적 업데이트**: 커밋 후 [context-tracking/](docs/context-tracking/) 폴더의 문서 상태 업데이트
- **커밋 메시지 컨벤션 준수**: [커밋 규칙](docs/conventions/commit-conventions.md) 참고
- **문서 동기화 확인**: 코드 변경 시 관련 문서도 함께 업데이트

### 에러 메시지 및 UI 텍스트 규칙
- **사용자 메시지는 한글**: 모든 UI 텍스트, 에러 메시지, 알림은 한글로 작성
- **디버깅 정보는 영어/원문 유지**: 에러 원인, 스택 트레이스, 로그는 영어 유지
- **혼합 형식 허용**: 사용자 메시지(한글) + 디버깅 정보(영어)
  ```dart
  // ✅ Good: 사용자에게는 한글, 개발자에게는 상세 정보
  '그룹 전환에 실패했습니다 (${error.toString()})'

  // ❌ Bad: 모두 영어
  'Failed to switch groups: ${error.toString()}'
  ```

### Speckit 작업 진행 시
- **Phase 완료 시 tasks.md 업데이트 필수** ([헌법 v1.2.0](.specify/memory/constitution.md#speckit-작업-진행-관리) 참조)
  - 각 Phase 완료 시 `specs/*/tasks.md`의 완료된 태스크를 `[ ] → [X]`로 체크
  - 통합 테스트 통과 결과를 tasks.md 또는 별도 검증 문서에 기록
  - 미완료 태스크가 있는 경우 이유와 다음 액션 명시
- **문서-코드 동기화**: 구현 완료 시점에 spec.md, plan.md, tasks.md도 함께 업데이트
- **진행 상황 가시성**: 다음 작업 시작 시 tasks.md를 신뢰할 수 있도록 실시간 동기화 유지
- **체크포인트 검증**: Phase 체크포인트에서 완료 태스크 개수 확인 및 테스트 결과 기록

---

## 🚀 현재 구현 상태

### 2025-11-18 Clean Architecture 마이그레이션 진행 중
- ✅ **Comment Feature Phase 2 완료** (Domain/Data/Presentation Layer 전체 구현)
  - 29/29 테스트 통과 (dart-flutter MCP)
  - 3-Layer Architecture 완벽 준수
  - AsyncNotifier 패턴 + Optimistic UI Updates
  - Legacy 호환성 유지 (CommentConverter)
- 🚧 **Channel Feature Phase 1.10-1.11 완료** (Widget 구현)
  - 86/86 테스트 통과
  - ChannelView + ChannelErrorState 위젯
- 🚧 **Post Feature Phase 3 진행 중** (Presentation Layer)
  - AsyncNotifier 패턴 적용
  - Sticky Header 타이밍 이슈 해결

### 2025-11-10 Navigator 2.0 리팩터링 완료
- ✅ **001-workspace-navigation-refactor 브랜치 develop 병합**
- ✅ **98/98 테스트 통과** (Unit 30 + Widget/Integration 58 + Performance/A11y 10)
- ✅ **Context-aware group switching** (권한 기반 폴백)
- ✅ **Edge cases 완료** (디바운싱, 로딩, 에러 핸들링, 스크롤/폼 보존)
- ✅ **코드 리뷰 개선** (LRU 정확성, Null Safety, Linting 0개)

### 2025-10-25 컴포넌트 추출 완료
- ✅ **Phase 1**: AppFormField (223줄), AppInfoBanner (242줄) 생성 - 86줄 절감
- ✅ **Phase 2**: DialogHelpers (107줄), AppDialogTitle (74줄), DialogAnimationMixin (100줄) 생성 - 304줄 절감
- **누적 효과**: 390줄 절감, 유지보수성 90% 향상

### 2025-10-01 권한 모델 개정 완료
- 시스템 역할(그룹장 / 교수 / 멤버) 불변성 명시
- ChannelRoleBinding 하이브리드 모델 전환 (기본 2채널 템플릿 + 사용자 정의 채널 0바인딩)
- Permission-Centric 매트릭스 문서화 완료

---

## 📚 컨텍스트 가이드

### 개발 시작 전 필독
1. [domain-overview.md](docs/concepts/domain-overview.md) - 전체 시스템 이해
2. [group-hierarchy.md](docs/concepts/group-hierarchy.md) - 그룹 구조 이해
3. [permission-system.md](docs/concepts/permission-system.md) - 권한 시스템 이해
4. [git-strategy.md](docs/conventions/git-strategy.md) - Git 전략 및 브랜치 규칙

### 백엔드 개발 시
1. [backend/README.md](docs/implementation/backend/README.md) - 백엔드 구현 가이드 인덱스
2. [api-reference.md](docs/implementation/api-reference.md) - API 규칙 (참조 문서)
3. [database-reference.md](docs/implementation/database-reference.md) - 데이터 모델 (참조 문서)

### 프론트엔드 개발 시
1. [frontend/README.md](docs/implementation/frontend/README.md) - 프론트엔드 구현 가이드 인덱스
2. [design-system.md](docs/ui-ux/concepts/design-system.md) - UI/UX 가이드

---

## 🔗 참조 체계

- **개념 문서** → 구현 가이드로 링크
- **구현 가이드** → 개념 설명으로 역링크
- **에러 문서** → 관련 개념/구현으로 링크
- **UI/UX 문서** → 구현 예시로 링크

---

## Active Technologies
- Dart 3.x (Flutter SDK 3.x)
- Navigator 2.0 (declarative navigation)
- In-memory navigation state (session-scoped)
- Dart 3.x (Flutter SDK 3.x) + Riverpod (state management), go_router (navigation), scroll_to_index (scroll control), visibility_detector (scroll tracking) (002-workspace-bugs-fix)
- In-memory session state (Navigator 2.0), API-persisted read positions (002-workspace-bugs-fix)
- Dart 3.x (Flutter SDK 3.x stable) (003-flutter-analysis-fixes)
- N/A (코드 품질 수정, 데이터 모델 변경 없음) (003-flutter-analysis-fixes)

## Recent Changes
- 2025-11-10: Navigator 2.0 리팩터링 완료, develop 브랜치 병합
- 2025-10-25: 컴포넌트 추출 Phase 1-2 완료
- 2025-10-01: 권한 모델 하이브리드 전환
