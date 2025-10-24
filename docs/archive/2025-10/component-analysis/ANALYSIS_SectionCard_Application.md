# SectionCard 컴포넌트 적용 분석 보고서

**날짜**: 2025-10-25
**목적**: Container + BoxDecoration 패턴을 SectionCard 컴포넌트로 교체하여 코드 일관성 개선 및 중복 제거

---

## 1. 현황 분석

### SectionCard 컴포넌트 현재 구현

**위치**: `lib/presentation/widgets/common/section_card.dart`

**특징**:
- 화이트 배경 + 그림자 + 둥근 모서리 (20px) 카드 스타일
- 기본 패딩: `EdgeInsets.all(AppSpacing.md)` (24px)
- 커스텀 가능한 속성:
  - `padding`: 패딩 오버라이드
  - `showShadow`: 그림자 표시 여부 (기본: true)
  - `backgroundColor`: 배경색 (기본: Colors.white)
  - `borderRadius`: 테두리 반경 (기본: AppRadius.card = 20px)

### Container + BoxDecoration 패턴 사용 현황

- **전체 검색 결과**: 81개 파일에서 `Container + BoxDecoration` 패턴 발견
- **실제 적용 가능 대상**: 약 40~50개 파일 (나머지는 특수한 UI 패턴)

---

## 2. 패턴 분류

### A. SectionCard 즉시 적용 가능 (High Priority) - 약 20개 파일

**특징**:
- 화이트 배경 + 그림자/테두리 + 둥근 모서리
- 패딩이 일정 (12~24px)
- 섹션/카드 컨테이너 역할

**주요 파일**:
1. `member_list_section.dart` (Line 234-240, 274-282, 380-383, 656-660, 679-682)
   - 데스크톱 테이블 컨테이너 (4개)
   - 모바일 멤버 카드 (1개)
   - **절약 예상**: 파일당 8~12줄 * 5개 = 40~60줄

2. `member_filter_panel.dart` (Line 621-625, 644-648, 672-676, 697-700)
   - 필터 상태 표시 카드 (4개)
   - **절약 예상**: 파일당 6~8줄 * 4개 = 24~32줄

3. `recruitment_management_page.dart` (Line 1041, 1149, 1434, 1573, 1616, 1660, 1675, 1746, 1780)
   - 지원자 카드, 질문 카드, 통계 카드 (9개)
   - **절약 예상**: 파일당 10~15줄 * 9개 = 90~135줄

4. `recruitment_detail_page.dart` (Line 192-195)
   - 정보 칩 컨테이너
   - **절약 예상**: 6~8줄

5. `role_management_section.dart` (Line 183-190, 214-221, 280-287, 315-322)
   - 역할 카드 (4개)
   - **절약 예상**: 8~12줄 * 4개 = 32~48줄

6. `recruitment_application_section.dart` (Line 146-152, 166-172, 280-286)
   - 지원자 카드 (3개)
   - **절약 예상**: 8~10줄 * 3개 = 24~30줄

7. `join_request_section.dart` (Line 91-97, 110-116)
   - 가입 요청 카드 (2개)
   - **절약 예상**: 8~10줄 * 2개 = 16~20줄

8. `group_home_view.dart` (Line 279-285, 421-427, 520-526)
   - 공지사항, 활동 요약, 통계 카드 (3개)
   - **절약 예상**: 8~12줄 * 3개 = 24~36줄

9. `place_card.dart` (Line 43)
   - 장소 카드 컨테이너
   - **절약 예상**: 10~15줄

10. `post_preview_card.dart` (Line 40-47)
    - 게시글 미리보기 카드
    - **절약 예상**: 10~15줄

**High Priority 총 절약 예상**: 약 278~441줄

---

### B. 커스텀 props 필요 (Medium Priority) - 약 15개 파일

**특징**:
- 배경색이나 패딩이 다양함
- SectionCard의 props로 대응 가능

**주요 파일**:
1. `group_explore_card.dart` (Line 71-78, 120-127)
   - 브랜드 컬러 배경 + 작은 패딩
   - **적용 방법**: `backgroundColor: AppColors.brandLight, padding: EdgeInsets.all(12)`
   - **절약 예상**: 8~10줄 * 2개 = 16~20줄

2. `action_card.dart` (Line 66-73)
   - 호버 효과 + 테두리
   - **적용 방법**: SectionCard + InkWell 조합
   - **절약 예상**: 8~12줄

3. `post_composer.dart`, `comment_composer.dart` (Line 82, 75)
   - 입력 폼 컨테이너
   - **적용 방법**: `padding: EdgeInsets.all(AppSpacing.md)`
   - **절약 예상**: 8~10줄 * 2개 = 16~20줄

4. `place_usage_management_tab.dart` (Line 617)
   - 사용 신청 카드
   - **절약 예상**: 10~15줄

5. `location_selector.dart` (Line 150, 190, 232)
   - 위치 선택 옵션 카드 (3개)
   - **절약 예상**: 8~10줄 * 3개 = 24~30줄

6. `group_event_form_dialog.dart` (Line 244, 278, 340)
   - 이벤트 폼 섹션 (3개)
   - **절약 예상**: 8~12줄 * 3개 = 24~36줄

**Medium Priority 총 절약 예상**: 약 106~143줄

---

### C. 특수 패턴 (Low Priority / 적용 불가) - 약 30개 파일

**특징**:
- 복잡한 인터랙션 (호버, 선택 상태)
- 동적 스타일 변경
- 특수한 UI 요구사항

