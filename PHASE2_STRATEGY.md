# SectionCard Phase 2 적용 전략 문서

작성일: 2025-10-25
작성자: Frontend Specialist Agent
브랜치: palce_callendar

## 📋 현황 분석

### Phase 1 완료 현황
- **적용 파일**: 8개
- **코드 절약**: 187줄
- **적용 패턴**: 기본 Container + BoxDecoration (흰색 배경, 기본 패딩, 기본 그림자)

### Phase 2 목표
- **대상 파일**: 79개 (Container + BoxDecoration 패턴 사용)
- **예상 절약**: 100-150줄
- **난이도**: Medium (커스텀 props 필요한 경우 다수)

## 🔍 SectionCard 현재 기능 확인

### 지원하는 Props (✅)
```dart
class SectionCard extends StatelessWidget {
  final Widget child;              // 필수
  final EdgeInsets? padding;       // 커스텀 패딩 ✅
  final bool showShadow;           // 그림자 표시 여부 ✅
  final Color? backgroundColor;    // 배경색 커스터마이징 ✅
  final double? borderRadius;      // 테두리 반경 ✅
}
```

### 현재 지원하지 않는 기능 (❌)
1. **onTap 콜백**: InkWell/GestureDetector 통합 ❌
2. **border 커스터마이징**: 테두리 색상/두께 세밀 제어 ❌
3. **gradient 배경**: 그라데이션 배경색 ❌
4. **elevation 세밀 제어**: 그림자 높이 조절 ❌

## 📊 대상 파일 분류

### Category A: 바로 적용 가능 (High Priority) - 30개
**특징**: 기본 SectionCard props만으로 대체 가능
- 흰색 배경 + 기본 패딩 + 기본 그림자
- InkWell 없음
- 특수한 border/decoration 없음

**예상 효과**: 60-80줄 절약

**샘플 파일**:
- `recruitment_detail_page.dart` (64-70줄): 에러 배너 - 커스텀 배경색만 필요
- `group_explore_page.dart` (64-89줄): 에러 배너 - 커스텀 배경색 + border
- `demo_member_filter_page.dart`: 여러 섹션 컨테이너

**적용 방식**:
```dart
// Before (group_explore_page.dart L64-89)
Container(
  padding: const EdgeInsets.all(AppSpacing.sm),
  decoration: BoxDecoration(
    color: AppColors.error.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(AppRadius.button),
    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
  ),
  child: Row(...),
)

// After
SectionCard(
  padding: const EdgeInsets.all(AppSpacing.sm),
  backgroundColor: AppColors.error.withValues(alpha: 0.1),
  borderRadius: AppRadius.button,
  showShadow: false,
  child: Row(...),
)
// ⚠️ border 속성이 없어서 border는 손실됨
```

### Category B: SectionCard 확장 필요 (Medium Priority) - 25개
**특징**: InkWell/GestureDetector와 조합
- 클릭 가능한 카드 (onTap 필요)
- 커스텀 배경색 사용
- 특수한 border 효과

**예상 효과**: 40-50줄 절약 (확장 후)

**샘플 파일**:
- `channel_list_section.dart` (89-112줄): Card + InkWell 조합
- `action_card.dart`: InkWell + Container (이미 전용 컴포넌트)
- `group_tree_node_widget.dart`: 클릭 가능한 노드

**필요한 확장**:
```dart
class SectionCard extends StatelessWidget {
  // 기존 props...
  final VoidCallback? onTap;           // 🆕 추가 필요
  final Color? borderColor;            // 🆕 추가 필요
  final double? borderWidth;           // 🆕 추가 필요
}
```

**확장 후 적용 방식**:
```dart
// Before (channel_list_section.dart L89-112)
Card(
  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
  child: InkWell(
    onTap: () => _handleChannelTap(context, channel),
    borderRadius: BorderRadius.circular(AppRadius.card),
    child: Padding(...),
  ),
)

// After
SectionCard(
  onTap: () => _handleChannelTap(context, channel),
  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
  child: ...,
)
```

### Category C: 제외 대상 (Low Priority / Exclude) - 24개
**특징**: 너무 특수하거나 이미 전용 컴포넌트
- 아이콘 컨테이너 (작은 크기, 특수 목적)
- 뱃지/칩 컴포넌트 (별도 디자인 시스템)
- 복잡한 gradient/animation
- 이미 전용 컴포넌트로 분리됨 (ActionCard, PlaceCard 등)

