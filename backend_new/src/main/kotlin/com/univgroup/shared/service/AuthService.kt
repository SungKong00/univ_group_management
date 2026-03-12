package com.univgroup.shared.service

import com.univgroup.domain.user.dto.UserDto
import com.univgroup.domain.user.entity.GlobalRole
import com.univgroup.domain.user.entity.User
import com.univgroup.domain.user.repository.UserRepository
import com.univgroup.shared.dto.LoginResponse
import com.univgroup.shared.dto.RefreshTokenResponse
import com.univgroup.shared.exception.BusinessException
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.security.GoogleIdTokenVerifierPort
import com.univgroup.shared.security.GoogleUserInfoFetcherPort
import com.univgroup.shared.security.JwtTokenProvider
import org.slf4j.LoggerFactory
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.Authentication
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class AuthService(
    private val userRepository: UserRepository,
    private val jwtTokenProvider: JwtTokenProvider,
    private val googleIdTokenVerifierPort: GoogleIdTokenVerifierPort,
    private val googleUserInfoFetcherPort: GoogleUserInfoFetcherPort,
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    /**
     * Google ID Token으로 인증
     */
    @Transactional
    fun authenticateWithGoogle(googleAuthToken: String): LoginResponse {
        val googleUser = googleIdTokenVerifierPort.verify(googleAuthToken)
            ?: throw BusinessException(ErrorCode.AUTH_INVALID_TOKEN)

        val user = findOrCreateUser(googleUser.email, googleUser.name, googleUser.profileImageUrl)
        if (!user.isActive) {
            throw BusinessException(ErrorCode.AUTH_UNAUTHORIZED)
        }

        return createLoginResponse(user)
    }

    /**
     * Google Access Token으로 인증 (웹에서 ID Token 미사용 시)
     */
    @Transactional
    fun authenticateWithGoogleAccessToken(accessToken: String): LoginResponse {
        val googleUser = googleUserInfoFetcherPort.fetch(accessToken)
            ?: throw BusinessException(ErrorCode.AUTH_INVALID_TOKEN)

        val user = findOrCreateUser(googleUser.email, googleUser.name, googleUser.profileImageUrl)
        if (!user.isActive) {
            throw BusinessException(ErrorCode.AUTH_UNAUTHORIZED)
        }

        return createLoginResponse(user)
    }

    /**
     * JWT 토큰 검증 및 사용자 정보 반환
     */
    fun verifyToken(): UserDto {
        val authentication = SecurityContextHolder.getContext().authentication
            ?: throw BusinessException(ErrorCode.AUTH_UNAUTHORIZED)

        val email = authentication.name
        logger.debug("Verifying token for user: {}", email)

        val user = userRepository.findByEmail(email)
            ?: throw BusinessException(ErrorCode.USER_NOT_FOUND)

        if (!user.isActive) {
            throw BusinessException(ErrorCode.AUTH_UNAUTHORIZED)
        }

        return UserDto.from(user)
    }

    /**
     * 리프레시 토큰으로 새로운 액세스 토큰 발급
     */
    fun refreshAccessToken(refreshToken: String): RefreshTokenResponse {
        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw BusinessException(ErrorCode.AUTH_INVALID_TOKEN)
        }

        val authentication = jwtTokenProvider.getAuthentication(refreshToken)
        val email = authentication.name

        logger.debug("Refreshing access token for user: {}", email)

        val user = userRepository.findByEmail(email)
            ?: throw BusinessException(ErrorCode.USER_NOT_FOUND)

        if (!user.isActive) {
            throw BusinessException(ErrorCode.AUTH_UNAUTHORIZED)
        }

        val newAccessToken = jwtTokenProvider.generateAccessToken(authentication)

        return RefreshTokenResponse(
            accessToken = newAccessToken,
            tokenType = "Bearer",
            expiresIn = 86400000L, // 24시간
        )
    }

    /**
     * 개발용 토큰 생성 (디버그 API)
     */
    @Transactional
    fun generateDevToken(email: String): LoginResponse {
        val user = userRepository.findByEmail(email)
            ?: throw BusinessException(ErrorCode.USER_NOT_FOUND)

        if (!user.isActive) {
            throw BusinessException(ErrorCode.AUTH_UNAUTHORIZED)
        }

        logger.debug("Generated dev token for user: {}", email)

        return createLoginResponse(user)
    }

    /**
     * 로그아웃 - 토큰을 블랙리스트에 추가하여 무효화
     *
     * @param accessToken 무효화할 액세스 토큰
     * @param refreshToken 무효화할 리프레시 토큰 (선택)
     */
    fun logout(accessToken: String, refreshToken: String? = null) {
        // 액세스 토큰 무효화
        jwtTokenProvider.invalidateToken(accessToken)
        logger.info("Access token invalidated for logout")

        // 리프레시 토큰도 무효화 (제공된 경우)
        refreshToken?.let {
            jwtTokenProvider.invalidateToken(it)
            logger.info("Refresh token invalidated for logout")
        }
    }

    // ===== Private Methods =====

    private fun findOrCreateUser(email: String, name: String, profileImageUrl: String?): User {
        return userRepository.findByEmail(email) ?: run {
            val newUser = User(
                email = email,
                name = name,
                password = "", // OAuth 사용자는 비밀번호 없음
                globalRole = GlobalRole.STUDENT,
                profileImageUrl = profileImageUrl,
                isActive = true,
                emailVerified = true,
                profileCompleted = false,
            )
            userRepository.save(newUser)
        }
    }

    private fun createLoginResponse(user: User): LoginResponse {
        val authorities = listOf(SimpleGrantedAuthority("ROLE_${user.globalRole.name}"))
        val authentication: Authentication = UsernamePasswordAuthenticationToken(user.email, null, authorities)

        val accessToken = jwtTokenProvider.generateAccessToken(authentication)
        val refreshToken = jwtTokenProvider.generateRefreshToken(authentication)

        return LoginResponse(
            accessToken = accessToken,
            tokenType = "Bearer",
            expiresIn = 86400000L, // 24시간
            user = UserDto.from(user),
            firstLogin = !user.profileCompleted,
            refreshToken = refreshToken,
        )
    }
}
