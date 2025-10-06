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

    @Column(name = "student_no", length = 30)
    val studentNo: String? = null, // 학번

    @Column(name = "school_email", length = 100)
    val schoolEmail: String? = null, // 학교 이메일

    @Column(name = "academic_year")
    val academicYear: Int? = null, // 학년

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
    @Column(nullable = false, length = 20)
    val visibility: GroupVisibility = GroupVisibility.PUBLIC, // 공개 범위

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
    @Column(name = "is_recruiting", nullable = false)
    val isRecruiting: Boolean = false, // 모집중 여부

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

// 그룹 공개 범위 Enum
enum class GroupVisibility {
    PUBLIC,
    PRIVATE,
    INVITE_ONLY,
}

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
*   **설명**: 그룹 내 역할. 시스템 역할(OWNER / ADVISOR / MEMBER)은 불변(이름/우선순위/권한 수정 및 삭제 금지, ErrorCode.SYSTEM_ROLE_IMMUTABLE).
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
    g.id, g.name, g.visibility,
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
-   **조회 조건 최적화**: `visibility`, `is_recruiting`, `status` 등 조회 조건으로 자주 사용되는 컬럼에 인덱스를 추가합니다.

```sql
-- V2__add_performance_indexes.sql

-- Groups 테이블
CREATE INDEX IF NOT EXISTS idx_groups_parent_id ON groups (parent_id);
CREATE INDEX IF NOT EXISTS idx_groups_owner_id ON groups (owner_id);
CREATE INDEX IF NOT EXISTS idx_groups_deleted_at ON groups (deleted_at);
CREATE INDEX IF NOT EXISTS idx_groups_university_college_dept ON groups (university, college, department);
CREATE INDEX IF NOT EXISTS idx_groups_visibility_recruiting ON groups (visibility, is_recruiting);
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
CREATE INDEX IF NOT EXISTS idx_groups_deleted_type_visibility ON groups (deleted_at, group_type, visibility) WHERE deleted_at IS NULL;
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

### 초기 데이터 설정
```sql
-- 시스템 관리자 생성
INSERT INTO users (email, name, global_role, profile_completed)
VALUES ('admin@hansin.ac.kr', '시스템관리자', 'ADMIN', true);

-- 기본 대학교 생성
INSERT INTO groups (name, owner_id, visibility)
VALUES ('한신대학교', 1, 'PUBLIC');

-- 기본 역할 생성 (각 그룹마다)
INSERT INTO group_roles (group_id, name, permissions, is_system_role)
VALUES
    (1, 'Owner', '["GROUP_MANAGE","MEMBER_READ","MEMBER_APPROVE","MEMBER_KICK","ROLE_MANAGE","CHANNEL_READ","CHANNEL_WRITE","POST_CREATE","POST_UPDATE_OWN","POST_DELETE_OWN","POST_DELETE_ANY","RECRUITMENT_CREATE","RECRUITMENT_UPDATE","RECRUITMENT_DELETE"]', true),
    (1, 'Member', '["CHANNEL_READ","POST_CREATE","POST_UPDATE_OWN","POST_DELETE_OWN"]', true);
```

## 변경 이력 (발췌)
| 날짜 | 변경 사항 |
|------|-----------|
| 2025-10-06 | **V2 마이그레이션**: 프로덕션 환경을 위한 대규모 성능 최적화 인덱스 추가. |
| 2025-10-01 | GroupRole 비불변화(data class 제거), 시스템 역할 불변성 명시, ChannelRoleBinding 자동 생성 제거, ChannelRoleBinding 스키마/엔티티 추가, 삭제 Bulk 순서 추가 |

## 캘린더 시스템 테이블 (Calendar System)

> **개발 우선순위**: Phase 6 이후 예정
> **상태**: 스키마 설계 예정 (개념 설계 완료)
> **관련 문서**: [캘린더 시스템](../concepts/calendar-system.md) | [설계 결정사항](../concepts/calendar-design-decisions.md)

캘린더 시스템은 6개 엔티티로 구성됩니다:

### 주요 엔티티 개요

1. **CourseTimetable**: 대학 강의 시간표 (사용자가 자신의 수강 과목 선택)
2. **PersonalSchedule**: 사용자 정의 반복 일정 (아르바이트, 근로장학생 등)
3. **GroupEvent**: 그룹 일정 (공식/비공식 구분, 반복 패턴 지원)
4. **EventParticipant**: 일정 참여자 정보 (참여 상태, 불참 사유)
5. **EventException**: 반복 일정 예외 (특정 날짜만 시간/장소 변경)
6. **PlaceReservation**: 장소 예약 정보 (GroupEvent와 1:1 관계)

### 설계 특징

- **반복 일정**: 명시적 인스턴스 저장 방식 (DD-CAL-002)
- **예외 처리**: EventException 분리 관리 (DD-CAL-003)
- **참여자 관리**: 독립 엔티티로 상태 추적 (DD-CAL-004)
- **장소 예약**: GroupEvent 부속 정보 (DD-CAL-006)

### 다음 단계

1. 각 엔티티의 상세 스키마 설계
2. JPA 엔티티 클래스 작성 (Kotlin)
3. Repository 및 Service 레이어 구현
4. 캘린더 권한 확인 로직 통합

---

## 관련 문서

### 백엔드 구현
- **백엔드 가이드**: [backend-guide.md](backend-guide.md)
- **API 참조**: [api-reference.md](api-reference.md)

### 도메인 개념
- **도메인 개요**: [../concepts/domain-overview.md](../concepts/domain-overview.md)
- **그룹 계층**: [../concepts/group-hierarchy.md](../concepts/group-hierarchy.md)
- **권한 시스템**: [../concepts/permission-system.md](../concepts/permission-system.md)
- **워크스페이스**: [../concepts/workspace-channel.md](../concepts/workspace-channel.md)
- **사용자 여정**: [../concepts/user-lifecycle.md](../concepts/user-lifecycle.md)
- **모집 시스템**: [../concepts/recruitment-system.md](../concepts/recruitment-system.md)
- **캘린더 시스템**: [../concepts/calendar-system.md](../concepts/calendar-system.md)

### 문제 해결
- **권한 에러**: [../troubleshooting/permission-errors.md](../troubleshooting/permission-errors.md)
