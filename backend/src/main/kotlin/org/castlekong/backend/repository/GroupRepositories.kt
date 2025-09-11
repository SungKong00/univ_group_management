package org.castlekong.backend.repository

import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupMember
import org.castlekong.backend.entity.GroupRole
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface GroupRepository : JpaRepository<Group, Long>

@Repository
interface GroupRoleRepository : JpaRepository<GroupRole, Long> {
    fun findByGroupIdAndName(groupId: Long, name: String): Optional<GroupRole>
}

@Repository
interface GroupMemberRepository : JpaRepository<GroupMember, Long> {
    fun findByGroupIdAndUserId(groupId: Long, userId: Long): Optional<GroupMember>
}

