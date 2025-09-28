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
*   **설명**: 그룹 내에서 사용될 역할을 정의. 권한(Permission)의 집합입니다.

```kotlin
@Entity
@Table(
    name = "group_roles",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "name"]),
    ],
)
data class GroupRole(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group, // 역할이 속한 그룹

    @Column(nullable = false, length = 50)
    val name: String, // 역할 이름 (예: 운영진, 신입생)

    @Column(name = "is_system_role", nullable = false)
    val isSystemRole: Boolean = false, // 시스템 기본 역할 여부 (Owner, Member 등)

    @Enumerated(EnumType.STRING)
    @Column(name = "role_type", nullable = false, length = 20)
    val roleType: RoleType = RoleType.OPERATIONAL, // 역할 유형

    @Column(nullable = false)
    val priority: Int = 0, // 역할의 우선순위 (숫자가 높을수록 높은 권한)

    // `@ElementCollection`을 통해 `group_role_permissions` 테이블에 권한 목록을 저장
    @ElementCollection(targetClass = GroupPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_role_permissions", joinColumns = [JoinColumn(name = "group_role_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    val permissions: Set<GroupPermission> = emptySet(),
)

// 역할 유형 Enum
enum class RoleType {
    OPERATIONAL, // 운영 역할 (그룹장, 부그룹장 등)
    SEGMENT // 분류 역할 (1학년, 2학년, 고학년 등)
}
```

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

-- 참고: 실제 코드에서는 isPrivate/isPublic 필드가 아직 존재함
-- 향후 권한 기반 가시성으로 마이그레이션 예정
```

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

### 주요 인덱스 전략
```sql
-- 복합 인덱스 (자주 함께 조회되는 컬럼)
CREATE INDEX idx_group_members_composite ON group_members(group_id, user_id, joined_at);

-- 부분 인덱스 (조건부 인덱스)
CREATE INDEX idx_active_groups ON groups(visibility, created_at)
WHERE deleted_at IS NULL;

-- 함수 기반 인덱스 (검색 최적화)
CREATE INDEX idx_user_search ON users(LOWER(name), LOWER(nickname));
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

### 문제 해결
- **권한 에러**: [../troubleshooting/permission-errors.md](../troubleshooting/permission-errors.md)
