# 멤버 필터링 UI 완성 메모

## 작업 일시
2025-10-24

## 구현 내용

### 1. 재사용 가능한 Chip 컴포넌트 설계 및 구현

#### 1.1 AppChip (`frontend/lib/presentation/components/chips/app_chip.dart`)
- **목적**: 범용 Chip 컴포넌트 (태그, 필터, 상태 표시)
- **특징**:
  - 색상 변형 5가지: default, primary, success, warning, error
  - 크기 변형 3가지: small, medium, large
  - 선택 가능/불가능 상태
  - 비활성화 상태 지원
  - 선행/후행 아이콘 지원
  - 삭제 버튼 지원
- **디자인 시스템 준수**:
  - AppColors 사용 (brand, success, warning, error)
  - AppRadius 사용 (sm, button)
  - AppTheme 타이포그래피 적용

#### 1.2 AppInputChip (`frontend/lib/presentation/components/chips/input_chip.dart`)
- **목적**: 사용자 입력 결과 표시 (검색 태그, 필터 선택)
- **특징**:
  - 삭제 버튼(× icon) 필수
  - onDeleted 콜백 필수
  - AppChip 기반 확장

#### 1.3 Export 파일 (`frontend/lib/presentation/components/chips/chips.dart`)
- 컴포넌트들을 한 곳에서 import 가능하도록 export

### 2. API 연동 Provider 구현

#### 2.1 하위 그룹 Provider (`frontend/lib/core/providers/member/member_filter_options_provider.dart`)
- **API**: `GET /api/groups/{groupId}/sub-groups`
- GroupService에 `getSubGroups` 메서드 추가 (`frontend/lib/core/services/group_service.dart`)
- Provider: `subGroupsProvider` (FutureProvider.family)

#### 2.2 학번 목록 Provider
- **로직**: 2010년 ~ (현재년도 + 1) 범위 생성 (신입생 고려)
- Provider: `availableYearsProvider` (내림차순 정렬)

#### 2.3 학년 목록 상수
- `availableGrades`: [1, 2, 3, 4, 5(졸업생), 0(기타)]
- `gradeLabels`: 학년별 레이블 맵

### 3. MemberFilterPanel 전체 확장

#### 3.1 적용된 필터 칩 표시 (`_AppliedFilters`)
- **위치**: 필터 섹션 상단 (필터 활성화 시에만 표시)
- **기능**:
  - 선택된 모든 필터를 InputChip으로 표시
  - 개별 제거: 각 칩의 × 버튼 클릭
  - 전체 제거: "모두 지우기" 버튼
  - 가로 스크롤 지원
- **디자인**:
  - 역할: primary variant (보라색)
  - 그룹: default variant (회색)
  - 학년/학번: success variant (녹색)
  - 각 칩에 아이콘 추가 (person, group, school, calendar_today)

#### 3.2 소속 그룹 필터 (`_GroupFilter`)
- **조건**: 하위 그룹이 있을 때만 표시
- **UI**: FilterChip으로 다중 선택
- **비활성화**: 역할 필터 사용 중일 때
- **아이콘**: Groups 아이콘

#### 3.3 학년/학번 필터 (`_GradeYearFilter`)
- **학년**: 1~4학년, 졸업생, 기타
- **학번**: 동적 생성 (2010~현재+1)
- **OR 관계**: 학년과 학번을 함께 선택 가능
- **비활성화**: 역할 필터 사용 중일 때
- **UI 구조**:
  - 제목: "학년 또는 학번"
  - 설명: "학년과 학번은 함께 선택 가능합니다 (OR 관계)"
  - 학년 칩: medium size
  - 학번 칩: small size

#### 3.4 비활성화 상태 UI
- **로직**:
  - 역할 필터 선택 → 일반 필터들 비활성화
  - 일반 필터 선택 → 역할 필터 비활성화
- **시각적 피드백**:
  - 제목 텍스트 회색 처리 (neutral400)
  - 정보 아이콘 회색 처리
  - Chip enabled=false → 회색 배경 + 회색 텍스트
  - onSelected: null → 클릭 불가

### 4. 결과 카운트 표시

#### 4.1 데스크톱 레이아웃
- **위치**: 테이블 상단 (테이블 헤더 위)
- **조건**: 필터 활성화 시에만 표시
- **디자인**:
  - 배경: neutral100
  - 아이콘: info_outline
  - 텍스트: "검색 결과: N명"

#### 4.2 모바일 레이아웃
- **위치**: 멤버 카드 목록 상단
- **조건**: 필터 활성화 시에만 표시
- **디자인**: 데스크톱과 동일

### 5. 파일 구조

```
frontend/lib/
├── presentation/
│   ├── components/
│   │   └── chips/
│   │       ├── app_chip.dart          (NEW)
│   │       ├── input_chip.dart        (NEW)
│   │       └── chips.dart             (NEW)
│   └── pages/
│       ├── member_management/
│       │   └── widgets/
│       │       ├── member_filter_panel.dart  (UPDATED)
│       │       └── member_list_section.dart  (UPDATED)
│       └── demo_member_filter_page.dart
└── core/
    ├── providers/
    │   └── member/
    │       ├── member_filter_provider.dart
    │       └── member_filter_options_provider.dart  (NEW)
    └── services/
        └── group_service.dart  (UPDATED: getSubGroups 추가)
```

