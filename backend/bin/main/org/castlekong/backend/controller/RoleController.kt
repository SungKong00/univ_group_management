package org.castlekong.backend.controller

import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.castlekong.backend.dto.ApiResponse
import org.castlekong.backend.service.UserService
import org.springframework.http.HttpStatus
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

data class RoleApplyRequest(val role: String)

@RestController
@RequestMapping("/api/roles")
@Tag(name = "Roles", description = "역할 신청/변경 API")
class RoleController(
    private val userService: UserService,
) {
    @PostMapping("/apply")
    @PreAuthorize("isAuthenticated()")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "역할 신청", description = "role=PROFESSOR일 때 승인 대기 상태를 생성합니다")
    fun applyRole(
        authentication: Authentication,
        @RequestBody req: RoleApplyRequest,
    ): ApiResponse<Unit> {
        val user =
            userService.findByEmail(authentication.name)
                ?: throw org.castlekong.backend.exception.BusinessException(org.castlekong.backend.exception.ErrorCode.USER_NOT_FOUND)
        userService.applyRole(user.id, req.role)
        return ApiResponse.success()
    }
}
