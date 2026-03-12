package com.univgroup.shared.dto

import com.univgroup.domain.user.dto.UserDto
import jakarta.validation.constraints.NotBlank

/**
 * Google 로그인 요청 DTO
 */
data class GoogleLoginRequest(
    // ID Token (권장)
    val googleAuthToken: String? = null,
    // Web에서 ID Token 미제공 시 대안
    val googleAccessToken: String? = null,
)

/**
 * 로그인 응답 DTO
 */
data class LoginResponse(
    val accessToken: String,
    val tokenType: String = "Bearer",
    val expiresIn: Long,
    val user: UserDto,
    val firstLogin: Boolean = false,
    val refreshToken: String = "",
)

/**
 * 토큰 갱신 요청 DTO
 */
data class RefreshTokenRequest(
    @field:NotBlank(message = "refreshToken is required")
    val refreshToken: String,
)

/**
 * 토큰 갱신 응답 DTO
 */
data class RefreshTokenResponse(
    val accessToken: String,
    val tokenType: String = "Bearer",
    val expiresIn: Long,
)

/**
 * 로그아웃 요청 DTO
 */
data class LogoutRequest(
    val refreshToken: String? = null, // 리프레시 토큰도 함께 무효화 (선택)
)
