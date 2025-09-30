package org.castlekong.backend.controller

import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.castlekong.backend.dto.*
import org.castlekong.backend.service.EmailVerificationService
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
    userService: UserService,
    private val emailVerificationService: EmailVerificationService,
) : BaseController(userService) {
    @PostMapping("")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "온보딩 가입 정보 제출", description = "첫 로그인 후 프로필/역할/학적/학교 이메일을 확정합니다")
    fun createOrCompleteSignup(
        @Valid @RequestBody request: SignupProfileRequest,
        authentication: Authentication,
    ): ApiResponse<UserResponse> {
        val user = getCurrentUser(authentication)
        val updatedUser = userService.submitSignupProfile(user.id, request)
        return ApiResponse.success(userService.convertToUserResponse(updatedUser))
    }

    @GetMapping("/nickname-check")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "닉네임 중복 확인", description = "닉네임 사용 가능 여부와 추천 닉네임을 반환")
    fun checkNickname(
        @RequestParam nickname: String,
    ): ApiResponse<NicknameCheckResponse> {
        val exists = userService.nicknameExists(nickname)
        val suggestions =
            if (exists) {
                val base = nickname.take(12)
                listOf(1, 2, 3).map { "$base${"%02d".format((10..99).random())}" }
            } else {
                emptyList()
            }
        return ApiResponse.success(NicknameCheckResponse(!exists, suggestions))
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
    ): ApiResponse<UserResponse> {
        val user = getCurrentUser(authentication)
        val updatedUser = userService.completeProfile(user.id, request)
        return ApiResponse.success(userService.convertToUserResponse(updatedUser))
    }

    @GetMapping("/search")
    @PreAuthorize("isAuthenticated()")
    fun searchUsers(
        @RequestParam("q") query: String,
        @RequestParam("role", required = false) role: String?,
    ): ApiResponse<List<UserSummaryResponse>> {
        val results = userService.searchUsers(query, role)
        val list = results.map { userService.convertToUserSummary(it) }
        return ApiResponse.success(list)
    }

    // === My Applications ===
    @GetMapping("/me/join-requests")
    @PreAuthorize("isAuthenticated()")
    fun getMyJoinRequests(
        authentication: Authentication,
        @RequestParam(required = false, defaultValue = "PENDING") status: String,
    ): ApiResponse<List<GroupJoinRequestResponse>> {
        val user = getCurrentUser(authentication)
        val list = userService.getMyJoinRequests(user.id, status)
        return ApiResponse.success(list)
    }

    @GetMapping("/me/sub-group-requests")
    @PreAuthorize("isAuthenticated()")
    fun getMySubGroupRequests(
        authentication: Authentication,
        @RequestParam(required = false, defaultValue = "PENDING") status: String,
    ): ApiResponse<List<SubGroupRequestResponse>> {
        val user = getCurrentUser(authentication)
        val list = userService.getMySubGroupRequests(user.id, status)
        return ApiResponse.success(list)
    }
}
