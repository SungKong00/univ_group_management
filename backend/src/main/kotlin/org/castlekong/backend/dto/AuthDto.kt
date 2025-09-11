package org.castlekong.backend.dto

import jakarta.validation.constraints.NotBlank
import java.time.LocalDateTime

data class GoogleLoginRequest(
    val googleAuthToken: String? = null,    // ID Token (권장)
    val googleAccessToken: String? = null,  // Web에서 ID Token 미제공 시 대안
)

data class LoginResponse(
    val accessToken: String,
    val tokenType: String = "Bearer",
    val expiresIn: Long,
    val user: UserResponse,
)

data class UserResponse(
    val id: Long,
    val name: String,
    val email: String,
    val globalRole: String,
    val isActive: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
)
