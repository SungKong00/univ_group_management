package org.castlekong.backend.service

import org.castlekong.backend.dto.LoginResponse
import org.castlekong.backend.dto.RefreshTokenResponse
import org.castlekong.backend.dto.UserResponse
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.security.JwtTokenProvider
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
    private val userService: UserService,
    private val jwtTokenProvider: JwtTokenProvider,
    // 신규 포트 주입
    private val googleIdTokenVerifierPort: GoogleIdTokenVerifierPort,
    // AccessToken 사용자 정보 조회 포트 추가
    private val googleUserInfoFetcherPort: GoogleUserInfoFetcherPort,
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    fun authenticateWithGoogle(googleAuthToken: String): LoginResponse {
        val googleUser =
            googleIdTokenVerifierPort.verify(googleAuthToken)
                ?: throw BusinessException(ErrorCode.INVALID_TOKEN)
        val user = userService.findOrCreateUser(googleUser)
        if (!user.isActive) throw BusinessException(ErrorCode.UNAUTHORIZED)
        val authorities = listOf(SimpleGrantedAuthority("ROLE_${user.globalRole.name}"))
        val authentication: Authentication = UsernamePasswordAuthenticationToken(user.email, null, authorities)
        val accessToken = jwtTokenProvider.generateAccessToken(authentication)
        val refreshToken = jwtTokenProvider.generateRefreshToken(authentication)
        return LoginResponse(
            accessToken = accessToken,
            tokenType = "Bearer",
            expiresIn = 86400000L,
            user = userService.convertToUserResponse(user),
            firstLogin = !user.profileCompleted,
        )
    }

    fun authenticateWithGoogleAccessToken(accessToken: String): LoginResponse {
        val googleUser =
            googleUserInfoFetcherPort.fetch(accessToken)
                ?: throw BusinessException(ErrorCode.INVALID_TOKEN)

        val user = userService.findOrCreateUser(googleUser)
        if (!user.isActive) {
            throw BusinessException(ErrorCode.UNAUTHORIZED)
        }

        val authorities = listOf(SimpleGrantedAuthority("ROLE_${user.globalRole.name}"))
        val authentication: Authentication =
            UsernamePasswordAuthenticationToken(user.email, null, authorities)
        val accessJwt = jwtTokenProvider.generateAccessToken(authentication)
        val refreshJwt = jwtTokenProvider.generateRefreshToken(authentication)

        return LoginResponse(
            accessToken = accessJwt,
            // tokenType은 Bearer 문자열 유지
            tokenType = "Bearer",
            expiresIn = 86400000L,
            user = userService.convertToUserResponse(user),
            firstLogin = !user.profileCompleted,
        )
    }

    /**
     * JWT 토큰 검증 및 사용자 정보 반환
     * SecurityContext에서 인증된 사용자 정보를 가져옴
     */
    fun verifyToken(): UserResponse {
        val authentication =
            SecurityContextHolder.getContext().authentication
                ?: throw BusinessException(ErrorCode.UNAUTHORIZED)

        val email = authentication.name
        logger.debug("Verifying token for user: {}", email)

        val user =
            userService.findByEmail(email)
                ?: throw BusinessException(ErrorCode.USER_NOT_FOUND)

        if (!user.isActive) throw BusinessException(ErrorCode.UNAUTHORIZED)

        return userService.convertToUserResponse(user)
    }

    /**
     * 리프레시 토큰으로 새로운 액세스 토큰 발급
     * 현재는 단순 구현 (리프레시 토큰 저장소 없음)
     */
    fun refreshAccessToken(refreshToken: String): RefreshTokenResponse {
        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw BusinessException(ErrorCode.INVALID_TOKEN)
        }

        // 리프레시 토큰에서 사용자 정보 추출
        val authentication = jwtTokenProvider.getAuthentication(refreshToken)
        val email = authentication.name

        logger.debug("Refreshing access token for user: {}", email)

        // 사용자 존재 및 활성 상태 확인
        val user =
            userService.findByEmail(email)
                ?: throw BusinessException(ErrorCode.USER_NOT_FOUND)

        if (!user.isActive) throw BusinessException(ErrorCode.UNAUTHORIZED)

        // 새로운 액세스 토큰 생성
        val newAccessToken = jwtTokenProvider.generateAccessToken(authentication)

        return RefreshTokenResponse(
            accessToken = newAccessToken,
            tokenType = "Bearer",
            // 24시간
            expiresIn = 86400000L,
        )
    }

    // 임시 디버그용 메서드 - 모든 사용자의 profileCompleted를 false로 초기화
    @Transactional
    fun resetAllUsersProfileStatus(): Int {
        val users = userService.findAll()
        var updatedCount = 0

        users.forEach { user ->
            if (user.profileCompleted) {
                val updatedUser =
                    User(
                        id = user.id,
                        name = user.name,
                        email = user.email,
                        password = user.password,
                        globalRole = user.globalRole,
                        isActive = user.isActive,
                        nickname = user.nickname,
                        profileImageUrl = user.profileImageUrl,
                        bio = user.bio,
                        profileCompleted = false,
                        emailVerified = user.emailVerified,
                        college = user.college,
                        department = user.department,
                        studentNo = user.studentNo,
                        schoolEmail = user.schoolEmail,
                        professorStatus = user.professorStatus,
                        academicYear = user.academicYear,
                        createdAt = user.createdAt,
                        updatedAt = user.updatedAt,
                    )
                userService.save(updatedUser)
                updatedCount++
                logger.debug("Reset profileCompleted for user: {}", user.email)
            }
        }

        return updatedCount
    }

    // 임시 디버그용 메서드 - 이메일로 개발 토큰 생성
    @Transactional
    fun generateDevToken(email: String): LoginResponse {
        val user =
            userService.findByEmail(email)
                ?: throw BusinessException(ErrorCode.USER_NOT_FOUND)

        if (!user.isActive) {
            throw BusinessException(ErrorCode.UNAUTHORIZED)
        }

        val authorities = listOf(SimpleGrantedAuthority("ROLE_${user.globalRole.name}"))
        val authentication: Authentication =
            UsernamePasswordAuthenticationToken(user.email, null, authorities)
        val accessToken = jwtTokenProvider.generateAccessToken(authentication)
        val refreshToken = jwtTokenProvider.generateRefreshToken(authentication)

        logger.debug("Generated dev token for user: {}", email)

        return LoginResponse(
            accessToken = accessToken,
            tokenType = "Bearer",
            expiresIn = 86400000L,
            user = userService.convertToUserResponse(user),
            firstLogin = !user.profileCompleted,
        )
    }
}

data class GoogleUserInfo(
    val email: String,
    val name: String,
    val profileImageUrl: String?,
)
