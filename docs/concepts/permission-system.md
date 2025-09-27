# 권한 시스템 (Permission System)

## RBAC (역할 기반 접근 제어) 모델

본 시스템의 권한은 역할 기반 접근 제어(RBAC) 모델을 따릅니다. 각 사용자는 그룹 내에서 특정 역할을 부여받으며, 해당 역할에 할당된 권한들을 갖게 됩니다.

`사용자` → `역할(Role)` → `권한들(Permissions)`

## 14가지 그룹 권한

*   **참고**: 아래 목록은 `GroupPermission` Enum으로 코드에 정의되어 있습니다.

### 그룹 관리 권한
- `GROUP_MANAGE`: 그룹 정보 수정, 삭제
- `MEMBER_READ`: 멤버 목록 조회
- `MEMBER_APPROVE`: 가입 요청 승인/거부
- `MEMBER_KICK`: 멤버 추방
- `ROLE_MANAGE`: 역할 생성/수정/삭제

### 컨텐츠 권한
- `CHANNEL_READ`: 채널 읽기
- `CHANNEL_WRITE`: 채널 생성/수정
- `POST_CREATE`: 게시글 작성
- `POST_UPDATE_OWN`: 본인 게시글 수정
- `POST_DELETE_OWN`: 본인 게시글 삭제
- `POST_DELETE_ANY`: 모든 게시글 삭제

### 모집 관련 권한
- `RECRUITMENT_CREATE`: 모집 게시글 작성
- `RECRUITMENT_UPDATE`: 모집 게시글 수정
- `RECRUITMENT_DELETE`: 모집 게시글 삭제

## 시스템 역할 (수정 불가)

### Owner (그룹 오너)
```kotlin
permissions = GroupPermission.values().toSet() // 모든 권한
isSystemRole = true
transferable = true // 소유권 양도 가능
```

### Member (기본 멤버)
```kotlin
permissions = setOf(
    CHANNEL_READ,
    POST_CREATE,
    POST_UPDATE_OWN,
    POST_DELETE_OWN
)
isSystemRole = true
```

## 커스텀 역할 예시

### Moderator (모더레이터)
```kotlin
permissions = setOf(
    CHANNEL_READ, CHANNEL_WRITE,
    POST_CREATE, POST_DELETE_ANY,
    MEMBER_KICK
)
description = "채널 관리 및 컨텐츠 모더레이션"
```

### Recruitment Manager (모집 담당자)
```kotlin
permissions = setOf(
    CHANNEL_READ, MEMBER_APPROVE,
    RECRUITMENT_CREATE, RECRUITMENT_UPDATE,
    RECRUITMENT_DELETE
)
description = "가입 승인 및 모집 관리"
```

### Sub-Admin (부관리자)
```kotlin
permissions = setOf(
    MEMBER_READ, MEMBER_APPROVE, MEMBER_KICK,
    CHANNEL_READ, CHANNEL_WRITE,
    ROLE_MANAGE
)
description = "멤버 및 역할 관리"
```

## 권한 체크 로직

### 백엔드 구현
실제 권한 계산은 `PermissionService`에서 수행되며, 역할 기반으로만 이루어집니다.

```kotlin
// GroupPermissionEvaluator
@PreAuthorize("@security.hasGroupPerm(#groupId, 'GROUP_MANAGE')")
fun updateGroup(groupId: Long, request: UpdateGroupRequest): GroupDto

// PermissionService의 실제 로직 요약
private fun computeEffective(groupId: Long, userId: Long): Set<GroupPermission> {
    // 1. 사용자의 그룹 멤버십 정보 조회
    val member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
    
    // 2. 멤버십에 할당된 역할(Role)의 권한을 그대로 반환
    return member.role.permissions
}
```

### 프론트엔드 구현
```dart
// Flutter - 권한 기반 UI 렌더링
Widget buildActionButton() {
  return FutureBuilder<bool>(
    future: permissionProvider.hasPermission(groupId, 'MEMBER_KICK'),
    builder: (context, snapshot) {
      if (snapshot.data == true) {
        return KickMemberButton();
      }
      return SizedBox.shrink();
    },
  );
}
```

## 권한 상속 규칙

### 그룹 계층 상속
```
대학교 (ADMIN 권한)
├── 학과 (학과 관련 관리 권한)
│   └── 동아리 (동아리 내부 권한만)
```

### 상속 우선순위
1. **글로벌 역할**: ADMIN > PROFESSOR > STUDENT
2. **그룹 계층**: 상위 그룹 권한 우선
3. **역할 권한**: 그룹 내 역할별 권한

## 일반적인 권한 시나리오

### 시나리오 1: 동아리 임원 임명
1. 동아리 오너가 활발한 멤버를 부회장으로 임명
2. "Sub-Admin" 커스텀 역할 생성
3. 해당 멤버에게 역할 할당
4. 멤버 관리 및 채널 관리 권한 획득

### 시나리오 2: 모집 담당자 지정
1. 신입 모집 시즌 도래
2. "Recruitment Manager" 역할 생성
3. 모집 업무 담당자들에게 할당
4. 가입 승인 및 모집 게시글 관리 가능

## API 사용 예시

### 역할 생성
```typescript
POST /api/groups/{groupId}/roles
{
  "name": "Content Manager",
  "permissions": ["CHANNEL_WRITE", "POST_DELETE_ANY"],
  "description": "컨텐츠 관리 담당"
}
```

### 권한 확인
```typescript
GET /api/groups/{groupId}/permissions/check?permission=GROUP_MANAGE
// Response: { "hasPermission": true }
```

## 관련 구현

### API 참조
- **권한 체크**: [../implementation/api-reference.md#권한체크](../implementation/api-reference.md#권한체크)
- **역할 관리**: [../implementation/api-reference.md#역할관리](../implementation/api-reference.md#역할관리)

### 데이터베이스 설계
- **GroupRole 테이블**: [../implementation/database-reference.md#GroupRole](../implementation/database-reference.md#GroupRole)

### 관련 개념
- **그룹 계층**: [group-hierarchy.md](group-hierarchy.md)
- **사용자 라이프사이클**: [user-lifecycle.md](user-lifecycle.md)

### 문제 해결
- **권한 에러**: [../troubleshooting/permission-errors.md](../troubleshooting/permission-errors.md)
