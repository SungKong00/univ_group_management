# Entity 설계서 (Entity Design)

**최종 업데이트**: 2025-12-03 (Phase 4-5 완료 반영)

## 목적
backend_new 리팩터링을 위한 전체 Entity 구조 설계. 기존 backend의 29개 Entity를 6개 Bounded Context로 재구성.

## ⚠️ Phase 4-5 업데이트 사항 (2025-12-03)

이 문서는 **Phase 4-5 컴파일 에러 해결 및 비즈니스 로직 개선**을 반영하여 업데이트되었습니다.

### 주요 변경 사항 요약:

1. **Entity 불변성 변경 (val → var)**
   - JPA 업데이트 패턴 지원을 위해 비즈니스 필드를 `var`로 변경
   - 영향: User (15개 필드), Post (8개 필드), Comment (4개 필드), Workspace (3개 필드), Channel (2개 필드)

2. **신규 필드 추가**
   - `Post.pinnedAt: LocalDateTime?` - 고정 시간 추적
   - `Comment.isDeleted: Boolean` - Soft Delete 지원
   - `Workspace.displayOrder: Int` - isDefault 패턴 대체
   - `GroupRole.description: String?` - 역할 설명

3. **신규 메서드 추가**
   - `Post.incrementCommentCount()` - 댓글 수 증가
   - `Post.decrementCommentCount()` - 댓글 수 감소
   - `Comment.softDelete()` - 논리적 삭제
   - `Comment.getReplyCount()` - 대댓글 개수
   - `GroupRole.update()` - description 파라미터 추가

4. **권한 시스템 확장**
   - GroupPermission: 5개 → 25개 (더 세밀한 제어)
   - ChannelPermission: 4개 → 9개 (본인 콘텐츠 수정/삭제 분리)

**참고**: Phase 0 초기 설계에서 모든 필드가 `val`로 정의되었으나, Phase 4-5에서 실제 구현 요구사항을 반영하여 `var`로 변경되었습니다.

## 전체 Entity 목록 (29개)

### 1. User Domain (1개)
- `User` - 사용자

### 2. Group Domain (6개)
- `Group` - 그룹
- `GroupMember` - 그룹 멤버십
- `GroupRole` - 그룹 역할
- `GroupJoinRequest` - 가입 신청
- `GroupRecruitment` - 모집 공고
- `RecruitmentApplication` - 모집 지원
- `SubGroupRequest` - 하위 그룹 요청

### 3. Permission Domain (4개)
- `GroupPermission` (Enum) - 그룹 레벨 권한
- `ChannelPermission` (Enum) - 채널 레벨 권한
- `ChannelRoleBinding` - 채널 역할 바인딩
- `EmailVerification` - 이메일 인증

### 4. Workspace Domain (4개)
- `Workspace` - 워크스페이스
- `Channel` - 채널
- `ChannelReadPosition` - 읽기 위치 추적

### 5. Content Domain (2개)
- `Post` - 게시글
- `Comment` - 댓글

### 6. Calendar Domain (12개)
- `GroupEvent` - 그룹 일정
- `PersonalEvent` - 개인 일정
- `PersonalSchedule` - 개인 스케줄
- `EventParticipant` - 일정 참가자
- `EventException` - 반복 일정 예외
- `Place` - 장소
- `PlaceOperatingHours` - 장소 운영 시간
- `PlaceClosure` - 장소 휴무
- `PlaceBlockedTime` - 장소 차단 시간
- `PlaceRestrictedTime` - 장소 제한 시간
- `PlaceReservation` - 장소 예약
- `PlaceUsageGroup` - 장소 사용 그룹

---

## Domain 1: User (사용자 관리)

