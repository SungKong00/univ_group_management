# Backend Architecture (Refactored)

## 도메인 경계 (Bounded Contexts)

```
com.univgroup/
├── domain/                    # 도메인 레이어
│   ├── user/                  # User 도메인
│   │   ├── entity/           # User
│   │   ├── repository/
│   │   ├── service/          # IUserService (공개 API)
│   │   ├── controller/
│   │   └── dto/
│   │
│   ├── group/                 # Group 도메인
│   │   ├── entity/           # Group, GroupMember, GroupRole
│   │   ├── repository/
│   │   ├── service/          # IGroupService, IGroupMemberService (공개 API)
│   │   ├── controller/
│   │   └── dto/
│   │
│   ├── permission/            # Permission 도메인
│   │   ├── entity/           # (필요시 추가)
│   │   ├── repository/
│   │   ├── service/
│   │   └── evaluator/        # IPermissionEvaluator (공개 API)
│   │
│   ├── workspace/             # Workspace 도메인
│   │   ├── entity/           # Workspace, Channel, ChannelRoleBinding
│   │   ├── repository/
│   │   ├── service/
│   │   ├── controller/
│   │   └── dto/
│   │
│   ├── content/               # Content 도메인
│   │   ├── entity/           # Post, Comment
│   │   ├── repository/
│   │   ├── service/
│   │   ├── controller/
│   │   └── dto/
│   │
│   └── calendar/              # Calendar 도메인 (향후)
│       └── ...
│
└── shared/                    # 공통 모듈
    ├── dto/                  # ApiResponse, ErrorCode
    ├── exception/            # BusinessException, GlobalExceptionHandler
    ├── security/             # JWT, OAuth 설정
    ├── config/               # Spring 설정
    └── util/                 # 유틸리티
```

## 도메인 간 의존성 규칙

```
┌─────────────┐
│   Content   │ ──────────────────────────────────┐
└─────────────┘                                   │
       │                                          │
       │ uses                                     │ uses
       ▼                                          ▼
┌─────────────┐     uses      ┌─────────────────────┐
│  Workspace  │ ───────────▶ │     Permission      │
└─────────────┘               │   (Evaluator)       │
       │                      └─────────────────────┘
       │ uses                          ▲
       ▼                               │ uses
┌─────────────┐                        │
│    Group    │ ───────────────────────┘
└─────────────┘
       │
       │ uses
       ▼
┌─────────────┐
│    User     │
└─────────────┘
```

### 규칙

1. **Repository 직접 접근 금지**: 다른 도메인의 Repository에 직접 접근하지 않음
2. **Service 인터페이스 통해 통신**: `IUserService`, `IGroupService`, `IPermissionEvaluator`
3. **순환 의존 금지**: A → B → A 형태의 의존성 금지

## 권한 검증 패턴 (역함수 패턴)

```kotlin
// Controller: 권한 먼저 확인
@GetMapping("/{channelId}/posts")
fun listPosts(
    @PathVariable channelId: Long,
    authentication: Authentication,
): ApiResponse<List<PostDto>> {
    val userId = getCurrentUserId(authentication)

    // 1단계: 권한 확인 (DB 접근 전)
    permissionEvaluator.requireChannelPermission(userId, channelId, ChannelPermission.POST_READ)

    // 2단계: 권한 확인된 후 Service 호출
    val posts = postService.listPosts(channelId)
    return ApiResponse.success(posts)
}
```

## API 응답 형식

모든 API는 `ApiResponse<T>` 형식으로 응답:

```json
// 성공
{
  "success": true,
  "data": { ... },
  "error": null,
  "timestamp": "2025-11-29T10:30:00Z"
}

// 실패
{
  "success": false,
  "data": null,
  "error": {
    "code": "GROUP_NOT_FOUND",
    "message": "그룹을 찾을 수 없습니다"
  },
  "timestamp": "2025-11-29T10:30:00Z"
}
```

## 완료된 Phase

- [x] Phase 0: 기반 구조 설계
  - 도메인 디렉토리 구조
  - 공통 모듈 (ApiResponse, ErrorCode, Exception)
  - 도메인 인터페이스 (IPermissionEvaluator, IGroupService, IUserService)
  - 핵심 엔티티 (User, Group, GroupRole, GroupMember, Workspace, Channel, Post, Comment)

- [x] Phase 1: Permission 도메인 구현
  - PermissionConstants (GroupPermission, ChannelPermission, SystemRole)
  - PermissionCacheManager (Caffeine 캐시)
  - AuditLogger (권한 검증 로깅)
  - PermissionEvaluator (역함수 패턴 구현체)
  - PermissionLoader (권한 조회)

- [x] Phase 2: Group 도메인 구현
  - Repository: GroupRepository, GroupMemberRepository, GroupRoleRepository
  - Service: GroupService, GroupMemberService, GroupRoleService
  - DTO: GroupDto, GroupMemberDto, GroupRoleDto
  - Controller: GroupController, GroupMemberController, GroupRoleController
  - PermissionLoader에 Repository 연동

- [x] Phase 3: Content 도메인 구현
  - Repository: PostRepository, CommentRepository
  - Service: PostService, CommentService
  - DTO: PostDto, CommentDto
  - Controller: PostController, CommentController
  - 역함수 패턴 적용 (채널 권한 확인 후 조회/수정)

- [x] Phase 4: Workspace/Channel 도메인 구현
  - Repository: WorkspaceRepository, ChannelRepository, ChannelRoleBindingRepository
  - Service: WorkspaceService, ChannelService
  - DTO: WorkspaceDto, ChannelDto
  - Controller: WorkspaceController, ChannelController

- [x] Phase 5: User 도메인 & API 표준화
  - Repository: UserRepository
  - Service: UserService
  - DTO: UserDto
  - Controller: UserController

## 진행 예정 Phase

- [ ] Phase 6: 테스트 & 문서화
- [ ] Phase 7: 테스트 데이터 (DevDataRunner, DemoDataRunner)
