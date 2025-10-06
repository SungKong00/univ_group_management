package org.castlekong.backend.service

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier
import com.google.api.client.http.javanet.NetHttpTransport
import com.google.api.client.json.gson.GsonFactory
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component

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
            if (idToken.startsWith("mock_google_token_for_")) {
                logger.info("Processing mock Google token for development")
                return GoogleUserInfo(
                    email = "castlekong1019@gmail.com",
                    name = "Castlekong",
                    profileImageUrl = null,
                )
            }
            // 테스트 / 로컬에서 임의 invalid.* 패턴이면 즉시 null
            if (idToken.startsWith("invalid.")) {
                return null
            }
            if (allowedGoogleClientIds.isEmpty()) {
                throw IllegalStateException("Google OAuth client IDs are not configured. Please set app.google.client-id")
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
                null
            }
        } catch (e: Exception) {
            throw IllegalArgumentException("Google token verification failed: ${e.message}")
        }
    }
}