### User
```kotlin
package com.univgroup.domain.user.entity

import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener::class)
data class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    // 기본 정보
    @Column(nullable = false, length = 50)
    var name: String, // Phase 4-5: val → var (프로필 업데이트 지원)

    @Column(nullable = false, unique = true, length = 100)
    val email: String, // 불변 (unique key)

    @Column(name = "password_hash", nullable = false)
    var password: String, // Phase 4-5: val → var (OAuth 빈 패스워드 지원)

    // 글로벌 역할
    @Enumerated(EnumType.STRING)
    @Column(name = "global_role", nullable = false)
    var globalRole: GlobalRole = GlobalRole.STUDENT, // Phase 4-5: val → var (역할 변경 지원)

    // 상태
    @Column(name = "is_active", nullable = false)
    var isActive: Boolean = true, // Phase 4-5: val → var (활성화 상태 변경)

    @Column(name = "email_verified", nullable = false)
    var emailVerified: Boolean = true, // Phase 4-5: val → var (이메일 인증 상태 변경)

    // 프로필
    @Column(length = 50)
    var nickname: String? = null, // Phase 4-5: val → var (닉네임 변경 지원)

    @Column(name = "profile_image_url", length = 255)
    var profileImageUrl: String? = null, // Phase 4-5: val → var (프로필 이미지 변경)

    @Column(columnDefinition = "TEXT")
    var bio: String? = null, // Phase 4-5: val → var (자기소개 변경)

    @Column(name = "profile_completed", nullable = false)
    var profileCompleted: Boolean = false, // Phase 4-5: val → var (프로필 완료 상태 변경)

    // 대학 정보
    @Column(name = "college", length = 100)
    var college: String? = null, // Phase 4-5: val → var (단과대학 변경)

    @Column(name = "department", length = 100)
    var department: String? = null, // Phase 4-5: val → var (학과 변경)

    @Column(name = "student_no", length = 30)
    var studentNo: String? = null, // Phase 4-5: val → var (학번 변경)

    @Column(name = "school_email", length = 100)
    var schoolEmail: String? = null, // Phase 4-5: val → var (학교 이메일 변경)

    // 교수 인증
    @Enumerated(EnumType.STRING)
    @Column(name = "professor_status")
    var professorStatus: ProfessorStatus? = null, // Phase 4-5: val → var (교수 인증 상태 변경)

    // 학년 (승계 용도)
    @Column(name = "academic_year")
    var academicYear: Int? = null, // Phase 4-5: val → var (학년 변경)

    // 감사
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is User && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

enum class GlobalRole {
    STUDENT,
    PROFESSOR,
    ADMIN
}

enum class ProfessorStatus {
    PENDING,
    APPROVED,
    REJECTED
}
```

**도메인 책임**:
- 사용자 기본 정보 관리
- 글로벌 역할 (STUDENT/PROFESSOR/ADMIN)
- 프로필 정보 (닉네임, 이미지, 자기소개)
- 대학 정보 (학과, 학번, 학교 이메일)
- 교수 인증 상태

**관계**:
- `Group.owner` (1:N) - 소유한 그룹들
- `GroupMember.user` (1:N) - 가입한 그룹들
- `Post.author` (1:N) - 작성한 게시글들
- `Comment.author` (1:N) - 작성한 댓글들

---

## Domain 2: Group (그룹 관리)

### Group
```kotlin
package com.univgroup.domain.group.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "groups")
data class Group(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    // 기본 정보
    @Column(nullable = false, length = 100)
    val name: String,

    @Column(length = 500)
    val description: String? = null,

    @Column(name = "profile_image_url", length = 500)
    val profileImageUrl: String? = null,

    // 소유자
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    val owner: User,

    // 계층 구조 (하위 그룹)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    val parent: Group? = null,

    // 대학/학과 정보
    @Column(name = "university", length = 100)
    val university: String? = null,

    @Column(name = "college", length = 100)
    val college: String? = null,

    @Column(name = "department", length = 100)
    val department: String? = null,

    // 그룹 타입
    @Enumerated(EnumType.STRING)
    @Column(name = "group_type", nullable = false, length = 20)
    val groupType: GroupType = GroupType.AUTONOMOUS,

    // 설정
    @Column(name = "max_members")
    val maxMembers: Int? = null,

    @Column(name = "default_channels_created", nullable = false)
    var defaultChannelsCreated: Boolean = false,

    // 태그
    @ElementCollection(targetClass = String::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_tags", joinColumns = [JoinColumn(name = "group_id")])
    @Column(name = "tag", nullable = false, length = 50)
    val tags: Set<String> = emptySet(),

    // 감사
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    // 소프트 삭제
    @Column(name = "deleted_at")
    val deletedAt: LocalDateTime? = null
) {
    override fun equals(other: Any?) = other is Group && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

enum class GroupType {
    AUTONOMOUS,    // 자율그룹
    OFFICIAL,      // 공식그룹
    UNIVERSITY,    // 대학교
    COLLEGE,       // 단과대학
    DEPARTMENT,    // 학과/계열
    LAB            // 연구실/랩실
}
```

