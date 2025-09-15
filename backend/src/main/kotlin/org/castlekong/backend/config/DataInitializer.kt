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
        // Ensure dev owner user exists
        val ownerEmail = "castlekong1019@gmail.com"
        val owner = userRepository.findByEmail(ownerEmail).orElseGet {
            val user = User(
                name = "Castlekong",
                email = ownerEmail,
                password = "",
                globalRole = GlobalRole.STUDENT,
                profileCompleted = true,
                nickname = "castlekong",
                department = "AI/SW계열",
                studentNo = "20250001",
                emailVerified = true,
            )
            userRepository.save(user)
        }

        // groups가 비어 있을 때만 기본 학교/계열/학과 시드 생성 (data.sql과 충돌 방지)
        if (groupRepository.count() == 0L) {
            seedDefaultGroups(owner)
        }

        // 개발 편의: 지정 계정을 모든 그룹의 그룹장으로 설정
        assignAsOwnerForAllGroups(owner)
    }

    private fun seedDefaultGroups(owner: User) {
        val univ = "한신대학교"
        val college = "AI/SW계열"
        val dept = "AI/SW학과"

        // Top: University
        val top = groupRepository.findByUniversityAndCollegeAndDepartment(univ, null, null).firstOrNull()
            ?: groupService.createGroup(
                CreateGroupRequest(
                    name = univ,
                    description = "$univ 최상위 조직",
                    university = univ,
                    college = null,
                    department = null,
                    groupType = GroupType.UNIVERSITY,
                ),
                owner.id
            ).let { groupRepository.findById(it.id).orElseThrow() }

        // Middle: College
        val mid = groupRepository.findByUniversityAndCollegeAndDepartment(univ, college, null).firstOrNull()
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
                owner.id
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
                owner.id
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
                    priority = 100
                )
            )
        }
        // PROFESSOR
        if (!groupRoleRepository.findByGroupIdAndName(group.id, "PROFESSOR").isPresent) {
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = "PROFESSOR",
                    isSystemRole = true,
                    permissions = GroupPermission.entries.toSet(),
                    priority = 99
                )
            )
        }
        // MEMBER
        if (!groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER").isPresent) {
            groupRoleRepository.save(
                GroupRole(
                    group = group,
                    name = "MEMBER",
                    isSystemRole = true,
                    permissions = setOf(
                        GroupPermission.CHANNEL_READ,
                        GroupPermission.POST_CREATE,
                        GroupPermission.POST_READ,
                        GroupPermission.COMMENT_CREATE,
                        GroupPermission.COMMENT_READ
                    ),
                    priority = 1
                )
            )
        }
    }

    private fun assignAsOwnerForAllGroups(targetOwner: User) {
        val groups = groupRepository.findAll()
        groups.forEach { group ->
            ensureDefaultRoles(group)
            val ownerRole = groupRoleRepository.findByGroupIdAndName(group.id, "OWNER").orElseThrow()
            val memberRole = groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER").orElseThrow()

            val previousOwner = group.owner

            // 1) 대상 소유자를 OWNER 멤버로 우선 보장 (없으면 생성, 있으면 역할 업데이트)
            val existing = groupMemberRepository.findByGroupIdAndUserId(group.id, targetOwner.id)
            if (existing.isPresent) {
                val updatedMember = existing.get().copy(role = ownerRole)
                groupMemberRepository.save(updatedMember)
            } else {
                val newMember = GroupMember(
                    group = group,
                    user = targetOwner,
                    role = ownerRole,
                    joinedAt = LocalDateTime.now()
                )
                groupMemberRepository.save(newMember)
            }

            // 2) Group 엔티티의 owner 업데이트 (멤버 보장 이후)
            if (previousOwner.id != targetOwner.id) {
                val updated = group.copy(owner = targetOwner, updatedAt = LocalDateTime.now())
                groupRepository.save(updated)

                // 3) 이전 그룹장을 MEMBER로 강등 (멤버십 없으면 추가)
                val prevMembership = groupMemberRepository.findByGroupIdAndUserId(group.id, previousOwner.id)
                if (prevMembership.isPresent) {
                    val demoted = prevMembership.get().copy(role = memberRole)
                    groupMemberRepository.save(demoted)
                } else {
                    val demoted = GroupMember(
                        group = group,
                        user = previousOwner,
                        role = memberRole,
                        joinedAt = LocalDateTime.now()
                    )
                    groupMemberRepository.save(demoted)
                }
            }
        }
    }
}
