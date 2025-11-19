package org.castlekong.backend.service

import org.castlekong.backend.dto.CreateGroupRequest
import org.castlekong.backend.dto.GroupResponse
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupMember
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional
class GroupInitializationService(
    private val groupService: GroupService,
    private val groupRepository: GroupRepository,
    private val groupRoleRepository: GroupRoleRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val groupRoleInitializationService: GroupRoleInitializationService,
    private val channelInitializationService: ChannelInitializationService,
    private val groupMapper: GroupMapper,
) {
    fun createGroupWithDefaults(
        request: CreateGroupRequest,
        ownerId: Long,
    ): GroupResponse {
        // 1. 그룹 엔티티 생성 (순수 CRUD)
        val response = groupService.createGroup(request, ownerId)

        // 2. 엔티티 재조회 (기본 역할 및 채널 생성을 위해)
        val savedGroup =
            groupRepository.findById(response.id)
                .orElseThrow { BusinessException(ErrorCode.GROUP_NOT_FOUND) }

        // 3. 기본 역할 생성 및 소유자 추가
        val (ownerRole, advisorRole, memberRole) = createDefaultRolesAndAddOwner(savedGroup, savedGroup.owner)

        // 4. 기본 채널 생성 및 권한 바인딩 설정
        channelInitializationService.createDefaultChannels(savedGroup, ownerRole, advisorRole, memberRole)

        // 5. 기본 채널 생성 완료 플래그 설정
        savedGroup.defaultChannelsCreated = true

        return groupMapper.toGroupResponse(savedGroup)
    }

    fun createDefaultRolesAndAddOwner(
        group: Group,
        owner: User,
    ): Triple<GroupRole, GroupRole, GroupRole> {
        // Use GroupRoleInitializationService to create default roles
        val roles = groupRoleInitializationService.ensureDefaultRoles(group)
        val ownerRole = roles.find { it.name == "그룹장" }!!
        val advisorRole = roles.find { it.name == "교수" }!!
        val memberRole = roles.find { it.name == "멤버" }!!

        // 그룹 생성자를 그룹장으로 추가
        val groupMember =
            GroupMember(
                group = group,
                user = owner,
                role = ownerRole,
                joinedAt = LocalDateTime.now(),
            )
        groupMemberRepository.save(groupMember)

        return Triple(ownerRole, advisorRole, memberRole)
    }

    fun ensureDefaultChannelsIfNeeded(group: Group) {
        if (group.deletedAt != null) return
        if (group.defaultChannelsCreated) return

        val ownerRole =
            groupRoleRepository.findByGroupIdAndName(group.id, "그룹장")
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }
        val advisorRole = groupRoleRepository.findByGroupIdAndName(group.id, "교수").orElse(null)
        val memberRole =
            groupRoleRepository.findByGroupIdAndName(group.id, "멤버")
                .orElseThrow { BusinessException(ErrorCode.GROUP_ROLE_NOT_FOUND) }

        val wasCreated =
            channelInitializationService.ensureDefaultChannelsExist(group, ownerRole, advisorRole, memberRole)

        if (wasCreated) {
            // 필드 직접 수정 (중복 저장 제거)
            group.defaultChannelsCreated = true
        }
    }
}
