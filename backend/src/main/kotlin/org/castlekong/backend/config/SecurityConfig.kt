package org.castlekong.backend.config

import org.castlekong.backend.security.JwtAuthenticationFilter
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
                    .requestMatchers("/api/auth/google").permitAll()
                    .requestMatchers("/api/auth/google/callback").permitAll()
                    .requestMatchers("/api/auth/debug/**").permitAll()
                    .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                    .requestMatchers("/h2-console/**").permitAll()
                    .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                    // 공개 그룹 탐색 엔드포인트
                    .requestMatchers(HttpMethod.GET, "/api/groups/explore").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/groups/hierarchy").permitAll()
                    // 공개 모집 조회 엔드포인트
                    .requestMatchers(HttpMethod.GET, "/api/groups/*/recruitments").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/recruitments/public").permitAll()
                    // 공개 장소 조회 엔드포인트 (인증 불필요)
                    .requestMatchers(HttpMethod.GET, "/api/places").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/places/*").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/places/*/operating-hours").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/places/*/restricted-times").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/places/*/closures").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/places/*/available-times").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/places/calendar").permitAll()
                    .requestMatchers(HttpMethod.GET, "/api/places/*/reservations").permitAll()
                    // 장소 예약 생성/수정/삭제는 인증 필요
                    .anyRequest().authenticated()
            }
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter::class.java)
            .headers { headers ->
                headers.frameOptions().sameOrigin() // H2 Console을 위한 설정
            }
            .build()
    }

    @Bean
    fun corsConfigurationSource(): CorsConfigurationSource {
        val config = CorsConfiguration()
        // 개발 편의를 위해 패턴으로 허용 (localhost의 다양한 포트 허용)
        config.allowedOriginPatterns =
            listOf(
                "http://localhost:*",
                "http://127.0.0.1:*",
            )
        // 모든 기본 메서드 허용 (개발용)
        config.allowedMethods = listOf("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
        // 모든 헤더 허용 (개발용)
        config.allowedHeaders = listOf("*")
        // 노출 헤더도 전체 허용 (개발용)
        config.exposedHeaders = listOf("*")
        // 인증 쿠키 사용하지 않음 (단순화)
        config.allowCredentials = false

        val source = UrlBasedCorsConfigurationSource()
        source.registerCorsConfiguration("/**", config)
        return source
    }
}
