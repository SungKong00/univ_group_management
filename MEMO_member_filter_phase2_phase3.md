# 멤버 필터 Phase 2 & 3 구현 메모

## 작업 일시
2025-10-24

## 구현 내용

### Phase 2: 모바일 바텀 시트 최적화

#### 1. PopScope 추가 (WillPopScope 대체)
- **위치**: `member_list_section.dart` `_showFilterBottomSheet` 메서드
- **목적**: 뒤로가기 시 드래프트 상태 유지하며 바텀 시트만 닫기
- **구현**:
  - Flutter 3.12 이후 `WillPopScope` deprecated → `PopScope` 사용
  - `canPop: true` 설정하여 뒤로가기 허용
  - 드래프트 필터는 MemberFilterNotifier 내부에서 자동 보존

#### 2. SafeArea 적용
- **위치**: 바텀 시트 Container 내부
- **목적**: 노치/홈 인디케이터 영역 고려한 레이아웃
- **구현**:
  ```dart
  child: SafeArea(
    child: Column(...),
  )
  ```

#### 3. Semantics 레이블 추가 (접근성)
- **헤더 영역**:
  - `Semantics(header: true, label: '멤버 필터 설정')`
- **닫기 버튼**:
  - `Semantics(button: true, label: '필터 닫기')`
- **기존 필터 칩**: 이미 `_RoleFilter`에서 `Semantics` 적용됨

#### 4. 키보드 네비게이션
- Flutter FilterChip 기본 지원으로 자동 처리
- Tab 키로 포커스 이동, Enter/Space로 선택 가능

---

### Phase 3: 예상 결과 개수 미리보기

#### 1. MemberCountProvider 생성
- **파일**: `frontend/lib/core/providers/member/member_count_provider.dart`
- **기능**:
  - 드래프트 필터 기반 멤버 개수 API 조회
  - 300ms 디바운싱으로 불필요한 API 호출 방지
  - memberRepository 사용 (기존 인프라 재사용)

- **Provider 구조**:
  ```dart
  // 내부 파라미터 기반 Provider
  final memberCountProvider = FutureProvider.family<int, _MemberCountParams>(...)

  // 드래프트 필터 자동 감지 Provider (편의 래퍼)
  final draftMemberCountProvider = FutureProvider.family<int, int>(...)
  ```

- **디바운싱 로직**:
  ```dart
  await Future.delayed(const Duration(milliseconds: 300));
  ```

#### 2. UI 구현 (_ActionSection 확장)
- **위치**: `member_filter_panel.dart` `_ActionSection` 위젯
- **표시 조건**: 드래프트 필터가 활성화되어 있을 때 (`draftFilter.isActive`)
- **상태별 UI**:

  **2.1 데이터 로드 성공 (data)**:
  ```dart
  Container(
    color: AppColors.actionTonalBg,
    border: Border.all(color: AppColors.action.withOpacity(0.2)),
    child: Row([
      Icon(Icons.info_outline, color: AppColors.action),
      Text('예상 결과: N명', color: AppColors.action),
    ])
  )
  ```

  **2.2 로딩 중 (loading)**:
  ```dart
  Container(
    color: AppColors.neutral100,
    child: Row([
      CircularProgressIndicator(size: 14, strokeWidth: 2),
      Text('결과 개수 확인 중...', color: AppColors.neutral600),
    ])
  )
  ```

  **2.3 에러 발생 (error)**:
  ```dart
  Container(
    color: AppColors.error.withOpacity(0.1),
    child: Row([
      Icon(Icons.error_outline, color: AppColors.error),
      Text('결과 개수를 불러올 수 없습니다', color: AppColors.error),
    ])
  )
  ```

#### 3. 레이아웃 순서
- **우선순위**: 예상 결과 → 변경 사항 칩 → 버튼 영역
- **간격**: `AppSpacing.sm` (16px)

---

## 디자인 시스템 준수 사항

### 컬러 (Phase 3)
- **예상 결과 배경**: `AppColors.actionTonalBg` (블루 톤)
- **예상 결과 텍스트**: `AppColors.action` (블루)
- **로딩 배경**: `AppColors.neutral100`
- **에러 배경**: `AppColors.error.withOpacity(0.1)`

### 간격
- **내부 패딩**: 12px (horizontal), 8px (vertical)
- **섹션 간격**: `AppSpacing.sm` (16px)

### 타이포그래피
- **본문**: `AppTheme.bodySmall` (12px/400)
- **강조**: `fontWeight: FontWeight.w600`

### 아이콘
- **크기**: 14-16px
- **색상**: 컨텍스트에 따라 action / neutral600 / error

---

## 성능 최적화

### 1. 디바운싱
- **구현 위치**: `memberCountProvider`
- **시간**: 300ms
- **효과**: 사용자가 필터를 빠르게 변경할 때 중간 상태의 API 호출 방지

### 2. Provider 캐싱
- `FutureProvider.family` 사용으로 동일한 필터 조합 자동 캐싱
- 드래프트 필터 변경 시에만 새로운 Provider 인스턴스 생성

### 3. API 요청 최적화
- 기존 `memberRepository` 재사용
- 필터가 비어있을 때와 있을 때 동일한 API 엔드포인트 사용
- 쿼리 파라미터로 필터 전달

---

## 파일 구조