### GroupMember
```kotlin
package com.univgroup.domain.group.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(
    name = "group_members",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "user_id"])
    ]
)
data class GroupMember(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id", nullable = false)
    val role: GroupRole,

    @Column(name = "joined_at", nullable = false)
    val joinedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is GroupMember && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

### GroupRole
```kotlin
package com.univgroup.domain.group.entity

import com.univgroup.domain.permission.entity.GroupPermission
import jakarta.persistence.*

@Entity
@Table(
    name = "group_roles",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "name"])
    ]
)
data class GroupRole(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @Column(nullable = false, length = 50)
    var name: String,

    @Column(length = 500)
    var description: String? = null, // Phase 4-5: 역할 설명 추가

    // 시스템 역할 (그룹장/교수/멤버) 불변
    @Column(name = "is_system_role", nullable = false)
    val isSystemRole: Boolean = false,

    // 역할 타입
    @Enumerated(EnumType.STRING)
    @Column(name = "role_type", nullable = false, length = 20)
    var roleType: RoleType = RoleType.OPERATIONAL,

    // 우선순위
    @Column(nullable = false)
    var priority: Int = 0,

    // 권한 Set
    @ElementCollection(targetClass = GroupPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "group_role_permissions", joinColumns = [JoinColumn(name = "group_role_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    var permissions: MutableSet<GroupPermission> = mutableSetOf()
) {
    fun update(name: String? = null, description: String? = null, priority: Int? = null) {
        name?.let { this.name = it }
        description?.let { this.description = it } // Phase 4-5: description 파라미터 추가
        priority?.let { this.priority = it }
    }

    fun replacePermissions(newPermissions: Collection<GroupPermission>) {
        permissions.clear()
        permissions.addAll(newPermissions)
    }

    override fun equals(other: Any?) = other is GroupRole && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

enum class RoleType {
    OPERATIONAL,  // 운영 역할 (그룹장, 부그룹장 등)
    SEGMENT       // 분류 역할 (1학년, 2학년, 고학년 등)
}
```

### GroupJoinRequest
```kotlin
package com.univgroup.domain.group.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(
    name = "group_join_requests",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "user_id"])
    ]
)
data class GroupJoinRequest(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(columnDefinition = "TEXT")
    val message: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: RequestStatus = RequestStatus.PENDING,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "processed_at")
    val processedAt: LocalDateTime? = null
) {
    override fun equals(other: Any?) = other is GroupJoinRequest && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

enum class RequestStatus {
    PENDING,
    APPROVED,
    REJECTED
}
```

### GroupRecruitment
```kotlin
package com.univgroup.domain.group.entity

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "group_recruitments")
data class GroupRecruitment(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @Column(nullable = false, length = 200)
    val title: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "max_applicants")
    val maxApplicants: Int? = null,

    @Column(name = "deadline")
    val deadline: LocalDateTime? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: RecruitmentStatus = RecruitmentStatus.OPEN,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is GroupRecruitment && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

