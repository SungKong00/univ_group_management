# 마크다운 컨텍스트 문서 관리 규칙

## ⚠️ 문서 작성 전 필수 확인

**이 페이지 하단의 "📋 체크리스트" 섹션을 반드시 읽고, 작성 후 모든 항목을 확인하세요.**
체크리스트를 지키지 않은 문서는 검토 단계에서 반려됩니다.

---

## 📝 작성 원칙

### 1. 100줄 이내 원칙
- 각 .md 파일은 **100줄 이내**로 작성
- 긴 내용은 여러 파일로 분할
- 핵심 내용만 포함, 세부사항은 하위 문서로 링크

#### 예외 대상 문서
다음 문서들은 참조 문서, 명세서, 체크리스트, 가이드 등의 특성상 100줄 원칙의 예외로 인정됩니다:

**참조 문서 (Reference Documents)**:
- `api-reference.md` - REST API 전체 명세
- `database-reference.md` - DB 스키마 전체 참조
- `test-data-reference.md` - 테스트 데이터 구조 참조
- `row-column-layout-checklist.md` - Flutter 레이아웃 체크리스트

**가이드 및 전략 문서 (Guides & Strategies)**:
- `testing-strategy.md` - 테스트 전략 및 패턴
- `common-errors.md` - 에러 트러블슈팅 전체 가이드

**개발 계획 및 명세 (Development Plans & Specifications)**:
- `group-calendar-development-plan.md` - Phase별 상세 계획
- `personal-calendar-mvp.md` - MVP 전체 명세서
- `place-calendar-specification.md` - 장소 캘린더 명세서
- `calendar-integration-roadmap.md` - 통합 개발 로드맵

**컨벤션 문서 (Conventions)**:
- `code-review-standards.md` - 코드 리뷰 표준
- `commit-conventions.md` - 커밋 메시지 컨벤션
- `pr-guidelines.md` - PR 가이드라인
- `git-strategy.md` - Git 전략

**서브에이전트 문서 (Sub-Agents)**:
- `frontend-development-agent.md` - 프론트엔드 개발 에이전트
- `context-sync-agent.md` - 컨텍스트 동기화 에이전트
- `commit-management-agent.md` - 커밋 관리 에이전트

**특수 추적 문서 (Tracking Documents)**:
- `sync-status.md` - 동기화 상태 추적 테이블 (자동 업데이트)

**예외 조건**:
- 축약이 불가능한 필수 참조 정보
- 체크리스트 형태의 반복 패턴
- Phase별/단계별 상세 계획
- 명세서 또는 레퍼런스 성격의 문서

**예외 적용 시 주의사항**:
- 예외 문서라도 목차와 섹션 구조를 명확히 작성
- 필요시 상단에 "문서 예외" 표시 권장
- 가능하면 섹션별로 분리 가능한지 재검토

### 2. 계층형 참조 구조
```
CLAUDE.md (마스터 인덱스)
├── concepts/ (개념 정의)
├── implementation/ (구현 가이드)
├── ui-ux/ (UI/UX 설계)
├── workflows/ (프로세스)
└── troubleshooting/ (문제해결)
```

### 3. 상호 참조 패턴
```markdown
# 올바른 참조 방법
- [개념 설명](../concepts/permission-system.md)
- [API 구현](../implementation/api-reference.md#권한체크)
- [에러 해결](../troubleshooting/permission-errors.md)

# 섹션 참조
- [권한 체크 로직](../concepts/permission-system.md#권한체크로직)
```

## 📁 파일 구조 규칙

### 파일명 규칙
- **kebab-case** 사용: `group-hierarchy.md`
- **영어 우선**, 필요시 한글: `권한시스템.md` → `permission-system.md`
- **의미 명확**: `backend.md` → `backend-guide.md`

### 디렉토리별 역할

| 디렉토리 | 역할 | 코드 참조 |
|---------|------|---------|
| `concepts/` | 도메인 개념, 비즈니스 로직, 서비스 흐름 (100줄 내) | ❌ 불가 |
| `backend/` | 기술 설계, 아키텍처 설계 원칙 (100줄 내) | ✅ 파일경로+클래스명만 |
| `implementation/` | 코드 구현 가이드, API 명세 (100줄 내) | ✅ 파일경로+클래스명만 |
| `ui-ux/` | 디자인 시스템, 컴포넌트 (100줄 내) | ✅ 파일경로+컴포넌트명만 |
| `workflows/` | 개발 프로세스, 테스트 전략 (100줄 내) | ❌ 불가 |
| `troubleshooting/` | 에러 해결, FAQ (100줄 내) | ✅ 파일경로만 |

**핵심**: 모든 디렉토리 100줄 이내 원칙, **구현 상세 코드는 절대 포함 금지**

## ✍️ 문서 템플릿

### 개념 문서 (concepts/)
**목표**: 서비스 흐름과 비즈니스 로직 이해 (코드 참조 없음)

