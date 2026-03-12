package com.univgroup.domain.user.service

import com.univgroup.domain.user.entity.User
import com.univgroup.domain.user.repository.UserRepository
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.ResourceNotFoundException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * 사용자 서비스 구현체
 *
 * User 도메인의 비즈니스 로직을 담당한다.
 */
@Service
@Transactional(readOnly = true)
class UserService(
    private val userRepository: UserRepository,
) : IUserService {
    // ========== IUserService 구현 ==========

    override fun findById(userId: Long): User? {
        return userRepository.findById(userId).orElse(null)
    }

    override fun getById(userId: Long): User {
        return userRepository.findById(userId).orElseThrow {
            ResourceNotFoundException(
                ErrorCode.USER_NOT_FOUND,
                "사용자를 찾을 수 없습니다: $userId",
            )
        }
    }

    override fun findByEmail(email: String): User? {
        return userRepository.findByEmail(email)
    }

    override fun exists(userId: Long): Boolean {
        return userRepository.existsById(userId)
    }

    override fun isNicknameAvailable(
        nickname: String,
        excludeUserId: Long?,
    ): Boolean {
        return if (excludeUserId != null) {
            !userRepository.existsByNicknameAndIdNot(nickname, excludeUserId)
        } else {
            !userRepository.existsByNickname(nickname)
        }
    }

    // ========== 추가 비즈니스 로직 ==========

    /**
     * 사용자 생성 또는 조회 (OAuth 로그인용)
     */
    @Transactional
    fun findOrCreateByEmail(
        email: String,
        name: String,
        profileImageUrl: String? = null,
    ): User {
        val existingUser = userRepository.findByEmail(email)
        if (existingUser != null) {
            return existingUser
        }

        val newUser =
            User(
                email = email,
                name = name,
                password = "", // OAuth 로그인 사용자는 패스워드 불필요
                profileImageUrl = profileImageUrl,
            )

        return userRepository.save(newUser)
    }

    /**
     * 사용자 프로필 업데이트
     */
    @Transactional
    fun updateProfile(
        userId: Long,
        updateFn: (User) -> Unit,
    ): User {
        val user = getById(userId)
        updateFn(user)
        return userRepository.save(user)
    }

    /**
     * 닉네임 변경
     */
    @Transactional
    fun updateNickname(
        userId: Long,
        nickname: String,
    ): User {
        if (!isNicknameAvailable(nickname, userId)) {
            throw IllegalArgumentException("이미 사용 중인 닉네임입니다: $nickname")
        }

        val user = getById(userId)
        user.nickname = nickname
        return userRepository.save(user)
    }

    /**
     * 프로필 완료 처리
     */
    @Transactional
    fun completeProfile(userId: Long): User {
        val user = getById(userId)
        user.profileCompleted = true
        return userRepository.save(user)
    }
}