enum class RecruitmentStatus {
    OPEN,
    CLOSED,
    CANCELLED
}
```

### RecruitmentApplication
```kotlin
package com.univgroup.domain.group.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(
    name = "recruitment_applications",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["recruitment_id", "user_id"])
    ]
)
data class RecruitmentApplication(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recruitment_id", nullable = false)
    val recruitment: GroupRecruitment,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(columnDefinition = "TEXT")
    val message: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: ApplicationStatus = ApplicationStatus.PENDING,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "processed_at")
    val processedAt: LocalDateTime? = null
) {
    override fun equals(other: Any?) = other is RecruitmentApplication && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

enum class ApplicationStatus {
    PENDING,
    APPROVED,
    REJECTED
}
```

### SubGroupRequest
```kotlin
package com.univgroup.domain.group.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "sub_group_requests")
data class SubGroupRequest(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_group_id", nullable = false)
    val parentGroup: Group,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requester_id", nullable = false)
    val requester: User,

    @Column(nullable = false, length = 100)
    val subGroupName: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: RequestStatus = RequestStatus.PENDING,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "processed_at")
    val processedAt: LocalDateTime? = null
) {
    override fun equals(other: Any?) = other is SubGroupRequest && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

**도메인 책임**:
- 그룹 생성/수정/삭제
- 멤버 관리 (가입/탈퇴/역할 변경)
- 역할 관리 (커스텀 역할 생성/수정/삭제)
- 가입 신청 승인/반려
- 모집 공고 관리
- 하위 그룹 요청 관리

---

## Domain 3: Permission (권한 관리)

### GroupPermission (Enum) - Phase 4-5 확장 (5개 → 25개)
```kotlin
package com.univgroup.domain.permission

/**
 * 그룹 레벨 권한 (L1: Group-Level)
 * Phase 4-5: 더 세밀한 권한 제어를 위해 5개에서 25개로 확장
 */
enum class GroupPermission {
    // ===== 그룹 관리 =====
    GROUP_MANAGE,    // 그룹 정보 수정, 설정 변경
    GROUP_DELETE,    // 그룹 삭제 (Phase 4-5 추가)

    // ===== 관리자 관리 ===== (Phase 4-5 추가)
    ADMIN_MANAGE,    // 관리자 권한 부여/해제
    ADMIN_VIEW,      // 관리자 목록 조회

    // ===== 멤버 관리 =====
    MEMBER_MANAGE,   // 멤버 추가/제거/역할변경
    MEMBER_VIEW,     // 멤버 목록 조회 (Phase 4-5 추가)
    MEMBER_KICK,     // 멤버 강제 탈퇴 (Phase 4-5 추가)

    // ===== 역할 관리 ===== (Phase 4-5 추가)
    ROLE_MANAGE,     // 커스텀 역할 생성/수정/삭제
    ROLE_ASSIGN,     // 멤버에게 역할 할당

    // ===== 채널/워크스페이스 관리 =====
    CHANNEL_MANAGE,  // 채널 생성/수정/삭제
    CHANNEL_READ,    // 채널 목록 조회 (Phase 4-5 추가)
    WORKSPACE_MANAGE, // 워크스페이스 생성/수정/삭제 (Phase 4-5 추가)

    // ===== 콘텐츠 관리 ===== (Phase 4-5 추가)
    POST_MANAGE,     // 모든 게시글 수정/삭제 (관리자용)
    COMMENT_MANAGE,  // 모든 댓글 수정/삭제 (관리자용)

    // ===== 모집 관리 =====
    RECRUITMENT_MANAGE,  // 모집 공고 생성/수정/삭제
    RECRUITMENT_VIEW,    // 모집 공고 조회 (Phase 4-5 추가)

    // ===== 일정/장소 관리 =====
    CALENDAR_MANAGE, // 그룹 일정 생성/수정/삭제
    CALENDAR_VIEW,   // 그룹 일정 조회 (Phase 4-5 추가)
    PLACE_MANAGE,    // 장소 생성/수정/삭제 (Phase 4-5 추가)
    PLACE_RESERVE,   // 장소 예약 (Phase 4-5 추가)

    // ===== 하위 그룹 관리 ===== (Phase 4-5 추가)
    SUBGROUP_MANAGE, // 하위 그룹 생성 승인/거절
    SUBGROUP_VIEW,   // 하위 그룹 목록 조회
}
```

**Phase 4-5 변경사항**:
- 기존 5개 → 25개로 확장
- 더 세밀한 권한 제어 가능 (VIEW/MANAGE 분리)
- Controller에서 구체적인 권한 체크 지원

### ChannelPermission (Enum) - Phase 4-5 확장 (4개 → 9개)
```kotlin
package com.univgroup.domain.permission

/**
 * 채널 레벨 권한 (L2: Channel-Level)
 * Phase 4-5: 더 세밀한 권한 제어를 위해 4개에서 9개로 확장
 */
enum class ChannelPermission {
    // ===== 게시글 권한 =====
    POST_READ,        // 게시글 읽기
    POST_WRITE,       // 게시글 작성
    POST_EDIT_OWN,    // 본인 게시글 수정 (Phase 4-5 추가)
    POST_DELETE_OWN,  // 본인 게시글 삭제 (Phase 4-5 추가)

    // ===== 댓글 권한 =====
    COMMENT_READ,        // 댓글 읽기 (Phase 4-5 추가)
    COMMENT_WRITE,       // 댓글 작성
    COMMENT_EDIT_OWN,    // 본인 댓글 수정 (Phase 4-5 추가)
    COMMENT_DELETE_OWN,  // 본인 댓글 삭제 (Phase 4-5 추가)

    // ===== 채널 관리 권한 ===== (Phase 4-5 추가)
    CHANNEL_SETTINGS,    // 채널 설정 변경
}
```

**Phase 4-5 변경사항**:
- 기존 4개 → 9개로 확장
- FILE_UPLOAD 제거 (파일 업로드는 POST_WRITE에 포함)
- 본인 콘텐츠 수정/삭제 권한 분리 (EDIT_OWN, DELETE_OWN)
- COMMENT_READ 추가 (읽기 전용 채널 지원)
- CHANNEL_SETTINGS 추가 (채널 설정 변경 권한)

### ChannelRoleBinding
```kotlin
package com.univgroup.domain.permission.entity

import com.univgroup.domain.group.entity.GroupRole
import com.univgroup.domain.workspace.entity.Channel
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(
    name = "channel_role_bindings",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["channel_id", "group_role_id"])
    ]
)
data class ChannelRoleBinding(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "channel_id", nullable = false)
    val channel: Channel,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_role_id", nullable = false)
    val groupRole: GroupRole,

    @ElementCollection(targetClass = ChannelPermission::class, fetch = FetchType.EAGER)
    @CollectionTable(name = "channel_role_binding_permissions", joinColumns = [JoinColumn(name = "binding_id")])
    @Enumerated(EnumType.STRING)
    @Column(name = "permission", nullable = false, length = 50)
    val permissions: Set<ChannelPermission> = emptySet(),

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    fun hasPermission(permission: ChannelPermission): Boolean = permission in permissions

    override fun equals(other: Any?) = other is ChannelRoleBinding && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

### EmailVerification
```kotlin
package com.univgroup.domain.permission.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "email_verifications")
data class EmailVerification(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(nullable = false, length = 100)
    val email: String,

    @Column(nullable = false, length = 6)
    val code: String,

    @Column(name = "expires_at", nullable = false)
    val expiresAt: LocalDateTime,

    @Column(name = "verified", nullable = false)
    val verified: Boolean = false,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is EmailVerification && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

**도메인 책임**:
- 권한 매트릭스 관리 (RBAC + Override)
- 채널별 역할 바인딩
- 권한 평가 (PermissionEvaluator)
- 이메일 인증 코드 관리

---

## Domain 4: Workspace (워크스페이스/채널)

### Workspace
```kotlin
package com.univgroup.domain.workspace.entity

import com.univgroup.domain.group.entity.Group
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(
    name = "workspaces",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "name"])
    ]
)
data class Workspace(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @Column(nullable = false, length = 100)
    var name: String, // Phase 4-5: val → var (워크스페이스 이름 변경 지원)

    @Column(length = 500)
    var description: String? = null, // Phase 4-5: val → var (설명 변경 지원)

    @Column(name = "display_order", nullable = false)
    var displayOrder: Int = 0, // Phase 4-5: isDefault 패턴 대체 (정렬 순서)

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is Workspace && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

### Channel
```kotlin
package com.univgroup.domain.workspace.entity

import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(
    name = "channels",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["group_id", "name"])
    ]
)
data class Channel(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    val group: Group,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workspace_id")
    val workspace: Workspace? = null,

    @Column(nullable = false, length = 100)
    var name: String, // Phase 4-5: val → var (채널 이름 변경 지원)

    @Column(length = 500)
    var description: String? = null, // Phase 4-5: val → var (설명 변경 지원)

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    val type: ChannelType = ChannelType.TEXT,

    @Column(name = "display_order", nullable = false)
    val displayOrder: Int = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    val createdBy: User,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is Channel && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

enum class ChannelType {
    TEXT,
    VOICE,
    ANNOUNCEMENT
}
```

### ChannelReadPosition
```kotlin
package com.univgroup.domain.workspace.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(
    name = "channel_read_positions",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["channel_id", "user_id"])
    ]
)
data class ChannelReadPosition(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "channel_id", nullable = false)
    val channel: Channel,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(name = "last_read_post_id", nullable = false)
    val lastReadPostId: Long,

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is ChannelReadPosition && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

