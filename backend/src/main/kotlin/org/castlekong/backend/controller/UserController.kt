package org.castlekong.backend.controller

import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.castlekong.backend.dto.*
import org.castlekong.backend.service.UserService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*
import io.swagger.v3.oas.annotations.responses.ApiResponse as SwaggerApiResponse

@RestController
@RequestMapping("/api/users")
@Tag(name = "User", description = "사용자 관련 API")
class UserController(
    private val userService: UserService,
) {
    @PutMapping("/profile")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "프로필 완성", description = "사용자 프로필을 완성합니다 (역할, 닉네임, 프로필 이미지, 자기소개)")
    @ApiResponses(
        value = [
            SwaggerApiResponse(responseCode = "200", description = "프로필 완성 성공"),
            SwaggerApiResponse(responseCode = "400", description = "잘못된 요청"),
            SwaggerApiResponse(responseCode = "401", description = "인증 필요"),
            SwaggerApiResponse(responseCode = "404", description = "사용자 없음"),
        ],
    )
    fun completeProfile(
        @Valid @RequestBody request: ProfileUpdateRequest,
        authentication: Authentication,
    ): ResponseEntity<ApiResponse<UserResponse>> {
        return try {
            val userEmail = authentication.name
            val user = userService.findByEmail(userEmail)
                ?: return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(
                        ApiResponse.error<UserResponse>(
                            code = "USER_NOT_FOUND",
                            message = "사용자를 찾을 수 없습니다.",
                        ),
                    )

            val updatedUser = userService.completeProfile(user.id, request)
            val userResponse = userService.convertToUserResponse(updatedUser)

            ResponseEntity.ok(
                ApiResponse.success(
                    data = userResponse,
                    message = "프로필이 성공적으로 완성되었습니다.",
                ),
            )
        } catch (e: IllegalArgumentException) {
            ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(
                    ApiResponse.error<UserResponse>(
                        code = "VALIDATION_ERROR",
                        message = e.message ?: "잘못된 요청 데이터입니다.",
                    ),
                )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(
                    ApiResponse.error<UserResponse>(
                        code = "INTERNAL_SERVER_ERROR",
                        message = "서버 내부 오류가 발생했습니다.",
                    ),
                )
        }
    }

    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "내 정보 조회", description = "현재 로그인한 사용자의 정보를 조회합니다")
    @ApiResponses(
        value = [
            SwaggerApiResponse(responseCode = "200", description = "조회 성공"),
            SwaggerApiResponse(responseCode = "401", description = "인증 필요"),
            SwaggerApiResponse(responseCode = "404", description = "사용자 없음"),
        ],
    )
    fun getCurrentUser(
        authentication: Authentication,
    ): ResponseEntity<ApiResponse<UserResponse>> {
        return try {
            val userEmail = authentication.name
            val user = userService.findByEmail(userEmail)
                ?: return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(
                        ApiResponse.error<UserResponse>(
                            code = "USER_NOT_FOUND",
                            message = "사용자를 찾을 수 없습니다.",
                        ),
                    )

            val userResponse = userService.convertToUserResponse(user)
            ResponseEntity.ok(
                ApiResponse.success(
                    data = userResponse,
                ),
            )
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(
                    ApiResponse.error<UserResponse>(
                        code = "INTERNAL_SERVER_ERROR",
                        message = "서버 내부 오류가 발생했습니다.",
                    ),
                )
        }
    }
}