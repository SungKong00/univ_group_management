package com.univgroup.shared.controller

import com.univgroup.domain.user.entity.User
import com.univgroup.domain.user.service.IUserService
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.AuthenticationException
import org.springframework.security.core.Authentication

/**
 * 기본 컨트롤러 (공통 헬퍼 메서드)
 *
 * 모든 컨트롤러는 이 클래스를 상속받아 공통 기능을 사용한다.
 * - 현재 사용자 조회
 * - 인증 정보 추출
 */
abstract class BaseController(
    protected val userService: IUserService,
) {
    /**
     * 현재 인증된 사용자 조회
     *
     * @param authentication Spring Security 인증 객체
     * @return 사용자 엔티티
     * @throws AuthenticationException 인증 정보가 없거나 사용자를 찾을 수 없는 경우
     */
    protected fun getCurrentUser(authentication: Authentication?): User {
        if (authentication == null || !authentication.isAuthenticated) {
            throw AuthenticationException(ErrorCode.AUTH_UNAUTHORIZED)
        }

        val email = authentication.name
        return userService.findByEmail(email)
            ?: throw AuthenticationException(ErrorCode.USER_NOT_FOUND, "사용자를 찾을 수 없습니다: $email")
    }

    /**
     * 현재 인증된 사용자 ID 조회
     *
     * @param authentication Spring Security 인증 객체
     * @return 사용자 ID
     * @throws IllegalStateException 사용자 ID가 할당되지 않은 경우
     */
    protected fun getCurrentUserId(authentication: Authentication?): Long {
        val user = getCurrentUser(authentication)
        return user.id.takeIf { it != 0L }
            ?: throw IllegalStateException("User ID is not assigned for user: ${user.email}")
    }
}
