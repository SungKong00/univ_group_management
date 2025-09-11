package org.castlekong.backend.fixture

import org.castlekong.backend.dto.GoogleLoginRequest
import org.castlekong.backend.entity.User
import org.castlekong.backend.entity.GlobalRole
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
        password: String = "", // Google OAuth2 users don't have passwords
        globalRole: GlobalRole = GlobalRole.STUDENT,
        isActive: Boolean = true,
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
            createdAt = createdAt,
            updatedAt = updatedAt,
        )
    }

    fun createGoogleLoginRequest(
        googleAuthToken: String = TEST_GOOGLE_TOKEN,
    ): GoogleLoginRequest {
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
}