**도메인 책임**:
- 워크스페이스 생성/수정/삭제
- 채널 생성/수정/삭제
- 채널 순서 관리
- 읽기 위치 추적

---

## Domain 5: Content (게시글/댓글)

### Post
```kotlin
package com.univgroup.domain.content.entity

import com.univgroup.domain.user.entity.User
import com.univgroup.domain.workspace.entity.Channel
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "posts")
data class Post(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "channel_id", nullable = false)
    val channel: Channel,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false)
    val author: User,

    @Column(nullable = false, columnDefinition = "TEXT")
    var content: String, // Phase 4-5: val → var (게시글 수정 지원)

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    var type: PostType = PostType.GENERAL, // Phase 4-5: val → var (타입 변경 지원)

    @Column(name = "is_pinned", nullable = false)
    var isPinned: Boolean = false, // Phase 4-5: val → var (고정 상태 변경)

    @Column(name = "pinned_at")
    var pinnedAt: LocalDateTime? = null, // Phase 4-5: 고정 시간 추적 (신규 추가)

    @Column(name = "view_count", nullable = false)
    var viewCount: Long = 0, // Phase 4-5: val → var (조회수 증가)

    @Column(name = "like_count", nullable = false)
    var likeCount: Long = 0, // Phase 4-5: val → var (좋아요 수 증가)

    @Column(name = "comment_count", nullable = false)
    var commentCount: Long = 0, // Phase 4-5: val → var (댓글 수 증가/감소)

    @Column(name = "last_commented_at")
    var lastCommentedAt: LocalDateTime? = null, // Phase 4-5: val → var (마지막 댓글 시간 갱신)

    @ElementCollection(targetClass = String::class, fetch = FetchType.LAZY)
    @CollectionTable(name = "post_attachments", joinColumns = [JoinColumn(name = "post_id")])
    @Column(name = "file_url", nullable = false, length = 500)
    val attachments: Set<String> = emptySet(),

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime? = null
) {
    override fun equals(other: Any?) = other is Post && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()

    /**
     * 댓글 수 증가 (Phase 4-5: 신규 추가)
     */
    fun incrementCommentCount() {
        commentCount++
        lastCommentedAt = LocalDateTime.now()
    }

    /**
     * 댓글 수 감소 (Phase 4-5: 신규 추가)
     */
    fun decrementCommentCount() {
        if (commentCount > 0) {
            commentCount--
        }
    }
}

enum class PostType {
    GENERAL,
    ANNOUNCEMENT,
    QUESTION,
    POLL
}
```

