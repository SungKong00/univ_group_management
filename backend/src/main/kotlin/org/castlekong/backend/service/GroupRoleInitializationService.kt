package org.castlekong.backend.service

import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.repository.GroupRoleRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * Service for initializing default group roles and permissions.
 *
 * This service provides reusable methods for:
 * - Creating default roles (OWNER, ADVISOR, MEMBER)
 * - Mapping permissions to each role
 * - Ensuring idempotency (safe to call multiple times)
 *
 * Used by:
 * - GroupInitializationRunner: Server startup initialization
 * - GroupManagementService: New group creation
 * - GroupMemberService: Group member operations
 */
@Service
class GroupRoleInitializationService(
    private val groupRoleRepository: GroupRoleRepository,
) {
    private val logger = LoggerFactory.getLogger(GroupRoleInitializationService::class.java)

    /**
     * Ensure default roles exist for the given group.
     *
     * Creates 3 system roles if they don't exist:
     * - OWNER: All permissions (priority 100)
     * - ADVISOR: All permissions (priority 99)
     * - MEMBER: No group-level permissions (priority 1)
     *
     * This method is idempotent - safe to call multiple times.
     *
     * @param group The group to initialize roles for
     * @return List of created/existing roles
     */
    @Transactional
    fun ensureDefaultRoles(group: Group): List<GroupRole> {
        logger.info("Ensuring default roles for group: ${group.name} (id=${group.id})")

        val ownerRole = getOrCreateOwnerRole(group)
        val advisorRole = getOrCreateAdvisorRole(group)
        val memberRole = getOrCreateMemberRole(group)

        logger.info("Default roles ensured for group ${group.id}: OWNER, ADVISOR, MEMBER")

        return listOf(ownerRole, advisorRole, memberRole)
    }

    /**
     * Get or create OWNER role with all permissions.
     */
    @Transactional
    fun getOrCreateOwnerRole(group: Group): GroupRole {
        return groupRoleRepository.findByGroupIdAndName(group.id, "OWNER")
            .orElseGet {
                logger.info("Creating OWNER role for group ${group.id}")
                groupRoleRepository.save(
                    GroupRole(
                        group = group,
                        name = "OWNER",
                        isSystemRole = true,
                        permissions = GroupPermission.entries.toMutableSet(),
                        priority = 100,
                    ),
                )
            }
    }

    /**
     * Get or create ADVISOR role with all permissions.
     */
    @Transactional
    fun getOrCreateAdvisorRole(group: Group): GroupRole {
        return groupRoleRepository.findByGroupIdAndName(group.id, "ADVISOR")
            .orElseGet {
                logger.info("Creating ADVISOR role for group ${group.id}")
                groupRoleRepository.save(
                    GroupRole(
                        group = group,
                        name = "ADVISOR",
                        isSystemRole = true,
                        permissions = GroupPermission.entries.toMutableSet(),
                        priority = 99,
                    ),
                )
            }
    }

    /**
     * Get or create MEMBER role with no group-level permissions.
     */
    @Transactional
    fun getOrCreateMemberRole(group: Group): GroupRole {
        return groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER")
            .orElseGet {
                logger.info("Creating MEMBER role for group ${group.id}")
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

    /**
     * Get all default roles for a group (OWNER, ADVISOR, MEMBER).
     *
     * @param group The group to get roles for
     * @return List of 3 roles (OWNER, ADVISOR, MEMBER)
     * @throws IllegalStateException if roles don't exist
     */
    fun getDefaultRoles(group: Group): List<GroupRole> {
        val owner =
            groupRoleRepository.findByGroupIdAndName(group.id, "OWNER")
                .orElseThrow { IllegalStateException("OWNER role not found for group ${group.id}") }
        val advisor =
            groupRoleRepository.findByGroupIdAndName(group.id, "ADVISOR")
                .orElseThrow { IllegalStateException("ADVISOR role not found for group ${group.id}") }
        val member =
            groupRoleRepository.findByGroupIdAndName(group.id, "MEMBER")
                .orElseThrow { IllegalStateException("MEMBER role not found for group ${group.id}") }

        return listOf(owner, advisor, member)
    }
}
