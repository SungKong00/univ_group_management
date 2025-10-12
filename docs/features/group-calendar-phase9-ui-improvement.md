# 그룹 캘린더 Phase 9: UI 개선 계획

> **버전**: 1.1
> **작성일**: 2025-10-13
> **최종 수정**: 2025-10-13 (Phase 번호 변경: 6 → 9)
> **상태**: 설계 완료, 구현 대기
> **선행 작업**: [Phase 6 수정/삭제](group-calendar-phase6-edit-delete.md) | [Phase 5 API 연동](group-calendar-phase5-api-integration.md)
> **관련 문서**: [캘린더 시스템](../concepts/calendar-system.md) | [설계 결정사항](../concepts/calendar-design-decisions.md) | [개발 계획](group-calendar-development-plan.md)

---

## 1. Phase 9 개요

### 1.1. 목표

권한 기반 일정 생성 UX 개선 및 재사용 가능한 다단계 선택 컴포넌트 시스템 구축

### 1.2. 배경

**현재 상황 (Phase 6 완료)**:
- ✅ Phase 5: 권한 API 연동 완료 (`GET /api/groups/{groupId}/permissions`)
- ✅ Phase 6: 일정 수정/삭제 기능 구현 완료
- 단일 폼으로 공식/비공식 일정 생성
- 권한 없는 사용자가 공식 일정 토글 시도 시 에러 발생

**문제점**:
- 공식 일정 토글이 숨겨져 있어 권한 소유자가 인지하기 어려움
- 일반 사용자에게 불필요한 옵션 노출
- 향후 TARGETED/RSVP 타입 추가 시 UI 복잡도 증가 예상

**참고**: Phase 7-8은 권한 통합 및 캘린더 뷰 개선으로 예정되어 있으므로, UI 개선은 Phase 9에 배치

---

## 2. ✅ 완료된 작업 (Phase 5)

### 2.1. 권한 API 연동 (완료: 2025-10-13)

**백엔드**:
```kotlin
// GroupEventController.kt
@GetMapping("/api/groups/{groupId}/permissions")
fun getGroupPermissions(
    @PathVariable groupId: Long,
    @AuthenticationPrincipal userId: Long
): Set<GroupPermission>
```

**프론트엔드**:
```dart
// group_permission_service.dart
class GroupPermissionService {
  Future<Set<GroupPermission>> getGroupPermissions(int groupId);
}

// group_permissions_provider.dart
final groupPermissionsProvider = StateNotifierProvider.autoDispose
    .family<GroupPermissionsNotifier, AsyncValue<Set<GroupPermission>>, int>(
  (ref, groupId) => GroupPermissionsNotifier(ref.read(groupPermissionServiceProvider), groupId),
);
```

**통합 테스트**: 3개 (100% 통과)
- 그룹장 권한 조회 성공 (CALENDAR_MANAGE 포함)
- 일반 멤버 권한 조회 성공 (CALENDAR_MANAGE 미포함)
- 비회원 권한 조회 403 Forbidden

### 2.2. GroupCalendarPage 권한 연동 (완료)

```dart
// 권한 로딩 대기 후 UI 렌더링
permissions.maybeWhen(
  data: (perms) {
    final canManageCalendar = perms.contains(GroupPermission.calendarManage);
    return _buildContent(canManageCalendar);
  },
  loading: () => const Center(child: CircularProgressIndicator()),
  orElse: () => const Center(child: Text('권한 로딩 실패')),
);
```

### 2.3. 공식 일정 토글 버그 수정 (완료)

**이슈**: 권한 로딩 전 토글 시 에러 발생
**해결**: maybeWhen으로 loading 상태 처리, data 상태에서만 폼 렌더링

---

## 3. 📋 설계 완료 (구현 대기)

### 3.1. Option C: 다단계 카드 선택 UI (채택)

**설계 결정 이유**:
- 명확한 권한 구분 (관리자 vs 일반 사용자)
- 직관적인 시각적 계층 구조
- 향후 TARGETED/RSVP 타입 확장 용이
- 재사용 가능한 컴포넌트 시스템

### 3.2. UI 플로우

#### Step 1: 공식/비공식 선택 (권한 보유자만)

```
┌─────────────────────────────────────────────┐
│         새 일정 만들기                        │
├─────────────────────────────────────────────┤
│                                             │
│  [📋 공식 일정]           [📝 비공식 일정]    │
│  그룹 전체 공지           개인 메모           │
│  캘린더 관리 권한 필요     누구나 생성 가능    │
│                                             │
└─────────────────────────────────────────────┘
```

#### Step 2: 일정 유형 선택 (Phase 2 구현)

**공식 일정 선택 시**:
```
┌─────────────────────────────────────────────┐
│         공식 일정 유형 선택                    │
├─────────────────────────────────────────────┤
│                                             │
│  [🌍 일반 일정]                              │
│  모든 멤버에게 표시                           │
│                                             │
│  [🎯 대상 지정 일정] (Phase 2)                │
│  특정 멤버만 참여                             │
│                                             │
│  [✅ 참여 신청 일정] (Phase 2)                │
│  선착순 참여 신청                             │
│                                             │
└─────────────────────────────────────────────┘
```