**예상 효과**: 0줄 (적용 안 함)

**샘플 파일**:
- `channel_list_section.dart` (100-112줄): 아이콘 컨테이너 (40x40)
- `channel_list_section.dart` (131-149줄): 뱃지 컨테이너 (작은 라벨)
- `action_card.dart`: 이미 ActionCard 전용 컴포넌트
- `place_card.dart`: 이미 PlaceCard 전용 컴포넌트
- `time_spinner.dart`, `cupertino_time_picker.dart`: 특수 UI 컴포넌트
- `event_card.dart`, `event_block.dart`: 캘린더 전용 컴포넌트

## 🎯 권장 전략: 하이브리드 (전략 C)

### 선택 근거
1. **SectionCard 단순성 유지**: 너무 많은 props 추가 → 복잡도 증가
2. **실용적 접근**: 가장 많은 ROI를 가져오는 Category A부터 시작
3. **점진적 확장**: 필요 시 최소한의 props만 추가 (onTap, border)

### 단계별 실행 계획

#### Step 1: Category A 적용 (우선순위 1) ⏱️ 2-3시간
- **대상**: 30개 파일
- **방법**: 현재 SectionCard만으로 적용
- **주의**: border 속성 손실 시 디자인 리뷰 필요

#### Step 2: 중간 빌드 테스트 ⏱️ 30분
- `flutter run -d chrome --web-hostname localhost --web-port 5173`
- 레이아웃 깨짐 확인
- 명암 대비 확인 (접근성)

#### Step 3: SectionCard 확장 검토 ⏱️ 1시간
- Category B 분석 결과 기반
- onTap, borderColor, borderWidth 추가 여부 결정
- 기존 사용처 영향 분석

#### Step 4: Category B 적용 (선택사항) ⏱️ 2-3시간
- SectionCard 확장 완료 후
- 25개 파일 적용

#### Step 5: 최종 빌드 테스트 ⏱️ 30분
- 전체 기능 테스트
- 회귀 테스트

#### Step 6: 문서화 및 커밋 ⏱️ 30분
- MEMO_component_analysis.md 업데이트
- 커밋 (feat: SectionCard Phase 2 적용)

### 예상 총 소요 시간
- **최소** (Step 1-2만): 2.5-3.5시간
- **최대** (Step 1-5 전체): 6-8시간

## ⚠️ 주의사항 체크리스트

### 🔴 필수 확인사항
- [ ] **Row/Column 제약 조건**: SectionCard 내부에서 Expanded/Flexible 사용 확인
- [ ] **기존 사용처 영향**: Phase 1 적용 파일 (8개) 정상 작동 확인
- [ ] **디자인 시스템 준수**: AppColors, AppSpacing, AppRadius 토큰 사용
- [ ] **빌드 테스트**: 각 단계 후 flutter run으로 확인

### 🟡 중요 확인사항
- [ ] **접근성**: 커스텀 배경색 사용 시 명암 대비 4.5:1 이상
- [ ] **InkWell 효과**: onTap 있는 경우 적절한 ripple 효과
- [ ] **null 안전성**: 모든 옵셔널 props에 기본값 설정
- [ ] **성능**: Consumer/watch() 불필요한 리빌드 방지

### 🟢 권장 확인사항
- [ ] **코드 리뷰**: 적용 전후 코드 비교
- [ ] **문서 업데이트**: MEMO_component_analysis.md 반영
- [ ] **테스트 커버리지**: StateView와 함께 사용되는 경우 확인

## 🚨 자주 하는 실수 (회피 방법)

### 실수 1: SectionCard 내부에서 무한 크기 에러
**증상**: "BoxConstraints forces an infinite width/height"
**원인**: Row/Column 내부에서 Expanded/Flexible 누락
**해결**:
```dart
// ❌ 잘못된 예
SectionCard(
  child: Row(
    children: [
      Text('긴 텍스트...'), // 에러 발생
    ],
  ),
)

// ✅ 올바른 예
SectionCard(
  child: Row(
    children: [
      Expanded(child: Text('긴 텍스트...')),
    ],
  ),
)
```

### 실수 2: border 속성 손실로 디자인 변경
**증상**: 적용 후 테두리가 사라짐
**원인**: 현재 SectionCard는 border 세밀 제어 불가
**해결**:
- **Option A**: border 필요한 경우 Category B로 분류, 확장 후 적용
- **Option B**: border가 중요하지 않으면 제거하고 디자인 리뷰

