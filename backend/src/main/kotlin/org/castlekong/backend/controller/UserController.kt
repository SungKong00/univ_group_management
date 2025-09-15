package org.castlekong.backend.controller

import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.castlekong.backend.dto.*
import org.castlekong.backend.service.UserService
import org.castlekong.backend.service.EmailVerificationService
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
    private val emailVerificationService: EmailVerificationService,
) {
    @PostMapping("")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "온보딩 가입 정보 제출", description = "첫 로그인 후 프로필/역할/학적/학교 이메일을 확정합니다")
    fun createOrCompleteSignup(
        @Valid @RequestBody request: SignupProfileRequest,
        authentication: Authentication,
    ): ResponseEntity<ApiResponse<UserResponse>> {
        return try {
            val userEmail = authentication.name
            val user = userService.findByEmail(userEmail)
                ?: return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error(code = "USER_NOT_FOUND", message = "사용자를 찾을 수 없습니다."))

            val updatedUser = userService.submitSignupProfile(user.id, request)
            ResponseEntity.ok(ApiResponse.success(userService.convertToUserResponse(updatedUser)))
        } catch (e: IllegalArgumentException) {
            ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(code = "VALIDATION_ERROR", message = e.message ?: "잘못된 요청"))
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(code = "INTERNAL_SERVER_ERROR", message = "서버 내부 오류"))
        }
    }

    @GetMapping("/nickname-check")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "닉네임 중복 확인", description = "닉네임 사용 가능 여부와 추천 닉네임을 반환")
    fun checkNickname(
        @RequestParam nickname: String,
    ): ResponseEntity<ApiResponse<NicknameCheckResponse>> {
        return try {
            val exists = userService.nicknameExists(nickname)
            val suggestions = if (exists) {
                val base = nickname.take(12)
                listOf(1, 2, 3).map { "$base${"%02d".format((10..99).random())}" }
            } else emptyList()
            ResponseEntity.ok(ApiResponse.success(NicknameCheckResponse(!exists, suggestions)))
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(code = "INTERNAL_SERVER_ERROR", message = "서버 내부 오류"))
        }
    }
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
                ApiResponse.success(userResponse),
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
                ApiResponse.success(userResponse),
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


    @GetMapping("/search")
    @PreAuthorize("isAuthenticated()")
    fun searchUsers(
        @RequestParam("q") query: String,
        @RequestParam("role", required = false) role: String?,
    ): ResponseEntity<ApiResponse<List<UserSummaryResponse>>> {
        return try {
            val results = userService.searchUsers(query, role)
            val list = results.map { userService.convertToUserSummary(it) }
            ResponseEntity.ok(ApiResponse.success(list))
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(
                    ApiResponse.error<List<UserSummaryResponse>>(
                        code = "INTERNAL_SERVER_ERROR",
                        message = "서버 내부 오류가 발생했습니다.",
                    ),
                )
        }
    }

    // /api/me는 별도 컨트롤러로 제공

    // === My Applications ===
    @GetMapping("/me/join-requests")
    @PreAuthorize("isAuthenticated()")
    fun getMyJoinRequests(
        authentication: Authentication,
        @RequestParam(required = false, defaultValue = "PENDING") status: String,
    ): ResponseEntity<ApiResponse<List<GroupJoinRequestResponse>>> {
        val user = userService.findByEmail(authentication.name)
            ?: return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(code = "USER_NOT_FOUND", message = "사용자를 찾을 수 없습니다."))
        val list = userService.getMyJoinRequests(user.id, status)
        return ResponseEntity.ok(ApiResponse.success(list))
    }

    @GetMapping("/me/sub-group-requests")
    @PreAuthorize("isAuthenticated()")
    fun getMySubGroupRequests(
        authentication: Authentication,
        @RequestParam(required = false, defaultValue = "PENDING") status: String,
    ): ResponseEntity<ApiResponse<List<SubGroupRequestResponse>>> {
        val user = userService.findByEmail(authentication.name)
            ?: return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(code = "USER_NOT_FOUND", message = "사용자를 찾을 수 없습니다."))
        val list = userService.getMySubGroupRequests(user.id, status)
        return ResponseEntity.ok(ApiResponse.success(list))
    }
}
