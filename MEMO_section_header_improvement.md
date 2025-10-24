# SectionHeader 개선 작업 분석 메모

## 작업 날짜
2025-10-24

## 1. 현재 SectionHeader 컴포넌트 분석

### 위치
`frontend/lib/presentation/widgets/common/section_header.dart`

### 현재 구조
```dart
SectionHeader(
  title: String (필수),
  subtitle: String? (선택),
  trailing: Widget? (선택),
  titleStyle: TextStyle? (선택),
  subtitleStyle: TextStyle? (선택),
)
```

### 현재 구현의 장점
- ✅ Row/Column 레이아웃 제약 조건 준수 (Expanded 사용)
- ✅ 디자인 토큰 활용 (AppTheme, AppSpacing)
- ✅ trailing 위젯 지원
- ✅ 명확한 주석과 사용 예시

### 현재 구현의 단점
- trailing이 null일 때도 Row의 MainAxisAlignment.spaceBetween 사용 (불필요한 공간 계산)
- subtitle이 null일 때도 Column 계층 구조 유지 (단순화 가능)

## 2. 섹션 헤더 패턴 사용 사례 분석

### 2.1 headlineSmall 스타일 사용 사례 (22개 파일)

#### 직접 적용 가능 - 쉬움 (Simple Title)
1. **group_home_view.dart** (Line 269)
   - `'읽지 않은 글'` - 단순 제목
   - trailing: 없음
   - 난이도: ⭐ (쉬움)

2. **group_recruitment_view.dart** (Line 29)
   - `'모집 공고'` - 플레이스홀더
   - trailing: 없음
   - 난이도: ⭐ (쉬움)

3. **state_view.dart** - 재사용 컴포넌트이므로 제외

#### 특수 케이스 - 중간 (Custom Layout)
4. **group_admin_page.dart** (Line 468)
   - `_AdminSection` 내부의 섹션 헤더
   - Icon + Title + Description 패턴 (커스텀 레이아웃)
   - 난이도: ⭐⭐ (중간) - 기존 구조 유지가 나을 수 있음

5. **group_calendar_page.dart**
   - 달력 헤더 (Line 503: `event.title`)
   - 특수 레이아웃 (이벤트 상세 정보)
   - 난이도: ⭐⭐⭐ (어려움) - 기존 구조 유지 권장

