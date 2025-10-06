package org.castlekong.backend.service

import org.castlekong.backend.dto.CreateGroupRoleRequest
import org.castlekong.backend.dto.GroupRoleResponse
import org.castlekong.backend.dto.UpdateGroupRoleRequest
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class GroupRoleService(
    private val groupRepository: GroupRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val permissionService: org.castlekong.backend.security.PermissionService,
) {
    @Transactional
    fun createGroupRole(
        groupId: Long,
        request: CreateGroupRoleRequest,
        userId: Long,
    ): GroupRoleResponse {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 권한 확인 (그룹 소유자만 역할 생성 가능)
        if (group.owner.id != userId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        // 같은 이름의 역할이 이미 존재하는지 확인
        if (groupRoleRepository.findByGroupIdAndName(groupId, request.name).isPresent) {
            throw BusinessException(ErrorCode.GROUP_ROLE_NAME_ALREADY_EXISTS)
        }

        // 권한 문자열을 GroupPermission enum으로 변환
        val permissions =
            request.permissions.mapNotNull { permString ->
                try {
                    GroupPermission.valueOf(permString)
                } catch (e: IllegalArgumentException) {
                    null
                }
            }.toMutableSet()
        val groupRole =
            GroupRole(
                group = group,
                name = request.name,
                permissions = permissions,
                priority = request.priority,
            )

        val savedRole = groupRoleRepository.save(groupRole)
        permissionService.invalidateGroup(groupId)
        return toGroupRoleResponse(savedRole)
    }

    fun getGroupRoles(groupId: Long): List<GroupRoleResponse> {
        // 그룹 존재 여부 확인
        if (!groupRepository.existsById(groupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }

        return groupRoleRepository.findByGroupId(groupId)
            .map { toGroupRoleResponse(it) }
    }

    fun getGroupRole(
        groupId: Long,
        roleId: Long,
    ): GroupRoleResponse {
        val role =
            groupRoleRepository.findById(roleId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

        // 역할이 해당 그룹에 속하는지 확인
        if (role.group.id != groupId) {
            throw BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND)
        }

        return toGroupRoleResponse(role)
    }

    @Transactional
    fun updateGroupRole(
        groupId: Long,
        roleId: Long,
        request: UpdateGroupRoleRequest,
        userId: Long,
    ): GroupRoleResponse {
        val role =
            groupRoleRepository.findById(roleId).orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }
        if (role.group.id != groupId) throw BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND)
        if (role.group.owner.id != userId) throw BusinessException(ErrorCode.FORBIDDEN)
        if (role.isSystemRole) throw BusinessException(ErrorCode.SYSTEM_ROLE_IMMUTABLE)
        if (request.name != null && request.name != role.name) {
            if (groupRoleRepository.findByGroupIdAndName(groupId, request.name).isPresent) {
                throw BusinessException(ErrorCode.GROUP_ROLE_NAME_ALREADY_EXISTS)
            }
        }
        request.permissions?.let { incoming ->
            val parsed = incoming.mapNotNull { p -> runCatching { GroupPermission.valueOf(p) }.getOrNull() }
            role.replacePermissions(parsed)
        }
        role.update(name = request.name, priority = request.priority)
        val savedRole = groupRoleRepository.save(role)
        permissionService.invalidateGroup(groupId)
        return toGroupRoleResponse(savedRole)
    }

    @Transactional
    fun deleteGroupRole(
        groupId: Long,
        roleId: Long,
        userId: Long,
    ) {
        val role =
            groupRoleRepository.findById(roleId).orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }
        if (role.group.id != groupId) throw BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND)
        if (role.group.owner.id != userId) throw BusinessException(ErrorCode.FORBIDDEN)
        if (role.isSystemRole) throw BusinessException(ErrorCode.SYSTEM_ROLE_IMMUTABLE)
        groupRoleRepository.delete(role)
        permissionService.invalidateGroup(groupId)
    }

    private fun toGroupRoleResponse(groupRole: GroupRole): GroupRoleResponse {
        return GroupRoleResponse(
            id = groupRole.id,
            name = groupRole.name,
            permissions = groupRole.permissions.map { it.name }.toSet(),
            priority = groupRole.priority,
        )
    }
}
