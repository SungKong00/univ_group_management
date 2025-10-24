package org.castlekong.backend.service

import org.assertj.core.api.Assertions.assertThat
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupMember
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.User
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
import java.time.LocalDateTime

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class GroupMemberFilterIntegrationTest {
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

    private lateinit var parentGroup: Group
    private lateinit var subGroup1: Group
    private lateinit var subGroup2: Group

    private lateinit var leaderRole: GroupRole
    private lateinit var professorRole: GroupRole
    private lateinit var memberRole: GroupRole

    private lateinit var leader: User
    private lateinit var professor: User
    private lateinit var student1: User // 1학년, 25학번
    private lateinit var student2: User // 2학년, 24학번
    private lateinit var student3: User // 3학년, 23학번

    @BeforeEach
    fun setUp() {
        // 사용자 생성
        leader =
            userRepository.save(
                User(
                    name = "그룹장",
                    email = "leader@test.com",
                    password = "password",
                    globalRole = GlobalRole.STUDENT,
                    academicYear = 4,
                    studentNo = "20220001",
                    college = "AI/SW계열",
                    department = "AI/SW학과",
                    profileCompleted = true,
                ),
            )

        professor =
            userRepository.save(
                User(
                    name = "교수님",
                    email = "prof@test.com",
                    password = "password",
                    globalRole = GlobalRole.PROFESSOR,
                    academicYear = null,
                    studentNo = null,
                    college = "AI/SW계열",
                    department = "AI/SW학과",
                    profileCompleted = true,
                ),
            )

        student1 =
            userRepository.save(
                User(
                    name = "학생1",
                    email = "student1@test.com",
                    password = "password",
                    globalRole = GlobalRole.STUDENT,
                    academicYear = 1,
                    studentNo = "20250001",
                    college = "AI/SW계열",
                    department = "AI/SW학과",
                    profileCompleted = true,
                ),
            )

        student2 =
            userRepository.save(
                User(
                    name = "학생2",
                    email = "student2@test.com",
                    password = "password",
                    globalRole = GlobalRole.STUDENT,
                    academicYear = 2,
                    studentNo = "20240002",
                    college = "AI/SW계열",
                    department = "AI/SW학과",
                    profileCompleted = true,
                ),
            )

        student3 =
            userRepository.save(
                User(
                    name = "학생3",
                    email = "student3@test.com",
                    password = "password",
                    globalRole = GlobalRole.STUDENT,
                    academicYear = 3,
                    studentNo = "20230003",
                    college = "AI/SW계열",
                    department = "AI/SW학과",
                    profileCompleted = true,
                ),
            )

        // 그룹 생성
        parentGroup =
            groupRepository.save(
                Group(
                    name = "AI학과",
                    description = "AI학과 전체",
                    groupType = GroupType.DEPARTMENT,
                    owner = leader,
                    university = "한신대학교",
                    college = "AI/SW계열",
                    department = "AI학과",
                ),
            )

        subGroup1 =
            groupRepository.save(
                Group(
                    name = "AI 학회",
                    description = "AI 학회",
                    groupType = GroupType.OFFICIAL,
                    owner = leader,
                    parent = parentGroup,
                    university = "한신대학교",
                    college = "AI/SW계열",
                    department = "AI학과",
                ),
            )

        subGroup2 =
            groupRepository.save(
                Group(
                    name = "프로그래밍 동아리",
                    description = "프로그래밍 동아리",
                    groupType = GroupType.AUTONOMOUS,
                    owner = leader,
                    parent = parentGroup,
                    university = "한신대학교",
                    college = "AI/SW계열",
                    department = "AI학과",
                ),
            )

        // 역할 생성
        leaderRole =
            groupRoleRepository.save(
                GroupRole(
                    group = parentGroup,
                    name = "그룹장",
                    priority = 100,
                    permissions = mutableSetOf(),
                ),
            )

        professorRole =
            groupRoleRepository.save(
                GroupRole(
                    group = parentGroup,
                    name = "교수",
                    priority = 90,
                    permissions = mutableSetOf(),
                ),
            )

        memberRole =
            groupRoleRepository.save(
                GroupRole(
                    group = parentGroup,
                    name = "멤버",
                    priority = 10,
                    permissions = mutableSetOf(),
                ),
            )

        // 멤버 추가 (부모 그룹)
        groupMemberRepository.save(
            GroupMember(
                group = parentGroup,
                user = leader,
                role = leaderRole,
                joinedAt = LocalDateTime.now(),
            ),
        )

        groupMemberRepository.save(
            GroupMember(
                group = parentGroup,
                user = professor,
                role = professorRole,
                joinedAt = LocalDateTime.now(),
            ),
        )

        groupMemberRepository.save(
            GroupMember(
                group = parentGroup,
                user = student1,
                role = memberRole,
                joinedAt = LocalDateTime.now(),
            ),
        )

        groupMemberRepository.save(
            GroupMember(
                group = parentGroup,
                user = student2,
                role = memberRole,
                joinedAt = LocalDateTime.now(),
            ),
        )

        groupMemberRepository.save(
            GroupMember(
                group = parentGroup,
                user = student3,
                role = memberRole,
                joinedAt = LocalDateTime.now(),
            ),
        )

        // 하위 그룹 멤버 추가
        val subGroup1LeaderRole =
            groupRoleRepository.save(
                GroupRole(
                    group = subGroup1,
                    name = "그룹장",
                    priority = 100,
                    permissions = mutableSetOf(),
                ),
            )
        val subGroup1MemberRole =
            groupRoleRepository.save(
                GroupRole(
                    group = subGroup1,
                    name = "멤버",
                    priority = 10,
                    permissions = mutableSetOf(),
                ),
            )
        groupMemberRepository.save(
            GroupMember(
                group = subGroup1,
                user = leader,
                role = subGroup1LeaderRole,
                joinedAt = LocalDateTime.now(),
            ),
        )
        groupMemberRepository.save(
            GroupMember(
                group = subGroup1,
                user = student1,
                role = subGroup1MemberRole,
                joinedAt = LocalDateTime.now(),
            ),
        )

        val subGroup2LeaderRole =
            groupRoleRepository.save(
                GroupRole(
                    group = subGroup2,
                    name = "그룹장",
                    priority = 100,
                    permissions = mutableSetOf(),
                ),
            )
        val subGroup2MemberRole =
            groupRoleRepository.save(
                GroupRole(
                    group = subGroup2,
                    name = "멤버",
                    priority = 10,
                    permissions = mutableSetOf(),
                ),
            )
        groupMemberRepository.save(
            GroupMember(
                group = subGroup2,
                user = leader,
                role = subGroup2LeaderRole,
                joinedAt = LocalDateTime.now(),
            ),
        )
        groupMemberRepository.save(
            GroupMember(
                group = subGroup2,
                user = student2,
                role = subGroup2MemberRole,
                joinedAt = LocalDateTime.now(),
            ),
        )
    }

    @Test
    @DisplayName("필터 없이 전체 멤버 조회")
    fun testGetAllMembers() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = null,
                groupIds = null,
                grades = null,
                years = null,
                pageable = pageable,
            )

        // then
        assertThat(result.content).hasSize(5)
        assertThat(result.content.map { it.user.name })
            .containsExactlyInAnyOrder("그룹장", "교수님", "학생1", "학생2", "학생3")
    }

    @Test
    @DisplayName("역할 필터: 그룹장만 조회")
    fun testFilterByRole_Leader() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = leaderRole.id.toString(),
                groupIds = null,
                grades = null,
                years = null,
                pageable = pageable,
            )

        // then
        assertThat(result.content).hasSize(1)
        assertThat(result.content[0].user.name).isEqualTo("그룹장")
        assertThat(result.content[0].role.name).isEqualTo("그룹장")
    }

    @Test
    @DisplayName("역할 필터: 그룹장 OR 교수 조회")
    fun testFilterByRole_LeaderOrProfessor() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = "${leaderRole.id},${professorRole.id}",
                groupIds = null,
                grades = null,
                years = null,
                pageable = pageable,
            )

        // then
        assertThat(result.content).hasSize(2)
        assertThat(result.content.map { it.user.name })
            .containsExactlyInAnyOrder("그룹장", "교수님")
    }

    @Test
    @DisplayName("역할 필터는 다른 필터 무시 (단독 동작)")
    fun testFilterByRole_IgnoresOtherFilters() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = leaderRole.id.toString(),
                groupIds = "${subGroup1.id}",
                grades = "1,2",
                years = "24,25",
                pageable = pageable,
            )

        // then
        // 역할 필터만 적용되고 다른 필터는 무시됨
        assertThat(result.content).hasSize(1)
        assertThat(result.content[0].user.name).isEqualTo("그룹장")
    }

    @Test
    @DisplayName("학년 필터: 2학년만 조회")
    fun testFilterByGrade_2ndYear() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = null,
                groupIds = null,
                grades = "2",
                years = null,
                pageable = pageable,
            )

        // then
        assertThat(result.content).hasSize(1)
        assertThat(result.content[0].user.name).isEqualTo("학생2")
        assertThat(result.content[0].user.academicYear).isEqualTo(2)
    }

    @Test
    @DisplayName("학년 필터: 1학년 OR 2학년 조회")
    fun testFilterByGrade_1stOr2ndYear() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = null,
                groupIds = null,
                grades = "1,2",
                years = null,
                pageable = pageable,
            )

        // then
        assertThat(result.content).hasSize(2)
        assertThat(result.content.map { it.user.name })
            .containsExactlyInAnyOrder("학생1", "학생2")
    }

    @Test
    @DisplayName("학번 필터: 24학번만 조회")
    fun testFilterByYear_2024() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = null,
                groupIds = null,
                grades = null,
                years = "24",
                pageable = pageable,
            )

        // then
        assertThat(result.content).hasSize(1)
        assertThat(result.content[0].user.name).isEqualTo("학생2")
        assertThat(result.content[0].user.studentNo).startsWith("2024")
    }

    @Test
    @DisplayName("학년/학번 필터: 1학년 OR 24학번 (OR 관계)")
    fun testFilterByGradeOrYear() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = null,
                groupIds = null,
                grades = "1",
                years = "24",
                pageable = pageable,
            )

        // then
        // 1학년(학생1) OR 24학번(학생2) = 2명
        assertThat(result.content).hasSize(2)
        assertThat(result.content.map { it.user.name })
            .containsExactlyInAnyOrder("학생1", "학생2")
    }

    @Test
    @DisplayName("소속 그룹 필터: AI 학회 소속 멤버만 조회")
    fun testFilterBySubGroup_AIClub() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = null,
                groupIds = subGroup1.id.toString(),
                grades = null,
                years = null,
                pageable = pageable,
            )

        // then
        // AI 학회 멤버: 그룹장, 학생1
        assertThat(result.content).hasSize(2)
        assertThat(result.content.map { it.user.name })
            .containsExactlyInAnyOrder("그룹장", "학생1")
    }

    @Test
    @DisplayName("소속 그룹 필터: AI 학회 OR 프로그래밍 동아리 소속 멤버 조회")
    fun testFilterBySubGroup_AIClubOrProgrammingClub() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = null,
                groupIds = "${subGroup1.id},${subGroup2.id}",
                grades = null,
                years = null,
                pageable = pageable,
            )

        // then
        // AI 학회 OR 프로그래밍 동아리: 그룹장, 학생1, 학생2
        assertThat(result.content).hasSize(3)
        assertThat(result.content.map { it.user.name })
            .containsExactlyInAnyOrder("그룹장", "학생1", "학생2")
    }

    @Test
    @DisplayName("복합 필터: 소속 그룹(AI 학회) AND 학년(1학년)")
    fun testFilterBySubGroupAndGrade() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = null,
                groupIds = subGroup1.id.toString(),
                grades = "1",
                years = null,
                pageable = pageable,
            )

        // then
        // AI 학회 AND 1학년 = 학생1만
        assertThat(result.content).hasSize(1)
        assertThat(result.content[0].user.name).isEqualTo("학생1")
    }

    @Test
    @DisplayName("복합 필터: 소속 그룹(프로그래밍 동아리) AND (2학년 OR 3학년)")
    fun testFilterBySubGroupAndMultipleGrades() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = null,
                groupIds = subGroup2.id.toString(),
                grades = "2,3",
                years = null,
                pageable = pageable,
            )

        // then
        // 프로그래밍 동아리 AND (2학년 OR 3학년) = 학생2만 (학생3은 프로그래밍 동아리 아님)
        assertThat(result.content).hasSize(1)
        assertThat(result.content[0].user.name).isEqualTo("학생2")
    }

    @Test
    @DisplayName("복합 필터: 결과 없음")
    fun testFilterWithNoResults() {
        // given
        val pageable = PageRequest.of(0, 20)

        // when
        val result =
            groupMemberService.getGroupMembersWithFilter(
                groupId = parentGroup.id,
                roleIds = null,
                groupIds = subGroup1.id.toString(),
                // AI 학회에는 3학년이 없음
                grades = "3",
                years = null,
                pageable = pageable,
            )

        // then
        assertThat(result.content).isEmpty()
    }
}
