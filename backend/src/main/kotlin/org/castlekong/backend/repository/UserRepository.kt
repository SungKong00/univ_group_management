package org.castlekong.backend.repository

import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.entity.User
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface UserRepository : JpaRepository<User, Long> {
    fun findByEmail(email: String): Optional<User>

    fun existsByEmail(email: String): Boolean

    fun existsByNicknameIgnoreCase(nickname: String): Boolean

    @Query(
        """
        SELECT u FROM User u
        WHERE (:role IS NULL OR u.globalRole = :role)
        AND (
            LOWER(u.name) LIKE LOWER(CONCAT('%', :q, '%')) OR
            LOWER(u.email) LIKE LOWER(CONCAT('%', :q, '%')) OR
            LOWER(COALESCE(u.nickname, '')) LIKE LOWER(CONCAT('%', :q, '%'))
        )
    """,
    )
    fun searchUsers(
        @Param("q") q: String,
        @Param("role") role: GlobalRole?,
    ): List<User>
}
