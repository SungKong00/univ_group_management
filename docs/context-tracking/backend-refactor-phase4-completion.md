# Backend Refactoring Phase 4 완료 보고서

**작성일**: 2025-12-03
**Phase**: Phase 4 - Controller Layer (일부 완료)
**상태**: 🟡 부분 완료 (핵심 문제 해결, Entity 불변성 문제 남음)

---

## 📋 Phase 4 목표

**목표**: Controller Layer 구현 및 컴파일 에러 해결

작업 범위:
- Permission Enum 타입 불일치 해결
- GroupVisibility, coverImageUrl, isDefault 제거된 필드 대응
- Null Safety 개선
- DTO/Controller/Repository/Service 수정
- 컴파일 테스트

---

## ✅ 완료 항목

### 1. Permission Enum 타입 불일치 해결 ⭐ (핵심 성과)

**문제**: `entity.GroupPermission` vs `permission.GroupPermission` 중복 정의로 타입 불일치

**해결**:
1. `permission/entity/GroupPermission.kt` 삭제
2. `permission/entity/ChannelPermission.kt` 삭제
3. `permission/PermissionConstants.kt`의 enum을 공식 버전으로 사용
4. `GroupRole.kt` import 수정: `permission.entity.GroupPermission` → `permission.GroupPermission`
5. `ChannelRoleBinding.kt` import 수정: `permission.ChannelPermission` 추가

### 2. Null Safety 개선 ⭐ (핵심 성과)

**문제**: `channel.workspace.group.id!!` - Workspace가 nullable

**해결**:
- `PermissionLoader.loadChannelPermissions()`: `channel.workspace.group.id` → `channel.group.id` (Channel에 Group 직접 참조)
- `ChannelService.createChannel()`: `channel.workspace.id` → `channel.group.id` (Group 단위 체크)
- Channel Entity `displayOrder`: `val` → `var` (재할당 가능하게 수정)

### 3. GroupVisibility 제거 ⭐ (핵심 성과)

**제거된 파일/참조**:
- `GroupRepository.kt`: `import GroupVisibility` 제거, `searchByKeyword()` 파라미터에서 visibility 제거
- `GroupService.kt`: `import GroupVisibility` 제거, `searchPublicGroups()` → `searchGroups()`로 메서드명 변경
- `GroupDto.kt`: `GroupVisibility` import 제거, DTO 필드에서 `visibility`, `coverImageUrl` 제거
- `GroupController.kt`: `searchPublicGroups()` → `searchGroups()` 호출 변경, Group 생성 시 `visibility` 제거

### 4. isDefault 필드 제거

**수정 파일**:
- `ChannelService.kt`:
  - `deleteChannel()`: `if (channel.isDefault)` 체크 제거
  - `getDefaultChannels()` → `getAnnouncementChannels()` (ChannelType.ANNOUNCEMENT 기반)
- `ChannelRepository.kt`: `findByWorkspaceIdAndIsDefault()` 제거, `existsByGroupIdAndName()` 추가

### 5. Runner 비활성화

테스트 데이터 생성용 Runner 파일들을 Phase 6으로 연기:
- `DemoDataRunner.kt` → `.disabled`
- `DevDataRunner.kt` → `.disabled`

---

## 🔧 주요 기술 해결 사항

### 1. Permission Enum 통합 전략

**변경 전**:
```
domain/permission/entity/GroupPermission.kt (5개 권한)
domain/permission/PermissionConstants.kt (30개 권한)
→ 타입 불일치 에러
```

**변경 후**:
```
domain/permission/PermissionConstants.kt (30개 권한) ← 공식 버전
→ 모든 Entity, Service, Controller가 이 enum 사용
```

### 2. Null Safety 패턴

**변경 전** (에러):
```kotlin
val member = groupMemberRepository.findByGroupIdAndUserId(
    channel.workspace.group.id!!, // ❌ Workspace가 nullable
    userId
)
```

**변경 후** (안전):
```kotlin
val member = groupMemberRepository.findByGroupIdAndUserId(
    channel.group.id!!, // ✅ Channel이 Group 직접 참조
    userId
)
```

### 3. Entity 불변성 문제 발견

**문제**: Entity 필드들이 `val`로 정의되어 JPA update 불가

**영향 받는 Entity**:
- Group, Post, Comment, GroupMember, Workspace 등 대부분의 Entity
- `updateGroup() { group.name = newName }` 같은 패턴 불가

**Phase 5 이후 해결 필요**:
- Entity 필드를 `var`로 변경
- 또는 copy() 패턴으로 전환 (data class 활용)

---

## 📊 Phase 4 통계

