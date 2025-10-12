# 그룹 캘린더 Phase 8: 권한 통합 구현

> **버전**: 1.0
> **작성일**: 2025-10-13
> **상태**: ✅ 구현 완료
> **관련 문서**: [개발 계획](group-calendar-development-plan.md) | [권한 시스템](../concepts/permission-system.md)

---

## 1. 개요

### 목표
공식 일정 수정/삭제 시 `CALENDAR_MANAGE` 권한을 체크하여, 권한이 있는 사용자만 수정/삭제할 수 있도록 구현합니다.

### 완료 상태
✅ **구현 완료**: 2025-10-13 기준 권한 통합 로직이 이미 완벽하게 구현되어 있습니다.

---

## 2. 구현 내용

### 2.1. 권한 체크 로직

**파일**: `frontend/lib/presentation/pages/workspace/calendar/group_calendar_page.dart`

**메서드**: `_canModifyEvent()` (424-443줄)

```dart
bool _canModifyEvent(GroupEvent event) {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) return false;

  // Check if user has CALENDAR_MANAGE permission
  final permissionsAsync = ref.read(groupPermissionsProvider(widget.groupId));
  final hasCalendarManage = permissionsAsync.maybeWhen(
    data: (permissions) => permissions.contains('CALENDAR_MANAGE'),
    orElse: () => false,
  );

  // Official events: Require CALENDAR_MANAGE permission
  if (event.isOfficial) {
    return hasCalendarManage;
  }

  // Unofficial events: Creator or CALENDAR_MANAGE
  return event.creatorId == currentUser.id || hasCalendarManage;
}
```

**핵심 로직**:
1. 현재 사용자가 로그인되어 있는지 확인
2. `groupPermissionsProvider`를 통해 `CALENDAR_MANAGE` 권한 조회
3. 공식 일정: `CALENDAR_MANAGE` 권한 필수
4. 비공식 일정: 작성자 본인 또는 `CALENDAR_MANAGE` 권한

### 2.2. UI 조건부 렌더링

**위치**: `_showEventDetail()` 메서드 (520-527줄)

```dart
if (_canModifyEvent(event))
  IconButton(
    icon: const Icon(Icons.more_vert),
    onPressed: () {
      Navigator.of(context).pop();
      _showEventActions(event);
    },
  ),
```

**동작**:
- 권한이 있는 경우: 수정/삭제 버튼(more_vert) 표시
- 권한이 없는 경우: 버튼 숨김 (읽기만 가능)

### 2.3. 사용된 Provider

#### groupPermissionsProvider

**파일**: `frontend/lib/presentation/providers/group_permission_provider.dart`

```dart
final groupPermissionsProvider =
    FutureProvider.family.autoDispose<Set<String>, int>((
  ref,
  groupId,
) async {
  final service = GroupPermissionService();
  return await service.getMyPermissions(groupId);
});
```

**특징**:
- `FutureProvider.family`: 그룹 ID별로 캐시
- `autoDispose`: 사용하지 않을 때 자동 메모리 해제
- API 엔드포인트: `GET /api/groups/{groupId}/permissions`

#### currentUserProvider

**파일**: `frontend/lib/presentation/providers/auth_provider.dart`

```dart
final currentUserProvider = Provider<UserInfo?>((ref) {
  return ref.watch(authProvider).user;
});
```

**특징**:
- 현재 로그인된 사용자 정보 제공
- 작성자 ID 비교에 사용

---

## 3. 테스트 시나리오

### 3.1. 그룹장 (CALENDAR_MANAGE 있음)

**예상 동작**:
- ✅ 공식 일정 상세 보기: 수정/삭제 버튼 표시
- ✅ 공식 일정 수정: 정상 동작
- ✅ 공식 일정 삭제: 정상 동작
- ✅ 본인의 비공식 일정: 수정/삭제 버튼 표시
- ✅ 타인의 비공식 일정: 수정/삭제 버튼 표시 (CALENDAR_MANAGE 권한)

### 3.2. 일반 멤버 (CALENDAR_MANAGE 없음)

**예상 동작**:
- ❌ 공식 일정 상세 보기: 수정/삭제 버튼 숨김
- ✅ 본인의 비공식 일정: 수정/삭제 버튼 표시
- ❌ 타인의 비공식 일정: 수정/삭제 버튼 숨김 (읽기만 가능)

### 3.3. 비로그인 사용자

**예상 동작**:
- ❌ 모든 일정: 수정/삭제 버튼 숨김

---

## 4. 권한 체계 요약

### 4.1. 권한 정의

| 권한 | 설명 | 적용 범위 |
|------|------|-----------|
| `CALENDAR_MANAGE` | 캘린더 관리 권한 | 공식 일정 생성/수정/삭제, 장소 관리 |

### 4.2. Permission-Centric 매트릭스

