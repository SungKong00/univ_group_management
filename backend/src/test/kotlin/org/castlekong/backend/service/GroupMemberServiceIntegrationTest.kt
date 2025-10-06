package org.castlekong.backend.service

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.GroupType
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
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class GroupMemberServiceIntegrationTest {
    @Autowired
    private lateinit var groupMemberService: GroupMemberService

    @Autowired
    private lateinit var userRepository: UserRepository

    @Autowired
    private lateinit var groupRepository: GroupRepository

    @Autowired
    private lateinit var groupRoleRepository: GroupRoleRepository

    @Autowired
    private lateinit var groupMemberRepository: GroupMemberRepository

    @Autowired
    private lateinit var groupInitializationRunner: org.castlekong.backend.runner.GroupInitializationRunner

    private lateinit var owner: User
    private lateinit var student: User
    private lateinit var professor: User

    @BeforeEach
    fun setUp() {
        val suffix = System.nanoTime().toString()
        owner =
            userRepository.save(
                TestDataFactory.createTestUser(
                    name = "그룹장",
                    email = "owner+$suffix@example.com",
                    globalRole = GlobalRole.STUDENT,
                ).copy(profileCompleted = true),
            )

        student =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "학생",
                    email = "student+$suffix@example.com",
                ),
            )

        professor =
            userRepository.save(
                TestDataFactory.createProfessorUser(
                    name = "교수",
                    email = "professor+$suffix@example.com",
                ),
            )
    }

    // === 그룹 가입 테스트 ===

    @Test
    @DisplayName("그룹 가입이 성공한다")
    fun joinGroup_Success() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)

        // When
        val response = groupMemberService.joinGroup(group.id, student.id)

        // Then
        assertThat(response.user.id).isEqualTo(student.id)
        assertThat(response.role.name).isEqualTo("MEMBER")

        val member = groupMemberRepository.findByGroupIdAndUserId(group.id, student.id)
        assertThat(member).isPresent
    }

    @Test
    @DisplayName("그룹 가입 시 상위 그룹에 자동으로 가입된다")
    fun joinGroup_AutoJoinParentGroups() {
        // Given
        val university = createGroupWithRoles("대학교", owner, GroupType.UNIVERSITY)
        val college = createGroupWithRoles("학부", owner, GroupType.COLLEGE, university)
        val department = createGroupWithRoles("학과", owner, GroupType.DEPARTMENT, college)

        // When
        groupMemberService.joinGroup(department.id, student.id)

        // Then
        // 학과 그룹 멤버십 확인
        assertThat(groupMemberRepository.findByGroupIdAndUserId(department.id, student.id)).isPresent

        // 학부 그룹 자동 가입 확인
        assertThat(groupMemberRepository.findByGroupIdAndUserId(college.id, student.id)).isPresent

        // 대학교 그룹 자동 가입 확인
        assertThat(groupMemberRepository.findByGroupIdAndUserId(university.id, student.id)).isPresent
    }

    @Test
    @DisplayName("중복 가입 시 예외가 발생한다")
    fun joinGroup_DuplicateMembership_ThrowsException() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)
        groupMemberService.joinGroup(group.id, student.id)

        // When & Then
        assertThatThrownBy { groupMemberService.joinGroup(group.id, student.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.ALREADY_GROUP_MEMBER)
    }

    @Test
    @DisplayName("최대 멤버 수 초과 시 예외가 발생한다")
    fun joinGroup_ExceedsMaxMembers_ThrowsException() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner, maxMembers = 1)

        // When & Then
        assertThatThrownBy { groupMemberService.joinGroup(group.id, student.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.GROUP_FULL)
    }

    // === 그룹 탈퇴 테스트 ===

    @Test
    @DisplayName("그룹 탈퇴가 성공한다")
    fun leaveGroup_Success() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)
        groupMemberService.joinGroup(group.id, student.id)

        // When
        groupMemberService.leaveGroup(group.id, student.id)

        // Then
        val member = groupMemberRepository.findByGroupIdAndUserId(group.id, student.id)
        assertThat(member).isNotPresent
    }

    @Test
    @DisplayName("그룹 탈퇴 시 하위 그룹에서 자동으로 탈퇴된다")
    fun leaveGroup_AutoLeaveChildGroups() {
        // Given
        val university = createGroupWithRoles("대학교", owner, GroupType.UNIVERSITY)
        val college = createGroupWithRoles("학부", owner, GroupType.COLLEGE, university)
        val department = createGroupWithRoles("학과", owner, GroupType.DEPARTMENT, college)

        groupMemberService.joinGroup(department.id, student.id)

        // When - 학부에서 탈퇴
        groupMemberService.leaveGroup(college.id, student.id)

        // Then
        // 학부 탈퇴 확인
        assertThat(groupMemberRepository.findByGroupIdAndUserId(college.id, student.id)).isNotPresent

        // 하위 학과에서도 자동 탈퇴 확인
        assertThat(groupMemberRepository.findByGroupIdAndUserId(department.id, student.id)).isNotPresent

        // 상위 대학교는 유지 (다른 학부가 없으므로 탈퇴)
        assertThat(groupMemberRepository.findByGroupIdAndUserId(university.id, student.id)).isNotPresent
    }

    @Test
    @DisplayName("형제 그룹 멤버십이 있으면 상위 그룹 유지")
    fun leaveGroup_KeepParentGroupIfSiblingExists() {
        // Given
        val university = createGroupWithRoles("대학교", owner, GroupType.UNIVERSITY)
        val college = createGroupWithRoles("학부", owner, GroupType.COLLEGE, university)
        val dept1 = createGroupWithRoles("학과1", owner, GroupType.DEPARTMENT, college)
        val dept2 = createGroupWithRoles("학과2", owner, GroupType.DEPARTMENT, college)

        // 두 학과 모두 가입
        groupMemberService.joinGroup(dept1.id, student.id)
        groupMemberService.joinGroup(dept2.id, student.id)

        // When - 학과1에서 탈퇴
        groupMemberService.leaveGroup(dept1.id, student.id)

        // Then
        // 학과1 탈퇴 확인
        assertThat(groupMemberRepository.findByGroupIdAndUserId(dept1.id, student.id)).isNotPresent

        // 학과2는 유지
        assertThat(groupMemberRepository.findByGroupIdAndUserId(dept2.id, student.id)).isPresent

        // 상위 학부/대학교 유지 (학과2 때문에)
        assertThat(groupMemberRepository.findByGroupIdAndUserId(college.id, student.id)).isPresent
        assertThat(groupMemberRepository.findByGroupIdAndUserId(university.id, student.id)).isPresent
    }

    @Test
    @DisplayName("그룹 소유자는 탈퇴할 수 없다")
    fun leaveGroup_OwnerCannotLeave_ThrowsException() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)

        // When & Then
        assertThatThrownBy { groupMemberService.leaveGroup(group.id, owner.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.GROUP_OWNER_CANNOT_LEAVE)
    }

    // === 멤버 관리 테스트 ===

    @Test
    @DisplayName("그룹장은 멤버를 추방할 수 있다")
    fun removeMember_Success() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)
        groupMemberService.joinGroup(group.id, student.id)

        // When
        groupMemberService.removeMember(group.id, student.id, owner.id)

        // Then
        val member = groupMemberRepository.findByGroupIdAndUserId(group.id, student.id)
        assertThat(member).isNotPresent
    }

    @Test
    @DisplayName("그룹장이 아니면 멤버를 추방할 수 없다")
    fun removeMember_NotOwner_ThrowsException() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)
        groupMemberService.joinGroup(group.id, student.id)
        val anotherUser =
            userRepository.save(TestDataFactory.createStudentUser(name = "다른학생", email = "another@example.com"))
        groupMemberService.joinGroup(group.id, anotherUser.id)

        // When & Then
        assertThatThrownBy { groupMemberService.removeMember(group.id, student.id, anotherUser.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("그룹장 본인은 추방할 수 없다")
    fun removeMember_CannotRemoveOwner_ThrowsException() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)

        // When & Then
        assertThatThrownBy { groupMemberService.removeMember(group.id, owner.id, owner.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.INVALID_REQUEST)
    }

    @Test
    @DisplayName("멤버 역할을 변경할 수 있다")
    fun updateMemberRole_Success() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)
        groupMemberService.joinGroup(group.id, student.id)

        val customRole =
            groupRoleRepository.save(
                TestDataFactory.createTestGroupRole(
                    group = group,
                    name = "MODERATOR",
                    isSystemRole = false,
                    permissions = setOf(GroupPermission.CHANNEL_MANAGE),
                    priority = 50,
                ),
            )

        // When
        val response = groupMemberService.updateMemberRole(group.id, student.id, customRole.id, owner.id)

        // Then
        assertThat(response.role.name).isEqualTo("MODERATOR")
    }

    @Test
    @DisplayName("OWNER 역할로 변경은 불가능하다")
    fun updateMemberRole_ToOwner_ThrowsException() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)
        groupMemberService.joinGroup(group.id, student.id)
        val ownerRole = groupRoleRepository.findByGroupIdAndName(group.id, "OWNER").get()

        // When & Then
        assertThatThrownBy { groupMemberService.updateMemberRole(group.id, student.id, ownerRole.id, owner.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.INVALID_REQUEST)
    }

    // === 지도교수 관리 테스트 ===

    @Test
    @DisplayName("교수를 지도교수로 지정할 수 있다")
    fun assignProfessor_Success() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)

        // When
        val response = groupMemberService.assignProfessor(group.id, professor.id, owner.id)

        // Then
        assertThat(response.role.name).isEqualTo("ADVISOR")
        assertThat(response.user.id).isEqualTo(professor.id)
    }

    @Test
    @DisplayName("교수가 아닌 사용자를 지도교수로 지정할 수 없다")
    fun assignProfessor_NotProfessor_ThrowsException() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)

        // When & Then
        assertThatThrownBy { groupMemberService.assignProfessor(group.id, student.id, owner.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.INVALID_REQUEST)
    }

    @Test
    @DisplayName("지도교수를 해제하면 일반 멤버가 된다")
    fun removeProfessor_Success() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)
        groupMemberService.assignProfessor(group.id, professor.id, owner.id)

        // When
        groupMemberService.removeProfessor(group.id, professor.id, owner.id)

        // Then
        val member = groupMemberRepository.findByGroupIdAndUserId(group.id, professor.id).get()
        assertThat(member.role.name).isEqualTo("MEMBER")
    }

    // === 그룹장 권한 위임 테스트 ===

    @Test
    @DisplayName("그룹장 권한을 다른 멤버에게 위임할 수 있다")
    fun transferOwnership_Success() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)
        groupMemberService.joinGroup(group.id, student.id)

        // When
        val response = groupMemberService.transferOwnership(group.id, student.id, owner.id)

        // Then
        assertThat(response.role.name).isEqualTo("OWNER")
        assertThat(response.user.id).isEqualTo(student.id)

        // 이전 그룹장은 일반 멤버로 강등
        val formerOwner = groupMemberRepository.findByGroupIdAndUserId(group.id, owner.id).get()
        assertThat(formerOwner.role.name).isEqualTo("MEMBER")

        // 그룹 엔티티의 owner도 변경되었는지 확인
        val updatedGroup = groupRepository.findById(group.id).get()
        assertThat(updatedGroup.owner.id).isEqualTo(student.id)
    }

    @Test
    @DisplayName("현재 그룹장이 아니면 권한 위임을 할 수 없다")
    fun transferOwnership_NotOwner_ThrowsException() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)
        groupMemberService.joinGroup(group.id, student.id)

        // When & Then
        assertThatThrownBy { groupMemberService.transferOwnership(group.id, owner.id, student.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.FORBIDDEN)
    }

    @Test
    @DisplayName("그룹 멤버가 아닌 사용자에게 권한 위임을 할 수 없다")
    fun transferOwnership_NonMember_ThrowsException() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)

        // When & Then
        assertThatThrownBy { groupMemberService.transferOwnership(group.id, student.id, owner.id) }
            .isInstanceOf(BusinessException::class.java)
            .hasFieldOrPropertyWithValue("errorCode", ErrorCode.GROUP_MEMBER_NOT_FOUND)
    }

    @Test
    @DisplayName("그룹장 유고 시 학년/가입일 기준으로 승계된다")
    fun handleOwnerAbsence_Success() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)
        val oldMember = userRepository.save(TestDataFactory.createStudentUser(name = "옛날멤버", email = "old@example.com"))
        groupMemberService.joinGroup(group.id, oldMember.id)
        Thread.sleep(10) // 가입 시간 차이 보장
        groupMemberService.joinGroup(group.id, student.id)

        // When - 그룹장 유고 처리
        val response = groupMemberService.handleOwnerAbsence(group.id)

        // Then
        assertThat(response).isNotNull
        // 가장 먼저 가입한 멤버가 승계
        assertThat(response!!.user.id).isEqualTo(oldMember.id)
        assertThat(response.role.name).isEqualTo("OWNER")

        // 그룹 엔티티의 owner도 변경되었는지 확인
        val updatedGroup = groupRepository.findById(group.id).get()
        assertThat(updatedGroup.owner.id).isEqualTo(oldMember.id)
    }

    @Test
    @DisplayName("승계 후보자가 없으면 null을 반환한다")
    fun handleOwnerAbsence_NoCandidates_ReturnsNull() {
        // Given
        val group = createGroupWithRoles("테스트 그룹", owner)

        // When
        val response = groupMemberService.handleOwnerAbsence(group.id)

        // Then
        assertThat(response).isNull()
    }

    // === Helper Methods ===

    private fun createGroupWithRoles(
        name: String,
        owner: User,
        groupType: GroupType = GroupType.AUTONOMOUS,
        parent: Group? = null,
        maxMembers: Int? = null,
    ): Group {
        // 그룹 생성
        val group =
            groupRepository.save(
                TestDataFactory.createTestGroup(
                    name = name,
                    owner = owner,
                    groupType = groupType,
                    parent = parent,
                    maxMembers = maxMembers,
                ),
            )

        // GroupInitializationRunner를 직접 호출하여 역할, 채널, 멤버십 초기화
        // 테스트 환경에서는 ApplicationRunner가 각 테스트마다 실행되지 않으므로 수동 호출 필요
        groupInitializationRunner.initializeGroup(group)

        return group
    }
}