### 실수 3: InkWell 효과 없어짐
**증상**: 클릭 시 ripple 효과 사라짐
**원인**: SectionCard가 onTap을 지원하지 않음
**해결**:
- Category B로 분류
- SectionCard 확장 후 적용

### 실수 4: 과도한 SectionCard 확장
**증상**: props가 10개 이상으로 증가
**원인**: 모든 use case를 커버하려는 시도
**해결**:
- **80-20 원칙**: 80%의 use case만 커버
- 특수한 경우는 별도 컴포넌트 사용 (ActionCard, PlaceCard 등)

### 실수 5: 작은 컨테이너에 적용
**증상**: 아이콘 배경, 뱃지 등에 SectionCard 적용
**원인**: "모든 Container를 SectionCard로" 잘못된 일반화
**해결**:
- **기준**: 패딩이 AppSpacing.md (16px) 이상인 경우만 적용
- 작은 UI 요소는 inline Container 유지

## 📈 예상 효과 및 리스크

### 긍정적 효과
1. **코드 감소**: 100-150줄 추가 절약 (Phase 1 187줄 + Phase 2 100-150줄 = 총 287-337줄)
2. **일관성**: 모든 카드 컨테이너가 동일한 스타일
3. **유지보수성**: 디자인 변경 시 1곳만 수정
4. **개발 속도**: 새 페이지 개발 시 재사용

### 리스크 및 완화 방안
1. **SectionCard 복잡도 증가**
   - 리스크: props 과다 추가 → 사용하기 어려움
   - 완화: 최소한의 props만 추가 (onTap, borderColor, borderWidth)
   - 완화: 모든 추가 props를 옵셔널로, 합리적 기본값 설정

2. **기존 사용처 영향**
   - 리스크: Phase 1 적용 파일 (8개)에 버그 발생
   - 완화: 확장 시 기존 동작 유지 (기본값 동일)
   - 완화: 단계별 빌드 테스트

3. **디자인 일관성 저하**
   - 리스크: border 손실로 일부 UI 변경
   - 완화: 디자인 리뷰 필수
   - 완화: 중요한 border는 확장 후 적용

4. **과도한 시간 투입**
   - 리스크: 모든 파일 적용 시 8시간 이상 소요
   - 완화: Category A만 우선 적용 (2-3시간)
   - 완화: ROI가 낮은 Category C는 제외

## 🎬 실행 결정

### 권장 접근 (Recommended)
1. **Phase 2-A**: Category A 30개 파일 적용 (현재 SectionCard로 가능)
2. **빌드 테스트 및 리뷰**
3. **필요 시 Phase 2-B**: SectionCard 확장 → Category B 25개 파일 적용

### 보수적 접근 (Conservative)
1. **샘플 3-5개** 파일만 적용
2. **빌드 테스트 및 사용자 피드백**
3. **점진적 확대**

### 공격적 접근 (Aggressive) - ⚠️ 비추천
1. SectionCard를 10+ props로 대폭 확장
2. 모든 79개 파일 일괄 적용
3. **리스크**: 복잡도 폭증, 버그 가능성 높음

## 📝 다음 단계 제안

### 즉시 실행 가능
1. ✅ **이 문서 검토 및 승인 대기**
2. ⏳ **Category A 파일 목록 상세 작성** (30개 파일 전체 경로)
3. ⏳ **샘플 3개 파일 먼저 적용** (proof of concept)

### 승인 후 실행
1. Category A 전체 적용
2. 중간 빌드 테스트
3. Category B 필요성 재평가

## 📚 참조 문서
- [MEMO_component_analysis.md](./MEMO_component_analysis.md) - Phase 1 완료 현황
- [docs/implementation/frontend/components.md](./docs/implementation/frontend/components.md) - 컴포넌트 구현 가이드
- [docs/implementation/row-column-layout-checklist.md](./docs/implementation/row-column-layout-checklist.md) - 레이아웃 에러 방지
- [docs/ui-ux/concepts/design-system.md](./docs/ui-ux/concepts/design-system.md) - 디자인 시스템
- [SectionCard 소스](./frontend/lib/presentation/widgets/common/section_card.dart)

---

**최종 권장사항**: **하이브리드 전략 (Category A 우선 적용)**으로 시작하여, 2-3시간 투입으로 60-80줄 절약하고, 필요 시 확장 검토.
