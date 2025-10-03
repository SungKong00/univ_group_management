package org.castlekong.backend.service

import org.castlekong.backend.dto.*
import org.castlekong.backend.entity.*
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional(readOnly = true)
class GroupMemberService(
    private val groupRepository: GroupRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val userRepository: UserRepository,
    private val permissionService: org.castlekong.backend.security.PermissionService,
    private val groupMapper: GroupMapper,
) {
    @Transactional
    fun joinGroup(
        groupId: Long,
        userId: Long,
    ): GroupMemberResponse {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        val user =
            userRepository.findById(userId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 이미 멤버인지 확인
        if (groupMemberRepository.findByGroupIdAndUserId(groupId, userId).isPresent) {
            throw BusinessException(ErrorCode.ALREADY_GROUP_MEMBER)
        }

        // 최대 멤버 수 확인
        if (group.maxMembers != null) {
            val currentMemberCount = groupMemberRepository.countByGroupId(groupId)
            if (currentMemberCount >= group.maxMembers) {
                throw BusinessException(ErrorCode.GROUP_FULL)
            }
        }

        // 선택한 그룹에 가입
        val primaryMember = joinGroupDirect(group, user)

        // 계층구조 자동 소속: 상위 그룹들에 자동 가입
        joinParentGroupsAutomatically(group, user)

        return groupMapper.toGroupMemberResponse(primaryMember)
    }

    private fun joinGroupDirect(
        group: Group,
        user: User,
    ): GroupMember {
        // 기본 MEMBER 역할 확보 (없으면 생성)
        val memberRole =
            groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER").orElseGet {
                // OWNER / ADVISOR 기본 역할도 보장
                ensureDefaultRoles(group)
                groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER").get()
            }

        val groupMember =
            GroupMember(
                group = group,
                user = user,
                role = memberRole,
                joinedAt = LocalDateTime.now(),
            )

        return groupMemberRepository.save(groupMember)
    }

    private fun ensureDefaultRoles(group: Group) {
        if (!groupRoleRepository.findByGroupIdAndName(group.id, "OWNER").isPresent) {
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = "OWNER",
                    isSystemRole = true,
                    permissions = GroupPermission.values().toMutableSet(),
                    priority = 100,
                ),
            )
        }
        if (!groupRoleRepository.findByGroupIdAndName(group.id, "ADVISOR").isPresent) {
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = "ADVISOR",
                    isSystemRole = true,
                    permissions = GroupPermission.values().toMutableSet(),
                    priority = 99,
                ),
            )
        }
        if (!groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER").isPresent) {
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = "MEMBER",
                    isSystemRole = true,
                    permissions = mutableSetOf(),
                    priority = 1,
                ),
            )
        }
    }

    private fun joinParentGroupsAutomatically(
        currentGroup: Group,
        user: User,
    ) {
        // 모든 상위 그룹 ID를 한 번에 조회 (배치 최적화)
        val parentGroupIds = groupMemberRepository.findParentGroupIds(currentGroup.id)

        if (parentGroupIds.isNotEmpty()) {
            // 이미 가입된 그룹들을 한 번에 확인
            val existingMemberships = groupMemberRepository.findExistingMemberships(user.id, parentGroupIds)
            val notJoinedGroupIds = parentGroupIds - existingMemberships.toSet()

            if (notJoinedGroupIds.isNotEmpty()) {
                // 배치로 한 번에 가입 처리
                joinGroupsBatch(notJoinedGroupIds, user)
            }
        }
    }

    @Transactional
    fun joinGroupsBatch(
        groupIds: List<Long>,
        user: User,
    ) {
        // 배치 크기로 청크 단위 처리
        val batchSize = 50
        groupIds.chunked(batchSize).forEach { chunk ->
            val groups = groupRepository.findAllById(chunk)
            val members = mutableListOf<GroupMember>()

            groups.forEach { group ->
                // 기본 MEMBER 역할 확보
                val memberRole = ensureMemberRole(group)
                members.add(
                    GroupMember(
                        group = group,
                        user = user,
                        role = memberRole,
                        joinedAt = LocalDateTime.now(),
                    ),
                )
            }

            // 배치로 한 번에 저장
            if (members.isNotEmpty()) {
                groupMemberRepository.saveAll(members)
            }
        }
    }

    private fun ensureMemberRole(group: Group): GroupRole {
        return groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER").orElseGet {
            ensureDefaultRoles(group)
            groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER").get()
        }
    }

    @Transactional
    fun leaveGroup(
        groupId: Long,
        userId: Long,
    ) {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 그룹 소유자는 탈퇴할 수 없음
        if (group.owner.id == userId) {
            throw BusinessException(ErrorCode.GROUP_OWNER_CANNOT_LEAVE)
        }

        val groupMember =
            groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        // 현재 그룹에서 탈퇴
        groupMemberRepository.delete(groupMember)
        // Invalidate permission cache for that member in this group
        permissionService.invalidate(groupId, userId)

        // 계층구조 연쇄 탈퇴: 하위 그룹에서 자동 탈퇴
        leaveChildGroupsAutomatically(group, userId)

        // 상위 그룹에서 연쇄 탈퇴 검토 (해당 사용자가 다른 하위 그룹에 속하지 않은 경우)
        leaveParentGroupsIfNoOtherMembership(group, userId)
    }

    private fun leaveChildGroupsAutomatically(
        currentGroup: Group,
        userId: Long,
    ) {
        // 현재 그룹의 모든 하위 그룹에서 탈퇴 (배치 최적화)
        val allDescendantIds = groupRepository.findAllDescendantIds(currentGroup.id)

        if (allDescendantIds.isNotEmpty()) {
            leaveGroupsBatch(allDescendantIds, userId)
        }
    }

    @Transactional
    fun leaveGroupsBatch(
        groupIds: List<Long>,
        userId: Long,
    ) {
        // 배치 크기로 청크 단위 처리
        val batchSize = 50
        groupIds.chunked(batchSize).forEach { chunk ->
            // 해당 그룹들에서 사용자의 멤버십을 한 번에 조회
            val membersToDelete = mutableListOf<GroupMember>()

            chunk.forEach { groupId ->
                val member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                if (member.isPresent) {
                    membersToDelete.add(member.get())
                }
            }

            // 배치로 삭제
            if (membersToDelete.isNotEmpty()) {
                groupMemberRepository.deleteAll(membersToDelete)

                // 권한 캐시 배치 무효화
                chunk.forEach { groupId ->
                    permissionService.invalidate(groupId, userId)
                }
            }
        }
    }

    private fun leaveParentGroupsIfNoOtherMembership(
        currentGroup: Group,
        userId: Long,
    ) {
        var parentGroup = currentGroup.parent
        while (parentGroup != null) {
            // 해당 사용자가 이 상위 그룹의 다른 하위 그룹에 속하는지 확인
            val siblingGroups = groupRepository.findByParentId(parentGroup.id)
            val hasOtherMembership =
                siblingGroups.any { siblingGroup ->
                    siblingGroup.id != currentGroup.id &&
                        groupMemberRepository.findByGroupIdAndUserId(siblingGroup.id, userId).isPresent
                }

            if (!hasOtherMembership) {
                // 다른 하위 그룹에 속하지 않으므로 상위 그룹에서도 탈퇴
                val parentMember = groupMemberRepository.findByGroupIdAndUserId(parentGroup.id, userId)
                if (parentMember.isPresent) {
                    groupMemberRepository.delete(parentMember.get())
                    permissionService.invalidate(parentGroup.id, userId)
                }
                parentGroup = parentGroup.parent
            } else {
                // 다른 하위 그룹에 속하므로 상위 그룹에는 유지
                break
            }
        }
    }

    fun getGroupMembers(
        groupId: Long,
        pageable: Pageable,
    ): Page<GroupMemberResponse> {
        // 그룹 존재 여부 확인
        if (!groupRepository.existsById(groupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }

        return groupMemberRepository.findByGroupId(groupId, pageable)
            .map { groupMapper.toGroupMemberResponse(it) }
    }

    fun getMyMembership(
        groupId: Long,
        userId: Long,
    ): GroupMemberResponse {
        groupRepository.findById(groupId)
            .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }
        val existing = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
        if (existing.isPresent) return groupMapper.toGroupMemberResponse(existing.get())
        throw BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND)
    }

    @Transactional
    fun removeMember(
        groupId: Long,
        targetUserId: Long,
        requesterId: Long,
    ) {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 그룹장만 멤버 추방 가능 (간소 정책)
        if (group.owner.id != requesterId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        // 그룹장 본인은 삭제 불가
        if (group.owner.id == targetUserId) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        val groupMember =
            groupMemberRepository.findByGroupIdAndUserId(groupId, targetUserId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        groupMemberRepository.delete(groupMember)
        permissionService.invalidate(groupId, targetUserId)
    }

    @Transactional
    fun updateMemberRole(
        groupId: Long,
        targetUserId: Long,
        roleId: Long,
        requesterId: Long,
    ): GroupMemberResponse {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 그룹장만 역할 변경 가능 (간소 정책)
        if (group.owner.id != requesterId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        val groupMember =
            groupMemberRepository.findByGroupIdAndUserId(groupId, targetUserId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        val newRole =
            groupRoleRepository.findById(roleId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

        // 역할은 동일 그룹 소속이어야 함
        if (newRole.group.id != groupId) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        // OWNER 역할 변경은 위임 API 사용
        if (newRole.name == "OWNER") {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        val updated = groupMember.copy(role = newRole)
        val saved = groupMemberRepository.save(updated)
        permissionService.invalidate(groupId, targetUserId)
        return groupMapper.toGroupMemberResponse(saved)
    }

    // === 지도교수 관리 ===

    @Transactional
    fun assignProfessor(
        groupId: Long,
        professorUserId: Long,
        ownerUserId: Long,
    ): GroupMemberResponse {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 그룹장만 지도교수 지정 가능
        if (group.owner.id != ownerUserId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        val professor =
            userRepository.findById(professorUserId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        // 지정할 사용자가 실제 교수인지 확인
        if (professor.globalRole != GlobalRole.PROFESSOR) {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        val professorRole =
            groupRoleRepository.findByGroupIdAndName(groupId, "ADVISOR")
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

        // 이미 그룹 멤버인지 확인
        val existingMember = groupMemberRepository.findByGroupIdAndUserId(groupId, professorUserId)

        if (existingMember.isPresent) {
            // 이미 멤버라면 역할을 지도교수로 변경
            val updated = existingMember.get().copy(role = professorRole)
            val saved = groupMemberRepository.save(updated)
            permissionService.invalidate(groupId, professorUserId)
            return groupMapper.toGroupMemberResponse(saved)
        } else {
            // 새로 지도교수로 추가
            val groupMember =
                GroupMember(
                    group = group,
                    user = professor,
                    role = professorRole,
                    joinedAt = LocalDateTime.now(),
                )
            val saved = groupMemberRepository.save(groupMember)
            permissionService.invalidate(groupId, professorUserId)
            return groupMapper.toGroupMemberResponse(saved)
        }
    }

    @Transactional
    fun removeProfessor(
        groupId: Long,
        professorUserId: Long,
        ownerUserId: Long,
    ) {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 그룹장만 지도교수 해제 가능
        if (group.owner.id != ownerUserId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        val groupMember =
            groupMemberRepository.findByGroupIdAndUserId(groupId, professorUserId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        // 지도교수 역할인지 확인
        if (groupMember.role.name != "ADVISOR") {
            throw BusinessException(ErrorCode.INVALID_REQUEST)
        }

        // 일반 멤버로 역할 변경 (완전 제거하지 않음)
        val memberRole =
            groupRoleRepository.findByGroupIdAndName(groupId, "MEMBER")
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

        val updated = groupMember.copy(role = memberRole)
        groupMemberRepository.save(updated)
        permissionService.invalidate(groupId, professorUserId)
    }

    fun getProfessors(groupId: Long): List<GroupMemberResponse> {
        if (!groupRepository.existsById(groupId)) {
            throw BusinessException(ErrorCode.GROUP_NOT_FOUND)
        }

        return groupMemberRepository.findAdvisorsByGroupId(groupId)
            .map { groupMapper.toGroupMemberResponse(it) }
    }

    // === 그룹장 권한 위임 및 유고 상황 처리 ===

    @Transactional
    fun transferOwnership(
        groupId: Long,
        newOwnerId: Long,
        currentOwnerId: Long,
    ): GroupMemberResponse {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 현재 그룹장만 권한 위임 가능
        if (group.owner.id != currentOwnerId) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }

        val newOwner =
            userRepository.findById(newOwnerId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        val newOwnerMember =
            groupMemberRepository.findByGroupIdAndUserId(groupId, newOwnerId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }

        val ownerRole =
            groupRoleRepository.findByGroupIdAndName(groupId, "OWNER")
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

        val memberRole =
            groupRoleRepository.findByGroupIdAndName(groupId, "MEMBER")
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

        // Group 엔티티의 owner 변경
        val updatedGroup = group.copy(owner = newOwner, updatedAt = LocalDateTime.now())
        groupRepository.save(updatedGroup)

        // 이전 그룹장을 일반 멤버로 강등
        val currentOwnerMember =
            groupMemberRepository.findByGroupIdAndUserId(groupId, currentOwnerId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_MEMBER_NOT_FOUND) }
        val demotedOwner = currentOwnerMember.copy(role = memberRole)
        groupMemberRepository.save(demotedOwner)

        // 새 그룹장을 OWNER 역할로 승급
        val promotedMember = newOwnerMember.copy(role = ownerRole)
        val savedMember = groupMemberRepository.save(promotedMember)

        // 권한 캐시 무효화
        permissionService.invalidate(groupId, currentOwnerId)
        permissionService.invalidate(groupId, newOwnerId)

        return groupMapper.toGroupMemberResponse(savedMember)
    }

    @Transactional
    fun handleOwnerAbsence(groupId: Long): GroupMemberResponse? {
        val group =
            groupRepository.findById(groupId)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 승계 후보자 조회 (학년 높은 순, 가입일 오래된 순)
        val candidates = groupMemberRepository.findSuccessionCandidates(groupId)

        if (candidates.isEmpty()) {
            // 승계할 멤버가 없으면 null 반환 (그룹 삭제 검토 필요)
            return null
        }

        val successor = candidates.first()
        val ownerRole =
            groupRoleRepository.findByGroupIdAndName(groupId, "OWNER")
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

        // Group 엔티티의 owner 변경
        val updatedGroup = group.copy(owner = successor.user, updatedAt = LocalDateTime.now())
        groupRepository.save(updatedGroup)

        // 승계자를 OWNER 역할로 변경
        val updatedMember = successor.copy(role = ownerRole)
        val savedMember = groupMemberRepository.save(updatedMember)

        permissionService.invalidate(groupId, successor.user.id)

        return groupMapper.toGroupMemberResponse(savedMember)
    }

    // === 권한 조회 (MVP 단순화) ===

    // === 나의 유효 권한 조회 ===
    fun getMyEffectivePermissions(
        groupId: Long,
        userId: Long,
    ): Set<String> {
        val effective = permissionService.getEffective(groupId, userId, ::systemRolePermissions)
        return effective.map { it.name }.toSet()
    }

    private fun systemRolePermissions(roleName: String): Set<GroupPermission> =
        when (roleName.uppercase()) {
            "OWNER" -> GroupPermission.entries.toSet()
            "ADVISOR" -> GroupPermission.entries.toSet() // MVP에서는 OWNER와 동일
            "MEMBER" -> emptySet() // 멤버는 기본적으로 워크스페이스 접근 가능, 별도 권한 불필요
            else -> emptySet()
        }

    // === 내 그룹 목록 조회 (워크스페이스 자동 진입용) ===

    fun getMyGroups(userId: Long): List<MyGroupResponse> {
        val memberships = groupMemberRepository.findByUserIdWithDetails(userId)

        return memberships.map { membership ->
            val group = membership.group
            val level = calculateGroupLevel(group)

            MyGroupResponse(
                id = group.id,
                name = group.name,
                type = group.groupType,
                level = level,
                parentId = group.parent?.id,
                role = membership.role.name,
                permissions = membership.role.permissions.map { it.name }.toSet(),
                profileImageUrl = group.profileImageUrl,
                visibility = group.visibility
            )
        }.sortedWith(compareBy({ it.level }, { it.id }))
    }

    private fun calculateGroupLevel(group: Group): Int {
        var level = 0
        var current: Group? = group
        while (current?.parent != null) {
            level++
            current = current.parent
        }
        return level
    }
}
