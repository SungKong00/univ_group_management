package org.castlekong.backend.dto

import java.time.LocalDateTime

data class GoogleLoginRequest(
    val googleAuthToken: String? = null, // ID Token (권장)
    val googleAccessToken: String? = null, // Web에서 ID Token 미제공 시 대안
)

data class LoginResponse(
    val accessToken: String,
    val tokenType: String = "Bearer",
    val expiresIn: Long,
    val user: UserResponse,
    val firstLogin: Boolean = false,
)

data class UserResponse(
    val id: Long,
    val name: String,
    val email: String,
    val globalRole: String,
    val isActive: Boolean,
    val nickname: String?,
    val profileImageUrl: String?,
    val bio: String?,
    val profileCompleted: Boolean,
    val emailVerified: Boolean,
    val professorStatus: String? = null,
    val department: String? = null,
    val studentNo: String? = null,
    val schoolEmail: String? = null,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)

data class ProfileUpdateRequest(
    val globalRole: String,
    val nickname: String,
    val profileImageUrl: String?,
    val bio: String?,
)

// 온보딩용 가입 정보 제출
data class SignupProfileRequest(
    val name: String,
    val nickname: String,
    val college: String?,
    val dept: String?,
    val studentNo: String?,
    val schoolEmail: String,
    val role: String, // STUDENT | PROFESSOR
)

// 닉네임 중복 응답
data class NicknameCheckResponse(
    val available: Boolean,
    val suggestions: List<String> = emptyList(),
)

// 이메일 인증 DTOs
data class EmailSendRequest(
    val email: String,
)

data class EmailVerifyRequest(
    val email: String,
    val code: String,
)
