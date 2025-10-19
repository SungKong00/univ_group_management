package org.castlekong.backend.config

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.SerializationFeature
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import com.fasterxml.jackson.module.kotlin.registerKotlinModule
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder

/**
 * Jackson 직렬화/역직렬화 설정
 *
 * 주요 설정:
 * - LocalTime, LocalDate, LocalDateTime을 ISO 8601 문자열 형식으로 변환
 * - 배열 형식([9, 0]) 대신 문자열 형식("09:00") 사용
 * - Kotlin 데이터 클래스 지원
 */
@Configuration
class JacksonConfig {

    @Bean
    fun objectMapper(): ObjectMapper {
        return Jackson2ObjectMapperBuilder()
            .modules(JavaTimeModule())
            .featuresToDisable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
            .build<ObjectMapper>()
            .registerKotlinModule()
    }
}
