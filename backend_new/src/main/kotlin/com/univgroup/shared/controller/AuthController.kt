package com.univgroup.shared.controller

import com.univgroup.domain.user.dto.UserDto
import com.univgroup.shared.dto.ApiResponse
import com.univgroup.shared.dto.GoogleLoginRequest
import com.univgroup.shared.dto.LoginResponse
import com.univgroup.shared.dto.LogoutRequest
import com.univgroup.shared.dto.RefreshTokenRequest
import com.univgroup.shared.dto.RefreshTokenResponse
import com.univgroup.shared.exception.BusinessException
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.service.AuthService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestHeader
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import io.swagger.v3.oas.annotations.responses.ApiResponse as SwaggerApiResponse

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "Google OAuth2 인증 관련 API")
class AuthController(
    private val authService: AuthService,
    @org.springframework.beans.factory.annotation.Value("\${app.debug.enabled:false}")
    private val debugEnabled: Boolean = false,
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
        val loginResponse = when {
            !googleLoginRequest.googleAuthToken.isNullOrBlank() ->
                authService.authenticateWithGoogle(googleLoginRequest.googleAuthToken)

            !googleLoginRequest.googleAccessToken.isNullOrBlank() ->
                authService.authenticateWithGoogleAccessToken(googleLoginRequest.googleAccessToken)

            else -> throw BusinessException(ErrorCode.COMMON_VALIDATION_FAILED, "Google token is required")
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
            throw BusinessException(ErrorCode.COMMON_VALIDATION_FAILED, "id_token is required")
        }
        val loginResponse = authService.authenticateWithGoogle(idToken)
        return ApiResponse.success(loginResponse)
    }

    @GetMapping("/verify")
    @Operation(summary = "토큰 검증", description = "JWT 액세스 토큰의 유효성을 검증하고 사용자 정보를 반환합니다")
    @ApiResponses(
        value = [
            SwaggerApiResponse(responseCode = "200", description = "토큰 유효함"),
            SwaggerApiResponse(responseCode = "401", description = "토큰 만료 또는 유효하지 않음"),
        ],
    )
    fun verifyToken(): ApiResponse<UserDto> {
        val userDto = authService.verifyToken()
        return ApiResponse.success(userDto)
    }

    @PostMapping("/refresh")
    @Operation(summary = "토큰 갱신", description = "리프레시 토큰으로 새로운 액세스 토큰을 발급받습니다")
    @ApiResponses(
        value = [
            SwaggerApiResponse(responseCode = "200", description = "토큰 갱신 성공"),
            SwaggerApiResponse(responseCode = "401", description = "리프레시 토큰 만료 또는 유효하지 않음"),
        ],
    )
    fun refreshToken(
        @Valid @RequestBody request: RefreshTokenRequest,
    ): ApiResponse<RefreshTokenResponse> {
        val response = authService.refreshAccessToken(request.refreshToken)
        return ApiResponse.success(response)
    }

    @PostMapping("/logout")
    @Operation(summary = "로그아웃", description = "사용자를 로그아웃하고 토큰을 무효화합니다")
    @ApiResponses(
        value = [
            SwaggerApiResponse(responseCode = "200", description = "로그아웃 성공"),
            SwaggerApiResponse(responseCode = "401", description = "인증 실패"),
        ],
    )
    fun logout(
        @RequestHeader("Authorization") authHeader: String,
        @RequestBody(required = false) request: LogoutRequest?,
    ): ApiResponse<String> {
        // Authorization 헤더에서 Bearer 토큰 추출
        val accessToken = if (authHeader.startsWith("Bearer ")) {
            authHeader.substring(7)
        } else {
            throw BusinessException(ErrorCode.AUTH_INVALID_TOKEN, "Invalid Authorization header format")
        }

        // 토큰 무효화
        authService.logout(accessToken, request?.refreshToken)

        return ApiResponse.success("로그아웃되었습니다")
    }

    // 개발용 디버그 API (프로덕션에서는 비활성화)
    // app.debug.enabled=true 설정 시에만 동작
    @PostMapping("/debug/generate-token")
    @Operation(summary = "[DEBUG] 이메일로 개발 토큰 생성", description = "디버그용 API - 개발 환경에서만 사용 (app.debug.enabled=true 필요)")
    fun generateDevToken(
        @RequestBody payload: Map<String, String>,
    ): ApiResponse<LoginResponse> {
        if (!debugEnabled) {
            throw BusinessException(ErrorCode.PERMISSION_DENIED, "Debug API is disabled in production")
        }

        val email = payload["email"]
            ?: throw BusinessException(ErrorCode.COMMON_VALIDATION_FAILED, "email is required")

        val loginResponse = authService.generateDevToken(email)
        return ApiResponse.success(loginResponse)
    }
}
