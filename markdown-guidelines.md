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

## 🎯 목표

이 규칙을 통해 달성하고자 하는 것:
1. **빠른 탐색**: Claude가 필요한 정보를 즉시 찾을 수 있음
2. **일관된 구조**: 예측 가능한 문서 구조
3. **유지보수 용이**: 변경사항이 전체에 반영됨
4. **컨텍스트 최적화**: 100줄 이내로 한 번에 이해 가능