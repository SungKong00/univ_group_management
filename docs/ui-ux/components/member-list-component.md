# 멤버 필터 컴포넌트 개요 (Member Filter Component Overview)

멤버 목록 필터링 및 표시를 위한 UI 컴포넌트 개요입니다.

## 컴포넌트 계층

```
MemberListView
├── MemberFilterPanel (필터 영역)
│   ├── RoleFilter (역할)
│   ├── GroupFilter (그룹)
│   ├── GradeYearFilter (학년/학번)
│   └── AppliedFilters (적용된 필터)
├── MemberListContent (목록)
│   ├── [Desktop] MemberTable
│   └── [Mobile] MemberCardList
└── MemberListFooter (페이지네이션)
```

## 재사용 컴포넌트

### RoleBadge
**파일**: `frontend/lib/presentation/widgets/member/role_badge.dart`
**용도**: 역할 배지 표시

### MemberInfoRow
**파일**: `frontend/lib/presentation/widgets/member/member_info_row.dart`
**용도**: 아이콘 + 라벨 + 값 정보 행

### MemberCard
**파일**: `frontend/lib/presentation/widgets/member/member_card.dart`
**용도**: 모바일 멤버 카드

### MemberTableRow
**파일**: `frontend/lib/presentation/widgets/member/member_table_row.dart`
**용도**: 데스크톱 테이블 행

## 필터 상호작용

**역할 필터**: 단독 모드 (다른 필터 비활성화)
**일반 필터**: 그룹 + 학년/학번 AND 관계
**학년/학번**: OR 관계 (같은 섹션 내)

## 반응형 레이아웃

**데스크톱**: 좌측 필터 패널 (300px) + 우측 테이블
**모바일**: 접기 가능 필터 + 카드 목록

## 상태별 UI

- **로딩**: 스켈레톤 로더
- **빈 상태**: "필터 조건에 맞는 멤버 없음" + 초기화 버튼
- **에러**: "멤버 목록 불러오기 실패" + 재시도 버튼

## 상세 문서

- **필터 UI 상세**: [멤버 필터 UI 명세](member-filter-ui-spec.md)
- **구현 가이드**: [멤버 필터 구현 - Phase 1](../../implementation/frontend/member-list-implementation.md)
- **고급 기능**: [멤버 필터 고급 기능](../../implementation/frontend/member-filter-advanced-features.md)
- **Chip 컴포넌트**: [Chip 컴포넌트](../../implementation/frontend/chip-components.md)
- **디자인 시스템**: [디자인 시스템](../concepts/design-system.md)
