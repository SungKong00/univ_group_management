package org.castlekong.backend.controller

import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.dto.UserResponse
import org.castlekong.backend.service.UserService
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api")
@Tag(name = "Me", description = "현재 사용자 정보 API")
class MeController(
    userService: UserService,
) : BaseController(userService) {
    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "내 정보 조회", description = "현재 로그인한 사용자의 정보를 조회합니다 (/api/me)")
    fun getMe(authentication: Authentication): ApiResponse<UserResponse> {
        val user = getCurrentUser(authentication)
        return ApiResponse.success(userService.convertToUserResponse(user))
    }
}