#### 다른 컴포넌트 내부 - 제외
6. **member_list_section.dart** - 멤버 필터 전용
7. **member_filter_panel.dart** - 필터 패널 전용
8. **recruitment_management_page.dart** - 관리 페이지
9. **weekly_schedule_editor.dart** - 시간표 편집기
10. **place_list_page.dart** - 장소 리스트
11. **group_picker_bottom_sheet.dart** - 바텀시트
12. **place_usage_management_tab.dart** - 장소 관리 탭
13. **group_tree_view.dart** - 트리 뷰
14. **place_reservation_dialog.dart** - 예약 다이얼로그
15. **place_form_dialog.dart** - 장소 폼
16. **step_header.dart** - 스텝 헤더 (다른 목적)
17. **event_detail_sheet.dart** - 이벤트 상세
18. **schedule_detail_sheet.dart** - 스케줄 상세
19. **auth/profile_setup_page.dart** - 프로필 설정
20. **subgroup_request_section.dart** - 하위 그룹 요청
21. **section_header.dart** - 컴포넌트 자체
22. **weekly_calendar/** - 주간 캘린더

### 2.2 bold 폰트 + 섹션 제목 패턴 (7개 파일)

1. **recruitment_detail_page.dart**
2. **place_selector_bottom_sheet.dart**
3. **application_submit_dialog.dart**
4. **group_calendar_page.dart** (이미 분석됨)
5. **group_picker_bottom_sheet.dart** (이미 분석됨)
6. **recruitment_card.dart** - 카드 내부
7. **group_card.dart** - 카드 내부

## 3. 주요 발견 사항

### 3.1 실제 적용 가능한 파일
실제로 SectionHeader로 대체 가능한 명확한 케이스는 **극히 제한적**:
- **group_home_view.dart**: `'읽지 않은 글'` 섹션 헤더
- **group_recruitment_view.dart**: `'모집 공고'` 플레이스홀더

대부분의 headlineSmall 사용은:
1. **이벤트/다이얼로그 제목** - SectionHeader가 아닌 제목 텍스트
2. **카드 내부 제목** - 카드 컴포넌트의 일부
3. **커스텀 레이아웃** - 아이콘/배지 등 복잡한 구조

### 3.2 SectionHeader 개선 방향

#### 현재 구현 검토
현재 SectionHeader는 이미 잘 설계되어 있음:
- ✅ Row/Column 제약 준수
- ✅ 디자인 토큰 활용
- ✅ 유연한 trailing 지원
- ✅ 명확한 문서화

#### 미세 개선 가능 사항
1. **조건부 Row 레이아웃**
   ```dart
   // Before: 항상 spaceBetween
   Row(
     mainAxisAlignment: MainAxisAlignment.spaceBetween,
     children: [
       Expanded(child: Text(...)),
       if (trailing != null) trailing!,
     ],
   )

   // After: trailing 없으면 start
   Row(
     mainAxisAlignment: trailing != null
       ? MainAxisAlignment.spaceBetween
       : MainAxisAlignment.start,
     children: [
       Expanded(child: Text(...)),
       if (trailing != null) trailing!,
     ],
   )
   ```

2. **아이콘 지원 추가** (선택)
   ```dart
   final Widget? leading; // 왼쪽 아이콘
   ```

3. **간격 커스터마이징** (선택)
   ```dart
   final double? bottomSpacing; // 기본값: AppSpacing.sm
   ```

## 4. 주의사항 및 체크리스트

### 4.1 Row/Column 레이아웃 제약
- ✅ 현재 구현은 이미 Expanded 사용
- ✅ trailing 위젯도 자동으로 제약 없음 (유연성 유지)
- ⚠️ 개선 시에도 Expanded 유지 필수

### 4.2 디자인 시스템 준수
- ✅ AppTheme.headlineSmallTheme 사용
- ✅ AppSpacing 사용
- ✅ 커스텀 스타일 오버라이드 가능

### 4.3 반응형 고려
- ✅ 텍스트는 자동 줄바꿈
- ✅ trailing은 최소 공간만 차지
- ℹ️ 모바일에서도 문제없이 동작

### 4.4 재사용성 검증
- ✅ 이미 재사용 가능한 컴포넌트
- ✅ 문서화 완료
- ✅ 다양한 사용 예시 제공

## 5. 작업 우선순위 및 추천 사항

### 5.1 우선순위 1 (미세 개선) - 선택 사항
- [ ] Row의 MainAxisAlignment 조건부 적용
- [ ] 추가 테스트: group_home_view.dart에 적용
- 예상 소요 시간: 15분

### 5.2 우선순위 2 (확장 기능) - 보류
- [ ] leading 아이콘 지원 추가
- [ ] bottomSpacing 커스터마이징
- 이유: 현재 사용 사례에서 필요하지 않음
- 예상 소요 시간: 30분

### 5.3 우선순위 3 (적용 확대) - 보류
- [ ] group_home_view.dart 적용
- [ ] group_recruitment_view.dart 적용
- 이유: 기존 코드도 충분히 명확하고 간결함
- 기대 효과: 최소 (2~3줄 절약)

## 6. 결론 및 제안

### 현재 상황
**SectionHeader 컴포넌트는 이미 잘 설계되어 있으며, 대규모 개선이 필요하지 않음.**

### 제안 사항
1. **현재 컴포넌트 유지**: 기존 설계가 우수하므로 큰 변경 불필요
2. **미세 개선만 적용**: Row MainAxisAlignment 조건부 적용 정도만 고려
3. **문서 강화**: 사용 가이드를 docs/implementation/frontend/components.md에 추가
4. **점진적 적용**: 새로운 페이지부터 SectionHeader 사용 권장

### 다음 단계
1. 사용자에게 분석 결과 공유
2. 미세 개선 여부 결정
3. 개선 시 테스트 및 문서 업데이트

---

## 추가 발견: _AdminSection 패턴

group_admin_page.dart의 `_AdminSection`은 SectionHeader보다 더 복잡한 구조:
- Icon + Title + Description (헤더)
- ActionCard 리스트 또는 확장 가능한 콘텐츠 (바디)

이는 별도의 "AdminSection" 컴포넌트로 분리할 가치가 있을 수 있음.
하지만 현재 한 곳에서만 사용되므로 재사용성 기준(3+ 사용처)에 미달.
