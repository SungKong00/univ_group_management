package org.castlekong.backend.controller

import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.castlekong.backend.dto.*
import org.castlekong.backend.exception.ValidationException
import org.castlekong.backend.service.AuthService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import io.swagger.v3.oas.annotations.responses.ApiResponse as SwaggerApiResponse

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "Google OAuth2 인증 관련 API")
class AuthController(
    private val authService: AuthService,
) {
    @PostMapping("/google")
    @Operation(summary = "Google OAuth2 로그인", description = "Google 인증 토큰으로 로그인합니다")
    @ApiResponses(
        value = [
            SwaggerApiResponse(responseCode = "200", description = "로그인 성공"),
            SwaggerApiResponse(responseCode = "400", description = "잘못된 요청"),
            SwaggerApiResponse(responseCode = "401", description = "인증 실패"),
        ],
    )
    fun googleLogin(
        @Valid @RequestBody googleLoginRequest: GoogleLoginRequest,
    ): ApiResponse<LoginResponse> {
        val loginResponse =
            when {
                !googleLoginRequest.googleAuthToken.isNullOrBlank() ->
                    authService.authenticateWithGoogle(googleLoginRequest.googleAuthToken)
                !googleLoginRequest.googleAccessToken.isNullOrBlank() ->
                    authService.authenticateWithGoogleAccessToken(googleLoginRequest.googleAccessToken)
                else -> throw ValidationException("Google token is required")
            }
        return ApiResponse.success(loginResponse)
    }

    @PostMapping("/google/callback")
    @Operation(summary = "Google OAuth2 콜백", description = "Google ID Token으로 로그인/회원가입")
    fun googleCallback(
        @RequestBody payload: Map<String, String>,
    ): ApiResponse<LoginResponse> {
        val idToken = payload["id_token"]
        if (idToken.isNullOrBlank()) {
            throw ValidationException("id_token is required")
        }
        val loginResponse = authService.authenticateWithGoogle(idToken)
        return ApiResponse.success(loginResponse)
    }

    @PostMapping("/logout")
    @Operation(summary = "로그아웃", description = "사용자를 로그아웃하고 토큰을 무효화합니다")
    @ApiResponses(
        value = [
            SwaggerApiResponse(responseCode = "200", description = "로그아웃 성공"),
            SwaggerApiResponse(responseCode = "401", description = "인증 실패"),
        ],
    )
    fun logout(): ApiResponse<String> {
        return ApiResponse.success("로그아웃되었습니다")
    }

    // 임시 디버그용 API - 모든 사용자의 profileCompleted를 false로 초기화
    @PostMapping("/debug/reset-profile-status")
    @Operation(summary = "[DEBUG] 모든 사용자의 profileCompleted를 false로 재설정", description = "디버그용 API - 개발 환경에서만 사용")
    fun resetProfileStatus(): ApiResponse<String> {
        val updatedCount = authService.resetAllUsersProfileStatus()
        return ApiResponse.success("Updated $updatedCount users' profileCompleted status to false")
    }
}
