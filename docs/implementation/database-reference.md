# 데이터베이스 참조 가이드 (Database Reference)

## 핵심 엔티티 관계

```
User [1:N] GroupMember [N:1] Group [1:1] Workspace [1:N] Channel [1:N] Post [1:N] Comment
                                  GroupRole [1:N] GroupMember
```

## 사용자 관련 테이블

### User 엔티티 (JPA) {#User}
*   **파일 위치**: `backend/src/main/kotlin/org/castlekong/backend/entity/User.kt`
*   **설명**: 시스템의 모든 사용자를 나타내는 핵심 엔티티입니다.

```kotlin
@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener::class)
data class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false, length = 50)
    val name: String, // 사용자 실명

    @Column(nullable = false, unique = true, length = 100)
    val email: String, // Google OAuth를 통해 받은 이메일 (로그인 ID로 사용)

    @Column(name = "password_hash", nullable = false)
    val password: String, // Google OAuth 인증이므로 실제 비밀번호 대신 임의의 해시값 저장

    @Enumerated(EnumType.STRING)
    @Column(name = "global_role", nullable = false)
    val globalRole: GlobalRole = GlobalRole.STUDENT, // 전역 역할 (학생, 교수, 관리자)

    @Column(name = "is_active", nullable = false)
    val isActive: Boolean = true, // 계정 활성 상태

    @Column(length = 50)
    val nickname: String? = null, // 사용자 별명

    @Column(name = "profile_image_url", length = 255)
    val profileImageUrl: String? = null, // 프로필 이미지 URL

    @Column(columnDefinition = "TEXT")
    val bio: String? = null, // 자기소개

    @Column(name = "profile_completed", nullable = false)
    val profileCompleted: Boolean = false, // 추가 정보(학과, 학번 등) 입력 완료 여부

    @Column(name = "email_verified", nullable = false)
    val emailVerified: Boolean = true, // 이메일 인증 여부 (MVP에서는 기본 true)

    // --- 학교 정보 (온보딩 시 입력) ---
    @Column(name = "college", length = 100)
    val college: String? = null, // 단과대학

    @Column(name = "department", length = 100)
    val department: String? = null, // 학과/학부

    @Column(name = "student_no", nullable = false, length = 30)
    val studentNo: String, // 학번 (온보딩 시 필수 입력)

    @Column(name = "academic_email", nullable = false, length = 100)
    val academicEmail: String, // 학교 이메일 (온보딩 시 필수 입력)

    @Column(name = "academic_year", nullable = false)
    val academicYear: Int, // 학년 (온보딩 시 필수 입력)

    @Enumerated(EnumType.STRING)
    @Column(name = "professor_status")
    val professorStatus: ProfessorStatus? = null, // 교수 인증 상태

    // --- 타임스탬프 (JPA Auditing) ---
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(), // 생성 일시

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(), // 마지막 수정 일시
)

// 전역 역할 Enum
enum class GlobalRole {
    STUDENT,
    PROFESSOR,
    ADMIN,
}

// 교수 인증 상태 Enum
enum class ProfessorStatus {
    PENDING,
    APPROVED,
    REJECTED,
}
```

## 그룹 관련 테이블

### Group 엔티티 (JPA) {#Group}
*   **파일 위치**: `backend/src/main/kotlin/org/castlekong/backend/entity/Group.kt`
*   **설명**: 모든 조직(학과, 동아리, 스터디 등)을 나타내는 엔티티. 계층 구조를 가집니다.

```kotlin
@Entity
@Table(name = "groups")
data class Group(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false, length = 100)
    val name: String, // 그룹 이름

    @Column(length = 500)
    val description: String? = null, // 그룹 설명

    @Column(name = "profile_image_url", length = 500)
    val profileImageUrl: String? = null, // 그룹 프로필 이미지

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    val owner: User, // 그룹 소유자

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    val parent: Group? = null, // 상위 그룹 (계층 구조)

    // --- 그룹 속성 ---
    @Enumerated(EnumType.STRING)
    @Column(name = "group_type", nullable = false, length = 20)
    val groupType: GroupType = GroupType.AUTONOMOUS, // 그룹 유형

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "group_tags", joinColumns = [JoinColumn(name = "group_id")])
    @Column(name = "tag", nullable = false, length = 50)
    val tags: Set<String> = emptySet(), // 그룹 태그

    // --- 대학/학과 정보 (해당 시) ---
    @Column(name = "university", length = 100)
    val university: String? = null,
    @Column(name = "college", length = 100)
    val college: String? = null,
    @Column(name = "department", length = 100)
    val department: String? = null,

    // --- 운영 정보 ---
    @Column(name = "max_members")
    val maxMembers: Int? = null, // 최대 멤버 수

    @Column(name = "default_channels_created", nullable = false)
    val defaultChannelsCreated: Boolean = false, // 기본 채널 생성 여부

    // --- 타임스탬프 ---
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "deleted_at")
    val deletedAt: LocalDateTime? = null, // Soft delete를 위한 필드
)

// 그룹 유형 Enum
enum class GroupType {
    AUTONOMOUS, // 자율그룹
    OFFICIAL, // 공식그룹
    UNIVERSITY, // 대학교
    COLLEGE, // 단과대학
    DEPARTMENT, // 학과/계열
    LAB, // 연구실/랩실
}
```

### GroupMember 엔티티 (JPA) {#GroupMember}
*   **파일 위치**: `backend/src/main/kotlin/org/castlekong/backend/entity/GroupMember.kt`
*   **설명**: 사용자와 그룹 간의 멤버십 관계를 정의하는 중간 테이블 엔티티.

```kotlin
@Entity
@Table(
    name = "group_members",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "user_id"]),
    ],
)
data class GroupMember(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group, // 소속 그룹

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User, // 소속 사용자

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id", nullable = false)
    val role: GroupRole, // 부여된 역할

    @Column(name = "joined_at", nullable = false)
    val joinedAt: LocalDateTime = LocalDateTime.now(), // 가입 일시
)
```

### GroupRole 엔티티 (JPA) {#GroupRole}
*   **파일 위치**: `backend/src/main/kotlin/org/castlekong/backend/entity/GroupRole.kt`
*   **설명**: 그룹 내 역할. 시스템 역할(그룹장 / 교수 / 멤버)은 불변(이름/우선순위/권한 수정 및 삭제 금지, ErrorCode.SYSTEM_ROLE_IMMUTABLE).
*   **변경 요약(2025-10-01)**: data class → 일반 class, id 기반 equals/hashCode, permissions: MutableSet.