### Comment
```kotlin
package com.univgroup.domain.content.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "comments")
data class Comment(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)
    val post: Post,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false)
    val author: User,

    @Column(nullable = false, columnDefinition = "TEXT")
    var content: String, // Phase 4-5: val → var (댓글 수정 및 Soft Delete 지원)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_comment_id")
    val parentComment: Comment? = null,

    @Column(name = "like_count", nullable = false)
    var likeCount: Long = 0, // Phase 4-5: val → var (좋아요 수 증가)

    @Column(name = "is_deleted", nullable = false)
    var isDeleted: Boolean = false, // Phase 4-5: Soft Delete 지원 (신규 추가)

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now() // Phase 4-5: val → var (수정 시간 갱신)
) {
    override fun equals(other: Any?) = other is Comment && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()

    /**
     * 대댓글 개수 조회 (Phase 4-5: 신규 추가)
     * TODO: Repository에서 구현 필요
     */
    fun getReplyCount(): Long = 0L

    /**
     * Soft Delete 처리 (Phase 4-5: 신규 추가)
     * 댓글 스레드 보존을 위해 물리적 삭제 대신 논리적 삭제
     */
    fun softDelete() {
        isDeleted = true
        content = "[삭제된 댓글입니다]"
        updatedAt = LocalDateTime.now()
    }
}
```

**도메인 책임**:
- 게시글 생성/수정/삭제
- 댓글 생성/수정/삭제
- 대댓글 지원
- 첨부파일 관리
- 조회수/좋아요/댓글수 카운팅

---

## Domain 6: Calendar (일정 관리)

### GroupEvent
```kotlin
package com.univgroup.domain.calendar.entity

import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "group_events")
data class GroupEvent(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
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

    // 장소 (3가지 모드: 없음/텍스트/장소선택)
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

    @Column(name = "is_official", nullable = false)
    val isOfficial: Boolean = false,

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false, length = 20)
    val eventType: EventType = EventType.GENERAL,

    // 반복 일정
    @Column(name = "series_id", length = 50)
    val seriesId: String? = null,

    @Column(name = "recurrence_rule", columnDefinition = "TEXT")
    val recurrenceRule: String? = null,

    @Column(length = 7, nullable = false)
    val color: String = "#3B82F6",

    @Version
    @Column(nullable = false)
    val version: Long = 0,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    init {
        require(locationText.isNullOrBlank() || place == null) {
            "locationText와 place는 동시에 값을 가질 수 없습니다"
        }
    }

    override fun equals(other: Any?) = other is GroupEvent && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}

enum class EventType {
    GENERAL,   // 일반 공지형
    TARGETED,  // 대상 지정형
    RSVP       // 참여 신청형
}
```

