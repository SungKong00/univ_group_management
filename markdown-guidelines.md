# 마크다운 컨텍스트 문서 관리 규칙

## 📝 작성 원칙

### 1. 100줄 이내 원칙
- 각 .md 파일은 **100줄 이내**로 작성
- 긴 내용은 여러 파일로 분할
- 핵심 내용만 포함, 세부사항은 하위 문서로 링크

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
- `concepts/`: 도메인 개념, 비즈니스 로직 설명
- `implementation/`: 코드 구현 가이드, API 문서
- `ui-ux/`: 디자인 시스템, 컴포넌트 가이드
- `workflows/`: 개발 프로세스, 테스트 전략
- `troubleshooting/`: 에러 해결, FAQ

## ✍️ 문서 템플릿

### 개념 문서 (concepts/)
```markdown
# 제목

## 개념 설명
[핵심 개념을 간결하게 설명]

## 구조/다이어그램
[시각적 표현]

## 주요 특징
[중요 포인트 3-5개]

## 관련 구현
- [API 가이드](../implementation/api-reference.md#관련섹션)
- [DB 설계](../implementation/database-reference.md#관련테이블)

## 실제 사용 예시
[구체적인 시나리오 1-2개]
```

### 구현 문서 (implementation/)
```markdown
# 제목

## 핵심 패턴
[주요 구현 패턴]

## 코드 예시
[실제 사용 가능한 코드]

## API/함수 참조
[주요 메서드/엔드포인트]

## 관련 개념
- [개념 설명](../concepts/관련개념.md)

## 주의사항
[흔한 실수, 베스트 프랙티스]
```

## 🔗 링크 작성 규칙

### 상대 경로 사용
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

## 📋 체크리스트

### 새 문서 작성 시
- [ ] 100줄 이내 작성
- [ ] 적절한 디렉토리에 배치
- [ ] CLAUDE.md에 링크 추가
- [ ] 관련 문서에 상호 참조 추가

### 기존 문서 수정 시
- [ ] 관련 문서의 링크 확인
- [ ] 일관성 검토
- [ ] 필요시 CLAUDE.md 업데이트
- [ ] 컨텍스트 추적 문서 2종([로그](docs/context-tracking/context-update-log.md), [상태](docs/context-tracking/sync-status.md))를 업데이트했는가?

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
