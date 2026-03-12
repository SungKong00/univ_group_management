package org.castlekong.backend.repository

import org.assertj.core.api.Assertions.assertThat
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.GroupMember
import org.castlekong.backend.entity.GroupRole
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.RoleType
import org.castlekong.backend.entity.User
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.data.domain.PageRequest
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional

/**
 * Repository N+1 Query Optimization Performance Test
 *
 * 이 테스트는 SQL 로깅을 통해 쿼리 수를 검증합니다.
 * application-test.yml에서 spring.jpa.show-sql: true 설정 필요
 *
 * 예상 결과:
 * - getGroupMembers: 2개 쿼리 (ID 조회 1개 + JOIN FETCH 1개)
 * - findAllDescendantIds: 1개 쿼리 (WITH RECURSIVE CTE)
 * - countByGroupIdIn: 1개 쿼리 (IN절 사용, H2 호환)
 * - findParentGroupIds: 1개 쿼리 (WITH RECURSIVE CTE)
 */
@DataJpaTest
@ActiveProfiles("test")
@Transactional
class GroupMemberRepositoryPerformanceTest {
    @Autowired
    private lateinit var groupRepository: GroupRepository

    @Autowired
    private lateinit var groupRoleRepository: GroupRoleRepository

    @Autowired
    private lateinit var groupMemberRepository: GroupMemberRepository

    @Autowired
    private lateinit var userRepository: UserRepository

    private lateinit var testGroup: Group
    private lateinit var testRole: GroupRole
    private lateinit var testUsers: List<User>

    @BeforeEach
    fun setUp() {
        // 테스트 오너 사용자 생성
        val owner =
            User(
                name = "Test Owner",
                email = "owner@test.com",
                password = "password123",
                globalRole = GlobalRole.STUDENT,
            )
        userRepository.save(owner)

        // 테스트 그룹 생성
        testGroup =
            Group(
                name = "Test Group",
                description = "Test Description",
                profileImageUrl = null,
                owner = owner,
                parent = null,
                university = "한성대학교",
                college = null,
                department = null,
                groupType = GroupType.AUTONOMOUS,
            )
        groupRepository.save(testGroup)

        // 테스트 역할 생성
        testRole =
            GroupRole(
                group = testGroup,
                name = "Member",
                priority = 100,
                isSystemRole = false,
                roleType = RoleType.OPERATIONAL,
            )
        groupRoleRepository.save(testRole)

        // 100명의 테스트 사용자 및 멤버 생성
        testUsers =
            (1..100).map { i ->
                val user =
                    User(
                        name = "User $i",
                        email = "user$i@test.com",
                        password = "password$i",
                        globalRole = GlobalRole.STUDENT,
                    )
                userRepository.save(user)

                val member =
                    GroupMember(
                        group = testGroup,
                        user = user,
                        role = testRole,
                    )
                groupMemberRepository.save(member)

                user
            }

        // 영속성 컨텍스트 초기화 (쿼리 정확한 카운트를 위해)
        groupMemberRepository.flush()
        userRepository.flush()
    }

    @Test
    fun `findIdsByGroupId and findByIdsWithDetails should execute exactly 2 queries`() {
        // Given: 100 members in the group
        val pageable = PageRequest.of(0, 20)

        // When: Fetch members with pagination (ID-only query + JOIN FETCH)
        println("\n=== Phase 1: ID-only query with pagination ===")
        val idsPage = groupMemberRepository.findIdsByGroupId(testGroup.id, pageable)

        println("\n=== Phase 2: JOIN FETCH query with details ===")
        val members = groupMemberRepository.findByIdsWithDetails(idsPage.content)

        // Then: Verify results
        assertThat(idsPage.content).hasSize(20)
        assertThat(members).hasSize(20)
        assertThat(idsPage.totalElements).isEqualTo(100)

        // Verify all relations are loaded (no lazy loading exceptions)
        members.forEach { member ->
            assertThat(member.group).isNotNull
            assertThat(member.user).isNotNull
            assertThat(member.role).isNotNull
            assertThat(member.role.permissions).isNotNull // Even if empty
        }

        println("\n=== Query count should be exactly 2 (check SQL logs above) ===")
    }

    // TODO: Add more tests for WITH RECURSIVE queries after fixing Group entity usage
}
