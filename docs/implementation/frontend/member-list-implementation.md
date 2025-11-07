# 멤버 필터 구현 가이드 - Phase 1 (Member Filter Implementation - Phase 1)

멤버 필터링 시스템의 기본 구현 가이드 (Phase 1)입니다.

## 개요

Phase 1: 기본 필터링 시스템 구축
- MemberFilter 모델
- MemberFilterProvider (역할, 그룹, 학년/학번)
- 기본 필터 UI (FilterChip)

**고급 기능**: Phase 2-3는 [멤버 필터 고급 기능](member-filter-advanced-features.md) 참고

## MemberFilter 모델

**파일**: `frontend/lib/core/models/member_filter.dart`

### 주요 필드

- `roleIds`: 역할 ID 목록 (역할 필터)
- `groupIds`: 소속 그룹 ID 목록 (그룹 필터)
- `grades`: 학년 목록 (학년 필터)
- `years`: 학번(입학년도) 목록 (학번 필터)

### 핵심 메서드

- `toQueryParameters()`: API 쿼리 파라미터 변환
- `isActive`: 필터 활성 여부
- `isRoleFilterActive`: 역할 필터 사용 중 여부

## MemberFilterProvider

**파일**: `frontend/lib/core/providers/member/member_filter_provider.dart`

### 필터 토글 메서드

- `toggleRole(int roleId)`: 역할 필터 토글 (단독 필터)
- `toggleGroup(int groupId)`: 그룹 필터 토글
- `toggleGrade(int grade)`: 학년 필터 토글
- `toggleYear(int year)`: 학번 필터 토글
- `reset()`: 모든 필터 초기화

### 필터 우선순위

**역할 필터 선택 시**:
- 모든 일반 필터 (그룹, 학년, 학번) 자동 초기화
- 역할 필터만 활성화 (단독 모드)

**일반 필터 선택 시**:
- 역할 필터 자동 해제
- 그룹 + 학년/학번 AND 관계
- 학년 OR 학번 (같은 섹션 내)

## FilteredMembersProvider

**파일**: `frontend/lib/core/providers/member/member_list_provider.dart`

### 동작 방식

1. `memberFilterStateProvider` 구독
2. 필터 활성 시: API에 쿼리 파라미터 전달
3. 필터 비활성 시: 전체 멤버 조회

## 기본 UI 컴포넌트

### RoleFilter (역할 필터)

**파일**: `frontend/lib/presentation/widgets/member/filters/role_filter.dart`

- FilterChip 사용
- Tooltip으로 단독 필터 안내
- 비활성화 상태 지원

### GradeYearFilter (학년/학번)

**파일**: `frontend/lib/presentation/widgets/member/filters/grade_year_filter.dart`

- 학년: FilterChip (1-4학년)
- 학번: 드롭다운 (동적 생성)
- "또는" 관계 시각적 구분

## API 통합

**엔드포인트**: `GET /api/groups/{groupId}/members`

**쿼리 파라미터**:
- `roleIds`: 1,2,3 (쉼표 구분)
- `groupIds`: 10,20
- `grades`: 2,3
- `years`: 24,25

**예시**: `/api/groups/1/members?roleIds=1,2&grades=2,3`

## 관련 문서

- [멤버 필터 개념](../../concepts/member-list-system.md) - 필터링 로직 이해
- [멤버 필터 고급 기능](member-filter-advanced-features.md) - Phase 2-3 구현
- [필터 UI 명세](../../ui-ux/components/member-filter-ui-spec.md) - 상세 UI/UX
- [상태 관리](state-management.md) - Riverpod 기본 패턴
