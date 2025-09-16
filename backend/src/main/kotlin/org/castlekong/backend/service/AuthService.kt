package org.castlekong.backend.service

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier
import com.google.api.client.http.javanet.NetHttpTransport
import com.google.api.client.json.gson.GsonFactory
import org.castlekong.backend.dto.LoginResponse
import org.castlekong.backend.security.JwtTokenProvider
import org.springframework.beans.factory.annotation.Value
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.Authentication
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class AuthService(
    private val userService: UserService,
    private val jwtTokenProvider: JwtTokenProvider,
    @Value("\${app.google.client-id:}") private val googleClientId: String,
) {
    fun authenticateWithGoogle(googleAuthToken: String): LoginResponse {
        // Google 토큰 검증
        val googleUser =
            verifyGoogleToken(googleAuthToken)
                ?: throw IllegalArgumentException("Invalid Google token")

        // 사용자 조회 또는 생성
        val user = userService.findOrCreateUser(googleUser)

        // 사용자가 활성 상태인지 확인
        if (!user.isActive) {
            throw IllegalArgumentException("비활성화된 사용자입니다")
        }

        // Authentication 객체 생성
        val authorities = listOf(SimpleGrantedAuthority("ROLE_${user.globalRole.name}"))
        val authentication: Authentication =
            UsernamePasswordAuthenticationToken(
                user.email,
                null,
                authorities,
            )

        // JWT 토큰 생성
        val accessToken = jwtTokenProvider.generateAccessToken(authentication)

        return LoginResponse(
            accessToken = accessToken,
            expiresIn = 86400000L, // 24시간 (밀리초)
            user = userService.convertToUserResponse(user),
            firstLogin = !user.profileCompleted,
        )
    }

    fun authenticateWithGoogleAccessToken(accessToken: String): LoginResponse {
        val googleUser =
            fetchUserInfoByAccessToken(accessToken)
                ?: throw IllegalArgumentException("Invalid Google access token")

        val user = userService.findOrCreateUser(googleUser)
        if (!user.isActive) {
            throw IllegalArgumentException("비활성화된 사용자입니다")
        }

        val authorities = listOf(SimpleGrantedAuthority("ROLE_${user.globalRole.name}"))
        val authentication: Authentication =
            UsernamePasswordAuthenticationToken(user.email, null, authorities)
        val accessJwt = jwtTokenProvider.generateAccessToken(authentication)

        return LoginResponse(
            accessToken = accessJwt,
            expiresIn = 86400000L,
            user = userService.convertToUserResponse(user),
            firstLogin = !user.profileCompleted,
        )
    }

    private fun verifyGoogleToken(token: String): GoogleUserInfo? {
        return try {
            val verifier =
                GoogleIdTokenVerifier.Builder(NetHttpTransport(), GsonFactory())
                    .setAudience(listOf(googleClientId))
                    .build()

            val idToken: GoogleIdToken? = verifier.verify(token)
            if (idToken != null) {
                val payload = idToken.payload
                GoogleUserInfo(
                    email = payload.email,
                    name = payload["name"] as String? ?: "",
                    profileImageUrl = payload["picture"] as String?,
                )
            } else {
                null
            }
        } catch (e: Exception) {
            throw IllegalArgumentException("Google token verification failed: ${e.message}")
        }
    }

    private fun fetchUserInfoByAccessToken(accessToken: String): GoogleUserInfo? {
        return try {
            val url = java.net.URL("https://www.googleapis.com/oauth2/v3/userinfo")
            val conn = url.openConnection() as java.net.HttpURLConnection
            conn.requestMethod = "GET"
            conn.setRequestProperty("Authorization", "Bearer $accessToken")
            conn.connectTimeout = 5000
            conn.readTimeout = 5000

            val code = conn.responseCode
            if (code in 200..299) {
                val body = conn.inputStream.bufferedReader().use { it.readText() }
                val mapper = jacksonObjectMapper()
                val node: JsonNode = mapper.readTree(body)
                val email = node.get("email")?.asText() ?: ""
                val name = node.get("name")?.asText() ?: ""
                val picture = node.get("picture")?.asText()
                if (email.isNotBlank()) GoogleUserInfo(email, name, picture) else null
            } else {
                null
            }
        } catch (e: Exception) {
            throw IllegalArgumentException("Google userinfo fetch failed: ${'$'}{e.message}")
        }
    }

    // 임시 디버그용 메서드 - 모든 사용자의 profileCompleted를 false로 초기화
    @Transactional
    fun resetAllUsersProfileStatus(): Int {
        val users = userService.findAll()
        var updatedCount = 0

        users.forEach { user ->
            if (user.profileCompleted) {
                val updatedUser = user.copy(profileCompleted = false)
                userService.save(updatedUser)
                updatedCount++
                println("DEBUG: Reset profileCompleted for user ${user.email}")
            }
        }

        return updatedCount
    }
}

data class GoogleUserInfo(
    val email: String,
    val name: String,
    val profileImageUrl: String?,
)