```
frontend/lib/
├── core/
│   └── providers/
│       └── member/
│           ├── member_filter_provider.dart       (기존)
│           ├── member_list_provider.dart         (기존)
│           └── member_count_provider.dart        (NEW - Phase 3)
└── presentation/
    └── pages/
        └── member_management/
            └── widgets/
                ├── member_filter_panel.dart      (UPDATED - Phase 1,3)
                └── member_list_section.dart      (UPDATED - Phase 2)
```

---

## 구현 체크리스트

### Phase 2: 모바일 바텀 시트 최적화
- [x] WillPopScope → PopScope 교체
- [x] SafeArea 적용
- [x] Semantics 레이블 추가 (헤더, 닫기 버튼)
- [x] 키보드 네비게이션 (FilterChip 기본 지원)

### Phase 3: 예상 결과 개수 미리보기
- [x] memberCountProvider 생성
- [x] 300ms 디바운싱 구현
- [x] draftMemberCountProvider 편의 래퍼
- [x] UI: 데이터 로드 성공 상태
- [x] UI: 로딩 상태
- [x] UI: 에러 상태
- [x] _ActionSection에 통합

---

## 테스트 체크리스트

### Phase 2 테스트
- [ ] 모바일 바텀 시트 열기/닫기
- [ ] 뒤로가기 버튼으로 바텀 시트 닫기 → 드래프트 유지 확인
- [ ] SafeArea 영역 확인 (노치 디바이스)
- [ ] 스크린 리더로 Semantics 레이블 확인
- [ ] Tab 키로 포커스 이동, Enter/Space로 선택

### Phase 3 테스트
- [ ] 필터 선택 시 예상 결과 개수 표시
- [ ] 로딩 스피너 표시 (300ms 이내)
- [ ] 에러 발생 시 에러 메시지 표시
- [ ] 필터 변경 시 디바운싱 작동 확인
- [ ] 필터 초기화 시 예상 결과 숨김
- [ ] 적용 버튼 클릭 시 실제 결과와 예상 결과 일치

### 통합 테스트
- [ ] Phase 1 (드래프트 분리) + Phase 2 (바텀 시트) + Phase 3 (예상 결과) 동시 작동
- [ ] 데스크톱/모바일 반응형 레이아웃
- [ ] 전체 워크플로우: 필터 선택 → 예상 결과 확인 → 적용 → 실제 결과 확인

---

## 알려진 이슈

### 1. withOpacity deprecated 경고
- **위치**: `member_filter_panel.dart` (3곳)
- **원인**: Flutter 3.27+ `.withOpacity()` deprecated
- **해결 방안**: `.withValues()` 사용 (추후 리팩토링)
- **영향**: 기능 정상 작동, 경고만 발생

### 2. sort_child_properties_last
- **위치**: `member_filter_panel.dart` (2곳)
- **원인**: child 속성이 마지막에 위치하지 않음
- **해결 방안**: 코드 스타일 조정 (추후 리팩토링)
- **영향**: 기능 정상 작동, 린트 경고만 발생

---

## 다음 단계 (추후 개선 사항)

### 1. Phase 4: 키보드 단축키
- [ ] Ctrl/Cmd + F: 필터 패널 포커스
- [ ] Esc: 바텀 시트 닫기
- [ ] Ctrl/Cmd + Enter: 필터 적용

### 2. Phase 5: 필터 프리셋
- [ ] 자주 사용하는 필터 조합 저장
- [ ] 프리셋 빠른 적용
- [ ] 최근 사용한 필터 히스토리

### 3. Phase 6: 고급 필터
- [ ] 날짜 범위 필터 (가입일 기준)
- [ ] 복합 조건 필터 (AND/OR 조합)
- [ ] 커스텀 필드 필터

---

## 참고 문서

- `/docs/implementation/frontend/member-list-implementation.md`
- `/docs/ui-ux/components/member-list-component.md`
- `/docs/ui-ux/concepts/design-system.md`
- `/docs/ui-ux/concepts/design-tokens.md`

---

## 트러블슈팅

### 1. 디바운싱 중복 호출 방지
- **문제**: 필터 변경 시 여러 Provider가 동시에 호출됨
- **해결**: `FutureProvider.family`의 파라미터 기반 캐싱 활용
- **결과**: 동일한 필터 조합은 1번만 API 호출

### 2. 드래프트 필터 감지
- **문제**: `draftFilter`가 private이라 외부에서 접근 불가
- **해결**: `MemberFilterNotifier`에 `draftFilter` getter 추가
- **결과**: Provider에서 드래프트 상태 감지 가능

### 3. Row/Column 제약 확인
- **확인 사항**: 모든 Row 자식에 Expanded 적용
- **결과**: 레이아웃 에러 없음

---

## 문서 업데이트 필요 사항

### 1. 구현 가이드
- `docs/implementation/frontend/member-list-implementation.md` 업데이트
  - Phase 2, 3 내용 추가
  - 최종 아키텍처 다이어그램

### 2. UI/UX 문서
- `docs/ui-ux/components/member-list-component.md` 업데이트
  - 예상 결과 개수 UI 스펙
  - 접근성 가이드라인

### 3. 성능 최적화 문서
- `docs/implementation/frontend/performance.md` 업데이트
  - 디바운싱 패턴 추가
  - Provider 캐싱 전략