```markdown
# 제목

## 개요
[개념의 목적을 1-2줄로 설명]

## 핵심 원칙/흐름
[서비스 동작 원리 3-5개 불렛]

## 구조/흐름도
[프로세스나 데이터 흐름 (텍스트나 다이어그램)]

## 주요 특징
[비즈니스 관점에서 중요한 포인트]

## 실제 사용 예시
[사용자/관리자 관점에서의 구체적 시나리오]

## 관련 구현 가이드
- [기술 설계](../backend/...)
- [API 구현](../implementation/api-reference.md#...)
- [개발 가이드](../implementation/...)
```

### 백엔드 문서 (backend/)
```markdown
# 제목

## 개요
[시스템/모듈의 목적을 1-2줄로 설명]

## 설계 원칙
[핵심 원칙 3-5개 불렛 포인트]

## 구조/다이어그램
[시각적 표현 또는 플로우]

## 코드 참조
- **Entity**: `backend/src/main/kotlin/.../entity/EntityName.kt`
- **Service**: `backend/src/main/kotlin/.../service/ServiceName.kt`
- **Controller**: `backend/src/main/kotlin/.../controller/ControllerName.kt`

## 관련 구현 문서
- [API 참조](../implementation/api-reference.md#섹션)
- [DB 설계](../implementation/database-reference.md#테이블)
```

### 구현 문서 (implementation/)
**목표**: 코드 구현 패턴과 사용법 (코드 참조만, 상세 구현 코드 제외)

```markdown
# 제목

## 개요
[구현 가이드의 목적]

## 핵심 패턴
[주요 구현 패턴을 텍스트로 설명]

## 코드 참조
- **클래스/함수**: `ClassName.methodName()`
- **파일 위치**: `backend/src/main/kotlin/.../file.kt`
- **상세 구현**: 위 파일을 직접 참고하세요

## 주요 메서드/엔드포인트
- `GET /api/endpoint` - 설명
- `POST /api/endpoint` - 설명
- 상세 명세는 [API 참조](./api-reference.md)

## 관련 개념
- [기본 개념](../concepts/관련개념.md)

## 주의사항
[흔한 실수, 베스트 프랙티스]
```

## 🔗 코드 참조 정책 (implementation/ + backend/ 문서만)

**목표**: 문서는 개념과 링크에 집중, 구현 상세는 코드에서 직접 확인

**원칙**: 파일 경로 + 클래스/함수명만 제시 (상세 코드 절대 포함 금지)

### 1. 파일 경로 명시 (절대 경로)
```markdown
**Backend**:
- Entity: `backend/src/main/kotlin/org/castlekong/backend/entity/Group.kt`
- Service: `backend/src/main/kotlin/org/castlekong/backend/service/GroupService.kt`
- Controller: `backend/src/main/kotlin/org/castlekong/backend/controller/GroupController.kt`

**Frontend**:
- Component: `frontend/lib/presentation/pages/group_page.dart`
- Provider: `frontend/lib/provider/group_provider.dart`
```

### 2. 클래스/함수/메서드명 명시
```markdown
# ✅ 올바른 예
- `GroupService.createGroup()` 메서드
- `GroupRepository` 의 `findByParent()` 메서드
- `GroupPage` 위젯의 빌드 로직
→ Claude가 Read 도구로 직접 파일을 열어 코드 확인 가능

# ❌ 절대 하지 말 것
- 전체 함수/메서드 구현 코드 복사
- 20줄 이상의 코드 블록 삽입
- JSON 응답 객체의 전체 스키마 (예시만 제시)
```

### 3. 구현 상세 코드는 절대 포함 금지
```markdown
# ❌ 피해야 할 것
## GroupRepository 구현
@Query("SELECT g FROM Group g WHERE g.parent IS NULL")
fun findRootGroups(): List<Group> {
    return repository.findAll().filter { it.parent == null }
}
... (전체 구현 코드)

# ✅ 올바른 방법
## GroupRepository 사용 방법
`GroupRepository` 의 `findByParent()` 메서드로 계층 쿼리를 수행합니다.
- 파일: `backend/src/main/kotlin/.../repository/GroupRepository.kt`
- 메서드: `findByParent(Group)`, `findByOwner(User)`
- 상세 구현은 위 파일의 코드를 직접 참고하세요
```

### 상대 경로 사용 (문서 간)
```markdown
# 올바른 예
[그룹 계층](../concepts/group-hierarchy.md)

# 잘못된 예
[그룹 계층](/docs/concepts/group-hierarchy.md)
```

### 섹션 링크
```markdown
# 섹션 참조
[권한 체크 로직](permission-system.md#권한체크로직)

# 다른 파일의 섹션
[API 인증](../implementation/api-reference.md#인증인가)
```

### 역링크 제공
- 참조된 문서에는 역링크 추가
- "관련 문서" 섹션에 양방향 링크 유지

## 🔄 업데이트 규칙

### 1. 일관성 유지
- 관련 문서들을 함께 업데이트
- 링크 깨짐 확인 및 수정

