package org.castlekong.backend.service

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.dto.CreateSubGroupRequest
import org.castlekong.backend.dto.ReviewGroupJoinRequestRequest
import org.castlekong.backend.dto.ReviewSubGroupRequestRequest
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupJoinRequestStatus
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.SubGroupRequestStatus
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.GroupJoinRequestRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.SubGroupRequestRepository
import org.castlekong.backend.repository.UserRepository
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class GroupRequestServiceIntegrationTest {
    @Autowired
    private lateinit var groupRequestService: GroupRequestService

    @Autowired
    private lateinit var userRepository: UserRepository

    @Autowired
    private lateinit var groupRepository: GroupRepository

    @Autowired
    private lateinit var groupRoleRepository: GroupRoleRepository

    @Autowired
    private lateinit var groupMemberRepository: GroupMemberRepository

    @Autowired
    private lateinit var subGroupRequestRepository: SubGroupRequestRepository

    @Autowired
    private lateinit var groupJoinRequestRepository: GroupJoinRequestRepository

    private lateinit var owner: User
    private lateinit var requester: User
    private lateinit var applicant: User
    private lateinit var parentGroup: Group
    private lateinit var memberRole: GroupRole

    @BeforeEach
    fun setUp() {
        val suffix = System.nanoTime().toString()
        owner =
            userRepository.save(
                TestDataFactory.createTestUser(
                    name = "그룹장",
                    email = "owner-request+$suffix@example.com",
                ).copy(profileCompleted = true),
            )

        requester =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "요청자",
                    email = "requester+$suffix@example.com",
                ),
            )

        applicant =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "지원자",
                    email = "applicant+$suffix@example.com",
                ),
            )

        parentGroup = createGroupWithDefaultRoles(owner)
        memberRole = groupRoleRepository.findByGroupIdAndName(parentGroup.id!!, "MEMBER").get()
    }

    @Test
    @DisplayName("하위 그룹 생성 신청을 등록할 수 있다")
    fun createSubGroupRequest_Success() {
        val request =
            CreateSubGroupRequest(
                requestedGroupName = "컴퓨터공학과",
                requestedGroupDescription = "신설 학과",
                requestedGroupType = GroupType.DEPARTMENT,
                requestedMaxMembers = 120,
            )

        val response = groupRequestService.createSubGroupRequest(parentGroup.id!!, request, requester.id!!)

        assertThat(response.requestedGroupName).isEqualTo("컴퓨터공학과")
        assertThat(response.status).isEqualTo(SubGroupRequestStatus.PENDING.name)
        assertThat(response.parentGroup.id).isEqualTo(parentGroup.id!!)
        assertThat(response.parentGroup.memberCount).isEqualTo(1) // 그룹장 1명

        val saved = subGroupRequestRepository.findById(response.id)
        assertThat(saved).isPresent
        assertThat(saved.get().requestedGroupName).isEqualTo("컴퓨터공학과")
    }

    @Test
    @DisplayName("하위 그룹 신청을 승인하면 실제 하위 그룹이 생성된다")
    fun reviewSubGroupRequest_Approve_CreatesGroup() {
        val request =
            CreateSubGroupRequest(
                requestedGroupName = "디자인학부",
                requestedGroupDescription = "디자인 전공",
                requestedGroupType = GroupType.COLLEGE,
            )
        val created = groupRequestService.createSubGroupRequest(parentGroup.id!!, request, requester.id!!)

        val reviewRequest = ReviewSubGroupRequestRequest(action = "APPROVE", responseMessage = "승인")
        val response = groupRequestService.reviewSubGroupRequest(created.id, reviewRequest, owner.id!!)

        assertThat(response.status).isEqualTo(SubGroupRequestStatus.APPROVED.name)
        assertThat(response.reviewedBy?.id).isEqualTo(owner.id!!)
        assertThat(response.responseMessage).isEqualTo("승인")

        val children = groupRepository.findByParentId(parentGroup.id!!)
        assertThat(children).anySatisfy { child ->
            assertThat(child.name).isEqualTo("디자인학부")
            assertThat(child.owner.id).isEqualTo(requester.id!!)
        }
    }

    @Test
    @DisplayName("하위 그룹 신청을 반려하면 상태가 REJECTED로 변경된다")
    fun reviewSubGroupRequest_Reject() {
        val request =
            CreateSubGroupRequest(
                requestedGroupName = "행정팀",
                requestedGroupType = GroupType.AUTONOMOUS,
            )
        val created = groupRequestService.createSubGroupRequest(parentGroup.id!!, request, requester.id!!)

        val reviewRequest = ReviewSubGroupRequestRequest(action = "REJECT", responseMessage = "요건 미충족")
        val response = groupRequestService.reviewSubGroupRequest(created.id, reviewRequest, owner.id!!)

        assertThat(response.status).isEqualTo(SubGroupRequestStatus.REJECTED.name)
        assertThat(response.responseMessage).isEqualTo("요건 미충족")
        assertThat(response.reviewedBy?.id).isEqualTo(owner.id!!)

        val children = groupRepository.findByParentId(parentGroup.id!!)
        assertThat(children).isEmpty()
    }

    @Test
    @DisplayName("그룹 가입 신청을 등록할 수 있다")
    fun createGroupJoinRequest_Success() {
        val response = groupRequestService.createGroupJoinRequest(parentGroup.id!!, "참여 희망", applicant.id!!)

        assertThat(response.status).isEqualTo(GroupJoinRequestStatus.PENDING.name)
        assertThat(response.user.id).isEqualTo(applicant.id!!)
        assertThat(response.group.id).isEqualTo(parentGroup.id!!)
        assertThat(response.group.memberCount).isEqualTo(1) // 그룹장만 존재

        val saved = groupJoinRequestRepository.findById(response.id)
        assertThat(saved).isPresent
        assertThat(saved.get().requestMessage).isEqualTo("참여 희망")
    }

    @Test
    @DisplayName("중복된 가입 신청은 허용되지 않는다")
    fun createGroupJoinRequest_Duplicate_ThrowsException() {
        groupRequestService.createGroupJoinRequest(parentGroup.id!!, null, applicant.id!!)

        assertThatThrownBy { groupRequestService.createGroupJoinRequest(parentGroup.id!!, "재요청", applicant.id!!) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.REQUEST_ALREADY_EXISTS)
    }

    @Test
    @DisplayName("이미 그룹 멤버라면 가입 신청을 할 수 없다")
    fun createGroupJoinRequest_AlreadyMember_ThrowsException() {
        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = parentGroup,
                user = applicant,
                role = memberRole,
            ),
        )

        assertThatThrownBy { groupRequestService.createGroupJoinRequest(parentGroup.id!!, null, applicant.id!!) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.ALREADY_GROUP_MEMBER)
    }

    @Test
    @DisplayName("그룹 가입 신청을 승인하면 멤버로 추가된다")
    fun reviewGroupJoinRequest_Approve_AddsMember() {
        val created = groupRequestService.createGroupJoinRequest(parentGroup.id!!, "가입", applicant.id!!)

        val reviewRequest = ReviewGroupJoinRequestRequest(action = "APPROVE", responseMessage = "환영합니다")
        val response = groupRequestService.reviewGroupJoinRequest(created.id, reviewRequest, owner.id!!)

        assertThat(response.status).isEqualTo(GroupJoinRequestStatus.APPROVED.name)
        assertThat(response.reviewedBy?.id).isEqualTo(owner.id!!)
        assertThat(response.responseMessage).isEqualTo("환영합니다")

        val membership = groupMemberRepository.findByGroupIdAndUserId(parentGroup.id!!, applicant.id!!)
        assertThat(membership).isPresent
        assertThat(membership.get().role.name).isEqualTo("MEMBER")
    }

    @Test
    @DisplayName("그룹 가입 신청을 반려하면 멤버가 추가되지 않는다")
    fun reviewGroupJoinRequest_Reject() {
        val created = groupRequestService.createGroupJoinRequest(parentGroup.id!!, "가입", applicant.id!!)

        val reviewRequest = ReviewGroupJoinRequestRequest(action = "REJECT", responseMessage = "자격 미달")
        val response = groupRequestService.reviewGroupJoinRequest(created.id, reviewRequest, owner.id!!)

        assertThat(response.status).isEqualTo(GroupJoinRequestStatus.REJECTED.name)
        assertThat(response.reviewedBy?.id).isEqualTo(owner.id!!)

        val membership = groupMemberRepository.findByGroupIdAndUserId(parentGroup.id!!, applicant.id!!)
        assertThat(membership).isNotPresent
    }

    private fun createGroupWithDefaultRoles(owner: User): Group {
        val group =
            groupRepository.save(
                TestDataFactory.createTestGroup(
                    name = "요청 테스트 그룹",
                    owner = owner,
                ),
            )

        val ownerRole = groupRoleRepository.save(TestDataFactory.createOwnerRole(group))
        groupRoleRepository.save(TestDataFactory.createAdvisorRole(group))
        val memberRole = groupRoleRepository.save(TestDataFactory.createMemberRole(group))

        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = owner,
                role = ownerRole,
            ),
        )

        return group
    }
}
