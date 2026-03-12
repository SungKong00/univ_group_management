package com.univgroup.domain.group.service

import com.univgroup.domain.group.entity.Group
import com.univgroup.domain.group.entity.GroupRole
import com.univgroup.domain.group.repository.GroupMemberRepository
import com.univgroup.domain.group.repository.GroupRoleRepository
import com.univgroup.domain.permission.GroupPermission
import com.univgroup.domain.permission.SystemRole
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.ResourceNotFoundException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * 그룹 역할 서비스 구현체
 *
 * 그룹 내 역할 관리 비즈니스 로직을 담당한다.
 */
@Service
@Transactional(readOnly = true)
class GroupRoleService(
    private val groupRoleRepository: GroupRoleRepository,
    private val groupMemberRepository: GroupMemberRepository,
) : IGroupRoleService {
    // ========== IGroupRoleService 구현 ==========

    override fun getRoleIds(groupId: Long): List<Long> {
        return groupRoleRepository.findByGroupId(groupId)
            .mapNotNull { it.id }
    }

    override fun isSystemRole(roleId: Long): Boolean {
        val role = groupRoleRepository.findById(roleId).orElse(null)
        return role?.isSystemRole ?: false
    }

    // ========== 역할 조회 ==========

    /**
     * 역할 조회
     */
    fun findById(roleId: Long): GroupRole? {
        return groupRoleRepository.findById(roleId).orElse(null)
    }

    /**
     * 역할 조회 (없으면 예외)
     */
    fun getById(roleId: Long): GroupRole {
        return groupRoleRepository.findById(roleId).orElseThrow {
            ResourceNotFoundException(
                ErrorCode.GROUP_ROLE_NOT_FOUND,
                "역할을 찾을 수 없습니다: $roleId",
            )
        }
    }

    /**
     * 그룹의 모든 역할 조회 (우선순위 순)
     */
    fun getRoles(groupId: Long): List<GroupRole> {
        return groupRoleRepository.findByGroupIdOrderByPriorityDesc(groupId)
    }

    /**
     * 그룹의 시스템 역할 조회
     */
    fun getSystemRoles(groupId: Long): List<GroupRole> {
        return groupRoleRepository.findByGroupIdAndIsSystemRole(groupId, true)
    }

    /**
     * 그룹의 커스텀 역할 조회
     */
    fun getCustomRoles(groupId: Long): List<GroupRole> {
        return groupRoleRepository.findByGroupIdAndIsSystemRole(groupId, false)
    }

    /**
     * 이름으로 역할 조회
     */
    fun findByName(
        groupId: Long,
        name: String,
    ): GroupRole? {
        return groupRoleRepository.findByGroupIdAndName(groupId, name)
    }

    /**
     * 시스템 역할 조회 (이름으로)
     */
    fun getSystemRole(
        groupId: Long,
        systemRole: SystemRole,
    ): GroupRole? {
        return groupRoleRepository.findSystemRoleByGroupIdAndName(groupId, systemRole.name)
    }

    // ========== 역할 생성 ==========

    /**
     * 그룹 생성 시 기본 시스템 역할 생성
     *
     * 그룹장(OWNER), 교수(PROFESSOR), 멤버(MEMBER) 역할을 생성한다.
     */
    @Transactional
    fun createDefaultRoles(group: Group): List<GroupRole> {
        val roles = mutableListOf<GroupRole>()

        // 그룹장 역할
        roles.add(
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = SystemRole.OWNER.name,
                    description = "그룹장 - 모든 권한 보유",
                    isSystemRole = true,
                    priority = SystemRole.OWNER.priority,
                    permissions = GroupPermission.entries.toMutableSet(),
                ),
            ),
        )

        // 교수 역할
        roles.add(
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = SystemRole.PROFESSOR.name,
                    description = "교수 - 관리 권한 보유",
                    isSystemRole = true,
                    priority = SystemRole.PROFESSOR.priority,
                    permissions =
                        mutableSetOf(
                            GroupPermission.GROUP_MANAGE,
                            GroupPermission.ADMIN_MANAGE,
                            GroupPermission.MEMBER_MANAGE,
                            GroupPermission.MEMBER_KICK,
                            GroupPermission.ROLE_MANAGE,
                            GroupPermission.CHANNEL_MANAGE,
                            GroupPermission.POST_MANAGE,
                            GroupPermission.RECRUITMENT_MANAGE,
                            GroupPermission.CALENDAR_MANAGE,
                        ),
                ),
            ),
        )

        // 멤버 역할
        roles.add(
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = SystemRole.MEMBER.name,
                    description = "일반 멤버",
                    isSystemRole = true,
                    priority = SystemRole.MEMBER.priority,
                    permissions = mutableSetOf(),
                ),
            ),
        )

        return roles
    }

    /**
     * 커스텀 역할 생성
     *
     * @param groupId 그룹 ID
     * @param name 역할 이름
     * @param description 설명
     * @param priority 우선순위
     * @param permissions 권한 집합
     * @return 생성된 역할
     */
    @Transactional
    fun createCustomRole(
        groupId: Long,
        name: String,
        description: String? = null,
        priority: Int = 50,
        permissions: Set<GroupPermission> = emptySet(),
    ): GroupRole {
        // 중복 이름 체크
        if (groupRoleRepository.existsByGroupIdAndName(groupId, name)) {
            throw IllegalArgumentException("이미 존재하는 역할 이름입니다: $name")
        }

        // 시스템 역할 이름 사용 금지
        if (SystemRole.entries.any { it.name == name }) {
            throw IllegalArgumentException("시스템 역할 이름은 사용할 수 없습니다: $name")
        }

        val group =
            Group::class.java.getDeclaredConstructor().newInstance().apply {
                // Proxy를 위한 임시 그룹 참조 (실제로는 groupId만 필요)
            }

        return groupRoleRepository.save(
            GroupRole(
                group = group,
                name = name,
                description = description,
                isSystemRole = false,
                priority = priority,
                permissions = permissions.toMutableSet(),
            ),
        )
    }

    // ========== 역할 수정 ==========

    /**
     * 역할 정보 수정
     *
     * 시스템 역할은 수정 불가
     */
    @Transactional
    fun updateRole(
        roleId: Long,
        name: String? = null,
        description: String? = null,
        priority: Int? = null,
        permissions: Set<GroupPermission>? = null,
    ): GroupRole {
        val role = getById(roleId)

        if (role.isSystemRole) {
            throw IllegalStateException("시스템 역할은 수정할 수 없습니다")
        }

        name?.let {
            if (groupRoleRepository.existsByGroupIdAndName(role.group.id!!, it) && it != role.name) {
                throw IllegalArgumentException("이미 존재하는 역할 이름입니다: $it")
            }
            role.name = it
        }

        description?.let { role.description = it }
        priority?.let { role.priority = it }
        permissions?.let { role.permissions = it.toMutableSet() }

        return groupRoleRepository.save(role)
    }

    // ========== 역할 삭제 ==========

    /**
     * 역할 삭제
     *
     * 시스템 역할은 삭제 불가
     * 해당 역할의 멤버가 있으면 삭제 불가
     */
    @Transactional
    fun deleteRole(roleId: Long) {
        val role = getById(roleId)

        if (role.isSystemRole) {
            throw IllegalStateException("시스템 역할은 삭제할 수 없습니다")
        }

        // 해당 역할을 가진 멤버 확인
        val membersWithRole = groupMemberRepository.findByGroupIdAndRoleId(role.group.id!!, roleId)
        if (membersWithRole.isNotEmpty()) {
            throw IllegalStateException("해당 역할을 가진 멤버가 ${membersWithRole.size}명 있습니다. 먼저 역할을 변경해주세요.")
        }

        groupRoleRepository.delete(role)
    }

    /**
     * 그룹의 모든 역할 삭제 (그룹 삭제 시)
     */
    @Transactional
    fun deleteAllRoles(groupId: Long) {
        groupRoleRepository.deleteAllByGroupId(groupId)
    }
}
