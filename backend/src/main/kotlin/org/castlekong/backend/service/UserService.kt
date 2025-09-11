package org.castlekong.backend.service

import org.castlekong.backend.dto.UserResponse
import org.castlekong.backend.entity.User
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.repository.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class UserService(
    private val userRepository: UserRepository,
) {
    fun findByEmail(email: String): User? {
        return userRepository.findByEmail(email).orElse(null)
    }

    @Transactional
    fun findOrCreateUser(googleUserInfo: org.castlekong.backend.service.GoogleUserInfo): User {
        // 기존 사용자 조회
        val existingUser = findByEmail(googleUserInfo.email)

        return if (existingUser != null) {
            // 기존 사용자 반환
            existingUser
        } else {
            // 새 사용자 생성
            val user =
                User(
                    name = googleUserInfo.name,
                    email = googleUserInfo.email,
                    password = "", // Google OAuth2 사용자는 비밀번호 불필요
                    globalRole = GlobalRole.STUDENT,
                )
            userRepository.save(user)
        }
    }

    fun convertToUserResponse(user: User): UserResponse {
        return UserResponse(
            id = user.id,
            name = user.name,
            email = user.email,
            globalRole = user.globalRole.name,
            isActive = user.isActive,
            createdAt = user.createdAt,
            updatedAt = user.updatedAt,
        )
    }
}