```kotlin
@Entity
@Table(
    name = "group_roles",
    uniqueConstraints = [UniqueConstraint(columnNames = ["group_id", "name")] ]
)
class GroupRole(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "group_id", nullable = false)
    var group: Group,
    @Column(nullable = false, length = 50)
    var name: String,
    @Column(name = "is_system_role", nullable = false)
    var isSystemRole: Boolean = false,
    @Enumerated(EnumType.STRING)
    @Column(name = "role_type", nullable = false, length = 20)
    var roleType: RoleType = RoleType.OPERATIONAL,
    @Column(nullable = false)
    var priority: Int = 0,
    @ElementCollection(targetClass = GroupPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_role_permissions", joinColumns = [JoinColumn(name = "group_role_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    var permissions: MutableSet<GroupPermission> = mutableSetOf(),
) {
    fun update(name: String? = null, priority: Int? = null) { name?.let { this.name = it }; priority?.let { this.priority = it } }
    fun replacePermissions(newPerms: Collection<GroupPermission>) { permissions.clear(); permissions.addAll(newPerms) }
    override fun equals(other: Any?) = other is GroupRole && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

> 시스템 역할은 서비스 계층에서 수정/삭제 시 BusinessException(ErrorCode.SYSTEM_ROLE_IMMUTABLE)

## 워크스페이스 & 채널

### Workspace 테이블 {#Workspace}
```sql
CREATE TABLE workspaces (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    group_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    -- is_default 필드 제거: 그룹당 워크스페이스 1개 고정
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);

-- 인덱스
CREATE INDEX idx_workspace_group ON workspaces(group_id);
```

### Channel 테이블 {#Channel}
```sql
CREATE TABLE channels (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    workspace_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    type ENUM('TEXT', 'VOICE', 'ANNOUNCEMENT', 'FILE_SHARE') DEFAULT 'TEXT',
    is_private BOOLEAN DEFAULT false,
    description TEXT,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
);

-- 인덱스
CREATE INDEX idx_channel_workspace ON channels(workspace_id);
CREATE INDEX idx_channel_order ON channels(workspace_id, display_order);
```

### ChannelRoleBinding 테이블 (채널 권한 매핑) {#ChannelRoleBinding}
* 목적: 그룹 역할(GroupRole) ↔ 채널(Channel) 사이의 가시성/읽기/쓰기 권한 결합
* 자동 생성 정책(변경됨 2025-10-01 rev5): **그룹 생성 시 초기 2개 채널(공지/자유)만 템플릿 바인딩 자동 생성**, 이후 사용자 정의 채널은 0개 바인딩에서 시작 (UI 권한 매트릭스에서 수동 구성 필요)
* 권한 평가: (1) 그룹 역할의 그룹 수준 권한 (2) 채널 바인딩 권한(override 성격) 결합

```sql
CREATE TABLE channel_role_bindings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    channel_id BIGINT NOT NULL,
    group_role_id BIGINT NOT NULL,
    can_view BOOLEAN NOT NULL DEFAULT false,
    can_post BOOLEAN NOT NULL DEFAULT false,
    can_manage BOOLEAN NOT NULL DEFAULT false, -- 채널 설정/순서 관리
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_channel_role (channel_id, group_role_id),
    FOREIGN KEY (channel_id) REFERENCES channels(id) ON DELETE CASCADE,
    FOREIGN KEY (group_role_id) REFERENCES group_roles(id) ON DELETE CASCADE
);