**제외 대상**:
1. `post_item.dart` (Line 180-188)
   - 호버 상태에 따른 동적 테두리
   - **이유**: 호버 효과가 핵심 기능

2. `selectable_option_card.dart` (Line 70-77)
   - 선택 상태에 따른 스타일 변경
   - **이유**: 선택 UI 로직이 복잡함

3. `post_skeleton.dart` (Line 21, 38, 47, 59, 68, 77, 87)
   - 스켈레톤 로딩 애니메이션
   - **이유**: 애니메이션 컬러가 고정되지 않음

4. `avatar_popup_menu.dart` (Line 43, 104, 136)
   - 팝업 메뉴 항목
   - **이유**: 메뉴 UI 패턴이 독립적

5. `external_events_overlay.dart` (Line 298, 360, 423)
   - 캘린더 이벤트 오버레이
   - **이유**: 캘린더 UI 전용 스타일

6. `event_block.dart`, `place_calendar_tab.dart` 등 캘린더 관련 파일
   - **이유**: 캘린더 전용 디자인 시스템

7. `time_spinner.dart`, `cupertino_time_picker.dart`
   - **이유**: 시스템 UI 컴포넌트

---

## 3. 적용 전략

### Phase 1: High Priority 파일 (Week 1)

**목표**: 핵심 섹션 카드 20개 파일 교체 → 약 280~440줄 절약

**작업 순서**:
1. `member_list_section.dart` (5개 패턴)
2. `recruitment_management_page.dart` (9개 패턴)
3. `role_management_section.dart` (4개 패턴)
4. `group_home_view.dart` (3개 패턴)
5. 나머지 15개 파일 (각 1~2개 패턴)

**검증 체크리스트**:
- [ ] 시각적 일관성 확인 (before/after 스크린샷)
- [ ] 반응형 레이아웃 테스트 (900px 브레이크포인트)
- [ ] 패딩/그림자/테두리 동일성 확인
- [ ] 기존 기능 정상 작동 (인터랙션, 상태 관리)

---

### Phase 2: Medium Priority 파일 (Week 2)

**목표**: 커스텀 props 활용하여 15개 파일 교체 → 약 106~143줄 절약

**작업 순서**:
1. `group_explore_card.dart` (배경색 커스텀)
2. `action_card.dart` (InkWell 조합 패턴)
3. `post_composer.dart`, `comment_composer.dart` (입력 폼)
4. 나머지 12개 파일

**검증 체크리스트**:
- [ ] 커스텀 props 정상 동작 확인
- [ ] 배경색/패딩 변형 테스트
- [ ] 기존 UI 일치 여부 확인

---

### Phase 3: 리팩토링 최적화 (Week 3)

**목표**: 추가 최적화 및 문서화

**작업 내용**:
1. SectionCard 컴포넌트 확장 (필요 시)
   - `border` prop 추가 (테두리 커스텀)
   - `elevation` prop 추가 (그림자 강도 조절)
2. 적용 불가 패턴 문서화
3. 디자인 시스템 가이드 업데이트

---

## 4. 예상 효과

### 정량적 효과

- **코드 절약**: 약 386~584줄 (Phase 1 + Phase 2)
- **파일 수**: 35개 파일 개선
- **패턴 통일**: 40~50개 Container + BoxDecoration → SectionCard

### 정성적 효과

1. **유지보수성 향상**:
   - 디자인 시스템 변경 시 SectionCard만 수정하면 전체 반영
   - 예: 카드 그림자 강도 조절 → 1개 파일만 수정

2. **코드 가독성 개선**:
   - 10줄 BoxDecoration → 3줄 SectionCard
   - 의도가 명확한 컴포넌트 이름

3. **일관성 강화**:
   - 모든 카드가 동일한 스타일 (20px 모서리, 그림자)
   - 디자인 토큰(AppSpacing, AppRadius) 자동 적용

---

## 5. 위험 요소 및 대응

### 위험 1: 시각적 차이 발생

**원인**: 기존 BoxDecoration이 미묘하게 다른 값 사용
**대응**: Before/After 스크린샷 비교, 디자이너 리뷰

### 위험 2: 반응형 레이아웃 깨짐

**원인**: 패딩 변경으로 인한 레이아웃 변화
**대응**: 900px 브레이크포인트 테스트, 모바일/데스크톱 확인

### 위험 3: 기능 회귀 버그

**원인**: 컨테이너 구조 변경으로 인한 인터랙션 오류
**대응**: 주요 기능 E2E 테스트, 수동 QA

---

## 6. 다음 단계

1. **승인 대기**: 사용자 확인 후 Phase 1 시작
2. **브랜치 생성**: `feature/apply-section-card-phase1`
3. **작업 시작**: `member_list_section.dart`부터 순차 적용
4. **커밋 단위**: 파일당 1개 커밋 (예: `refactor: Apply SectionCard to member_list_section`)
5. **PR 생성**: Phase 1 완료 후 리뷰 요청

---

## 부록: SectionCard 적용 예시

### Before (기존 코드)
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(color: AppColors.neutral300),
  ),
  child: Column(
    children: [
      Text('멤버 목록'),
      // ...
    ],
  ),
)
```

### After (SectionCard 적용)
```dart
SectionCard(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      Text('멤버 목록'),
      // ...
    ],
  ),
)
```

**절약**: 10줄 → 6줄 (4줄 절약)

---

**작성자**: Frontend Development Specialist
**리뷰 요청**: 사용자 확인 필요
