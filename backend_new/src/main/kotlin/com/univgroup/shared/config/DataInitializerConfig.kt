package com.univgroup.shared.config

import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Profile

/**
 * 데이터 초기화 설정
 *
 * Profile별로 다른 데이터 초기화 전략 사용:
 * - dev: 개발용 최소 데이터 (DevDataRunner)
 * - demo: 데모용 풍부한 데이터 (DemoDataRunner)
 * - prod: 초기화 없음
 */
@Configuration
class DataInitializerConfig
