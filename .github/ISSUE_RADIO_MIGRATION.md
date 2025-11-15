# [Tech Debt] Radio 위젯을 RadioGroup으로 마이그레이션

## 📋 요약
Flutter 3.32.0+에서 `Radio` 위젯의 `groupValue`와 `onChanged` 속성이 deprecated 되었습니다. 새로운 `RadioGroup` 위젯으로 마이그레이션하여 접근성을 향상시키고 경고를 제거해야 합니다.

---

## 🔍 문제 설명

### 현재 상태
`create_subgroup_dialog.dart` 파일에서 `Radio<String>` 위젯을 사용할 때 deprecated 경고를 무시하고 있습니다:

**파일**: `lib/presentation/widgets/dialogs/create_subgroup_dialog.dart`
**라인**: 408-420

```dart
// ignore: deprecated_member_use
Radio<String>(
  value: value,
  // ignore: deprecated_member_use
  groupValue: _selectedType,
  // ignore: deprecated_member_use
  onChanged: _isSubmitting
      ? null
      : (val) {
          setState(() {
            _selectedType = val!;
          });
        },
  activeColor: AppColors.brand,
),
```

### 경고 개수
- **3개의 `// ignore: deprecated_member_use` 지시문** 사용 중

---

## 📚 배경: 왜 Deprecated 되었나?

### Flutter API 변경 (v3.32.0+)
Flutter는 **ARIA Practices Guide(APG)** 접근성 표준을 준수하기 위해 Radio 위젯 API를 재설계했습니다.

### 주요 변경사항
1. **RadioGroup 도입**: Radio 버튼 그룹의 상태와 이벤트를 중앙 관리
2. **키보드 네비게이션**: 방향키로 Radio 간 이동 자동 지원
3. **접근성 개선**: 스크린 리더 지원 강화

