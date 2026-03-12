# 리팩터링 설계 원칙 (Refactoring Design Principles)

처음부터 다시 설계한다면 반드시 지켜야 할 원칙들을 문서화했습니다. **AI agent(Claude Code)가 개발할 때 가장 먼저 참고하는 문서입니다.**

## 🎯 빠른 네비게이션

### 백엔드 개발
처음부터 설계할 때 우선순위 TOP 3:

1. **[도메인 경계 설계](backend/domain-boundaries.md)** - 가장 먼저!
   - 각 도메인의 책임을 명확히
   - 도메인 간 통신 방식 정의
   - 데이터 소유권 규칙
   - 도메인별 public API 명시

2. **[API 단순화](backend/api-simplification.md)** - 두 번째!
   - REST 동사 5가지로 제한 (GET/POST/PATCH/DELETE)
   - 모든 응답을 ApiResponse<T> 형식으로
   - 부분 조회는 쿼리 파라미터로만
   - 별도 엔드포인트 금지

3. **[권한 검증 (역함수 패턴)](backend/permission-guard.md)** - 세 번째!
   - 권한을 먼저 확인 (DB 접근 전)
   - 권한에 따른 쿼리 최적화
   - N+1 쿼리 문제 해결
   - 감시 로깅 명확화

### 프론트엔드 개발
처음부터 설계할 때 우선순위 TOP 6:

1. **[상태 생명주기](frontend/state-lifecycle.md)** - 가장 먼저!
   - StateScope 정의 (APP/SESSION/VIEW/TEMPORARY)
   - Provider 생명주기 관리
   - 로그아웃 시 자동 정리

2. **[API 응답 매핑](frontend/api-response-mapping.md)** - 두 번째!
   - ApiResponse<T> → AsyncValue<T> 변환
   - 모든 Provider가 동일한 방식으로 처리
   - 통일된 에러 타입

3. **[권한을 UI 조건으로](frontend/permission-ui.md)** - 세 번째!
   - 백엔드 권한 플래그만 신뢰
   - 프론트엔드 권한 계산 금지
   - DTO에 권한 정보 포함

4. **[명시적 상태 머신](frontend/state-machine.md)** - 네 번째!
   - 상태를 명확한 enum으로 정의
   - 상태 전환 규칙 명시
   - switch/when으로 모든 상태 처리

5. **[화면 구조 템플릿](frontend/screen-structure.md)** - 다섯 번째!
   - 모든 Feature가 동일한 폴더 구조
   - {FEATURE}_STRUCTURE.md 작성 규칙
   - data/domain/presentation 계층 분리

6. **[Provider 의존성 맵](frontend/provider-dependency.md)** - 여섯 번째!
   - ScreenProviderMap으로 중앙 관리
   - 화면별 Provider 의존성 명시
   - Provider 4가지 카테고리 분류

---

## 📊 백엔드 vs 프론트엔드 원칙 비교

| 원칙 | 백엔드 | 프론트엔드 |
|------|--------|----------|
| **구조 | 도메인 경계 | Feature별 폴더 |
| **데이터 | Entity + DTO | Entity + DTO |
| **권한 | 도메인에서 검증 | UI 조건으로만 사용 |
| **API | Minimal + ApiResponse | AsyncValue 매핑 |
| **상태 | 비즈니스 로직 | 명시적 enum |

---

## 🔍 AI Agent 사용 시나리오

### 시나리오 1: "Post 리팩터링 진행 상황 파악"
```
1. 이 파일 (README.md) 읽기
   ↓
2. backend/domain-boundaries.md 또는 frontend/state-lifecycle.md 읽기
   ↓
3. 구체적 설계 파일 읽기
```

### 시나리오 2: "새로운 Comment 기능 추가"
```
1. [화면 구조 템플릿](frontend/screen-structure.md) 읽기
   ↓
2. features/comment/ 폴더 구조 생성
   ↓
3. [API 응답 매핑](frontend/api-response-mapping.md) 따라 Provider 작성
   ↓
4. [상태 머신](frontend/state-machine.md) 따라 상태 정의
   ↓
5. [Provider 의존성 맵](frontend/provider-dependency.md)에 등록
```

### 시나리오 3: "백엔드 권한 시스템 개선"
```
1. [도메인 경계](backend/domain-boundaries.md) 읽기
   ↓
2. [권한 검증 (역함수 패턴)](backend/permission-guard.md) 읽기
   ↓
3. Permission Domain 재설계
   ↓
4. API 엔드포인트 검증 ([API 단순화](backend/api-simplification.md))
```

---

## ⚡ 충돌 해결 항목

이 문서 작성 중에 발견한 중요한 충돌/개선사항:

