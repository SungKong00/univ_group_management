package org.castlekong.backend.fixture

import org.castlekong.backend.dto.GoogleLoginRequest
import org.castlekong.backend.dto.ProfileUpdateRequest
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupMember
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.User
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.Authentication
import org.springframework.security.core.authority.SimpleGrantedAuthority
import java.time.LocalDateTime

object TestDataFactory {
    // Test User Data
    const val TEST_EMAIL = "test@example.com"
    const val TEST_NAME = "테스트 사용자"
    const val TEST_USER_ID = 1L
    const val TEST_GOOGLE_TOKEN = "test.google.token"

    // JWT Test Data
    const val TEST_JWT_SECRET = "testSecretKeyForJWTWhichIsVeryLongAndSecureForTestingPurposesOnly12345678901234567890"
    const val TEST_ACCESS_TOKEN_EXPIRATION = 86400000L // 24시간
    const val TEST_REFRESH_TOKEN_EXPIRATION = 604800000L // 7일

    fun createTestUser(
        id: Long = 0L,
        name: String = TEST_NAME,
        email: String = TEST_EMAIL,
        // Google OAuth2 users don't have passwords
        password: String = "",
        globalRole: GlobalRole = GlobalRole.STUDENT,
        isActive: Boolean = true,
        studentNo: String = "20201234",
        academicYear: Int = 1,
        createdAt: LocalDateTime = LocalDateTime.now(),
        updatedAt: LocalDateTime = LocalDateTime.now(),
    ): User {
        return User(
            id = id,
            name = name,
            email = email,
            password = password,
            globalRole = globalRole,
            isActive = isActive,
            studentNo = studentNo,
            academicYear = academicYear,
            createdAt = createdAt,
            updatedAt = updatedAt,
        )
    }

    fun createGoogleLoginRequest(googleAuthToken: String = TEST_GOOGLE_TOKEN): GoogleLoginRequest {
        return GoogleLoginRequest(
            googleAuthToken = googleAuthToken,
        )
    }

    fun createAuthentication(
        email: String = TEST_EMAIL,
        role: GlobalRole = GlobalRole.STUDENT,
    ): Authentication {
        val authorities = listOf(SimpleGrantedAuthority("ROLE_${role.name}"))
        return UsernamePasswordAuthenticationToken(
            email,
            null,
            authorities,
        )
    }

    // 잘못된 데이터 생성 메서드들
    fun createInvalidGoogleLoginRequest(): GoogleLoginRequest {
        return GoogleLoginRequest(
            googleAuthToken = "",
        )
    }

    fun createInvalidGoogleTokenRequest(): GoogleLoginRequest {
        return GoogleLoginRequest(
            googleAuthToken = "invalid.google.token",
        )
    }

    fun createInactiveUser(): User {
        return createTestUser(
            isActive = false,
        )
    }

    fun createAdminUser(): User {
        return createTestUser(
            id = 2L,
            email = "admin@example.com",
            globalRole = GlobalRole.ADMIN,
        )
    }

    fun createProfileUpdateRequest(
        globalRole: String = "STUDENT",
        nickname: String = "테스트닉네임",
        profileImageUrl: String? = null,
        bio: String? = null,
    ): ProfileUpdateRequest {
        return ProfileUpdateRequest(
            globalRole = globalRole,
            nickname = nickname,
            profileImageUrl = profileImageUrl,
            bio = bio,
        )
    }

    fun createGoogleAccessTokenRequest(googleAccessToken: String = "valid.google.access.token"): GoogleLoginRequest {
        return GoogleLoginRequest(
            googleAuthToken = null,
            googleAccessToken = googleAccessToken,
        )
    }

    fun createInvalidGoogleAccessTokenRequest(): GoogleLoginRequest {
        return GoogleLoginRequest(
            googleAuthToken = null,
            googleAccessToken = "invalid.google.access.token",
        )
    }

    // === Group & Role Test Data ===

    fun createTestGroup(
        id: Long = 0L,
        name: String = "테스트 그룹",
        description: String? = "테스트 그룹입니다",
        owner: User,
        parent: Group? = null,
        university: String? = null,
        college: String? = null,
        department: String? = null,
        groupType: GroupType = GroupType.AUTONOMOUS,
        isRecruiting: Boolean = false,
        maxMembers: Int? = null,
        tags: Set<String> = emptySet(),
    ): Group {
        return Group(
            id = id,
            name = name,
            description = description,
            owner = owner,
            parent = parent,
            university = university,
            college = college,
            department = department,
            groupType = groupType,
            isRecruiting = isRecruiting,
            maxMembers = maxMembers,
            tags = tags,
        )
    }

    fun createTestGroupRole(
        id: Long = 0L,
        group: Group,
        name: String = "멤버",
        isSystemRole: Boolean = true,
        permissions: Set<GroupPermission> = emptySet(),
        priority: Int = 1,
    ): GroupRole {
        return GroupRole(
            id = id,
            group = group,
            name = name,
            isSystemRole = isSystemRole,
            permissions = permissions.toMutableSet(),
            priority = priority,
        )
    }

    fun createTestGroupMember(
        id: Long = 0L,
        group: Group,
        user: User,
        role: GroupRole,
        joinedAt: LocalDateTime = LocalDateTime.now(),
    ): GroupMember {
        return GroupMember(
            id = id,
            group = group,
            user = user,
            role = role,
            joinedAt = joinedAt,
        )
    }

    fun createOwnerRole(group: Group): GroupRole {
        return createTestGroupRole(
            group = group,
            name = "그룹장",
            isSystemRole = true,
            permissions = GroupPermission.values().toSet(),
            priority = 100,
        )
    }

    fun createAdvisorRole(group: Group): GroupRole {
        return createTestGroupRole(
            group = group,
            name = "교수",
            isSystemRole = true,
            permissions = GroupPermission.values().toSet(),
            priority = 99,
        )
    }

    fun createMemberRole(group: Group): GroupRole {
        return createTestGroupRole(
            group = group,
            name = "멤버",
            isSystemRole = true,
            permissions = emptySet(),
            priority = 1,
        )
    }

    fun createProfessorUser(
        id: Long = 0L,
        name: String = "교수님",
        email: String = "professor@example.com",
    ): User {
        return createTestUser(
            id = id,
            name = name,
            email = email,
            globalRole = GlobalRole.PROFESSOR,
        )
    }

    fun createStudentUser(
        id: Long = 0L,
        name: String = "학생",
        email: String = "student@example.com",
    ): User {
        return createTestUser(
            id = id,
            name = name,
            email = email,
            globalRole = GlobalRole.STUDENT,
        )
    }

    fun uniqueEmail(prefix: String): String = "$prefix-${System.nanoTime()}@test.local"
}