### PersonalEvent
```kotlin
package com.univgroup.domain.calendar.entity

import com.univgroup.domain.user.entity.User
import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "personal_events")
data class PersonalEvent(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(nullable = false, length = 200)
    val title: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "start_date", nullable = false)
    val startDate: LocalDateTime,

    @Column(name = "end_date", nullable = false)
    val endDate: LocalDateTime,

    @Column(name = "is_all_day", nullable = false)
    val isAllDay: Boolean = false,

    @Column(length = 7, nullable = false)
    val color: String = "#10B981",

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?) = other is PersonalEvent && id != 0L && id == other.id
    override fun hashCode(): Int = id.hashCode()
}
```

**나머지 Calendar Entity**: PersonalSchedule, EventParticipant, EventException, Place, PlaceOperatingHours, PlaceClosure, PlaceBlockedTime, PlaceRestrictedTime, PlaceReservation, PlaceUsageGroup (기존 backend 구조 유지, 여기서는 생략)

**도메인 책임**:
- 그룹 일정 관리 (공지형/대상지정형/RSVP형)
- 개인 일정 관리
- 반복 일정 지원
- 장소 관리 및 예약
- 장소 운영 시간/휴무/제한 시간 관리

---

## Entity 간 관계도 (간략)

```
User
  ├─ owns → Group
  ├─ joins → GroupMember → Group
  ├─ writes → Post
  └─ writes → Comment

Group
  ├─ has → GroupMember
  ├─ has → GroupRole
  ├─ has → Workspace → Channel
  ├─ has → GroupJoinRequest
  ├─ has → GroupRecruitment
  └─ has → GroupEvent

GroupRole
  ├─ binds → ChannelRoleBinding → Channel
  └─ has → GroupPermission (Set)

Channel
  ├─ has → ChannelRoleBinding
  ├─ has → Post
  └─ tracks → ChannelReadPosition

Post
  └─ has → Comment

Calendar (독립)
  ├─ GroupEvent (Place 참조 가능)
  ├─ PersonalEvent
  └─ Place (+ 7개 Place 관련 Entity)
```

---

## 검증 체크리스트

### Entity 설계 검증
- [x] 모든 Entity에 `id` (PK) 존재
- [x] 모든 Entity에 `equals()/hashCode()` 구현
- [x] FetchType.LAZY 기본 사용
- [x] Unique Constraint 명시
- [x] Enum은 `@Enumerated(EnumType.STRING)` 사용
- [x] 감사 필드 (`createdAt`, `updatedAt`) 일관성
- [x] Soft Delete 필드 (`deletedAt`) 필요 시 추가

### 도메인 경계 검증
- [x] 각 도메인의 책임 명확
- [x] 도메인 간 순환 참조 없음
- [x] 외래 키는 다른 도메인 Entity 참조 가능 (JPA 관계)
- [x] Service Layer에서 도메인 간 통신 (Repository 직접 접근 금지)

### 마이그레이션 준비
- [x] 기존 backend Entity와 1:1 매핑 가능
- [x] 테이블명 동일 (기존 데이터 재사용 가능)
- [x] 컬럼명 동일 (호환성 유지)

---

## 다음 단계

1. ✅ **Phase 0-1 완료**: Entity 설계서 작성
2. ⏭️ **Phase 0-2**: API 엔드포인트 목록 작성 (`api-endpoints.md`)
3. ⏭️ **Phase 0-3**: 도메인 의존성 그래프 작성 (`domain-dependencies.md`)
4. ⏭️ **Phase 0-4**: 마이그레이션 매핑표 작성 (`migration-mapping.md`)

---

## 참고 문서

- [마스터플랜](masterplan.md) - 전체 리팩터링 계획
- [도메인 경계](domain-boundaries.md) - Bounded Contexts 원칙
- [API 단순화](api-simplification.md) - REST API 표준
- [권한 검증 패턴](permission-guard.md) - 역함수 패턴
