package org.castlekong.backend.util

import io.jsonwebtoken.Jwts
import io.jsonwebtoken.SignatureAlgorithm
import io.jsonwebtoken.security.Keys
import java.util.Date

/**
 * JWT 테스트 토큰 생성 유틸리티
 *
 * Usage: Run this main function to generate a test JWT token
 */
object JwtTestTokenGenerator {
    private const val SECRET_KEY = "defaultSecretKeyForJWTWhichIsVeryLongAndSecure"
    private const val EXPIRATION_MS = 86400000L // 24 hours

    @JvmStatic
    fun main(args: Array<String>) {
        val email = if (args.isNotEmpty()) args[0] else "castlekong1019@gmail.com"
        val token = generateToken(email)

        println("=".repeat(80))
        println("JWT Test Token Generated")
        println("=".repeat(80))
        println("Email: $email")
        println("Expiration: ${EXPIRATION_MS / 1000 / 60 / 60} hours")
        println()
        println("Token:")
        println(token)
        println()
        println("Usage:")
        println("curl -H \"Authorization: Bearer $token\" http://localhost:8080/api/places")
        println("=".repeat(80))
    }

    fun generateToken(email: String): String {
        val now = Date()
        val expiryDate = Date(now.time + EXPIRATION_MS)
        val key = Keys.hmacShaKeyFor(SECRET_KEY.toByteArray())

        return Jwts.builder()
            .subject(email)
            .claim("auth", "ROLE_USER")
            .issuedAt(now)
            .expiration(expiryDate)
            .signWith(key, SignatureAlgorithm.HS512)
            .compact()
    }
}
