# 링크 매핑 테이블 (Link Mapping Table)

**작성일**: 2025-10-24
**상태**: 63개 깨진 링크 매핑 완료

## 📋 개요

이 문서는 삭제되거나 이동된 파일의 링크를 새로운 파일로 매핑하는 테이블입니다.
자동 링크 업데이트 스크립트에서 사용됩니다.

## 🗺️ 삭제된 파일 → 신규 파일 매핑

### 개념 문서 (Concepts)

| 삭제된 파일 | 신규 파일 | 비고 |
|------------|----------|------|
| `calendar-system.md` | `personal-calendar-system.md`<br>`group-calendar-system.md`<br>`place-calendar-system.md`<br>`calendar-integration.md` | 4개 파일로 분리 (개인/그룹/장소/통합) |
| `calendar-design-decisions.md` | `../backend/calendar-core-design.md`<br>`../backend/calendar-specialized-design.md` | 백엔드 설계 문서로 이동 |
| `calendar-place-management.md` | `place-calendar-system.md` | 장소 캘린더 시스템으로 통합 |

### 구현 가이드 (Implementation)

| 삭제된 파일 | 신규 파일 | 비고 |
|------------|----------|------|
| `backend/README.md` | `backend/README.md` | 백엔드 인덱스로 변경 |
| `frontend-guide.md` | `frontend/README.md` | 프론트엔드 인덱스로 변경 |
| `component-reusability-guide.md` | `frontend/components.md` | 프론트엔드 컴포넌트 가이드로 통합 |
| `frontend-workspace-guide.md` | `workspace-page-implementation-guide.md` | 워크스페이스 구현 가이드로 통합 |
| `workspace-level-navigation-guide.md` | `workspace-state-management.md` | 상태 관리 가이드로 통합 |

### 백엔드 문서 (Backend)

| 잘못된 경로 | 올바른 경로 | 비고 |
|------------|----------|------|
| `../backend/calendar-core-design.md` | `../backend/calendar-core-design.md`<br>`../backend/calendar-specialized-design.md` | 2개 파일로 분리 |
| `../concepts/permission-system.md` | `../concepts/permission-system.md` | 개념 문서로 이동 |
| `./architecture.md` | `../implementation/backend/architecture.md` | 구현 가이드로 이동 |
| `../implementation/backend/permission-checking.md` | `../implementation/backend/permission-checking.md` | 파일명 변경 |

### 기타

| 잘못된 링크 | 올바른 링크 | 비고 |
|------------|----------|------|
| `testing-strategy.md` | `../workflows/testing-strategy.md` | 상대 경로 오류 |
| `file.md` | (삭제 필요) | 임시 링크 |
| `path.md` | (삭제 필요) | 예시 링크 |
| `../../ui-ux/concepts/design-system.md` | `../../ui-ux/concepts/design-system.md` | 경로 변경 |
| `../member_management/member_management_page.md` | (삭제 필요) | 존재하지 않는 파일 |

---

## 🔧 자동 수정 스크립트 (sed 명령어)

### 1단계: calendar-system.md → 4개 파일 분리

**대상**: 개념 설명 링크
```bash
# 개인 캘린더 관련 링크
sed -i '' 's|../concepts/calendar-system.md|../concepts/personal-calendar-system.md|g' docs/**/*.md

# 그룹 캘린더 관련 링크 (context에 따라 수동 조정 필요)
# sed -i '' 's|../concepts/calendar-system.md|../concepts/group-calendar-system.md|g' [특정 파일]

# 장소 캘린더 관련 링크
# sed -i '' 's|../concepts/calendar-system.md|../concepts/place-calendar-system.md|g' [특정 파일]

# 통합 관련 링크
# sed -i '' 's|../concepts/calendar-system.md|../concepts/calendar-integration.md|g' [특정 파일]
```

**주의**: calendar-system.md는 컨텍스트에 따라 다른 파일로 매핑되므로 수동 검토 필요

### 2단계: calendar-design-decisions.md → 백엔드 설계 문서

```bash
# 권한 및 반복 설계 관련
find docs -name "*.md" -type f -exec sed -i '' 's|../concepts/calendar-design-decisions.md|../backend/calendar-core-design.md|g' {} +

# 시간표 및 장소 설계 관련 (수동 조정 필요)
```

### 3단계: calendar-place-management.md → place-calendar-system.md

```bash
find docs -name "*.md" -type f -exec sed -i '' 's|../concepts/place-calendar-system.md|../concepts/place-calendar-system.md|g' {} +
```

### 4단계: backend/README.md → backend/README.md

```bash
find docs -name "*.md" -type f -exec sed -i '' 's|../implementation/backend/README.md|../implementation/backend/README.md|g' {} +
find docs -name "*.md" -type f -exec sed -i '' 's|backend/README.md|backend/README.md|g' {} +
```

### 5단계: frontend-guide.md → frontend/README.md

```bash
find docs -name "*.md" -type f -exec sed -i '' 's|../implementation/frontend/README.md|../implementation/frontend/README.md|g' {} +
```

### 6단계: component-reusability-guide.md → frontend/components.md

```bash
find docs -name "*.md" -type f -exec sed -i '' 's|../implementation/frontend/components.md|../implementation/frontend/components.md|g' {} +
find docs -name "*.md" -type f -exec sed -i '' 's|component-reusability-guide.md|frontend/components.md|g' {} +
```

### 7단계: workspace 관련 가이드 통합