| 항목 | 개수 |
|------|------|
| 해결된 핵심 문제 | 3개 (Permission Enum, Null Safety, GroupVisibility) |
| 수정된 파일 | 15개 |
| 삭제된 파일 | 2개 (중복 enum) |
| 비활성화 파일 | 2개 (Runner) |
| 컴파일 에러 (변경 전) | 60+ |
| 컴파일 에러 (변경 후) | 30+ (Entity 불변성 문제) |
| 해결률 | **50%** (핵심 문제는 100% 해결) |

---

## 🚧 남은 컴파일 에러 (Phase 5 이후 해결 예정)

### 1. Entity 불변성 문제 (가장 큰 이슈)

**에러 패턴**: `Val cannot be reassigned`

**발생 위치**:
- `PostController.kt:165-166`: `post.isPinned = true`
- `CommentService.kt:104`: `comment.content = newContent`
- `GroupMemberService.kt:154`: `member.role = newRole`
- `WorkspaceController.kt:118-123`: `workspace.name = newName`

**근본 원인**: Phase 0 Entity 설계에서 모든 필드를 `val`로 정의

**해결 방법 (Phase 5 이후)**:
1. Entity 필드를 `var`로 변경
2. 또는 copy() + save() 패턴 사용

### 2. 제거된 필드 참조

**영향 받는 파일**:
- `CommentDto.kt:38`: `comment.isDeleted` (Comment Entity에 없음)
- `PostDto.kt:40`: `post.pinnedAt` nullable 불일치
- `PostDto.kt:85`: `PostType.NORMAL` (존재하지 않는 enum)
- `GroupMemberController.kt:51`: `group.visibility` (제거된 필드)
- `WorkspaceDto.kt:29`: `workspace.isDefault` (제거된 필드)
- `ChannelDto.kt:36`: `channel.isDefault` (제거된 필드)

### 3. Entity 메서드 누락

- `CommentService.kt:84`: `post.incrementCommentCount()` (메서드 없음)
- `CommentService.kt:120`: `comment.softDelete()` (메서드 없음)
- `CommentService.kt:128`: `post.decrementCommentCount()` (메서드 없음)

### 4. 타입 불일치

- `CommentDto.kt:37`: `Long` vs `Int` (replyCount)
- `PostDto.kt:36-38, 72-73`: `Long` vs `Int` (viewCount, likeCount, commentCount)

---

## ✅ Phase 4 검증 기준 달성 여부

| 검증 기준 | 상태 |
|----------|------|
| Permission Enum 타입 불일치 해결 | ✅ 100% |
| GroupVisibility 제거 | ✅ 100% |
| Null Safety 개선 | ✅ 100% |
| ~~Entity 불변성 문제 해결~~ | ❌ Phase 5 연기 |
| ~~컴파일 에러 0개~~ | ❌ 30개 남음 (Entity 불변성) |
| 핵심 문제 해결 | ✅ 100% |

---

## 📝 다음 단계 (Phase 5 권장 작업)

**Phase 5: Entity 재설계 + 컴파일 에러 완전 해결**

우선순위 높은 작업:
1. **Entity 불변성 해결** (최우선)
   - 수정 가능한 필드를 `val` → `var` 변경
   - 또는 copy() 패턴 설계

2. **제거된 필드 대응**
   - Comment Entity에 `isDeleted` 추가 (soft delete)
   - Post Entity에 `pinnedAt: LocalDateTime?` nullable 수정
   - PostType enum 재확인 (NORMAL vs TEXT)

3. **Entity 메서드 추가**
   - Post: `incrementCommentCount()`, `decrementCommentCount()`
   - Comment: `softDelete()`

4. **타입 일관성**
   - viewCount, likeCount, commentCount, replyCount를 모두 `Long` 또는 `Int`로 통일

5. **DTO 수정**
   - 제거된 필드 참조 제거
   - 타입 불일치 수정

---

## 🎯 Phase 4 요약

**핵심 성과**:
1. ✅ **Permission Enum 타입 불일치 완전 해결** (entity 패키지 중복 제거)
2. ✅ **Null Safety 개선** (workspace nullable 문제 우회)
3. ✅ **GroupVisibility 완전 제거** (Repository, Service, DTO, Controller 전체 수정)
4. ✅ **isDefault 필드 제거** (ChannelService, Repository 수정)
5. ✅ **Channel.displayOrder var 수정** (재할당 가능)

**남은 과제**:
- ❌ Entity 불변성 문제 (30개 컴파일 에러)
- ❌ 제거된 필드 참조 (DTO, Service)
- ❌ 타입 불일치 (Long vs Int)

**다음 작업**: Phase 5 (Entity 재설계) 또는 Phase 6 (테스트 우선) 선택 가능