-- 조회 최적화 인덱스
CREATE INDEX idx_crb_role ON channel_role_bindings(group_role_id, channel_id);
CREATE INDEX idx_crb_channel ON channel_role_bindings(channel_id, group_role_id);
```

#### JPA 개요 (요약)
```kotlin
@Entity
@Table(
    name = "channel_role_bindings",
    uniqueConstraints = [UniqueConstraint(columnNames = ["channel_id", "group_role_id"])]
)
class ChannelRoleBinding(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "channel_id", nullable = false)
    var channel: Channel,
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "group_role_id", nullable = false)
    var role: GroupRole,
    @Column(name = "can_view", nullable = false) var canView: Boolean = false,
    @Column(name = "can_post", nullable = false) var canPost: Boolean = false,
    @Column(name = "can_manage", nullable = false) var canManage: Boolean = false,
) {
    fun update(view: Boolean? = null, post: Boolean? = null, manage: Boolean? = null) {
        view?.let { canView = it }; post?.let { canPost = it }; manage?.let { canManage = it }
    }
    override fun equals(other: Any?) = other is ChannelRoleBinding && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

> 생성 규칙: 서비스 계층은 필요 시 명시적으로 생성. 기본 가시성은 그룹 역할의 채널 접근 암묵 권한이 아닌, 존재하는 바인딩 기준으로만 판단 (미존재 → 접근 불가). 향후 캐시 계층(e.g. Redis) 적용 시 channel_id + role_id 키로 압축 저장 예정.

## 컨텐츠 테이블

### Post 테이블
```sql
CREATE TABLE posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    channel_id BIGINT NOT NULL,
    author_id BIGINT NOT NULL,
    title VARCHAR(200),
    content TEXT NOT NULL,
    type ENUM('GENERAL', 'ANNOUNCEMENT', 'QUESTION', 'POLL') DEFAULT 'GENERAL',
    is_pinned BOOLEAN DEFAULT false,
    view_count BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (channel_id) REFERENCES channels(id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES users(id)
);

-- 인덱스
CREATE INDEX idx_post_channel ON posts(channel_id);
CREATE INDEX idx_post_author ON posts(author_id);
CREATE INDEX idx_post_created ON posts(created_at DESC);
CREATE INDEX idx_post_pinned ON posts(channel_id, is_pinned, created_at DESC);
```

### Comment 테이블
```sql
CREATE TABLE comments (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    post_id BIGINT NOT NULL,
    author_id BIGINT NOT NULL,
    parent_comment_id BIGINT,
    content TEXT NOT NULL,
    depth INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES users(id),
    FOREIGN KEY (parent_comment_id) REFERENCES comments(id)
);

-- 인덱스
CREATE INDEX idx_comment_post ON comments(post_id);
CREATE INDEX idx_comment_parent ON comments(parent_comment_id);
CREATE INDEX idx_comment_created ON comments(post_id, created_at);
```

## 가입 요청 관리

### GroupJoinRequest 테이블
```sql
CREATE TABLE group_join_requests (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    group_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
    message TEXT,
    processed_by BIGINT,
    processed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (processed_by) REFERENCES users(id),

    UNIQUE KEY unique_request (group_id, user_id, status)
);
```

## 복잡한 쿼리 예시

### 사용자가 속한 그룹 조회 (권한 포함)
*   **참고**: 개인별 권한 재정의(Override) 기능이 제거되어 쿼리가 단순화되었습니다.

```sql
SELECT
    g.id, g.name,
    gr.name as role_name,
    gr.permissions as role_permissions
FROM groups g
JOIN group_members gm ON g.id = gm.group_id
JOIN group_roles gr ON gm.role_id = gr.id
WHERE gm.user_id = ? AND g.deleted_at IS NULL
ORDER BY gm.joined_at DESC;
```

### 그룹 계층 구조 조회 (재귀 CTE)
```sql
WITH RECURSIVE group_hierarchy AS (
    -- 기준 그룹
    SELECT id, name, parent_group_id, 0 as level
    FROM groups
    WHERE id = ?

    UNION ALL

    -- 하위 그룹들
    SELECT g.id, g.name, g.parent_group_id, gh.level + 1
    FROM groups g
    JOIN group_hierarchy gh ON g.parent_group_id = gh.id
    WHERE g.deleted_at IS NULL
)
SELECT * FROM group_hierarchy ORDER BY level, name;
```

### 채널별 최신 게시글 조회
```sql
SELECT DISTINCT
    c.id as channel_id,
    c.name as channel_name,
    p.id as latest_post_id,
    p.title as latest_post_title,
    u.nickname as latest_author,
    p.created_at as latest_post_time
FROM channels c
LEFT JOIN posts p ON c.id = p.channel_id
LEFT JOIN users u ON p.author_id = u.id
WHERE c.workspace_id = ?
AND p.id = (
    SELECT p2.id
    FROM posts p2
    WHERE p2.channel_id = c.id
    ORDER BY p2.created_at DESC
    LIMIT 1
)
ORDER BY p.created_at DESC;
```

## 성능 최적화

### 주요 인덱스 전략 (V2 마이그레이션 기준)

`V2__add_performance_indexes.sql` 마이그레이션을 통해 대규모 인덱스가 추가되었습니다. 주요 전략은 다음과 같습니다.

-   **외래 키 (FK) 인덱싱**: 대부분의 `*_id` 외래 키 컬럼에 인덱스를 추가하여 `JOIN` 성능을 향상시킵니다.
-   **복합 인덱스**: `WHERE` 절에서 자주 함께 사용되는 컬럼들을 묶어 복합 인덱스를 생성합니다. (예: `group_members(group_id, user_id)`)
-   **정렬 순서 고려**: `ORDER BY` 절에 사용되는 컬럼(특히 `created_at DESC`)에 대한 인덱스를 생성하여 정렬 성능을 최적화합니다.
-   **소프트 삭제 고려**: `deleted_at IS NULL` 조건을 포함하는 부분 인덱스를 생성하여 활성 레코드 조회 속도를 높입니다.

```sql
-- V2__add_performance_indexes.sql

-- Groups 테이블
CREATE INDEX IF NOT EXISTS idx_groups_parent_id ON groups (parent_id);
CREATE INDEX IF NOT EXISTS idx_groups_owner_id ON groups (owner_id);
CREATE INDEX IF NOT EXISTS idx_groups_deleted_at ON groups (deleted_at);
CREATE INDEX IF NOT EXISTS idx_groups_university_college_dept ON groups (university, college, department);
CREATE INDEX IF NOT EXISTS idx_groups_group_type ON groups (group_type);
CREATE INDEX IF NOT EXISTS idx_groups_created_at ON groups (created_at);

-- Group Members 테이블
CREATE INDEX IF NOT EXISTS idx_group_members_group_user ON group_members(group_id, user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_role_id ON group_members(role_id);
CREATE INDEX IF NOT EXISTS idx_group_members_joined_at ON group_members(joined_at);

-- Group Roles 테이블
CREATE INDEX IF NOT EXISTS idx_group_roles_group_name ON group_roles(group_id, name);
CREATE INDEX IF NOT EXISTS idx_group_roles_system_role ON group_roles(is_system_role);
CREATE INDEX IF NOT EXISTS idx_group_roles_priority ON group_roles(priority DESC);

-- Channels, Posts, Comments 등 다른 주요 테이블에도 유사한 전략의 인덱스가 추가되었습니다.
-- 전체 목록은 V2 마이그레이션 스크립트를 참조하십시오.

-- 복합 인덱스 (자주 함께 사용되는 컬럼들)
CREATE INDEX IF NOT EXISTS idx_groups_deleted_type ON groups (deleted_at, group_type) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_group_members_group_role_joined ON group_members(group_id, role_id, joined_at);
CREATE INDEX IF NOT EXISTS idx_posts_channel_created_pinned ON posts(channel_id, created_at DESC, is_pinned DESC);
CREATE INDEX IF NOT EXISTS idx_comments_post_created ON comments(post_id, created_at);
```

### 페이징 최적화
```sql
-- 커서 기반 페이징 (offset 대신 사용)
SELECT * FROM posts
WHERE channel_id = ? AND id < ?
ORDER BY id DESC
LIMIT 20;
```

## 데이터 마이그레이션

### 초기 데이터 설정 (v2, 2025-10-07 이후)

`data.sql` 파일은 이제 시스템 운영에 필요한 최소한의 데이터만 포함합니다.

-   **포함되는 데이터**: `users`, `groups` (기본적인 대학교, 계열, 학과 구조)
-   **제외되는 데이터**: `group_roles`, `group_members`, `channels`, `channel_role_bindings` 등

애플리케이션 시작 시 `GroupInitializationRunner`가 `defaultChannelsCreated`가 `false`인 그룹을 대상으로 기본 역할, 채널, 멤버십을 자동으로 생성합니다. 이로 인해 `data.sql`은 매우 단순하게 유지됩니다.

**`data.sql` 예시:**
```sql
-- 사용자 생성
INSERT INTO users (id, email, name, ...) VALUES (1, 'castlekong1019@gmail.com', ...);

-- 최상위 그룹(대학교) 생성
INSERT INTO groups (id, name, owner_id, university, group_type, ...) VALUES (1, '한신대학교', 1, '한신대학교', 'UNIVERSITY', ...);

-- 하위 그룹(계열) 생성
INSERT INTO groups (id, name, owner_id, parent_id, ...) VALUES (2, 'AI/SW계열', 1, 1, ...);
```

> **참고**: 상세한 초기화 로직은 `GroupInitializationRunner`, `GroupRoleInitializationService`, `ChannelInitializationService` 코드를 참조하십시오.

## 변경 이력 (발췌)
| 날짜 | 변경 사항 |
|------|-----------|
| 2025-10-18 | **V5 마이그레이션**: GroupEvent에 장소 통합 (location → location_text 변경, place_id 외래키 추가, 3가지 모드 지원) |
| 2025-10-06 | **V2 마이그레이션**: 프로덕션 환경을 위한 대규모 성능 최적화 인덱스 추가. |
| 2025-10-01 | GroupRole 비불변화(data class 제거), 시스템 역할 불변성 명시, ChannelRoleBinding 자동 생성 제거, ChannelRoleBinding 스키마/엔티티 추가, 삭제 Bulk 순서 추가 |

## 캘린더 시스템 테이블 (Calendar System)

> **개발 우선순위**: Phase 6 이후 예정
> **상태**: 스키마 설계 완료 (2025-10-07), 구현 예정
> **관련 문서**: [캘린더 통합](../concepts/calendar-integration.md) | [캘린더 핵심 설계](../backend/calendar-core-design.md) | [장소 캘린더 시스템](../concepts/place-calendar-system.md)

캘린더 시스템은 학교 시간표, 개인 일정, 그룹 일정, 장소 예약을 관리하는 9개 엔티티로 구성됩니다.

### 엔티티 관계 다이어그램

```
User [1:N] CourseTimetable
User [1:N] PersonalSchedule
User + Group [1:N] GroupEvent (creator + group)

GroupEvent [1:N] EventParticipant [N:1] User
GroupEvent [1:N] EventException
GroupEvent [0:1] PlaceReservation [N:1] Place

Place [N:1] Group (관리 주체)
Place [1:N] PlaceUsageGroup [N:1] Group (사용 그룹)
```

### 설계 원칙 및 주요 결정사항

- **DD-CAL-001**: 권한 통합 - RBAC 시스템에 4개 캘린더 권한 추가
- **DD-CAL-002**: 반복 일정 명시적 인스턴스 저장 (범위 지정 필수)
- **DD-CAL-003**: EventException 분리로 예외 관리
- **DD-CAL-004**: EventParticipant 독립 엔티티로 상태 추적
- **DD-CAL-005**: Course와 CourseTimetable 분리 (과목 vs 분반)
- **DD-CAL-006**: PlaceReservation은 GroupEvent의 부속 (1:1)
- **DD-CAL-007**: 최적 시간 추천 - 가능 인원 최대화 알고리즘
- **DD-CAL-008**: 동시성 제어 - 낙관적 락 + 중복 검증

---

## 1. 개인 캘린더 (Personal Calendar)

### 1.1. PersonalEvent 테이블 (개인 이벤트)

사용자가 개인 캘린더에 직접 추가하는 일회성 이벤트 정보입니다.

```sql
CREATE TABLE personal_events (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    location VARCHAR(100),
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    is_all_day BOOLEAN DEFAULT false,
    color VARCHAR(7),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_personal_event_user ON personal_events(user_id);
CREATE INDEX idx_personal_event_date ON personal_events(user_id, start_date, end_date);
```

---

## 2. 학교 시간표 (School Timetable)

### 2.1. Course 테이블 (과목 정보)

관리자가 등록한 대학 강의 과목 정보입니다. 동일 과목의 여러 분반을 지원하기 위해 Course와 CourseTimetable을 분리합니다.

```sql
CREATE TABLE courses (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    university VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    semester VARCHAR(20) NOT NULL, -- 예: '2025-1', '2025-2'
    course_code VARCHAR(20) NOT NULL, -- 과목 코드 (예: 'CS101')
    course_name VARCHAR(100) NOT NULL,
    credits INT NOT NULL,
    professor_name VARCHAR(50),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_course (university, department, semester, course_code)
);

CREATE INDEX idx_course_semester ON courses(university, semester);
CREATE INDEX idx_course_dept ON courses(department, semester);
```

### 2.2. CourseTimetable 테이블 (분반별 시간표)

사용자가 자신의 시간표에 추가할 수 있는 강의 분반 정보입니다.

```sql
CREATE TABLE course_timetables (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    course_id BIGINT NOT NULL,
    section_number VARCHAR(10) NOT NULL, -- 분반 번호 (예: '01', '02')
    day_of_week ENUM('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    location VARCHAR(100), -- 강의실 위치
    max_students INT, -- 수강 정원
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

CREATE INDEX idx_timetable_course ON course_timetables(course_id);
CREATE INDEX idx_timetable_time ON course_timetables(day_of_week, start_time);
```

### 2.3. UserCourseTimetable 테이블 (사용자 수강 목록)

사용자가 선택한 강의 목록입니다. 사용자와 CourseTimetable의 다대다 관계를 나타냅니다.

```sql
CREATE TABLE user_course_timetables (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    course_timetable_id BIGINT NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uk_user_course (user_id, course_timetable_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (course_timetable_id) REFERENCES course_timetables(id) ON DELETE CASCADE
);

CREATE INDEX idx_user_course_user ON user_course_timetables(user_id);
CREATE INDEX idx_user_course_timetable ON user_course_timetables(course_timetable_id);
```

---

## 3. 개인 시간표 (Personal Timetable)

### 3.1. PersonalSchedule 테이블 (개인 반복 일정)

사용자가 직접 생성한 반복 일정 (아르바이트, 근로장학생 등)입니다. **단순 주간 반복 방식**을 사용합니다 (매주 특정 요일에 반복).

```sql
CREATE TABLE personal_schedules (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    location VARCHAR(100),
    day_of_week ENUM('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_all_day BOOLEAN DEFAULT false,
    color VARCHAR(7), -- 색상 코드 (#RRGGBB)

    -- 반복 패턴 정보 (원본 보존용)
    series_id VARCHAR(50), -- 동일 반복 패턴 그룹화
    recurrence_rule TEXT, -- RRULE 형식 또는 JSON
    valid_from DATE NOT NULL, -- 유효 시작일
    valid_until DATE, -- 유효 종료일 (NULL이면 무기한)

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_personal_user ON personal_schedules(user_id);
CREATE INDEX idx_personal_series ON personal_schedules(series_id);
CREATE INDEX idx_personal_day ON personal_schedules(user_id, day_of_week, start_time);
CREATE INDEX idx_personal_date ON personal_schedules(user_id, valid_from, valid_until);
```

**JPA 엔티티 (PersonalSchedule.kt)**:

```kotlin
@Entity
@Table(name = "personal_schedules")
class PersonalSchedule(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    var user: User,

    @Column(nullable = false, length = 200)
    var title: String,

    @Column(columnDefinition = "TEXT")
    var description: String? = null,

    @Column(length = 100)
    var location: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false)
    var dayOfWeek: DayOfWeek,

    @Column(name = "start_time", nullable = false)
    var startTime: LocalTime,

    @Column(name = "end_time", nullable = false)
    var endTime: LocalTime,

    @Column(name = "is_all_day", nullable = false)
    var isAllDay: Boolean = false,

    @Column(length = 7)
    var color: String? = null,

    // 반복 패턴 정보
    @Column(name = "series_id", length = 50)
    var seriesId: String? = null,

    @Column(name = "recurrence_rule", columnDefinition = "TEXT")
    var recurrenceRule: String? = null,

    @Column(name = "valid_from", nullable = false)
    var validFrom: LocalDate,

    @Column(name = "valid_until")
    var validUntil: LocalDate? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    override fun equals(other: Any?) = other is PersonalSchedule && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

enum class DayOfWeek {
    MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY
}
```

---

## 4. 그룹 일정 (Group Event)

그룹 캘린더의 공식/비공식 일정입니다. 반복 일정 지원 및 채널 게시글 연동 기능이 포함됩니다.

```sql
CREATE TABLE group_events (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    group_id BIGINT NOT NULL,
    creator_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,

    -- ===== 장소 통합 (3가지 모드 지원) - V5 Migration =====
    -- Mode A: location_text=null, place_id=null (장소 없음)
    -- Mode B: location_text="텍스트", place_id=null (수동 입력)
    -- Mode C: location_text=null, place_id=1 (장소 선택 + 자동 예약)
    -- 주의: locationText와 placeId는 상호 배타적 (엔티티에서 검증)
    location_text VARCHAR(100),  -- 기존 'location' 컬럼 이름 변경
    place_id BIGINT,              -- 장소 선택 시 외래키

    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    is_all_day BOOLEAN DEFAULT false,

    -- 일정 분류
    is_official BOOLEAN DEFAULT false, -- 공식 일정 여부
    event_type ENUM('GENERAL', 'TARGETED', 'RSVP') DEFAULT 'GENERAL',

    -- 반복 패턴 정보
    series_id VARCHAR(50), -- 동일 반복 패턴 그룹화
    recurrence_rule TEXT, -- JSON 형식: {"type": "DAILY"} 또는 {"type": "WEEKLY", "daysOfWeek": ["MONDAY", "WEDNESDAY"]}

    -- 메타 정보
    color VARCHAR(7) NOT NULL DEFAULT '#3B82F6', -- 색상 코드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (creator_id) REFERENCES users(id),
    FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE SET NULL
);

-- 기본 인덱스
CREATE INDEX idx_event_group ON group_events(group_id);
CREATE INDEX idx_event_creator ON group_events(creator_id);
CREATE INDEX idx_event_date ON group_events(group_id, start_date, end_date);
CREATE INDEX idx_event_series ON group_events(series_id);
CREATE INDEX idx_event_official ON group_events(group_id, is_official, start_date);
CREATE INDEX idx_event_type ON group_events(group_id, event_type);

-- 장소 연동 인덱스 (V5 Migration)
CREATE INDEX idx_group_event_place ON group_events(place_id);
```

**JPA 엔티티 (GroupEvent.kt)**:

```kotlin
@Entity
@Table(name = "group_events")
data class GroupEvent(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id", nullable = false)
    val creator: User,

    @Column(nullable = false, length = 200)
    val title: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    // ===== 장소 통합 필드 (3가지 모드 지원) - V5 Migration =====
    // Mode A: locationText=null, place=null (장소 없음)
    // Mode B: locationText="텍스트", place=null (수동 입력)
    // Mode C: locationText=null, place=Place객체 (장소 선택 + 자동 예약)
    @Column(name = "location_text", length = 100)
    val locationText: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id")
    val place: Place? = null,

    @Column(name = "start_date", nullable = false)
    val startDate: LocalDateTime,

    @Column(name = "end_date", nullable = false)
    val endDate: LocalDateTime,

    @Column(name = "is_all_day", nullable = false)
    val isAllDay: Boolean = false,

    // 일정 분류
    @Column(name = "is_official", nullable = false)
    val isOfficial: Boolean = false,

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false)
    val eventType: EventType = EventType.GENERAL,

    // 반복 패턴
    @Column(name = "series_id", length = 50)
    val seriesId: String? = null,

    @Column(name = "recurrence_rule", columnDefinition = "TEXT")
    val recurrenceRule: String? = null, // JSON 형식: {"type": "DAILY"} 또는 {"type": "WEEKLY", "daysOfWeek": ["MONDAY", "WEDNESDAY"]}

    @Column(length = 7, nullable = false)
    val color: String = "#3B82F6", // 색상 코드

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    init {
        // 검증: locationText와 place는 동시에 값을 가질 수 없음 (상호 배타적)
        require(locationText.isNullOrBlank() || place == null) {
            "locationText와 place는 동시에 값을 가질 수 없습니다. " +
                "(locationText='$locationText', place.id=${place?.id})"
        }
    }
}

enum class EventType {
    GENERAL,   // 일반 공지형 (MVP)
    TARGETED,  // 대상 지정형 (Phase 2)
    RSVP,      // 참여 신청형 (Phase 2)
}
```

---

## 5. 일정 참여자 (Event Participant)

일정 참여자 정보 및 참여 상태를 추적합니다.

```sql
CREATE TABLE event_participants (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    status ENUM('PENDING', 'ACCEPTED', 'DECLINED') DEFAULT 'PENDING',
    decline_reason TEXT, -- 불참 사유
    notification_sent BOOLEAN DEFAULT false, -- 알림 발송 여부
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_event_participant (event_id, user_id),
    FOREIGN KEY (event_id) REFERENCES group_events(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_participant_event ON event_participants(event_id);
CREATE INDEX idx_participant_user ON event_participants(user_id);
CREATE INDEX idx_participant_status ON event_participants(user_id, status);
```

**JPA 엔티티 (EventParticipant.kt)** - 2025-10 구현 완료:

```kotlin
@Entity
@Table(
    name = "event_participants",
    uniqueConstraints = [UniqueConstraint(columnNames = ["group_event_id", "user_id"])]
)
class EventParticipant(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_event_id", nullable = false)
    val groupEvent: GroupEvent,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val status: ParticipantStatus = ParticipantStatus.PENDING,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),
)

enum class ParticipantStatus {
    PENDING,    // 초대됨 (아직 응답 안 함)
    ACCEPTED,   // 수락 (참여 확정)
    REJECTED,   // 거절 (불참)
    TENTATIVE   // 미정 (참석 여부 불확실)
}
```

**구현 위치**: `backend/src/main/kotlin/org/castlekong/backend/entity/EventParticipant.kt`

---

## 6. 반복 일정 예외 (Event Exception)

반복 일정 중 특정 날짜만 시간/장소가 다른 경우를 처리합니다.

```sql
CREATE TABLE event_exceptions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_event_id BIGINT NOT NULL, -- 원본 반복 일정 ID
    exception_date DATE NOT NULL, -- 예외 발생 날짜

    -- 오버라이드할 필드 (NULL이면 원본 유지)
    new_title VARCHAR(200),
    new_description TEXT,
    new_location VARCHAR(100),
    new_start_time TIME,
    new_end_time TIME,
    is_cancelled BOOLEAN DEFAULT false, -- 이 날짜만 취소

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_exception (parent_event_id, exception_date),
    FOREIGN KEY (parent_event_id) REFERENCES group_events(id) ON DELETE CASCADE
);

CREATE INDEX idx_exception_parent ON event_exceptions(parent_event_id);
CREATE INDEX idx_exception_date ON event_exceptions(parent_event_id, exception_date);
```

**JPA 엔티티 (EventException.kt)** - 2025-10 구현 완료:

```kotlin
@Entity
@Table(
    name = "event_exceptions",
    uniqueConstraints = [UniqueConstraint(columnNames = ["group_event_id", "exception_date"])]
)
class EventException(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_event_id", nullable = false)
    val groupEvent: GroupEvent,

    @Column(name = "exception_date", nullable = false)
    val exceptionDate: LocalDate,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val type: ExceptionType = ExceptionType.CANCELLED,

    @Column(name = "new_start_time")
    val newStartTime: LocalDateTime? = null,

    @Column(name = "new_end_time")
    val newEndTime: LocalDateTime? = null,

    @Column(name = "modified_description", columnDefinition = "TEXT")
    val modifiedDescription: String? = null,

    @Column(columnDefinition = "TEXT")
    val reason: String? = null,
)

enum class ExceptionType {
    CANCELLED,    // 해당 날짜 일정 취소
    RESCHEDULED,  // 일정 시간 변경 (newStartTime, newEndTime 필수)
    MODIFIED      // 일정 내용 변경 (modifiedDescription 필수)
}
```

**구현 위치**: `backend/src/main/kotlin/org/castlekong/backend/entity/EventException.kt`

---

## 7. 장소 관리 (Place Management)

### 7.1. Place 테이블 (장소 정보)

그룹이 등록한 장소(동아리방, 랩실, 회의실 등) 정보입니다.

```sql
CREATE TABLE places (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    building VARCHAR(100) NOT NULL,
    room_number VARCHAR(50) NOT NULL,
    alias VARCHAR(100), -- 별칭 (예: 'AISC랩실')
    description TEXT,
    capacity INT, -- 수용 인원

    -- 관리 주체
    managing_group_id BIGINT NOT NULL, -- 현재 관리 주체 그룹

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_place (building, room_number),
    FOREIGN KEY (managing_group_id) REFERENCES groups(id)
);

CREATE INDEX idx_place_managing ON places(managing_group_id);
CREATE INDEX idx_place_building ON places(building);
```

### 7.1.1. PlaceOperatingHours 테이블 (장소 운영 시간)

장소의 기본 운영 시간을 요일별로 정의합니다. 각 요일당 하나의 시간대와 휴무 여부만 설정하여 모델을 단순화했습니다.

```sql
CREATE TABLE place_operating_hours (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    place_id BIGINT NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_closed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    UNIQUE KEY uk_operating_hours (place_id, day_of_week),
    FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE INDEX idx_operating_place ON place_operating_hours(place_id);
CREATE INDEX idx_operating_day ON place_operating_hours(place_id, day_of_week);
```

**JPA 엔티티 (PlaceOperatingHours.kt)**:

```kotlin
@Entity
@Table(
    name = "place_operating_hours",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_operating_hours", columnNames = ["place_id", "day_of_week"]),
    ]
)
class PlaceOperatingHours(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,
    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 10)
    var dayOfWeek: DayOfWeek,
    @Column(name = "start_time", nullable = false)
    var startTime: LocalTime,
    @Column(name = "end_time", nullable = false)
    var endTime: LocalTime,
    @Column(name = "is_closed", nullable = false)
    var isClosed: Boolean = false, // 해당 요일 휴무 여부
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),
    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    // ... methods ...
    override fun equals(other: Any?) = other is PlaceOperatingHours && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

### 7.1.2. PlaceBlockedTime 테이블 (장소 예약 차단 시간)

특정 날짜/시간대에 장소를 예약할 수 없는 차단 시간을 관리합니다. PlaceAvailability가 정의하는 운영 시간 내에서 추가로 예약을 차단하는 데 사용됩니다.

```sql
CREATE TABLE place_blocked_times (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    place_id BIGINT NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    block_type ENUM('MAINTENANCE', 'EMERGENCY', 'HOLIDAY', 'OTHER') NOT NULL,
    reason VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE INDEX idx_blocked_place ON place_blocked_times(place_id);
CREATE INDEX idx_blocked_time ON place_blocked_times(place_id, start_datetime, end_datetime);
CREATE INDEX idx_blocked_type ON place_blocked_times(place_id, block_type);
```

**JPA 엔티티 (PlaceBlockedTime.kt)**:

```kotlin
@Entity
@Table(name = "place_blocked_times")
class PlaceBlockedTime(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,

    @Column(name = "start_datetime", nullable = false)
    var startDatetime: LocalDateTime,

    @Column(name = "end_datetime", nullable = false)
    var endDatetime: LocalDateTime,

    @Enumerated(EnumType.STRING)
    @Column(name = "block_type", nullable = false)
    var blockType: BlockType,

    @Column(length = 200)
    var reason: String? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    override fun equals(other: Any?) = other is PlaceBlockedTime && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

enum class BlockType {
    MAINTENANCE,  // 유지보수
    EMERGENCY,    // 긴급 상황
    HOLIDAY,      // 휴일/휴무
    OTHER         // 기타
}
```

**JPA 엔티티 (Place.kt)**:

```kotlin
@Entity
@Table(
    name = "places",
    uniqueConstraints = [UniqueConstraint(columnNames = ["building", "room_number"])]
)
class Place(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,

    @Column(nullable = false, length = 100)
    var building: String,

    @Column(name = "room_number", nullable = false, length = 50)
    var roomNumber: String,

    @Column(length = 100)
    var alias: String? = null,

    @Column(columnDefinition = "TEXT")
    var description: String? = null,

    @Column
    var capacity: Int? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "managing_group_id", nullable = false)
    var managingGroup: Group,

    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    override fun equals(other: Any?) = other is Place && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()

    fun getFullName(): String = "$building-$roomNumber${alias?.let { "($it)" } ?: ""}"
}
```

### 7.2. PlaceUsageGroup 테이블 (장소 사용 그룹)

장소를 예약할 수 있는 승인된 그룹 목록입니다.

```sql
CREATE TABLE place_usage_groups (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    place_id BIGINT NOT NULL,
    group_id BIGINT NOT NULL,
    status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP,
    approved_by BIGINT, -- 승인한 사용자 (관리 주체의 관리자)

    UNIQUE KEY uk_place_group (place_id, group_id),
    FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id)
);

CREATE INDEX idx_usage_place ON place_usage_groups(place_id);
CREATE INDEX idx_usage_group ON place_usage_groups(group_id);
CREATE INDEX idx_usage_status ON place_usage_groups(place_id, status);
```

**JPA 엔티티 (PlaceUsageGroup.kt)**:

```kotlin
@Entity
@Table(
    name = "place_usage_groups",
    uniqueConstraints = [UniqueConstraint(columnNames = ["place_id", "group_id"])]
)
class PlaceUsageGroup(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    var group: Group,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: UsageStatus = UsageStatus.PENDING,

    @Column(name = "requested_at", nullable = false, updatable = false)
    var requestedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "approved_at")
    var approvedAt: LocalDateTime? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    var approvedBy: User? = null,
) {
    override fun equals(other: Any?) = other is PlaceUsageGroup && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

enum class UsageStatus {
    PENDING,
    APPROVED,
    REJECTED
}
```

### 7.3. PlaceReservation 테이블 (장소 예약)

일정에 연결된 장소 예약 정보입니다. GroupEvent와 1:1 관계를 가집니다.

```sql
CREATE TABLE place_reservations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    event_id BIGINT NOT NULL UNIQUE, -- 1:1 관계
    place_id BIGINT NOT NULL,
    reserved_by BIGINT NOT NULL, -- 예약한 사용자

    -- 동시성 제어
    version BIGINT DEFAULT 0, -- 낙관적 락

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (event_id) REFERENCES group_events(id) ON DELETE CASCADE,
    FOREIGN KEY (place_id) REFERENCES places(id),
    FOREIGN KEY (reserved_by) REFERENCES users(id)
);

