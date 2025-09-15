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
    ): ResponseEntity<ApiResponse<LoginResponse>> {
        return try {
            val loginResponse = when {
                !googleLoginRequest.googleAuthToken.isNullOrBlank() ->
                    authService.authenticateWithGoogle(googleLoginRequest.googleAuthToken)
                !googleLoginRequest.googleAccessToken.isNullOrBlank() ->
                    authService.authenticateWithGoogleAccessToken(googleLoginRequest.googleAccessToken)
                else -> throw ValidationException("Google token is required")
            }
            ResponseEntity.ok(
                ApiResponse.success(
                    data = loginResponse,
                ),
            )
        } catch (e: ValidationException) {
            ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(
                    ApiResponse.error<LoginResponse>(
                        code = "VALIDATION_ERROR",
                        message = e.message ?: "Invalid request data.",
                    ),
                )
        } catch (e: IllegalArgumentException) {
            ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(
                    ApiResponse.error<LoginResponse>(
                        code = "AUTH_ERROR",
                        message = e.message ?: "Invalid token.",
                    ),
                )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(
                    ApiResponse.error<LoginResponse>(
                        code = "INTERNAL_SERVER_ERROR",
                        message = "서버 내부 오류가 발생했습니다.",
                    ),
                )
        }
    }

    @PostMapping("/google/callback")
    @Operation(summary = "Google OAuth2 콜백", description = "Google ID Token으로 로그인/회원가입")
    fun googleCallback(
        @RequestBody payload: Map<String, String>,
    ): ResponseEntity<ApiResponse<LoginResponse>> {
        val idToken = payload["id_token"]
        if (idToken.isNullOrBlank()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(code = "VALIDATION_ERROR", message = "id_token is required"))
        }
        return try {
            val loginResponse = authService.authenticateWithGoogle(idToken)
            ResponseEntity.ok(ApiResponse.success(loginResponse))
        } catch (e: IllegalArgumentException) {
            ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.error(code = "AUTH_ERROR", message = e.message ?: "Invalid token"))
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(code = "INTERNAL_SERVER_ERROR", message = "서버 내부 오류"))
        }
    }
    
    // 임시 디버그용 API - 모든 사용자의 profileCompleted를 false로 초기화
    @PostMapping("/debug/reset-profile-status")
    @Operation(summary = "[DEBUG] 모든 사용자의 profileCompleted를 false로 재설정", description = "디버그용 API - 개발 환경에서만 사용")
    fun resetProfileStatus(): ResponseEntity<ApiResponse<String>> {
        return try {
            val updatedCount = authService.resetAllUsersProfileStatus()
            ResponseEntity.ok(
                ApiResponse.success(
                    data = "Updated $updatedCount users' profileCompleted status to false"
                )
            )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(
                    ApiResponse.error<String>(
                        code = "INTERNAL_SERVER_ERROR",
                        message = "프로필 상태 초기화 중 오류가 발생했습니다: ${e.message}"
                    )
                )
        }
    }
}
