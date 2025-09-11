package org.castlekong.backend.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.access.PermissionEvaluator
import org.springframework.security.access.expression.method.DefaultMethodSecurityExpressionHandler
import org.springframework.security.access.expression.method.MethodSecurityExpressionHandler

@Configuration
class MethodSecurityConfig(
    private val permissionEvaluator: PermissionEvaluator,
) {
    @Bean
    fun methodSecurityExpressionHandler(): MethodSecurityExpressionHandler {
        val handler = DefaultMethodSecurityExpressionHandler()
        handler.setPermissionEvaluator(permissionEvaluator)
        return handler
    }
}

