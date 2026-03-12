package com.univgroup.shared.security

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier
import com.google.api.client.http.javanet.NetHttpTransport
import com.google.api.client.json.gson.GsonFactory
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component

/**
 * Google 사용자 정보
 */
data class GoogleUserInfo(
    val email: String,
    val name: String,
    val profileImageUrl: String?,
)

/**
 * Google ID Token 검증을 위한 포트 (전략 인터페이스)
 */
interface GoogleIdTokenVerifierPort {
    fun verify(idToken: String): GoogleUserInfo?
}

@Component
class DefaultGoogleIdTokenVerifierPort(
    @Value("\${app.google.client-id:}") private val googleClientId: String,
    @Value("\${app.google.additional-client-ids:}") private val googleAdditionalClientIds: String,
) : GoogleIdTokenVerifierPort {
    private val logger = LoggerFactory.getLogger(javaClass)

    private val allowedGoogleClientIds: List<String> by lazy {
        (googleClientId.split(',') + googleAdditionalClientIds.split(','))
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
    }

    override fun verify(idToken: String): GoogleUserInfo? {
        return try {
            // 개발용 Mock 토큰 처리
            if (idToken.startsWith("mock_google_token_for_")) {
                logger.info("Processing mock Google token for development")
                val userIdentifier = idToken.substringAfter("mock_google_token_for_")
                return when (userIdentifier) {
                    "admin" ->
                        GoogleUserInfo(
                            email = "admin@univgroup.com",
                            name = "Admin User",
                            profileImageUrl = null,
                        )
                    "testuser1" ->
                        GoogleUserInfo(
                            email = "testuser1@hs.ac.kr",
                            name = "TestUser1",
                            profileImageUrl = null,
                        )
                    "testuser2" ->
                        GoogleUserInfo(
                            email = "testuser2@hs.ac.kr",
                            name = "TestUser2",
                            profileImageUrl = null,
                        )
                    else -> null
                }
            }

            // 테스트용 invalid 토큰
            if (idToken.startsWith("invalid.")) {
                return null
            }

            if (allowedGoogleClientIds.isEmpty()) {
                logger.warn("Google OAuth client IDs are not configured. Please set app.google.client-id")
                return null
            }

            val verifier =
                GoogleIdTokenVerifier.Builder(NetHttpTransport(), GsonFactory())
                    .setAudience(allowedGoogleClientIds)
                    .build()

            val token: GoogleIdToken? = verifier.verify(idToken)
            if (token != null) {
                val payload = token.payload
                GoogleUserInfo(
                    email = payload.email,
                    name = payload["name"] as String? ?: "",
                    profileImageUrl = payload["picture"] as String?,
                )
            } else {
                logger.warn("Google token verification returned null for token")
                null
            }
        } catch (e: Exception) {
            logger.error("Google token verification failed: ${e.message}")
            null // 일관성 있게 null 반환, AuthService에서 BusinessException으로 변환
        }
    }
}
