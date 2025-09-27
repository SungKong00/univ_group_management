# 권한 시스템 (Permission System)

## RBAC (역할 기반 접근 제어) 모델

본 시스템의 권한은 역할 기반 접근 제어(RBAC) 모델을 따릅니다. 각 사용자는 그룹 내에서 특정 역할을 부여받으며, 해당 역할에 할당된 권한들을 갖게 됩니다.

`사용자` → `역할(Role)` → `권한들(Permissions)`

## 2레벨 권한 구조

권한 시스템은 **그룹 레벨**과 **채널 레벨**의 2단계 구조로 구성됩니다.

### 그룹 레벨 권한 (GroupPermission)

*   **참고**: `GroupPermission` Enum으로 코드에 정의되어 있습니다.

- `GROUP_MANAGE`: 그룹 정보 수정, 삭제
- `ADMIN_MANAGE`: 멤버 관리 + 역할 관리 통합 (멤버 역할 변경, 강제 탈퇴, 커스텀 역할 생성/수정/삭제, 가입 신청 승인/반려)
- `CHANNEL_MANAGE`: 채널 생성, 삭제, 설정 수정, 채널별 역할 바인딩 설정
- `RECRUITMENT_MANAGE`: 모집 공고 작성/수정/마감, 모집 관련 설정 관리

### 채널 레벨 권한 (ChannelPermission)

*   **참고**: `ChannelPermission` Enum으로 코드에 정의되어 있습니다.

- `CHANNEL_VIEW`: 채널 존재 확인 및 기본 정보 조회
- `POST_READ`: 채널 내 게시글 조회
- `POST_WRITE`: 채널 내 새 게시글 작성
- `COMMENT_WRITE`: 게시글에 댓글 작성
- `FILE_UPLOAD`: 게시글 및 댓글에 파일 첨부

## 시스템 역할 (수정 불가)

### Owner (그룹 오너)
```kotlin
permissions = GroupPermission.values().toSet() // 모든 그룹 권한
isSystemRole = true
transferable = true // 소유권 양도 가능
```

### Member (기본 멤버)
```kotlin
permissions = emptySet() // 그룹 멤버십만으로 워크스페이스 접근 가능
isSystemRole = true
// 채널별 권한은 별도 바인딩으로 관리
```

## 커스텀 역할 예시

### Staff (운영진)
```kotlin
permissions = setOf(
    CHANNEL_MANAGE,
    ADMIN_MANAGE
)
description = "채널 관리 및 멤버 관리"
```

### Recruitment Manager (모집 담당자)
```kotlin
permissions = setOf(
    RECRUITMENT_MANAGE,
    ADMIN_MANAGE
)
description = "가입 승인 및 모집 관리"
```

### Content Manager (컨텐츠 관리자)
```kotlin
permissions = setOf(
    CHANNEL_MANAGE
)
description = "채널 및 컨텐츠 관리"
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

// 채널 권한은 별도 바인딩으로 관리
private fun getChannelPermissions(channelId: Long, userId: Long): Set<ChannelPermission> {
    // 채널별 역할 바인딩을 통한 권한 계산
    return channelPermissionService.getEffectivePermissions(channelId, userId)
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
2. "Staff" 커스텀 역할 생성 (ADMIN_MANAGE + CHANNEL_MANAGE)
3. 해당 멤버에게 역할 할당
4. 멤버 관리 및 채널 관리 권한 획득

### 시나리오 2: 모집 담당자 지정
1. 신입 모집 시즌 도래
2. "Recruitment Manager" 역할 생성 (RECRUITMENT_MANAGE + ADMIN_MANAGE)
3. 모집 업무 담당자들에게 할당
4. 가입 승인 및 모집 게시글 관리 가능

### 시나리오 3: 채널별 세부 권한 설정
1. 특정 채널에 대한 세부 권한 필요
2. 채널별 역할 바인딩 생성
3. 특정 역할에 대해 채널 권한 조합 설정
4. 해당 역할 멤버들이 채널별 차별화된 권한 획득

## API 사용 예시

### 역할 생성
```typescript
POST /api/groups/{groupId}/roles
{
  "name": "Content Manager",
  "permissions": ["CHANNEL_MANAGE"],
  "description": "컨텐츠 관리 담당"
}
```

### 멤버 역할 변경
```typescript
PUT /api/groups/{groupId}/members/{userId}/role
{
  "roleId": 123
}
```

### 가입 신청 처리
```typescript
PATCH /api/groups/{groupId}/join-requests/{requestId}
{
  "action": "APPROVE"
}
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