#### Step 3: 일정 상세 정보 입력

기존 `GroupEventFormDialog` 재사용 (제목, 날짜, 시간, 반복 설정 등)

### 3.3. 일반 사용자 플로우

**권한 미보유 시**: Step 1 생략하고 비공식 일정 폼 바로 표시

```dart
if (canManageCalendar) {
  showDialog(context, MultiStepEventCreation());
} else {
  showDialog(context, GroupEventFormDialog(isOfficial: false));
}
```

---

## 4. 🚀 구현 계획 (Phase 1-5)

### 4.1. Atomic Design 컴포넌트 계층

#### Atoms (2-3시간)
- `SelectableOptionCard`: 클릭 가능한 카드 (선택 상태, 리플 효과)
- `OptionIcon`: 이모지 또는 Material Icon
- `OptionText`: 제목 + 설명 텍스트 스타일

#### Molecules (1-2시간)
- `OptionCardGroup`: 카드 리스트 레이아웃 (그리드/수직)
- `StepHeader`: 단계 제목 + 뒤로 가기 버튼

#### Organisms (3-4시간)
- `SingleStepSelector<T>`: 단일 선택 다이얼로그 (제네릭)
- `MultiStepSelector<T>`: 다단계 선택 위저드 (상태 관리 포함)

#### Pages (2시간)
- `GroupEventCreationFlow`: 그룹 일정 생성 진입점
- 기존 `GroupEventFormDialog` 리팩터링

#### 문서화 및 예제 (1-2시간)
- 컴포넌트 사용 가이드 작성
- Storybook 스타일 예제 앱

**총 예상 시간**: 9-13시간

---

## 5. Phase 1: Atoms 구현

### 5.1. SelectableOptionCard

**파일 위치**: `lib/presentation/widgets/selectable_option_card.dart`

```dart
class SelectableOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? accentColor;

  const SelectableOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    this.selected = false,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accentColor?.withOpacity(0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: selected ? 4 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? accentColor ?? Colors.blue : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              icon,
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 4),
                    Text(description, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}
```

**예상 작업 시간**: 1시간

---

## 6. 재사용 시나리오

### 6.1. 캘린더 일정 유형 선택 (현재)

```dart
SingleStepSelector<EventType>(
  title: '일정 유형 선택',
  options: [
    SelectableOption(value: EventType.official, title: '공식 일정', ...),
    SelectableOption(value: EventType.unofficial, title: '비공식 일정', ...),
  ],
  onSelected: (type) => _showEventForm(type),
);
```

### 6.2. 채널 권한 역할 선택

```dart
SingleStepSelector<GroupRole>(
  title: '역할 선택',
  options: roles.map((role) => SelectableOption(...)),
  onSelected: (role) => _assignRole(role),
);
```

### 6.3. 장소 예약 시간 선택 (Phase 3)

```dart
MultiStepSelector<PlaceReservation>(
  steps: [
    StepConfig(title: '장소 선택', options: places),
    StepConfig(title: '날짜 선택', options: availableDates),
    StepConfig(title: '시간 선택', options: timeSlots),
  ],
  onComplete: (reservation) => _confirmReservation(reservation),
);
```

---

## 7. 타임라인 및 우선순위

| Phase | 작업 내용 | 예상 시간 | 우선순위 |
|-------|----------|----------|---------|
| Phase 1 | Atoms 구현 (카드, 아이콘, 텍스트) | 2-3h | P0 (필수) |
| Phase 2 | Molecules 구현 (카드 그룹, 헤더) | 1-2h | P0 (필수) |
| Phase 3 | Organisms 구현 (선택기) | 3-4h | P0 (필수) |
| Phase 4 | 그룹 일정 다이얼로그 적용 | 2h | P0 (필수) |
| Phase 5 | 문서화 및 예제 | 1-2h | P1 (권장) |

**총 예상 시간**: 9-13시간

---

## 8. 관련 문서

### 개념 문서
- [캘린더 시스템](../concepts/calendar-system.md) - 전체 시스템 개요
- [설계 결정사항](../concepts/calendar-design-decisions.md) - DD-CAL-003 UI 설계
- [권한 시스템](../concepts/permission-system.md) - CALENDAR_MANAGE 권한

### 구현 가이드
- [프론트엔드 가이드](../implementation/frontend-guide.md) - Flutter 아키텍처
- [컴포넌트 재사용 가이드](../implementation/component-reusability-guide.md) - Atomic Design 패턴
- [디자인 시스템](../ui-ux/concepts/design-system.md) - 색상, 타이포그래피

### 선행 작업
- [Phase 5 API 연동](group-calendar-phase5-api-integration.md) - 권한 API 구현
- [개발 계획](group-calendar-development-plan.md) - 전체 로드맵

---

**다음 단계**: Phase 1 Atoms 구현 착수