### 2. 버전 관리
- 주요 변경사항은 CLAUDE.md에 반영
- 구현 상태 업데이트 (`✅ 완료`, `🚧 진행중`, `❌ 미구현`)

### 3. 중복 제거
- 동일한 내용이 여러 파일에 있으면 하나로 통합
- 참조 링크로 중복 방지

### 4. 컨텍스트 추적 문서 업데이트
코드 변경 및 문서 수정 사항을 체계적으로 추적하기 위해, 다음 두 관리 문서를 업데이트합니다. 이 작업은 주로 자동화된 에이전트가 수행하지만, 수동으로 작업할 때의 규칙은 다음과 같습니다.

#### [`context-update-log.md`](docs/context-tracking/context-update-log.md) 업데이트
- **시점**: 문서 수정 내용을 **커밋(Commit)할 때마다** 진행합니다.
- **방법**: 파일 최상단에 새로운 로그 항목을 **추가(Append)**합니다.
- **내용**: 어떤 커밋에서 어떤 문서가 왜 업데이트되었는지, 그리고 그로 인해 새로 업데이트가 필요해진 문서는 무엇인지 형식에 맞게 기록합니다.

#### [`sync-status.md`](docs/context-tracking/sync-status.md) 업데이트
- **시점**: 특정 문서의 **동기화 상태가 변경될 때마다** 진행합니다.
- **방법**: 테이블에서 해당 파일의 상태 표시자(예: `✅`, `❌`)를 **수정(Modify)**하고, 상단의 전체 동기화율을 다시 계산하여 갱신합니다.
- **주요 변경 사례**:
    - 코드 변경으로 기존 문서가 더 이상 최신이 아닐 때: `✅ 최신` → `❌ 업데이트 필요`
    - 업데이트가 필요한 문서를 수정하여 최신화했을 때: `❌ 업데이트 필요` → `✅ 최신`

## 📋 체크리스트 (작성 후 반드시 확인)

⚠️ **이 체크리스트를 지키지 않은 문서는 검토 단계에서 반려됩니다.**

### 공통 (모든 문서)
- [ ] **100줄 이내** 작성했는가? (줄 수 확인)
  - 예외 문서인 경우: 상단에 "문서 예외" 표시 권장
  - 예외 문서 목록: 위 "1. 100줄 이내 원칙 > 예외 대상 문서" 참조
- [ ] **적절한 디렉토리**에 배치했는가?
- [ ] **구현 상세 코드는 포함하지 않았는가?** (파일 경로+함수명만)
- [ ] **CLAUDE.md에 링크 추가**했는가?
- [ ] **관련 문서에 역링크** 추가했는가?

### concepts/ 문서 전용
- [ ] **코드 참조가 없는가?** (완전히 제거)
- [ ] **서비스 흐름/원칙이 명확한가?**
- [ ] **실제 사용 예시가 포함되었는가?**
- [ ] **비즈니스 관점에서 이해 가능한가?**

### implementation/ + backend/ 문서 전용
- [ ] **파일 경로 + 클래스/함수명만 제시했는가?** (상세 코드 없음)
- [ ] **20줄 이상의 코드 블록을 포함하지 않았는가?**
- [ ] **관련 concepts/ 문서로 역링크**했는가?

### 문서 수정 시
- [ ] **관련 문서의 링크가 깨지지 않았는가?**
- [ ] **일관성을 검토**했는가? (다른 문서와 내용 충돌 없음)
- [ ] **필요시 CLAUDE.md 업데이트**했는가?
- [ ] **컨텍스트 추적 문서 업데이트**했는가?
  - `docs/context-tracking/context-update-log.md`
  - `docs/context-tracking/sync-status.md`

## 🎯 목표

이 규칙을 통해 달성하고자 하는 것:
1. **빠른 탐색**: Claude가 필요한 정보를 즉시 찾을 수 있음
2. **일관된 구조**: 예측 가능한 문서 구조
3. **유지보수 용이**: 변경사항이 전체에 반영됨
4. **컨텍스트 최적화**: 100줄 이내로 한 번에 이해 가능

---

##  문서 동기화 워크플로우

### 1. 구현 완료 후 문서 업데이트
```markdown
1. API 변경 시: [api-reference.md](../implementation/api-reference.md)
2. DB 스키마 변경 시: [database-reference.md](../implementation/database-reference.md)
3. 새 개념 추가/확장 시: concepts/ (예: recruitment-system.md 확장)
4. UI 변경 시: ui-ux/pages/ (예: channel-pages.md Permission-Centric 반영)
5. 권한 모델 영향 시: permission-system.md / channel-permissions.md
6. 최상위 요약: CLAUDE.md 개정 요약 반영
```

### 2. 문서 일관성 확인
```markdown
□ Git / Commit / PR / 리뷰 문서 링크 포함
□ 채널 권한 플로우(매트릭스)가 channel-pages.md 와 api-reference.md 정합
□ 모집 API 스펙이 recruitment-system.md 와 api-reference.md 정합
```
