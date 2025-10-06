package org.castlekong.backend.service

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.dto.CreateGroupRequest
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.entity.GroupVisibility
import org.castlekong.backend.entity.User
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.UserRepository
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.data.domain.PageRequest
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class GroupServiceIntegrationTest {
    @Autowired
    private lateinit var groupManagementService: GroupManagementService

    @Autowired
    private lateinit var groupMemberService: GroupMemberService

    @Autowired
    private lateinit var userRepository: UserRepository

    @Autowired
    private lateinit var groupRepository: GroupRepository

    @Autowired
    private lateinit var groupMemberRepository: GroupMemberRepository

    @Autowired
    private lateinit var groupRoleRepository: GroupRoleRepository

    private lateinit var testUser: User

    @BeforeEach
    fun setUp() {
        testUser =
            userRepository.save(
                User(
                    name = "테스트 사용자",
                    email = TestDataFactory.uniqueEmail("group-int"),
                    password = "hashedPassword",
                    globalRole = GlobalRole.STUDENT,
                    profileCompleted = true,
                ),
            )
    }

    @Test
    @DisplayName("그룹 생성이 성공한다")
    fun createGroup_Success() {
        // given
        val request =
            CreateGroupRequest(
                name = "테스트 그룹",
                description = "테스트용 그룹입니다",
                visibility = GroupVisibility.PUBLIC,
                isRecruiting = true,
                maxMembers = 50,
                tags = setOf("스터디", "개발"),
            )

        // when
        val response = groupManagementService.createGroup(request, testUser.id)

        // then
        assertThat(response.id).isGreaterThan(0)
        assertThat(response.name).isEqualTo("테스트 그룹")
        assertThat(response.description).isEqualTo("테스트용 그룹입니다")
        assertThat(response.owner.id).isEqualTo(testUser.id)
        assertThat(response.visibility).isEqualTo(GroupVisibility.PUBLIC)
        assertThat(response.isRecruiting).isTrue()
        assertThat(response.maxMembers).isEqualTo(50)
        assertThat(response.tags).containsExactlyInAnyOrder("스터디", "개발")

        // 그룹 생성자가 OWNER 역할로 자동 추가되었는지 확인
        val groupMember = groupMemberRepository.findByGroupIdAndUserId(response.id, testUser.id)
        assertThat(groupMember).isPresent
        assertThat(groupMember.get().role.name).isEqualTo("OWNER")

        // 기본 역할들이 생성되었는지 확인
        val roles = groupRoleRepository.findByGroupId(response.id)
        assertThat(roles).hasSize(3)
        assertThat(roles.map { role -> role.name }).containsExactlyInAnyOrder("OWNER", "ADVISOR", "MEMBER")
    }

    @Test
    @DisplayName("그룹 조회가 성공한다")
    fun getGroup_Success() {
        // given
        val request =
            CreateGroupRequest(
                name = "조회 테스트 그룹",
                description = "조회 테스트용 그룹입니다",
            )
        val createdGroup = groupManagementService.createGroup(request, testUser.id)

        // when
        val response = groupManagementService.getGroup(createdGroup.id)

        // then
        assertThat(response.id).isEqualTo(createdGroup.id)
        assertThat(response.name).isEqualTo("조회 테스트 그룹")
        assertThat(response.description).isEqualTo("조회 테스트용 그룹입니다")
        assertThat(response.owner.id).isEqualTo(testUser.id)
    }

    @Test
    @DisplayName("존재하지 않는 그룹 조회 시 예외가 발생한다")
    fun getGroup_NotFound() {
        // given
        val nonExistentGroupId = 999L

        // when & then
        assertThatThrownBy { groupManagementService.getGroup(nonExistentGroupId) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.GROUP_NOT_FOUND)
    }

    @Test
    @DisplayName("그룹 목록 조회가 성공한다")
    fun getGroups_Success() {
        // given
        val request1 = CreateGroupRequest(name = "그룹 1")
        val request2 = CreateGroupRequest(name = "그룹 2")
        groupManagementService.createGroup(request1, testUser.id)
        groupManagementService.createGroup(request2, testUser.id)

        val pageable = PageRequest.of(0, 10)

        // when
        val response = groupManagementService.getGroups(pageable)

        // then
        assertThat(response.content).hasSizeGreaterThanOrEqualTo(2)
        assertThat(response.content.map { it.name }).contains("그룹 1", "그룹 2")
    }

    @Test
    @DisplayName("그룹 가입이 성공한다")
    fun joinGroup_Success() {
        // given
        val groupRequest = CreateGroupRequest(name = "가입 테스트 그룹")
        val createdGroup = groupManagementService.createGroup(groupRequest, testUser.id)

        val newUser =
            userRepository.save(
                User(
                    name = "새로운 사용자",
                    email = "new@example.com",
                    password = "hashedPassword",
                    globalRole = GlobalRole.STUDENT,
                    profileCompleted = true,
                ),
            )

        // when
        val response = groupMemberService.joinGroup(createdGroup.id, newUser.id)

        // then
        assertThat(response.user.id).isEqualTo(newUser.id)
        assertThat(response.role.name).isEqualTo("MEMBER")

        // 데이터베이스에서 확인
        val groupMember = groupMemberRepository.findByGroupIdAndUserId(createdGroup.id, newUser.id)
        assertThat(groupMember).isPresent
    }

    @Test
    @DisplayName("이미 가입한 그룹에 다시 가입 시 예외가 발생한다")
    fun joinGroup_AlreadyMember() {
        // given
        val groupRequest = CreateGroupRequest(name = "중복 가입 테스트 그룹")
        val createdGroup = groupManagementService.createGroup(groupRequest, testUser.id)

        // when & then (그룹 생성자는 이미 멤버이므로)
        assertThatThrownBy { groupMemberService.joinGroup(createdGroup.id, testUser.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.ALREADY_GROUP_MEMBER)
    }

    @Test
    @DisplayName("그룹 탈퇴가 성공한다")
    fun leaveGroup_Success() {
        // given
        val groupRequest = CreateGroupRequest(name = "탈퇴 테스트 그룹")
        val createdGroup = groupManagementService.createGroup(groupRequest, testUser.id)

        val newUser =
            userRepository.save(
                User(
                    name = "탈퇴할 사용자",
                    email = "leave@example.com",
                    password = "hashedPassword",
                    globalRole = GlobalRole.STUDENT,
                    profileCompleted = true,
                ),
            )

        groupMemberService.joinGroup(createdGroup.id, newUser.id)

        // when
        groupMemberService.leaveGroup(createdGroup.id, newUser.id)

        // then
        val groupMember = groupMemberRepository.findByGroupIdAndUserId(createdGroup.id, newUser.id)
        assertThat(groupMember).isNotPresent
    }

    @Test
    @DisplayName("그룹 소유자는 그룹을 떠날 수 없다")
    fun leaveGroup_OwnerCannotLeave() {
        // given
        val groupRequest = CreateGroupRequest(name = "소유자 탈퇴 테스트 그룹")
        val createdGroup = groupManagementService.createGroup(groupRequest, testUser.id)

        // when & then
        assertThatThrownBy { groupMemberService.leaveGroup(createdGroup.id, testUser.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.GROUP_OWNER_CANNOT_LEAVE)
    }

    @Test
    @DisplayName("그룹 멤버 목록 조회가 성공한다")
    fun getGroupMembers_Success() {
        // given
        val groupRequest = CreateGroupRequest(name = "멤버 조회 테스트 그룹")
        val createdGroup = groupManagementService.createGroup(groupRequest, testUser.id)

        val newUser =
            userRepository.save(
                User(
                    name = "추가 멤버",
                    email = "member@example.com",
                    password = "hashedPassword",
                    globalRole = GlobalRole.STUDENT,
                    profileCompleted = true,
                ),
            )
        groupMemberService.joinGroup(createdGroup.id, newUser.id)

        val pageable = PageRequest.of(0, 10)

        // when
        val response = groupMemberService.getGroupMembers(createdGroup.id, pageable)

        // then
        assertThat(response.content).hasSize(2)
        assertThat(response.content.map { member -> member.user.id }).containsExactlyInAnyOrder(testUser.id, newUser.id)
    }
}
