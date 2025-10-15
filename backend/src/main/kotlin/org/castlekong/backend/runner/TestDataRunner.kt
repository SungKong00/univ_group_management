package org.castlekong.backend.runner

import org.castlekong.backend.dto.CreateApplicationRequest
import org.castlekong.backend.dto.CreateGroupRequest
import org.castlekong.backend.dto.CreateGroupRoleRequest
import org.castlekong.backend.dto.CreatePlaceRequest
import org.castlekong.backend.dto.CreateRecruitmentRequest
import org.castlekong.backend.dto.GroupResponse
import org.castlekong.backend.dto.RequestUsageRequest
import org.castlekong.backend.dto.UpdateUsageStatusRequest
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.UsageStatus
import org.castlekong.backend.entity.User
import org.castlekong.backend.service.GroupManagementService
import org.castlekong.backend.service.GroupMemberService
import org.castlekong.backend.service.GroupRoleService
import org.castlekong.backend.service.PlaceService
import org.castlekong.backend.service.PlaceUsageGroupService
import org.castlekong.backend.service.RecruitmentService
import org.castlekong.backend.service.UserService
import org.slf4j.LoggerFactory
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.core.annotation.Order
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Component
@Order(2) // Run after GroupInitializationRunner
class TestDataRunner(
    private val userService: UserService,
    private val groupManagementService: GroupManagementService,
    private val groupMemberService: GroupMemberService,
    private val groupRoleService: GroupRoleService,
    private val recruitmentService: RecruitmentService,
    private val placeService: PlaceService,
    private val placeUsageGroupService: PlaceUsageGroupService,
) : ApplicationRunner {
    private val logger = LoggerFactory.getLogger(TestDataRunner::class.java)

    @Transactional
    override fun run(args: ApplicationArguments) {
        if (groupManagementService.getAllGroups().any { it.name == "코딩 동아리 'DevCrew'" }) {
            logger.info("Test groups already exist, skipping TestDataRunner.")
            return
        }

        logger.info("--- Starting Test Data Creation ---")

        try {
            // Step 1: Fetch Users
            logger.info("[1/8] Fetching test users...")
            val user1 = userService.findByEmail("testuser1@hs.ac.kr")!!
            val user2 = userService.findByEmail("testuser2@hs.ac.kr")!!
            val user3 = userService.findByEmail("testuser3@hs.ac.kr")!!
            logger.info("-> SUCCESS: Fetched 3 test users.")

            // Step 2: Auto-join to department groups
            logger.info("[2/8] Auto-joining users to hierarchy groups...")
            try {
                val users = listOf(user1, user2, user3)
                val departmentGroupIds = listOf(1L, 2L, 13L) // 1: 한신대학교, 2: AI/SW계열, 13: AI/SW학과
                for (user in users) {
                    for (groupId in departmentGroupIds) {
                        if (!groupMemberService.isMember(groupId, user.id)) {
                            groupMemberService.joinGroup(groupId, user.id)
                        }
                    }
                }
                logger.info("-> SUCCESS: Auto-joined users to department groups.")
            } catch (e: Exception) {
                logger.error("--> FAILED at step 2: Auto-joining users.", e)
                throw e
            }

            // Step 3: Create Custom Groups
            logger.info("[3/8] Creating custom groups...")
            val devCrewGroup = createGroup(user1, "코딩 동아리 'DevCrew'", GroupType.AUTONOMOUS)
            val studentCouncilGroup = createGroup(user2, "학생회", GroupType.OFFICIAL, parentId = 1)
            logger.info("-> SUCCESS: Created custom groups.")

            // Step 4: Add Members to Custom Groups
            logger.info("[4/8] Adding members to custom groups...")
            try {
                groupMemberService.joinGroup(studentCouncilGroup.id, user3.id)
                logger.info("-> SUCCESS: Added user3 to Student Council.")
            } catch (e: Exception) {
                logger.error("--> FAILED at step 4: Adding user3 to Student Council.", e)
                throw e
            }

            // Step 5: Create and Assign Custom Role
            logger.info("[5/8] Creating and assigning custom role...")
            val executiveRole = try {
                groupRoleService.createGroupRole(
                    studentCouncilGroup.id,
                    CreateGroupRoleRequest(
                        name = "학생회 간부",
                        permissions = setOf(GroupPermission.CHANNEL_MANAGE.name, GroupPermission.RECRUITMENT_MANAGE.name),
                        priority = 50,
                    ),
                    user2.id,
                )
            } catch (e: Exception) {
                logger.error("--> FAILED at step 5.1: Creating custom role.", e)
                throw e
            }
            logger.info("-> SUCCESS: Created custom role '${executiveRole.name}'.")

            try {
                groupMemberService.updateMemberRole(studentCouncilGroup.id, user3.id, executiveRole.id, user2.id)
                logger.info("-> SUCCESS: Assigned custom role to user3.")
            } catch (e: Exception) {
                logger.error("--> FAILED at step 5.2: Assigning custom role.", e)
                throw e
            }

            // Step 6: Create Recruitment and Applications
            logger.info("[6/8] Creating recruitment and applications...")
            val recruitment = try {
                recruitmentService.createRecruitment(
                    studentCouncilGroup.id,
                    CreateRecruitmentRequest(title = "학생회 2025년 2학기 신입 부원 모집", content = "열정 넘치는 신입 부원을 모집합니다!", recruitmentEndDate = LocalDateTime.now().plusWeeks(2), applicationQuestions = listOf("자기소개를 해주세요.")),
                    user2.id,
                )
            } catch (e: Exception) {
                logger.error("--> FAILED at step 6.1: Creating recruitment.", e)
                throw e
            }
            logger.info("-> SUCCESS: Created recruitment post.")

            try {
                recruitmentService.submitApplication(
                    recruitment.id,
                    CreateApplicationRequest(motivation = "학생 사회에 기여하고 싶습니다.", questionAnswers = mapOf(0 to "안녕하세요, TestUser1입니다.")),
                    user1.id,
                )
                logger.info("-> SUCCESS: User1 submitted application.")
            } catch (e: Exception) {
                logger.error("--> FAILED at step 6.2: Submitting application.", e)
                throw e
            }

            // Step 7: Create Place
            logger.info("[7/8] Creating place...")
            val labPlace = try {
                placeService.createPlace(user2, CreatePlaceRequest(managingGroupId = studentCouncilGroup.id, building = "학생회관", roomNumber = "201호", alias = "학생회실", capacity = 25))
            } catch (e: Exception) {
                logger.error("--> FAILED at step 7: Creating place.", e)
                throw e
            }
            logger.info("-> SUCCESS: Created place '${labPlace.displayName}'.")

            // Step 8: Request and Approve Place Usage
            logger.info("[8/8] Requesting and approving place usage...")
            try {
                placeUsageGroupService.requestUsage(user1, labPlace.id, RequestUsageRequest(groupId = devCrewGroup.id, reason = "매주 스터디를 위해 사용하고 싶습니다."))
                logger.info("-> SUCCESS: Requested place usage.")
            } catch (e: Exception) {
                logger.error("--> FAILED at step 8.1: Requesting place usage.", e)
                throw e
            }

            try {
                placeUsageGroupService.updateUsageStatus(user2, labPlace.id, devCrewGroup.id, UpdateUsageStatusRequest(status = UsageStatus.APPROVED))
                logger.info("-> SUCCESS: Approved place usage.")
            } catch (e: Exception) {
                logger.error("--> FAILED at step 8.2: Approving place usage.", e)
                throw e
            }

            logger.info("--- Test Data Creation Finished Successfully ---")
        } catch (e: Exception) {
            // This final catch block will now only catch unhandled exceptions or re-thrown ones.
            logger.error("--- Test Data Creation Failed Due to an Uncaught Exception ---", e)
        }
    }

    private fun createGroup(owner: User, name: String, groupType: GroupType, parentId: Long? = 1, description: String? = null): GroupResponse {
        return groupManagementService.createGroup(
            CreateGroupRequest(
                name = name,
                parentId = parentId,
                university = "한신대학교",
                college = if(parentId == 2L) "AI/SW계열" else null,
                department = null,
                groupType = groupType,
                description = description,
                tags = emptySet(),
            ),
            owner.id,
        )
    }
}