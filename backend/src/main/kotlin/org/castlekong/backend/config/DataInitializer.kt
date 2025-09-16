package org.castlekong.backend.config

import org.castlekong.backend.dto.CreateGroupRequest
import org.castlekong.backend.entity.*
import org.castlekong.backend.repository.*
import org.castlekong.backend.service.GroupService
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Component
class DataInitializer(
    private val userRepository: UserRepository,
    private val groupRepository: GroupRepository,
    private val groupService: GroupService,
    private val groupRoleRepository: GroupRoleRepository,
    private val groupMemberRepository: GroupMemberRepository,
) : ApplicationRunner {
    @Transactional
    override fun run(args: ApplicationArguments?) {
        // data.sql에서 이미 castlekong1019@gmail.com 계정이 생성되므로 별도 처리 불필요
        val ownerEmail = "castlekong1019@gmail.com"
        val owner =
            userRepository.findByEmail(ownerEmail).orElseThrow {
                RuntimeException("castlekong1019@gmail.com 계정이 data.sql에서 생성되지 않았습니다.")
            }

        // groups가 비어 있을 때만 기본 학교/계열/학과 시드 생성 (data.sql과 충돌 방지)
        if (groupRepository.count() == 0L) {
            seedDefaultGroups(owner)
        }

        // data.sql에서 이미 올바른 owner_id로 설정되므로 소유권 전환 로직 불필요
        // 모든 그룹에 기본 역할만 보장
        ensureDefaultRolesForAllGroups()
    }

    private fun seedDefaultGroups(owner: User) {
        val univ = "한신대학교"
        val college = "AI/SW계열"
        val dept = "AI/SW학과"

        // Top: University
        val top =
            groupRepository.findByUniversityAndCollegeAndDepartment(univ, null, null).firstOrNull()
                ?: groupService.createGroup(
                    CreateGroupRequest(
                        name = univ,
                        description = "$univ 최상위 조직",
                        university = univ,
                        college = null,
                        department = null,
                        groupType = GroupType.UNIVERSITY,
                    ),
                    owner.id,
                ).let { groupRepository.findById(it.id).orElseThrow() }

        // Middle: College
        val mid =
            groupRepository.findByUniversityAndCollegeAndDepartment(univ, college, null).firstOrNull()
                ?: groupService.createGroup(
                    CreateGroupRequest(
                        name = college,
                        description = "$college 소속 조직",
                        parentId = top.id,
                        university = univ,
                        college = college,
                        department = null,
                        groupType = GroupType.COLLEGE,
                    ),
                    owner.id,
                ).let { groupRepository.findById(it.id).orElseThrow() }

        // Bottom: Department/Track
        groupRepository.findByUniversityAndCollegeAndDepartment(univ, college, dept).firstOrNull()
            ?: groupService.createGroup(
                CreateGroupRequest(
                    name = dept,
                    description = "$dept 학생 조직",
                    parentId = mid.id,
                    university = univ,
                    college = college,
                    department = dept,
                    groupType = GroupType.DEPARTMENT,
                ),
                owner.id,
            )
    }

    private fun ensureDefaultRoles(group: Group) {
        // OWNER
        if (!groupRoleRepository.findByGroupIdAndName(group.id, "OWNER").isPresent) {
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = "OWNER",
                    isSystemRole = true,
                    permissions = GroupPermission.entries.toSet(),
                    priority = 100,
                ),
            )
        }
        // ADVISOR
        if (!groupRoleRepository.findByGroupIdAndName(group.id, "ADVISOR").isPresent) {
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = "ADVISOR",
                    isSystemRole = true,
                    permissions = GroupPermission.entries.toSet(),
                    priority = 99,
                ),
            )
        }
        // MEMBER
        if (!groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER").isPresent) {
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = "MEMBER",
                    isSystemRole = true,
                    permissions =
                        setOf(
                            GroupPermission.CHANNEL_READ,
                            GroupPermission.POST_CREATE,
                            GroupPermission.POST_READ,
                            GroupPermission.COMMENT_CREATE,
                            GroupPermission.COMMENT_READ,
                        ),
                    priority = 1,
                ),
            )
        }
    }

    private fun ensureDefaultRolesForAllGroups() {
        val groups = groupRepository.findAll()
        groups.forEach { group ->
            ensureDefaultRoles(group)

            // 그룹 소유자를 OWNER 멤버로 추가 (아직 멤버가 아닌 경우에만)
            val ownerRole = groupRoleRepository.findByGroupIdAndName(group.id, "OWNER").orElseThrow()
            val existing = groupMemberRepository.findByGroupIdAndUserId(group.id, group.owner.id)

            if (!existing.isPresent) {
                val ownerMember =
                    GroupMember(
                        group = group,
                        user = group.owner,
                        role = ownerRole,
                        joinedAt = LocalDateTime.now(),
                    )
                groupMemberRepository.save(ownerMember)
            }
        }
    }
}
