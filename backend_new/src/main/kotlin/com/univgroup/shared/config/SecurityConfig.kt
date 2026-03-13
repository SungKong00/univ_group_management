package com.univgroup.shared.config

import com.univgroup.shared.security.JwtAuthenticationFilter
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.http.HttpMethod
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.CorsConfigurationSource
import org.springframework.web.cors.UrlBasedCorsConfigurationSource

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
class SecurityConfig(
    private val jwtAuthenticationFilter: JwtAuthenticationFilter,
    @org.springframework.beans.factory.annotation.Value("\${app.cors.allowed-origins:http://localhost:*,http://127.0.0.1:*}")
    private val allowedOrigins: String = "http://localhost:*,http://127.0.0.1:*",
) {
    @Bean
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
        return http
            .csrf { it.disable() }
            .cors { }
            .sessionManagement {
                it.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            }
            .authorizeHttpRequests { auth ->
                auth
                    // 인증 관련 엔드포인트
                    .requestMatchers("/api/auth/**").permitAll()
                    // Swagger UI
                    .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                    // H2 Console (개발용)
                    .requestMatchers("/h2-console/**").permitAll()
                    // OPTIONS 요청 (CORS preflight)
                    .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                    // 공개 그룹 탐색 엔드포인트
                    .requestMatchers(HttpMethod.GET, "/api/groups/explore").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/groups/hierarchy").permitAll()
                    // 공개 모집 조회 엔드포인트
                    .requestMatchers(HttpMethod.GET, "/api/groups/*/recruitments").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/recruitments/public").permitAll()
                    // 공개 장소 조회 엔드포인트
                    .requestMatchers(HttpMethod.GET, "/api/places").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/places/*").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/places/*/operating-hours").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/places/*/reservations").permitAll()
                    // 나머지 요청은 인증 필요
                    .anyRequest().authenticated()
            }
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter::class.java)
            .headers { headers ->
                @Suppress("DEPRECATION")
                headers.frameOptions().sameOrigin() // H2 Console을 위한 설정
            }
            .build()
    }

    @Bean
    fun corsConfigurationSource(): CorsConfigurationSource {
        val config = CorsConfiguration()
        // 환경변수로 허용 도메인 설정 (app.cors.allowed-origins)
        // 예: http://localhost:*,http://127.0.0.1:*,https://example.com
        config.allowedOriginPatterns = allowedOrigins
            .split(",")
            .map { it.trim() }
            .filter { it.isNotBlank() }
        // 모든 기본 메서드 허용
        config.allowedMethods = listOf("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
        // 모든 헤더 허용
        config.allowedHeaders = listOf("*")
        // 노출 헤더
        config.exposedHeaders = listOf("*")
        // 인증 쿠키 사용하지 않음
        config.allowCredentials = false

        val source = UrlBasedCorsConfigurationSource()
        source.registerCorsConfiguration("/**", config)
        return source
    }
}