CREATE INDEX idx_reservation_place ON place_reservations(place_id);
CREATE INDEX idx_reservation_event ON place_reservations(event_id);
CREATE INDEX idx_reservation_user ON place_reservations(reserved_by);
```

**JPA 엔티티 (PlaceReservation.kt)**:

```kotlin
@Entity
@Table(name = "place_reservations")
class PlaceReservation(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0,

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false, unique = true)
    var event: GroupEvent,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    var place: Place,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reserved_by", nullable = false)
    var reservedBy: User,

    // 낙관적 락 (동시성 제어)
    @Version
    @Column(nullable = false)
    var version: Long = 0,

    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),
) {
    override fun equals(other: Any?) = other is PlaceReservation && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

---

## 주요 쿼리 패턴

### 1. 사용자의 모든 일정 조회 (개인 캘린더)

개인 캘린더는 학교 시간표 + 개인 일정 + 참여 중인 그룹 일정을 통합하여 보여줍니다.

```kotlin
// 1. 학교 시간표
val courseTimetables = userCourseTimetableRepository.findByUserId(userId)

// 2. 개인 일정
val personalSchedules = personalScheduleRepository.findByUserIdAndDateRange(
    userId, startDate, endDate
)

// 3. 참여 중인 그룹 일정
val participatingEvents = eventParticipantRepository.findByUserIdAndStatusAndDateRange(
    userId, ParticipantStatus.ACCEPTED, startDate, endDate
)

// 통합하여 반환
```

### 2. 그룹 캘린더 조회 (날짜 범위)

```sql
SELECT e.*
FROM group_events e
WHERE e.group_id = ?
  AND e.start_date >= ?
  AND e.end_date <= ?
ORDER BY e.start_date;
```

### 3. 장소 예약 현황 조회 (충돌 검증)

```sql
SELECT r.*
FROM place_reservations r
JOIN group_events e ON r.event_id = e.id
WHERE r.place_id = ?
  AND e.start_date < ? -- 새 일정 종료 시간
  AND e.end_date > ?   -- 새 일정 시작 시간
FOR UPDATE; -- 비관적 락 (동시성 제어)
```

### 4. 최적 시간 추천 (가능 인원 계산)

대상자 지정 일정 생성 시 참여 가능한 인원이 가장 많은 시간대를 찾습니다.

```kotlin
// 1. 대상자 목록 추출
val targetUsers = groupMemberRepository.findByGroupIdAndCriteria(groupId, targetCriteria)

// 2. 각 시간대별 불가능한 사용자 계산
val unavailableUsers = mutableMapOf<TimeSlot, Set<Long>>()

for (timeSlot in candidateTimeSlots) {
    // 학교 시간표 충돌
    val courseBusy = userCourseTimetableRepository.findUsersWithCourseAt(timeSlot)

    // 개인 일정 충돌
    val personalBusy = personalScheduleRepository.findUsersWithScheduleAt(timeSlot)

    // 그룹 일정 충돌
    val eventBusy = eventParticipantRepository.findUsersWithEventAt(timeSlot)

    unavailableUsers[timeSlot] = (courseBusy + personalBusy + eventBusy).toSet()
}

// 3. 가능 인원이 가장 많은 시간대 선택
val bestTimeSlot = candidateTimeSlots.maxByOrNull { timeSlot ->
    targetUsers.size - unavailableUsers[timeSlot]!!.size
}
```

---

## 인덱스 전략 요약

캘린더 시스템의 주요 조회 패턴을 고려한 인덱스 전략입니다.

### 복합 인덱스 (조회 성능 최적화)

1. **날짜 범위 조회**: `(group_id, start_date, end_date)`, `(user_id, valid_from, valid_until)`
2. **참여자 필터링**: `(user_id, status)`, `(event_id, status)`
3. **반복 일정 그룹화**: `(series_id)`, `(parent_event_id, exception_date)`
4. **장소 예약 조회**: `(place_id, start_date)`, `(place_id, status)`
5. **일정 타입별 조회**: `(group_id, is_official, start_date)`, `(group_id, event_type)`

### 외래키 인덱스

모든 외래키 컬럼에 인덱스를 생성하여 JOIN 성능을 최적화합니다.

### 유니크 제약 조건

- `(building, room_number)`: 장소 중복 방지
- `(place_id, group_id)`: 사용 그룹 중복 방지
- `(event_id, user_id)`: 참여자 중복 방지
- `(parent_event_id, exception_date)`: 예외 중복 방지
- `event_id` (PlaceReservation): 1:1 관계 보장

---

## 데이터 무결성 및 CASCADE 전략

### CASCADE DELETE 적용

| 부모 테이블 | 자식 테이블 | 정책 | 이유 |
|------------|------------|------|------|
| `groups` | `group_events` | CASCADE | 그룹 삭제 시 일정도 삭제 |
| `group_events` | `event_participants` | CASCADE | 일정 삭제 시 참여자도 삭제 |
| `group_events` | `event_exceptions` | CASCADE | 일정 삭제 시 예외도 삭제 |
| `group_events` | `place_reservations` | CASCADE | 일정 삭제 시 예약도 삭제 |
| `places` | `place_reservations` | NO ACTION | 장소 삭제 전 예약 확인 필요 |
| `places` | `place_usage_groups` | CASCADE | 장소 삭제 시 사용 그룹도 삭제 |
| `users` | `personal_schedules` | CASCADE | 사용자 삭제 시 개인 일정 삭제 |
| `courses` | `course_timetables` | CASCADE | 과목 삭제 시 분반도 삭제 |

### SET NULL 적용

- `group_events.linked_channel_id`: 채널 삭제 시 NULL로 변경 (일정은 유지)
- `group_events.linked_post_id`: 게시글 삭제 시 NULL로 변경

---

## 동시성 제어 전략

### 낙관적 락 (Optimistic Lock)

`PlaceReservation` 테이블에 `@Version` 컬럼을 추가하여 동시 예약 충돌을 방지합니다.

**충돌 시나리오:**
1. 사용자 A와 B가 동시에 같은 장소/시간 예약 시도
2. 중복 검증 쿼리에서 둘 다 "예약 없음" 확인
3. A가 먼저 INSERT 성공
4. B가 INSERT 시도 시 version 충돌 발생 (OptimisticLockException)
5. B에게 "이미 예약된 시간입니다" 에러 응답

**구현 예시:**

```kotlin
@Transactional
fun createReservation(request: CreateReservationRequest): PlaceReservationDto {
    // 1. 중복 검증
    val conflicts = placeReservationRepository.findConflicts(
        request.placeId, request.startDate, request.endDate
    )
    if (conflicts.isNotEmpty()) {
        throw BusinessException(ErrorCode.RESERVATION_CONFLICT)
    }

    // 2. 예약 생성 (낙관적 락 적용)
    try {
        val reservation = PlaceReservation(...)
        return placeReservationRepository.save(reservation).toDto()
    } catch (e: OptimisticLockException) {
        throw BusinessException(ErrorCode.RESERVATION_CONFLICT)
    }
}
```

---

## 다음 단계

### 백엔드 구현 필요

1. **Repository 레이어**
   - 9개 엔티티의 Repository 인터페이스 작성
   - 복잡한 조회 쿼리 (날짜 범위, 참여자 필터링 등)
   - 최적 시간 추천 쿼리

2. **Service 레이어**
   - 일정 생성/수정/삭제 로직 (반복 일정 처리)
   - 참여자 자동 생성 로직 (대상자 지정)
   - 장소 예약 중복 검증
   - 권한 확인 통합 (CALENDAR_MANAGE, PLACE_MANAGE 등)

3. **Controller 레이어**
   - REST API 엔드포인트 (CRUD + 최적 시간 추천)
   - @PreAuthorize 어노테이션 적용
   - ApiResponse 래퍼

4. **테스트**
   - 반복 일정 생성/수정/삭제 통합 테스트
   - 동시성 제어 테스트 (낙관적 락)
   - 권한 검증 테스트

### 프론트엔드 구현 필요

1. **캘린더 UI**
   - 4가지 캘린더 뷰 (학교 시간표, 개인 일정, 그룹 캘린더, 장소 캘린더)
   - 일정 생성/수정/삭제 플로우
   - 반복 범위 설정 UI

2. **게시글 연동**
   - JSON 임베딩 렌더링
   - 액션 버튼 (불참, 참여 신청)

3. **최적 시간 추천**
   - 시간대별 가능/불가능 인원 시각화

### 권한 시스템 통합

1. GroupRole 엔티티에 4개 권한 추가
2. PermissionService 확장
3. UI 권한 매트릭스에 캘린더 탭 추가

---

## 관련 문서

### 백엔드 구현
- **백엔드 가이드**: [backend/README.md](backend/README.md)
- **API 참조**: [api-reference.md](api-reference.md)

### 도메인 개념
- **도메인 개요**: [../concepts/domain-overview.md](../concepts/domain-overview.md)
- **그룹 계층**: [../concepts/group-hierarchy.md](../concepts/group-hierarchy.md)
- **권한 시스템**: [../concepts/permission-system.md](../concepts/permission-system.md)
- **워크스페이스**: [../concepts/workspace-channel.md](../concepts/workspace-channel.md)
- **사용자 여정**: [../concepts/user-lifecycle.md](../concepts/user-lifecycle.md)
- **모집 시스템**: [../concepts/recruitment-system.md](../concepts/recruitment-system.md)
- **캘린더 통합**: [../concepts/calendar-integration.md](../concepts/calendar-integration.md)

### 문제 해결
- **권한 에러**: [../troubleshooting/permission-errors.md](../troubleshooting/permission-errors.md)
