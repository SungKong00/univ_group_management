package org.castlekong.backend.runner

import org.castlekong.backend.entity.GroupMember
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.service.ChannelInitializationService
import org.castlekong.backend.service.GroupRoleInitializationService
import org.slf4j.LoggerFactory
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.core.annotation.Order
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

/**
 * ApplicationRunner that initializes groups on server startup.
 *
 * This runner executes after Spring Boot startup and ensures that all groups
 * have their default roles, permissions, channels, and channel role bindings set up.
 *
 * Execution flow:
 * 1. Find all groups where defaultChannelsCreated = false
 * 2. For each group:
 *    a. Create default roles (그룹장, 교수, 멤버) with permissions
 *    b. Create default channels (ANNOUNCEMENT, TEXT)
 *    c. Create channel role bindings for each channel
 *    d. Set defaultChannelsCreated = true
 *
 * This allows data.sql to only contain basic group information,
 * while roles/channels/bindings are automatically set up by the application.
 *
 * Idempotency: Safe to run multiple times - checks before creating each resource.
 */
@Component
@Order(1) // Run before other runners to ensure base data is set up
class GroupInitializationRunner(
    private val groupRepository: GroupRepository,
    private val groupRoleInitializationService: GroupRoleInitializationService,
    private val channelInitializationService: ChannelInitializationService,
    private val groupMemberRepository: GroupMemberRepository,
) : ApplicationRunner {
    private val logger = LoggerFactory.getLogger(GroupInitializationRunner::class.java)

    @Transactional
    override fun run(args: ApplicationArguments?) {
        logger.info("=== Starting Group Initialization Runner ===")

        // Find all groups that haven't been initialized yet
        val uninitializedGroups =
            groupRepository.findAll()
                .filter { !it.defaultChannelsCreated }

        if (uninitializedGroups.isEmpty()) {
            logger.info("No uninitialized groups found. Skipping initialization.")
            return
        }

        logger.info("Found ${uninitializedGroups.size} uninitialized group(s)")

        uninitializedGroups.forEach { group ->
            try {
                initializeGroup(group)
            } catch (e: Exception) {
                logger.error("Failed to initialize group ${group.id} (${group.name}): ${e.message}", e)
                // Continue with other groups even if one fails
            }
        }

        logger.info("=== Group Initialization Runner Completed ===")
    }

    /**
     * Initialize a single group with default roles, channels, and bindings.
     *
     * @param group The group to initialize
     */
    @Transactional
    fun initializeGroup(group: org.castlekong.backend.entity.Group) {
        logger.info("Initializing group: ${group.name} (id=${group.id})")

        // Step 1: Ensure default roles exist with permissions
        logger.info("[${group.id}] Step 1/3: Creating default roles...")
        val roles = groupRoleInitializationService.ensureDefaultRoles(group)
        val ownerRole = roles.find { it.name == "그룹장" }!!
        val advisorRole = roles.find { it.name == "교수" }
        val memberRole = roles.find { it.name == "멤버" }!!

        logger.info(
            "[${group.id}] Roles created - 그룹장: ${ownerRole.permissions.size} permissions, " +
                "교수: ${advisorRole?.permissions?.size ?: 0} permissions, " +
                "멤버: ${memberRole.permissions.size} permissions",
        )

        // Step 1.5: Add group owner as 그룹장 role member
        logger.info("[${group.id}] Step 1.5/4: Adding group owner as 그룹장 member...")
        val existingMembership = groupMemberRepository.findByGroupIdAndUserId(group.id, group.owner.id)
        if (existingMembership.isEmpty) {
            val ownerMembership =
                GroupMember(
                    group = group,
                    user = group.owner,
                    role = ownerRole,
                    joinedAt = LocalDateTime.now(),
                )
            groupMemberRepository.save(ownerMembership)
            logger.info("[${group.id}] Added owner ${group.owner.email} as 그룹장 role member")
        } else {
            logger.info("[${group.id}] Owner ${group.owner.email} already has membership")
        }

        // Step 2: Ensure default channels exist
        logger.info("[${group.id}] Step 2/4: Creating default channels...")
        val channelsCreated =
            channelInitializationService.ensureDefaultChannelsExist(
                group = group,
                ownerRole = ownerRole,
                advisorRole = advisorRole,
                memberRole = memberRole,
            )

        if (channelsCreated) {
            logger.info("[${group.id}] Default channels created (ANNOUNCEMENT, TEXT)")
        } else {
            logger.info("[${group.id}] Default channels already exist")
        }

        // Step 3: Mark group as initialized
        logger.info("[${group.id}] Step 3/4: Marking group as initialized...")
        val updatedGroup = group.copy(defaultChannelsCreated = true)
        groupRepository.save(updatedGroup)

        logger.info("[${group.id}] ✅ Group initialization completed successfully")
    }
}
