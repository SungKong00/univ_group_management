package org.castlekong.backend.controller

import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.service.UserService
import org.springframework.security.core.Authentication

/**
 * 모든 컨트롤러의 기본 클래스
 * 공통 헬퍼 메서드와 표준화된 패턴을 제공합니다.
 */
abstract class BaseController(
    protected val userService: UserService,
) {
    /**
     * 현재 로그인한 사용자 정보를 조회합니다.
     * 사용자를 찾을 수 없는 경우 BusinessException을 발생시킵니다.
     *
     * @param authentication Spring Security Authentication 객체
     * @return 현재 로그인한 사용자 엔티티
     * @throws BusinessException 사용자를 찾을 수 없는 경우
     */
    protected fun getCurrentUser(authentication: Authentication): User =
        userService.findByEmail(authentication.name)
            ?: throw BusinessException(ErrorCode.USER_NOT_FOUND)

    /**
     * 이메일로 사용자를 조회합니다.
     * 사용자를 찾을 수 없는 경우 BusinessException을 발생시킵니다.
     *
     * @param email 사용자 이메일
     * @return 사용자 엔티티
     * @throws BusinessException 사용자를 찾을 수 없는 경우
     */
    protected fun getUserByEmail(email: String): User =
        userService.findByEmail(email)
            ?: throw BusinessException(ErrorCode.USER_NOT_FOUND)
}
