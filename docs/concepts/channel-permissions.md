# 채널 권한 시스템 (Channel Permission System)

## 권한 체계 개요

채널 권한은 **ChannelRoleBinding**을 통해 그룹 역할(GroupRole)과 채널별 권한(ChannelPermission)을 연결하는 방식으로 동작합니다.

```
GroupRole + Channel → ChannelRoleBinding → Set<ChannelPermission>
```

## 채널 권한 종류

```kotlin
enum class ChannelPermission {
    CHANNEL_VIEW,   // 채널 보기 권한 (가시성 제어)
    POST_READ,      // 게시글 읽기 권한
    POST_WRITE,     // 게시글 작성 권한
    COMMENT_WRITE,  // 댓글 작성 권한
    FILE_UPLOAD,    // 파일 업로드 권한
}
```

### 권한별 상세 설명

#### CHANNEL_VIEW
- **목적**: 채널 존재 확인 및 기본 정보 조회
- **중요성**: 모든 채널 활동의 기본 전제 조건
- **효과**: 이 권한이 없으면 채널이 네비게이션에서 숨겨짐

#### POST_READ
- **목적**: 채널 내 게시글 조회
- **의존성**: CHANNEL_VIEW 권한 필요
- **범위**: 게시글 목록, 게시글 상세 내용

#### POST_WRITE
- **목적**: 채널 내 새 게시글 작성
- **제한**: 채널 타입에 따라 제한될 수 있음 (예: ANNOUNCEMENT 채널)

#### COMMENT_WRITE
- **목적**: 게시글에 댓글 작성
- **특징**: POST_WRITE 권한이 없어도 댓글은 작성 가능

#### FILE_UPLOAD
- **목적**: 게시글 및 댓글에 파일 첨부
- **제한**: 파일 크기, 확장자 제한 적용

## 채널 역할 바인딩

### ChannelRoleBinding 엔티티

```kotlin
@Entity
data class ChannelRoleBinding(
    val channel: Channel,
    val groupRole: GroupRole,
    val permissions: Set<ChannelPermission>
)
```

### 기본 권한 구성

#### ANNOUNCEMENT 채널 (공지사항)
```kotlin
// OWNER 역할
permissions = setOf(
    ChannelPermission.CHANNEL_VIEW,
    ChannelPermission.POST_READ,
    ChannelPermission.POST_WRITE,
    ChannelPermission.COMMENT_WRITE,
    ChannelPermission.FILE_UPLOAD
)

// MEMBER 역할
permissions = setOf(
    ChannelPermission.CHANNEL_VIEW,
    ChannelPermission.POST_READ,
    ChannelPermission.COMMENT_WRITE
)
```

#### TEXT 채널 (일반 대화)
```kotlin
// OWNER 역할
permissions = setOf(
    ChannelPermission.CHANNEL_VIEW,
    ChannelPermission.POST_READ,
    ChannelPermission.POST_WRITE,
    ChannelPermission.COMMENT_WRITE,
    ChannelPermission.FILE_UPLOAD
)

// MEMBER 역할
permissions = setOf(
    ChannelPermission.CHANNEL_VIEW,
    ChannelPermission.POST_READ,
    ChannelPermission.POST_WRITE,
    ChannelPermission.COMMENT_WRITE
)
```

## 권한 확인 프로세스

### 1. 사용자 권한 조회
```kotlin
fun getUserChannelPermissions(userId: Long, channelId: Long): Set<ChannelPermission> {
    val userGroupRole = getUserGroupRole(userId, channelId)
    val channelBinding = getChannelRoleBinding(channelId, userGroupRole)
    return channelBinding?.permissions ?: emptySet()
}
```

### 2. 가시성 제어
```kotlin
fun isChannelVisible(userId: Long, channelId: Long): Boolean {
    val permissions = getUserChannelPermissions(userId, channelId)
    return ChannelPermission.CHANNEL_VIEW in permissions
}
```

### 3. 작업별 권한 확인
```kotlin
fun canWritePost(userId: Long, channelId: Long): Boolean {
    val permissions = getUserChannelPermissions(userId, channelId)
    return ChannelPermission.POST_WRITE in permissions
}
```

## 권한 관리 서비스

### ChannelPermissionManagementService

- **역할**: 채널별 권한 설정 및 관리
- **기능**:
  - 채널 생성 시 기본 권한 설정
  - 역할별 권한 수정
  - 권한 조회 및 캐싱

### ChannelPermissionCacheManager

- **역할**: 권한 조회 성능 최적화
- **기능**:
  - 사용자별 채널 권한 캐싱
  - 권한 변경 시 캐시 무효화

## 실제 사용 예시

### 채널 목록 필터링
```kotlin
fun getVisibleChannels(userId: Long, workspaceId: Long): List<Channel> {
    val allChannels = channelRepository.findByWorkspaceId(workspaceId)
    return allChannels.filter { channel ->
        isChannelVisible(userId, channel.id)
    }
}
```

### 게시글 작성 권한 확인
```kotlin
@PreAuthorize("@channelPermissionService.hasPermission(#userId, #channelId, 'POST_WRITE')")
fun createPost(userId: Long, channelId: Long, content: String): Post {
    // 게시글 작성 로직
}
```

## 현재 구현 상태

### 완료된 기능
- ✅ ChannelPermission enum 정의
- ✅ ChannelRoleBinding 엔티티
- ✅ 기본 채널 권한 설정
- ✅ 권한 캐싱 시스템

### 개선 예정
- 🔄 isPrivate/isPublic 필드 → 권한 기반 시스템으로 마이그레이션
- 🔄 FILE_SHARE 채널 타입 제거 (사용되지 않음)
- 🔄 세밀한 권한 제어 (게시글별, 댓글별)

## 관련 문서

### 구현 참조
- **백엔드 가이드**: [../implementation/backend-guide.md](../implementation/backend-guide.md)
- **데이터베이스 참조**: [../implementation/database-reference.md](../implementation/database-reference.md)

### 관련 개념
- **그룹 권한**: [permission-system.md](permission-system.md)
- **워크스페이스 구조**: [workspace-channel.md](workspace-channel.md)