## 디자인 시스템 준수 사항

### 컬러
- **Brand**: primary (#5C068C), brandStrong, brandLight
- **Neutral**: neutral100~neutral900
- **System**: success (녹색), warning (주황), error (빨강)
- **Disabled**: disabledBgLight, disabledTextLight

### 간격
- **xxs**: 8px
- **xs**: 12px
- **sm**: 16px
- **md**: 24px

### 타이포그래피
- **headlineSmall**: 18px/600 (패널 제목)
- **titleMedium**: 14px/500 (섹션 제목)
- **bodySmall**: 12px/400 (칩, 라벨)

### 반응형
- **브레이크포인트**: 768px (데스크톱/모바일 구분)

## 주요 개선 사항

### 1. 사용자 경험
- **즉각적인 피드백**: 적용된 필터 칩으로 현재 상태 명확히 표시
- **직관적인 제거**: 각 칩의 × 버튼으로 개별 제거
- **배타적 관계 시각화**: 비활성화된 필터는 회색 처리 + 툴팁
- **결과 투명성**: 필터 결과 개수를 상단에 표시

### 2. 접근성
- **Semantics**: 모든 칩에 label 추가
- **Tooltip**: 비활성화된 필터에 이유 설명
- **키보드 접근성**: FilterChip 사용으로 기본 지원

### 3. 성능
- **디바운싱**: 300ms 후 상태 업데이트 (기존 Provider에 구현됨)
- **ListView.builder**: 멤버 목록 가상화
- **ValueKey**: 리빌드 최적화

## 테스트 체크리스트

### 기능 테스트
- [ ] 역할 필터: 단일/다중 선택
- [ ] 소속 그룹 필터: 다중 선택
- [ ] 학년 필터: 다중 선택
- [ ] 학번 필터: 다중 선택
- [ ] 학년+학번 동시 선택 (OR)
- [ ] 역할 선택 시 다른 필터 비활성화
- [ ] 일반 필터 선택 시 역할 필터 비활성화
- [ ] 적용된 필터 칩: 개별 제거
- [ ] 적용된 필터 칩: 모두 지우기
- [ ] 결과 카운트: 실시간 업데이트

### UI/UX 테스트
- [ ] 데스크톱 레이아웃 (768px 이상)
- [ ] 모바일 레이아웃 (768px 미만)
- [ ] 모바일 필터 바텀 시트
- [ ] 칩 색상/크기 일관성
- [ ] 비활성화 상태 시각화
- [ ] 툴팁 표시
- [ ] 스크롤 동작 (가로/세로)

### 반응형 테스트
- [ ] 데스크톱 → 모바일 전환
- [ ] 모바일 → 데스크톱 전환
- [ ] 각 브레이크포인트에서 레이아웃 확인

## 다음 단계 (추후 개선 사항)

### 1. 성능 최적화
- [ ] Chip 컴포넌트 메모이제이션
- [ ] 필터 상태 영속화 (SessionStorage)

### 2. 추가 기능
- [ ] 필터 프리셋 저장 기능
- [ ] 최근 사용한 필터 히스토리
- [ ] 고급 필터: 날짜 범위, 커스텀 조건

### 3. 접근성 개선
- [ ] 스크린 리더 테스트
- [ ] 고대비 모드 지원
- [ ] 키보드 단축키

## 문서 업데이트 필요 사항

### 1. UI/UX 문서
- `docs/ui-ux/components/chip-component.md` (신규): Chip 컴포넌트 명세
- `docs/ui-ux/components/member-list-component.md` (업데이트): 완성된 UI 반영

### 2. 구현 가이드
- `docs/implementation/frontend/components.md` (업데이트): Chip 컴포넌트 추가
- `docs/implementation/frontend/member-list-implementation.md` (업데이트): 완성된 구현 반영

### 3. 디자인 시스템
- `docs/ui-ux/concepts/design-system.md` (확인): Chip 컴포넌트 패턴 추가 필요 여부 확인

## 트러블슈팅 노트

### 1. firstWhere orElse 타입 문제
- **문제**: `orElse: () => null`에서 타입 에러
- **원인**: Dart null safety
- **해결**: dynamic 타입 사용 또는 null 체크 추가

### 2. Row/Column 제약 확인
- **확인 사항**: 모든 Row 자식에 Expanded/Flexible 적용
- **결과**: 레이아웃 에러 없음

### 3. Provider 순환 참조
- **주의**: MemberFilterPanel에서 여러 Provider 동시 watch
- **해결**: family provider 사용으로 그룹별 독립 상태 관리

## 참고 문서
- `/docs/ui-ux/components/member-list-component.md`
- `/docs/implementation/frontend/member-list-implementation.md`
- `/docs/ui-ux/concepts/design-system.md`
- `/docs/ui-ux/concepts/design-tokens.md`
- `/docs/concepts/member-list-system.md`