```bash
# frontend-workspace-guide.md → workspace-page-implementation-guide.md
find docs -name "*.md" -type f -exec sed -i '' 's|../implementati../workspace-page-implementation-guide.md|../implementation/workspace-page-implementation-guide.md|g' {} +
find docs -name "*.md" -type f -exec sed -i '' 's|frontend-workspace-guide.md|workspace-page-implementation-guide.md|g' {} +

# workspace-level-navigation-guide.md → workspace-state-management.md
find docs -name "*.md" -type f -exec sed -i '' 's|../implementati../workspace-state-management.md|../implementation/workspace-state-management.md|g' {} +
find docs -name "*.md" -type f -exec sed -i '' 's|workspace-level-navigation-guide.md|workspace-state-management.md|g' {} +
```

### 8단계: 백엔드 경로 수정

```bash
# calendar-design.md → calendar-core-design.md (수동 조정 필요)
find docs -name "*.md" -type f -exec sed -i '' 's|../backend/calendar-core-design.md|../backend/calendar-core-design.md|g' {} +

# permission-system.md 경로 수정
find docs -name "*.md" -type f -exec sed -i '' 's|../concepts/permission-system.md|../concepts/permission-system.md|g' {} +

# architecture.md 경로 수정
find docs/backend -name "*.md" -type f -exec sed -i '' 's|./architecture.md|../implementation/backend/architecture.md|g' {} +

# permission-validation.md → permission-checking.md
find docs -name "*.md" -type f -exec sed -i '' 's|../implementation/backend/permission-checking.md|../implementation/backend/permission-checking.md|g' {} +
```

### 9단계: 기타 경로 수정

```bash
# testing-strategy.md 상대 경로 수정
find docs/testing -name "*.md" -type f -exec sed -i '' 's|testing-strategy.md|../workflows/testing-strategy.md|g' {} +

# design-system.md 경로 수정
find docs -name "*.md" -type f -exec sed -i '' 's|../../ui-ux/concepts/design-system.md|../../ui-ux/concepts/design-system.md|g' {} +

# 존재하지 않는 링크 제거 (수동)
# - file.md
# - path.md
# - ../member_management/member_management_page.md
```

---

## 📊 링크 수정 우선순위

### P0: CLAUDE.md 네비게이션 (1개 파일)
- **중요도**: 최상
- **영향 범위**: 모든 사용자 진입점
- **수정 방법**: 수동 (컨텍스트 이해 필요)

### P1: 개념 문서 → 구현 가이드 링크 (30개 예상)
- **중요도**: 상
- **영향 범위**: 개발 워크플로우
- **수정 방법**: 자동 + 수동 검증

### P2: 구현 가이드 내부 링크 (20개 예상)
- **중요도**: 중
- **영향 범위**: 상세 구현 참조
- **수정 방법**: 자동

### P3: 기능 개발 계획 문서 링크 (12개 예상)
- **중요도**: 하
- **영향 범위**: 특정 기능 개발
- **수정 방법**: 자동

---

## ✅ 수정 완료 체크리스트

### 자동 수정 가능 (45개)
- [ ] backend/README.md → backend/README.md (7개)
- [ ] frontend-guide.md → frontend/README.md (6개)
- [ ] component-reusability-guide.md → frontend/components.md (5개)
- [ ] calendar-place-management.md → place-calendar-system.md (8개)
- [ ] frontend-workspace-guide.md → workspace-page-implementation-guide.md (4개)
- [ ] workspace-level-navigation-guide.md → workspace-state-management.md (3개)
- [ ] testing-strategy.md 상대 경로 수정 (1개)
- [ ] design-system.md 경로 수정 (1개)
- [ ] backend/permission-system.md → concepts/permission-system.md (2개)
- [ ] architecture.md 경로 수정 (1개)
- [ ] permission-validation.md → permission-checking.md (1개)
- [ ] calendar-design.md → calendar-core-design.md (6개)

### 수동 수정 필요 (18개)
- [ ] calendar-system.md → 4개 파일 중 컨텍스트에 맞는 파일 선택 (11개)
- [ ] calendar-design-decisions.md → core/specialized 중 선택 (4개)
- [ ] 존재하지 않는 링크 제거 (file.md, path.md, member_management) (3개)

---

## 🚨 주의사항

### 1. calendar-system.md 링크는 컨텍스트별로 다르게 매핑
- **개인 일정/시간표** 언급 → `personal-calendar-system.md`
- **그룹 공유 일정** 언급 → `group-calendar-system.md`
- **장소 예약** 언급 → `place-calendar-system.md`
- **전체 통합** 언급 → `calendar-integration.md`

### 2. calendar-design-decisions.md 링크는 내용별로 다르게 매핑
- **권한, 반복 일정, 예외 처리** 언급 → `calendar-core-design.md`
- **시간표, 장소 예약, 동시성** 언급 → `calendar-specialized-design.md`

### 3. 백업 생성 권장
```bash
# 수정 전 백업
cp -r docs docs_backup_$(date +%Y%m%d_%H%M%S)
```

### 4. 수정 후 검증 필수
```bash
# 링크 검증 재실행
./scripts/check-broken-links.sh

# 0개의 깨진 링크가 될 때까지 반복
```

---

## 🔗 관련 문서
- [Broken Links Report](broken-links-report.md)
- [Documentation Improvement Action Plan](documentation-improvement-action-plan.md)
- [Sync Status](sync-status.md)
