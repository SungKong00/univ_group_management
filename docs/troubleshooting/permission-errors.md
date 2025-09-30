# 권한 에러 해결 가이드 (Permission Error Troubleshooting)

## 일반적인 권한 에러

### 1. 403 Forbidden - 권한 부족

#### 증상
```http
HTTP/1.1 403 Forbidden
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_PERMISSION",
    "message": "해당 작업을 수행할 권한이 없습니다"
  }
}
```

#### 원인 분석 체크리스트
```markdown
□ 사용자가 해당 그룹의 멤버인가?
□ 사용자의 역할에 필요한 권한이 있는가?
□ @PreAuthorize 어노테이션이 올바르게 설정되었는가?
```

#### 디버깅 방법
```kotlin
// 1. 사용자 멤버십 확인
val membership = groupMemberRepository.findByUserIdAndGroupId(userId, groupId)
if (membership == null) {
    log.debug("User {} is not a member of group {}", userId, groupId)
}

// 2. 역할 권한 확인
val rolePermissions = membership?.role?.permissions ?: emptySet()
log.debug("User {} in group {} has role permissions: {}", userId, groupId, rolePermissions)
```

#### 해결 방법
```kotlin
// 역할에 필요한 권한이 부여되어 있는지 확인하고, 필요 시 역할을 변경하거나 역할 자체의 권한을 수정합니다.
fun addPermissionToRole(roleId: Long, permission: GroupPermission) {
    val role = roleRepository.findById(roleId).orElseThrow()
    role.permissions = role.permissions + permission
    roleRepository.save(role)
}
```

### 2. 401 Unauthorized - 인증 실패

#### 증상
```http
HTTP/1.1 401 Unauthorized
{
  "success": false,
  "error": {
    "code": "AUTHENTICATION_REQUIRED",
    "message": "인증이 필요합니다"
  }
}
```

#### 원인 및 해결
```markdown
## JWT 토큰 문제
- **만료된 토큰**: 새로운 토큰으로 재로그인
- **잘못된 토큰**: Authorization 헤더 형식 확인 (`Bearer {token}`)
- **토큰 없음**: 로그인 페이지로 리다이렉트
```

#### 프론트엔드 처리
```dart
// Flutter - HTTP 인터셉터
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // 토큰 만료 - 로그아웃 처리
      GetIt.instance<AuthProvider>().logout();
      // 로그인 페이지로 이동
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    }
    handler.next(err);
  }
}
```

## 특정 시나리오별 권한 문제

### 3. 그룹 생성 권한 문제

#### 증상
사용자가 하위 그룹을 생성하려 하지만 403 에러 발생

#### 해결 단계
```kotlin
// 1. 부모 그룹에서의 권한 확인
@PreAuthorize("@security.hasGroupPerm(#request.parentGroupId, 'SUB_GROUP_CREATE')")
fun createSubGroup(request: CreateGroupRequest): GroupDto

// 2. 권한이 없다면 부모 그룹 관리자에게 권한을 가진 역할을 부여받아야 함
```

### 4. 채널 관리 권한 문제

#### 증상
```
사용자가 채널을 생성하려 하지만 "CHANNEL_WRITE 권한이 없습니다" 에러 발생
```

#### 진단 및 해결
```kotlin
// 1. 권한 체크 로직
@PreAuthorize("@security.hasGroupPerm(#workspaceId, 'CHANNEL_WRITE')")
fun createChannel(workspaceId: Long, request: CreateChannelRequest): ChannelDto

// 2. 워크스페이스에서 그룹 ID 추출
fun getGroupIdFromWorkspace(workspaceId: Long): Long {
    val workspace = workspaceRepository.findById(workspaceId)
        ?: throw IllegalArgumentException("워크스페이스를 찾을 수 없습니다")
    return workspace.groupId
}

// 3. 올바른 권한 체크
@PreAuthorize("@security.hasGroupPerm(@workspaceService.getGroupId(#workspaceId), 'CHANNEL_WRITE')")
```

### 5. 멤버 관리 권한 문제

#### 시나리오: 멤버 추방이 안 되는 경우
```kotlin
// 문제가 되는 케이스들
fun kickMember(groupId: Long, targetUserId: Long, kickerUserId: Long) {
    // 1. 자기 자신을 추방하려는 경우
    if (targetUserId == kickerUserId) {
        throw IllegalArgumentException("자기 자신을 추방할 수 없습니다")
    }

    // 2. 그룹 오너를 추방하려는 경우
    val group = groupRepository.findById(groupId)
    if (group.ownerId == targetUserId) {
        throw IllegalArgumentException("그룹 오너는 추방할 수 없습니다")
    }

    // 3. 상위 권한 사용자를 추방하려는 경우 (priority 비교)
    val kickerRole = getMemberRole(kickerUserId, groupId)
    val targetRole = getMemberRole(targetUserId, groupId)

    if (targetRole.priority >= kickerRole.priority) {
        throw IllegalArgumentException("동등하거나 상위 권한의 사용자는 추방할 수 없습니다")
    }
}
```

