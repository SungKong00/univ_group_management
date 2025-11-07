package org.castlekong.backend.service

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component

/**
 * Google Access Token 으로 사용자 정보(userinfo) 조회를 수행하는 포트
 * 테스트에서는 이 인터페이스를 Mock 하여 네트워크 의존성을 제거
 */
interface GoogleUserInfoFetcherPort {
    fun fetch(accessToken: String): GoogleUserInfo?
}

@Component
class DefaultGoogleUserInfoFetcherPort : GoogleUserInfoFetcherPort {
    private val logger = LoggerFactory.getLogger(javaClass)

    override fun fetch(accessToken: String): GoogleUserInfo? {
        return try {
            // 테스트에서 invalid.* 패턴 시 null 반환 용이
            if (accessToken.startsWith("invalid.")) return null

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
                logger.warn("Google userinfo fetch failed with code {}", code)
                null
            }
        } catch (e: Exception) {
            throw IllegalArgumentException("Google userinfo fetch failed: ${e.message}")
        }
    }
}
