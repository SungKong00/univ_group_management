package org.castlekong.backend.controller

import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.dto.EmailSendRequest
import org.castlekong.backend.dto.EmailVerifyRequest
import org.castlekong.backend.service.EmailVerificationService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/email/verification")
@Tag(name = "Email Verification", description = "학교 이메일 OTP 인증 API")
class EmailVerificationController(
    private val emailVerificationService: EmailVerificationService,
) {
    @PostMapping("/send")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "인증 코드 발송", description = "학교 이메일로 6자리 인증 코드를 발송합니다")
    fun sendCode(
        authentication: Authentication,
        @Valid @RequestBody req: EmailSendRequest,
    ): ResponseEntity<ApiResponse<Unit>> {
        return try {
            emailVerificationService.sendCode(authentication.name, req)
            ResponseEntity.ok(ApiResponse.success())
        } catch (e: IllegalArgumentException) {
            ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(code = "VALIDATION_ERROR", message = e.message ?: "잘못된 요청"))
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(code = "INTERNAL_SERVER_ERROR", message = "서버 내부 오류"))
        }
    }

    @PostMapping("/verify")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "인증 코드 검증", description = "학교 이메일과 코드를 검증하고 사용자에 인증 상태를 반영합니다")
    fun verifyCode(
        authentication: Authentication,
        @Valid @RequestBody req: EmailVerifyRequest,
    ): ResponseEntity<ApiResponse<Unit>> {
        return try {
            emailVerificationService.verifyCode(authentication.name, req)
            ResponseEntity.ok(ApiResponse.success())
        } catch (e: IllegalArgumentException) {
            ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(code = "VALIDATION_ERROR", message = e.message ?: "잘못된 요청"))
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(code = "INTERNAL_SERVER_ERROR", message = "서버 내부 오류"))
        }
    }
}
