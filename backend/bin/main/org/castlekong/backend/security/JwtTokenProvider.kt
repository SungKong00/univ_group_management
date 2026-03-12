package org.castlekong.backend.security

import io.jsonwebtoken.JwtException
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.SignatureAlgorithm
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
class JwtTokenProvider {
    @Value("\${jwt.secret:defaultSecretKeyForJWTWhichIsVeryLongAndSecure}")
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
            .signWith(key, SignatureAlgorithm.HS512)
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

    fun getAuthentication(token: String): Authentication {
        val claims =
            Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .payload

        val authorities: Collection<GrantedAuthority> =
            claims["auth"].toString()
                .split(",")
                .filter { it.isNotBlank() }
                .map { SimpleGrantedAuthority(it) }

        return UsernamePasswordAuthenticationToken(claims.subject, "", authorities)
    }

    fun validateToken(token: String): Boolean {
        return try {
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
}
