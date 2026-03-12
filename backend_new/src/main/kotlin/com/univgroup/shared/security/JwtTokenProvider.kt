package com.univgroup.shared.security

import io.jsonwebtoken.JwtException
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import jakarta.annotation.PostConstruct
import org.springframework.beans.factory.annotation.Value
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.Authentication
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.stereotype.Component
import java.util.Date
import javax.crypto.SecretKey

@Component
class JwtTokenProvider(
    private val tokenBlacklist: TokenBlacklist,
) {
    @Value("\${jwt.secret:defaultSecretKeyForJWTWhichIsVeryLongAndSecureEnoughForHS512Algorithm64Bytes!}")
    private lateinit var secretKey: String

    @Value("\${jwt.expiration:86400000}")
    private val accessTokenExpiration: Long = 86400000L // 24시간

    @Value("\${jwt.refresh-expiration:604800000}")
    private val refreshTokenExpiration: Long = 604800000L // 7일

    private lateinit var key: SecretKey

    @PostConstruct
    private fun init() {
        val keyBytes = secretKey.toByteArray()
        this.key = Keys.hmacShaKeyFor(keyBytes)
    }

    fun generateAccessToken(authentication: Authentication): String {
        return generateToken(authentication, accessTokenExpiration)
    }

    fun generateRefreshToken(authentication: Authentication): String {
        return generateToken(authentication, refreshTokenExpiration)
    }

    fun generateAccessToken(userId: Long, email: String, authorities: List<String> = emptyList()): String {
        val now = Date()
        val expiryDate = Date(now.time + accessTokenExpiration)

        return Jwts.builder()
            .subject(email)
            .claim("userId", userId)
            .claim("auth", authorities.joinToString(","))
            .issuedAt(now)
            .expiration(expiryDate)
            .signWith(key, Jwts.SIG.HS512)
            .compact()
    }

    fun generateRefreshToken(userId: Long, email: String): String {
        val now = Date()
        val expiryDate = Date(now.time + refreshTokenExpiration)

        return Jwts.builder()
            .subject(email)
            .claim("userId", userId)
            .issuedAt(now)
            .expiration(expiryDate)
            .signWith(key, Jwts.SIG.HS512)
            .compact()
    }

    private fun generateToken(
        authentication: Authentication,
        expiration: Long,
    ): String {
        val now = Date()
        val expiryDate = Date(now.time + expiration)

        val authorities = authentication.authorities.joinToString(",") { it.authority }

        return Jwts.builder()
            .subject(authentication.name)
            .claim("auth", authorities)
            .issuedAt(now)
            .expiration(expiryDate)
            .signWith(key, Jwts.SIG.HS512)
            .compact()
    }

    fun getUsernameFromToken(token: String): String {
        val claims =
            Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .payload

        return claims.subject
    }

    fun getUserIdFromToken(token: String): Long? {
        return try {
            val claims =
                Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .payload

            claims["userId"]?.toString()?.toLongOrNull()
        } catch (e: Exception) {
            null
        }
    }

    fun getAuthentication(token: String): Authentication {
        val claims =
            Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .payload

        val authorities: Collection<GrantedAuthority> =
            claims["auth"]?.toString()
                ?.split(",")
                ?.filter { it.isNotBlank() }
                ?.map { SimpleGrantedAuthority(it) }
                ?: emptyList()

        return UsernamePasswordAuthenticationToken(claims.subject, "", authorities)
    }

    fun validateToken(token: String): Boolean {
        return try {
            // 블랙리스트 체크
            if (tokenBlacklist.isBlacklisted(token)) {
                return false
            }

            Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
            true
        } catch (e: JwtException) {
            false
        } catch (e: IllegalArgumentException) {
            false
        }
    }

    /**
     * 토큰의 만료 시간 조회
     */
    fun getExpirationFromToken(token: String): java.time.Instant? {
        return try {
            val claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .payload

            claims.expiration?.toInstant()
        } catch (e: Exception) {
            null
        }
    }

    /**
     * 토큰을 블랙리스트에 추가 (로그아웃 시 사용)
     */
    fun invalidateToken(token: String) {
        val expiration = getExpirationFromToken(token)
        if (expiration != null) {
            tokenBlacklist.add(token, expiration)
        }
    }
}