| 권한 | 허용 역할 (기본 설정) | 비고 |
|------|----------------------|------|
| CALENDAR_MANAGE | 그룹장, 교수 | 운영진만 공식 일정 관리 |

### 4.3. 멤버십 기반 기능 (권한 불필요)

| 기능 | 접근 조건 | 비고 |
|------|----------|------|
| 캘린더 조회 | 그룹 멤버 (`isMember()`) | 모든 멤버가 그룹 캘린더 조회 가능 |
| 비공식 일정 생성 | 그룹 멤버 | 모든 멤버가 자유롭게 생성 가능 |

---

## 5. 기술적 구현 세부사항

### 5.1. 권한 확인 플로우

```
사용자 일정 수정 시도
    ↓
_canModifyEvent() 호출
    ↓
currentUser 확인 → null이면 false 반환
    ↓
groupPermissionsProvider 조회
    ↓
공식 일정?
    ├─ YES → CALENDAR_MANAGE 권한 있으면 true
    └─ NO  → 작성자 본인 OR CALENDAR_MANAGE 권한 있으면 true
```

### 5.2. Provider 캐싱 전략

**groupPermissionsProvider**:
- `FutureProvider.family`: 그룹 ID별로 권한 결과 캐시
- `autoDispose`: 페이지 이탈 시 자동 해제
- 중복 API 호출 방지

**성능 최적화**:
- 권한은 그룹별로 한 번만 로드
- 페이지 내에서 권한 상태는 캐시됨
- 로그아웃/계정 전환 시 자동 초기화

### 5.3. 에러 처리

```dart
final hasCalendarManage = permissionsAsync.maybeWhen(
  data: (permissions) => permissions.contains('CALENDAR_MANAGE'),
  orElse: () => false,
);
```

- `maybeWhen` 사용으로 안전한 fallback
- 로딩 중이거나 에러 발생 시: `false` 반환 (안전 우선)
- 권한이 없는 것으로 간주하여 보수적 접근

---

## 6. 검증 체크리스트

### 6.1. 코드 품질

- [x] 권한 체크 로직이 `_canModifyEvent()`에 중앙화됨
- [x] Provider를 통한 일관된 권한 조회
- [x] null 안전성 보장
- [x] 에러 시 안전한 fallback (false 반환)

### 6.2. UI/UX

- [x] 권한 없는 경우 수정/삭제 버튼 숨김
- [x] 일정 상세 보기는 모든 사용자에게 표시
- [x] 권한이 없어도 읽기는 가능

### 6.3. 보안

- [x] 프론트엔드 권한 체크로 UI 제어
- [x] 백엔드에서도 권한 재검증 필요 (별도 구현)
- [x] 작성자 ID와 현재 사용자 ID 비교

---

## 7. 다음 단계

### 7.1. 수동 테스트

1. **그룹장 계정으로 로그인**
   - [ ] 공식 일정 수정 버튼 표시 확인
   - [ ] 타인의 비공식 일정 수정 버튼 표시 확인

2. **일반 멤버 계정으로 로그인**
   - [ ] 공식 일정 수정 버튼 숨김 확인
   - [ ] 본인의 비공식 일정만 수정 버튼 표시 확인

3. **권한 전환 테스트**
   - [ ] 역할 변경 후 권한 자동 업데이트 확인

### 7.2. 백엔드 검증

- [ ] `PUT /api/groups/{groupId}/events/{eventId}` 권한 체크 확인
- [ ] `DELETE /api/groups/{groupId}/events/{eventId}` 권한 체크 확인
- [ ] 공식 일정 수정/삭제 시 `CALENDAR_MANAGE` 권한 검증

### 7.3. E2E 테스트

- [ ] 그룹장 → 일반 멤버 → 그룹장 역할 변경 시나리오
- [ ] 여러 사용자가 동시에 일정 수정 시도
- [ ] 권한 없는 사용자가 직접 API 호출 시도 (보안 테스트)

---

## 8. 관련 문서

### 개념 문서
- [권한 시스템](../concepts/permission-system.md) - RBAC 권한 체계
- [캘린더 시스템](../concepts/calendar-system.md) - 캘린더 전체 구조

### 구현 가이드
- [프론트엔드 가이드](../implementation/frontend-guide.md) - Provider 패턴
- [그룹 캘린더 개발 계획](group-calendar-development-plan.md) - Phase 1-8 전체 계획

### 기타
- [Phase 5 API 연동](group-calendar-phase5-api-integration.md) - API 엔드포인트
- [Phase 6 UI 개선](group-calendar-phase6-ui-improvement.md) - UI/UX 설계

---

## 9. 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|----------|--------|
| 2025-10-13 | 1.0 | Phase 8 완료 문서 작성 | Claude |

---

**다음 Phase**: Phase 9 - 장소 캘린더 구현 (예정)