### 공식 문서
- [Radio API Redesign - Flutter Breaking Changes](https://docs.flutter.dev/release/breaking-changes/radio-api-redesign)
- [GitHub Issue #170915](https://github.com/flutter/flutter/issues/170915)
- [Stack Overflow Discussion](https://stackoverflow.com/questions/79748989/flutter-3-35-2-what-is-the-replacement-for-deprecated-groupvalue-and-onchanged)

---

## 🎯 마이그레이션 계획

### Before (현재 - Deprecated)
```dart
Widget _buildGroupTypeField() {
  return Column(
    children: [
      _buildRadioOption(
        value: 'OFFICIAL',
        title: '공식 그룹',
        description: '...',
      ),
      _buildRadioOption(
        value: 'AUTONOMOUS',
        title: '자율 그룹',
        description: '...',
      ),
    ],
  );
}

Widget _buildRadioOption({required String value, ...}) {
  return InkWell(
    onTap: () { setState(() { _selectedType = value; }); },
    child: Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedType,    // ❌ Deprecated
          onChanged: (val) { ... },     // ❌ Deprecated
        ),
        // ... 설명 텍스트
      ],
    ),
  );
}
```

### After (권장 - RadioGroup)
```dart
Widget _buildGroupTypeField() {
  return RadioGroup<String>(
    groupValue: _selectedType,        // ✅ RadioGroup으로 이동
    onChanged: _isSubmitting
        ? null
        : (val) {
            setState(() {
              _selectedType = val!;
            });
          },
    child: Column(
      children: [
        _buildRadioOption(
          value: 'OFFICIAL',
          title: '공식 그룹',
          description: '...',
        ),
        _buildRadioOption(
          value: 'AUTONOMOUS',
          title: '자율 그룹',
          description: '...',
        ),
      ],
    ),
  );
}

Widget _buildRadioOption({required String value, ...}) {
  final isSelected = _selectedType == value;

  return InkWell(
    // InkWell은 시각적 피드백용으로만 사용
    // 실제 선택은 RadioGroup이 처리
    onTap: null,  // 또는 제거 가능
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.brandLight : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: isSelected ? AppColors.brand : AppColors.lightOutline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Radio<String>(
            value: value,              // ✅ value만 전달
            // groupValue, onChanged 제거
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, ...),
                Text(description, ...),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## ⚠️ 주의사항 및 리스크

### 1. 구조 변경 필요 (🔴 높은 리스크)
- `_buildGroupTypeField()` 메서드 전체 리팩터링 필요
- RadioGroup으로 감싸야 하므로 위젯 트리 구조 변경

### 2. 중복 핸들러 제거 (🟡 중간 리스크)
- 현재: `InkWell.onTap` + `Radio.onChanged` 두 곳에서 setState() 호출
- 변경 후: `RadioGroup.onChanged`로 통합
- InkWell은 시각적 피드백만 담당하도록 변경

### 3. 시각적 피드백 유지 (🟡 중간 리스크)
- 현재의 선택 시 배경색, 테두리 강조 효과 유지 필요
- InkWell의 ripple 효과 동작 검증 필요

### 4. 비활성화 상태 처리
- `_isSubmitting` 상태일 때 Radio 비활성화
- RadioGroup의 `onChanged: null`로 처리 가능

### 5. 테스트 영향
- 위젯 테스트가 있다면 수정 필요
- 통합 테스트에서 Radio 선택 시나리오 재검증 필요

---

## ✅ 체크리스트

### Phase 1: 준비 단계
- [ ] Flutter 버전 확인 (3.32.0+ 필요)
- [ ] RadioGroup API 문서 숙지
- [ ] 현재 동작 스크린샷/비디오 캡처 (비교용)
- [ ] 관련 테스트 파일 식별

### Phase 2: 구현 단계
- [ ] `_buildGroupTypeField()` 메서드 리팩터링
  - [ ] RadioGroup 래퍼 추가
  - [ ] groupValue, onChanged 이동
  - [ ] _isSubmitting 조건 처리
- [ ] `_buildRadioOption()` 메서드 수정
  - [ ] Radio에서 groupValue, onChanged 제거
  - [ ] InkWell 핸들러 조정 (또는 제거)
  - [ ] 시각적 피드백 유지 확인
- [ ] `// ignore` 주석 제거

### Phase 3: 검증 단계
- [ ] 빌드 성공 확인
- [ ] 경고 메시지 제거 확인 (3개 → 0개)
- [ ] 기능 테스트
  - [ ] OFFICIAL 선택 동작
  - [ ] AUTONOMOUS 선택 동작
  - [ ] 선택 시 시각적 피드백 (배경색, 테두리)
  - [ ] 비활성화 상태 (_isSubmitting=true)
  - [ ] 키보드 네비게이션 (Tab, 방향키)
- [ ] 반응형 테스트
  - [ ] 데스크톱 레이아웃
  - [ ] 모바일 레이아웃
- [ ] 접근성 테스트
  - [ ] 스크린 리더 테스트
  - [ ] 키보드 전용 네비게이션

### Phase 4: 마무리
- [ ] 코드 리뷰 요청
- [ ] 변경사항 문서화
- [ ] PR 생성 및 머지
- [ ] 관련 문서 업데이트 (필요시)

---

## 📦 영향 범위

### 수정 필요 파일
- `lib/presentation/widgets/dialogs/create_subgroup_dialog.dart`
  - `_buildGroupTypeField()` (341-375줄)
  - `_buildRadioOption()` (378-449줄)

### 영향받는 기능
- 하위 그룹 생성 다이얼로그
- 그룹 타입 선택 UI (OFFICIAL / AUTONOMOUS)

### 영향받는 사용자 플로우
1. 그룹 관리자가 "하위 그룹 만들기" 클릭
2. 다이얼로그에서 그룹 타입 선택
3. 선택 상태 시각적 피드백 확인
4. 폼 제출

---

## 📊 우선순위 및 예상 작업 시간

| 항목 | 값 |
|------|-----|
| **우선순위** | 🟡 Medium (기술 부채) |
| **심각도** | 🟢 Low (현재 동작 정상) |
| **예상 작업 시간** | 2-4시간 |
| **테스트 시간** | 1-2시간 |
| **총 소요 시간** | 3-6시간 |

### 우선순위 근거
- ✅ 현재 기능은 완벽히 작동 중
- ⚠️ 경고 3개 발생 (무시 처리됨)
- 📌 미래 Flutter 버전 대응 필요
- 🎯 접근성 향상 효과

---

## 🔗 참고 자료

### 공식 문서
- [Flutter Breaking Changes: Radio API Redesign](https://docs.flutter.dev/release/breaking-changes/radio-api-redesign)
- [Radio Class - Flutter API](https://api.flutter.dev/flutter/material/Radio-class.html)
- [RadioGroup Class - Flutter API](https://api.flutter.dev/flutter/material/RadioGroup-class.html)

### GitHub Issues
- [Issue #170915: groupValue and onChanged are deprecated](https://github.com/flutter/flutter/issues/170915)
- [Issue #175355: Migrate radio list tile example](https://github.com/flutter/flutter/issues/175355)

### Stack Overflow
- [Flutter 3.35.2: Radio widget deprecation replacement](https://stackoverflow.com/questions/79748989/flutter-3-35-2-what-is-the-replacement-for-deprecated-groupvalue-and-onchanged)

### 관련 커밋
- `c77bc99` - refactor(theme): 사용되지 않는 deprecated 색상 상수 제거 (Phase 1 완료)

---

## 💡 추가 제안

### 다른 Radio 사용 위치 확인
프로젝트 전체에서 Radio 위젯을 사용하는 곳이 더 있는지 확인:
```bash
grep -r "Radio<" lib --include="*.dart" -l
```

만약 다른 곳에서도 Radio를 사용한다면 함께 마이그레이션하는 것이 효율적입니다.

### 컴포넌트 추출 고려
RadioGroup을 사용하는 재사용 가능한 컴포넌트를 만들 수 있습니다:
- `AppRadioGroup` - RadioGroup + 스타일링
- `AppRadioOption` - Radio + 설명 카드

---

## 🏷️ Labels
- `tech-debt`
- `enhancement`
- `accessibility`
- `flutter-upgrade`
- `good-first-issue` (명확한 마이그레이션 가이드 제공됨)
- `low-priority`

---

## 👥 Assignees
- TBD

## 📅 Milestone
- TBD (여유 있을 때 진행)

---

**작성일**: 2025-11-12
**작성자**: Claude (AI Assistant)
**관련 브랜치**: `claude/fix-flutter-build-errors-011CV3cyAWZEJPexiWPGwX3q`