### 1️⃣ 100줄 원칙 예외 추가
**현재 상태**: 리팩터링 문서(masterplan, checklist)가 100줄 초과
**결정**: 헌법에서 "개발 계획"으로 공식 인정 (예외 추가)
**영향**: 리팩터링 문서는 100줄 제외

### 2️⃣ Speckit vs docs/refactor 역할 분담
**Speckit (`specs/{번호}-{프로젝트명}/`)**:
- 구체적 프로젝트 실행 (tasks.md 체크)
- Phase 완료 추적

**docs/refactor (`docs/refactor/`)**:
- 리팩터링 지식 축적 (재사용 가능한 패턴)
- 향후 리팩터링에 참고

### 3️⃣ 기존 문서와의 관계
- `docs/workflows/post-refactoring-*` 기존 문서: 유지
- 새로운 리팩터링: 모두 `docs/refactor/`에 작성
- 참조: `docs/refactor/README.md`에서 링크 제공

---

## 📋 문서 구조

```
docs/refactor/
├── README.md                    ← 이 파일 (전체 가이드)
├── backend/
│   ├── domain-boundaries.md     (도메인 경계 설계)
│   ├── api-simplification.md    (API 단순화)
│   └── permission-guard.md      (권한 역함수 패턴)
├── frontend/
│   ├── state-lifecycle.md       (상태 생명주기)
│   ├── api-response-mapping.md  (API 응답 매핑)
│   ├── permission-ui.md         (권한 UI 조건)
│   ├── state-machine.md         (상태 머신)
│   ├── screen-structure.md      (화면 구조 템플릿)
│   └── provider-dependency.md   (Provider 의존성 맵)
└── templates/
    ├── refactoring-plan.md      (향후 사용)
    └── phase-completion.md      (향후 사용)
```

---

## 🎓 각 원칙의 핵심 메시지

### 백엔드

**도메인 경계**
> 새 기능 추가 시 기존 도메인을 건드리지 않도록 경계를 명확히 한다.

**API 단순화**
> 클라이언트가 예측 불가능한 형식에 대응하지 않도록 API를 극도로 단순화한다.

**권한 검증 (역함수)**
> 권한 없는 데이터도 조회하지 않도록 권한을 먼저 확인한다.

### 프론트엔드

**상태 생명주기**
> "이 상태는 언제까지 살아있어야 하는가?"를 먼저 정의한다.

**API 응답 매핑**
> 모든 Provider가 동일한 AsyncValue 방식으로 응답하도록 통일한다.

**권한을 UI 조건으로**
> 백엔드가 계산한 권한 플래그를 신뢰하고, 프론트에서 계산하지 않는다.

**상태 머신**
> 상태를 명확한 enum으로 정의하여 불명확한 조합을 제거한다.

**화면 구조**
> 모든 화면이 동일한 구조를 따르도록 표준화한다.

**Provider 의존성 맵**
> 화면이 필요로 하는 Provider를 중앙에서 관리한다.

---

## ✅ 검증 체크리스트

### 개발 시작 전
- [ ] 백엔드: 도메인 경계를 정의했는가?
- [ ] 프론트엔드: StateScope를 정의했는가?

### 개발 중
- [ ] 백엔드: API가 5가지 동사만 사용하는가?
- [ ] 프론트엔드: Provider가 AsyncValue를 반환하는가?
- [ ] 권한이 명확한가? (백엔드: 역함수, 프론트엔드: 플래그)

### 개발 완료 후
- [ ] 테스트가 통과하는가?
- [ ] 문서가 코드와 동기화되어 있는가?
- [ ] 새 기능 추가 시 기존 코드 수정이 최소인가?

---

## 🚀 다음 단계

### 현재 프로젝트에 적용
1. Post, Comment Feature 검토 (이미 대부분 적용됨)
2. Channel Feature 리팩터링
3. Group Feature 리팩터링

### 새 Feature 추가 시
1. 이 문서 (README.md) 읽기
2. 해당 도메인의 원칙 문서 읽기 (backend/* 또는 frontend/*)
3. 구현 시작

### 문서 유지보수
- 새 Feature 추가 시 ScreenProviderMap 업데이트
- 권한 변경 시 permission-*.md 검토
- API 변경 시 api-*.md 검토

---

## 📞 문의 사항

각 원칙 문서의 관련 링크를 확인하세요:
- **아키텍처**: [헌법](../.specify/memory/constitution.md)
- **구현 가이드**: [백엔드](../implementation/backend/), [프론트엔드](../implementation/frontend/)
- **개념**: [도메인](../concepts/domain-overview.md), [권한](../concepts/permission-system.md)

---

**Version**: 1.0.0
**Last Updated**: 2025-11-20
**Author**: AI Agent (Claude Code)
**Status**: Active