## 권한 시스템 디버깅 도구

### 1. 권한 상태 조회 API
```kotlin
@GetMapping("/api/groups/{groupId}/permissions/debug")
@PreAuthorize("@security.hasGroupPerm(#groupId, 'GROUP_MANAGE')")
fun debugPermissions(
    @PathVariable groupId: Long,
    @RequestParam userId: Long
): ResponseEntity<PermissionDebugInfo> {

    val membership = groupMemberRepository.findByUserIdAndGroupId(userId, groupId).orElse(null)

    val debugInfo = PermissionDebugInfo(
        isMember = membership != null,
        roleName = membership?.role?.name,
        rolePermissions = membership?.role?.permissions ?: emptySet()
    )

    return ResponseEntity.ok(debugInfo)
}
```

### 2. 프론트엔드 권한 확인 도구
```dart
// Flutter - 개발용 권한 확인 위젯
class PermissionDebugWidget extends StatelessWidget {
  final int groupId;
  final List<String> permissions;

  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('권한 디버그'),
      children: permissions.map((permission) {
        return FutureBuilder<bool>(
          future: PermissionService.hasPermission(groupId, permission),
          builder: (context, snapshot) {
            final hasPermission = snapshot.data ?? false;
            return ListTile(
              title: Text(permission),
              trailing: Icon(
                hasPermission ? Icons.check : Icons.close,
                color: hasPermission ? Colors.green : Colors.red,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
```

## 자주 발생하는 실수

### 1. @PreAuthorize 어노테이션 실수
```kotlin
// ❌ 잘못된 예시
@PreAuthorize("@security.hasGroupPerm(groupId, 'GROUP_MANAGE')")
fun updateGroup(groupId: Long): GroupDto

// ✅ 올바른 예시
@PreAuthorize("@security.hasGroupPerm(#groupId, 'GROUP_MANAGE')")
fun updateGroup(groupId: Long): GroupDto

// ❌ 문자열 파라미터 실수
@PreAuthorize("@security.hasGroupPerm(#groupId, GROUP_MANAGE)")

// ✅ 문자열로 전달
@PreAuthorize("@security.hasGroupPerm(#groupId, 'GROUP_MANAGE')")
```

### 2. 프론트엔드 권한 체크 누락
```dart
// ❌ 권한 체크 없이 UI 표시
Widget buildDeleteButton() {
  return IconButton(
    onPressed: () => deleteGroup(),
    icon: Icon(Icons.delete),
  );
}

// ✅ 권한 기반 UI
Widget buildDeleteButton() {
  return PermissionBuilder(
    permission: 'GROUP_MANAGE',
    groupId: groupId,
    child: IconButton(
      onPressed: () => deleteGroup(),
      icon: Icon(Icons.delete),
    ),
  );
}
```

## 권한 관련 로깅

### 개발 환경 로깅 설정
```yaml
# application-dev.yml
logging:
  level:
    org.castlekong.backend.security: DEBUG
    org.springframework.security: DEBUG
```

### 유용한 로그 메시지
```kotlin
@Component
class GroupPermissionEvaluator {
    private val logger = LoggerFactory.getLogger(javaClass)

    fun hasGroupPermission(groupId: Long, permission: String): Boolean {
        val userId = getCurrentUserId()
        logger.debug("Checking permission '{}' for user {} in group {}", permission, userId, groupId)

        val result = // 권한 계산 로직

        logger.debug("Permission check result: {} (user: {}, group: {}, permission: {})",
                    result, userId, groupId, permission)

        return result
    }
}
```

## 관련 문서

### 권한 시스템 개념
- **권한 시스템**: [../concepts/permission-system.md](../concepts/permission-system.md)
- **그룹 계층**: [../concepts/group-hierarchy.md](../concepts/group-hierarchy.md)

### 구현 참조
- **백엔드 가이드**: [../implementation/backend-guide.md](../implementation/backend-guide.md)
- **API 참조**: [../implementation/api-reference.md](../implementation/api-reference.md)

### 일반적 문제
- **공통 에러**: [common-errors.md](common-errors.md)
