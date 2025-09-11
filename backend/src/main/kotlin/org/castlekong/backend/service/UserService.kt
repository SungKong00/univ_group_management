package org.castlekong.backend.service

import org.castlekong.backend.dto.UserResponse
import org.castlekong.backend.dto.ProfileUpdateRequest
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
    
    fun findAll(): List<User> {
        return userRepository.findAll()
    }
    
    @Transactional
    fun save(user: User): User {
        return userRepository.save(user)
    }

    @Transactional
    fun findOrCreateUser(googleUserInfo: org.castlekong.backend.service.GoogleUserInfo): User {
        // 기존 사용자 조회
        val existingUser = findByEmail(googleUserInfo.email)

        return if (existingUser != null) {
            // 기존 사용자 반환
            println("DEBUG: Found existing user - email: ${existingUser.email}, profileCompleted: ${existingUser.profileCompleted}")
            existingUser
        } else {
            // 새 사용자 생성
            val user =
                User(
                    name = googleUserInfo.name,
                    email = googleUserInfo.email,
                    password = "", // Google OAuth2 사용자는 비밀번호 불필요
                    globalRole = GlobalRole.STUDENT,
                    profileCompleted = false, // 명시적으로 false 설정
                )
            val savedUser = userRepository.save(user)
            println("DEBUG: Created new user - email: ${savedUser.email}, profileCompleted: ${savedUser.profileCompleted}")
            savedUser
        }
    }

    @Transactional
    fun completeProfile(userId: Long, request: ProfileUpdateRequest): User {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("사용자를 찾을 수 없습니다: $userId") }
        
        val updatedUser = user.copy(
            globalRole = GlobalRole.valueOf(request.globalRole),
            nickname = request.nickname,
            profileImageUrl = request.profileImageUrl,
            bio = request.bio,
            profileCompleted = true
        )
        
        return userRepository.save(updatedUser)
    }

    fun convertToUserResponse(user: User): UserResponse {
        return UserResponse(
            id = user.id,
            name = user.name,
            email = user.email,
            globalRole = user.globalRole.name,
            isActive = user.isActive,
            nickname = user.nickname,
            profileImageUrl = user.profileImageUrl,
            bio = user.bio,
            profileCompleted = user.profileCompleted,
            emailVerified = user.emailVerified,
            createdAt = user.createdAt,
            updatedAt = user.updatedAt,
        )
    }
}
