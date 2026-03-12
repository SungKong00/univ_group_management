package com.univgroup.domain.user.controller

import com.univgroup.domain.user.dto.*
import com.univgroup.domain.user.service.UserService
import com.univgroup.shared.controller.BaseController
import com.univgroup.shared.dto.ApiResponse
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.*

/**
 * 사용자 컨트롤러
 */
@RestController
@RequestMapping("/api/users")
class UserController(
    userService: UserService,
) : BaseController(userService) {
    private val userServiceImpl: UserService = userService

    // ========== 현재 사용자 ==========

    /**
     * 내 프로필 조회
     */
    @GetMapping("/me")
    fun getMyProfile(authentication: Authentication): ApiResponse<UserDto> {
        val user = getCurrentUser(authentication)
        return ApiResponse.success(UserDto.from(user))
    }

    /**
     * 내 프로필 수정
     */
    @PatchMapping("/me")
    fun updateMyProfile(
        @RequestBody request: UpdateProfileRequest,
        authentication: Authentication,
    ): ApiResponse<UserDto> {
        val userId = getCurrentUserId(authentication)

        val updated =
            userServiceImpl.updateProfile(userId) { user ->
                request.name?.let { user.name = it }
                request.bio?.let { user.bio = it }
                request.profileImageUrl?.let { user.profileImageUrl = it }
                request.college?.let { user.college = it }
                request.department?.let { user.department = it }
                request.studentNo?.let { user.studentNo = it }
                request.academicYear?.let { user.academicYear = it }
            }

        // 닉네임은 별도 API로 변경
        request.nickname?.let { nickname ->
            userServiceImpl.updateNickname(userId, nickname)
        }

        return ApiResponse.success(UserDto.from(updated))
    }

    /**
     * 프로필 완료 처리
     */
    @PostMapping("/me/complete-profile")
    fun completeProfile(authentication: Authentication): ApiResponse<UserDto> {
        val userId = getCurrentUserId(authentication)
        val updated = userServiceImpl.completeProfile(userId)
        return ApiResponse.success(UserDto.from(updated))
    }

    // ========== 다른 사용자 조회 ==========

    /**
     * 사용자 조회 (공개 정보)
     */
    @GetMapping("/{userId}")
    fun getUser(
        @PathVariable userId: Long,
    ): ApiResponse<UserSummaryDto> {
        val user = userServiceImpl.getById(userId)
        return ApiResponse.success(UserSummaryDto.from(user))
    }

    // ========== 닉네임 ==========

    /**
     * 닉네임 중복 확인
     */
    @GetMapping("/check-nickname")
    fun checkNickname(
        @RequestParam nickname: String,
        authentication: Authentication?,
    ): ApiResponse<NicknameCheckResponse> {
        val excludeUserId = authentication?.let { getCurrentUserId(it) }
        val available = userServiceImpl.isNicknameAvailable(nickname, excludeUserId)

        return ApiResponse.success(NicknameCheckResponse(nickname, available))
    }

    /**
     * 닉네임 변경
     */
    @PatchMapping("/me/nickname")
    fun updateNickname(
        @RequestParam nickname: String,
        authentication: Authentication,
    ): ApiResponse<UserDto> {
        val userId = getCurrentUserId(authentication)
        val updated = userServiceImpl.updateNickname(userId, nickname)
        return ApiResponse.success(UserDto.from(updated))
    }
}
