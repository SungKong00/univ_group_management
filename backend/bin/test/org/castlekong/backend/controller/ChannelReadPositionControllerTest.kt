package org.castlekong.backend.controller

import com.fasterxml.jackson.databind.ObjectMapper
import org.castlekong.backend.dto.UpdateReadPositionRequest
import org.castlekong.backend.entity.Channel
import org.castlekong.backend.entity.ChannelType
import org.castlekong.backend.entity.GlobalRole
import org.castlekong.backend.entity.Group
import org.castlekong.backend.entity.Post
import org.castlekong.backend.entity.PostType
import org.castlekong.backend.entity.User
import org.castlekong.backend.fixture.TestDataFactory
import org.castlekong.backend.repository.ChannelReadPositionRepository
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.GroupRepository
import org.castlekong.backend.repository.GroupRoleRepository
import org.castlekong.backend.repository.PostRepository
import org.castlekong.backend.repository.UserRepository
import org.castlekong.backend.security.JwtTokenProvider
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put
import org.springframework.test.web.servlet.result.MockMvcResultHandlers.print
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.transaction.annotation.Transactional

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("ChannelReadPositionController 통합 테스트")
class ChannelReadPositionControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Autowired
    private lateinit var jwtTokenProvider: JwtTokenProvider

    @Autowired
    private lateinit var userRepository: UserRepository

    @Autowired
    private lateinit var groupRepository: GroupRepository

    @Autowired
    private lateinit var groupRoleRepository: GroupRoleRepository

    @Autowired
    private lateinit var groupMemberRepository: GroupMemberRepository

    @Autowired
    private lateinit var channelRepository: ChannelRepository

    @Autowired
    private lateinit var postRepository: PostRepository

    @Autowired
    private lateinit var readPositionRepository: ChannelReadPositionRepository

    @Autowired
    private lateinit var groupInitializationRunner: org.castlekong.backend.runner.GroupInitializationRunner

    // Test data
    private lateinit var owner: User
    private lateinit var member: User
    private lateinit var outsider: User
    private lateinit var group: Group
    private lateinit var channel: Channel
    private lateinit var ownerToken: String
    private lateinit var memberToken: String
    private lateinit var outsiderToken: String
    private lateinit var post1: Post
    private lateinit var post2: Post
    private lateinit var post3: Post

    @BeforeEach
    fun setUp() {
        val suffix = System.nanoTime().toString()

        // Create users
        val ownerBase =
            TestDataFactory.createTestUser(
                name = "그룹장",
                email = "owner-read+$suffix@example.com",
                globalRole = GlobalRole.STUDENT,
            )
        owner =
            userRepository.save(
                User(
                    id = ownerBase.id,
                    name = ownerBase.name,
                    email = ownerBase.email,
                    password = ownerBase.password,
                    globalRole = ownerBase.globalRole,
                    isActive = ownerBase.isActive,
                    nickname = ownerBase.nickname,
                    profileImageUrl = ownerBase.profileImageUrl,
                    bio = ownerBase.bio,
                    profileCompleted = true,
                    emailVerified = ownerBase.emailVerified,
                    college = ownerBase.college,
                    department = ownerBase.department,
                    studentNo = ownerBase.studentNo,
                    schoolEmail = ownerBase.schoolEmail,
                    professorStatus = ownerBase.professorStatus,
                    academicYear = ownerBase.academicYear,
                    createdAt = ownerBase.createdAt,
                    updatedAt = ownerBase.updatedAt,
                ),
            )

        member =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "멤버",
                    email = "member-read+$suffix@example.com",
                ),
            )

        outsider =
            userRepository.save(
                TestDataFactory.createStudentUser(
                    name = "외부인",
                    email = "outsider-read+$suffix@example.com",
                ),
            )

        // Create group and roles
        group = createGroupWithRoles(owner)
        val memberRole = groupRoleRepository.findByGroupIdAndName(group.id, "멤버").get()

        // Add member to group
        groupMemberRepository.save(
            TestDataFactory.createTestGroupMember(
                group = group,
                user = member,
                role = memberRole,
            ),
        )

        // Get auto-generated channel (TEXT type with member permissions)
        val autoGeneratedChannels = channelRepository.findByGroup_Id(group.id)
        channel =
            autoGeneratedChannels.firstOrNull { ch -> ch.type == ChannelType.TEXT }
                ?: throw IllegalStateException("Auto-generated TEXT channel not found")

        // Create test posts
        post1 =
            postRepository.save(
                Post(
                    channel = channel,
                    author = owner,
                    content = "첫 번째 게시글",
                    type = PostType.GENERAL,
                ),
            )

        post2 =
            postRepository.save(
                Post(
                    channel = channel,
                    author = owner,
                    content = "두 번째 게시글",
                    type = PostType.GENERAL,
                ),
            )

        post3 =
            postRepository.save(
                Post(
                    channel = channel,
                    author = owner,
                    content = "세 번째 게시글",
                    type = PostType.GENERAL,
                ),
            )

        // Generate JWT tokens
        ownerToken = generateToken(owner)
        memberToken = generateToken(member)
        outsiderToken = generateToken(outsider)
    }

    private fun createGroupWithRoles(owner: User): Group {
        val groupBase =
            TestDataFactory.createTestGroup(
                name = "테스트 그룹 ${System.nanoTime()}",
                owner = owner,
            )
        val savedGroup = groupRepository.save(groupBase)
        groupInitializationRunner.initializeGroup(savedGroup)
        return groupRepository.findById(savedGroup.id).get()
    }

    private fun generateToken(user: User): String {
        val authentication =
            UsernamePasswordAuthenticationToken(
                user.email,
                null,
                listOf(org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_${user.globalRole.name}")),
            )
        return jwtTokenProvider.generateAccessToken(authentication)
    }

    @Nested
    @DisplayName("GET /api/channels/{channelId}/read-position")
    inner class GetReadPosition {
        @Test
        @DisplayName("읽음 위치가 없는 경우 null 반환")
        fun shouldReturnNullWhenNoReadPosition() {
            mockMvc
                .perform(
                    get("/api/channels/${channel.id}/read-position")
                        .header("Authorization", "Bearer $memberToken"),
                ).andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isEmpty)
        }

        @Test
        @DisplayName("읽음 위치 조회 성공")
        fun shouldReturnReadPosition() {
            // Given: 읽음 위치 저장
            val request = UpdateReadPositionRequest(lastReadPostId = post2.id)
            mockMvc
                .perform(
                    put("/api/channels/${channel.id}/read-position")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)),
                ).andExpect(status().isOk)

            // When & Then: 읽음 위치 조회
            mockMvc
                .perform(
                    get("/api/channels/${channel.id}/read-position")
                        .header("Authorization", "Bearer $memberToken"),
                ).andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.lastReadPostId").value(post2.id))
                .andExpect(jsonPath("$.data.updatedAt").exists())
        }

        @Test
        @DisplayName("권한 없는 채널 접근 시 403 Forbidden")
        fun shouldReturn403WhenNoAccess() {
            mockMvc
                .perform(
                    get("/api/channels/${channel.id}/read-position")
                        .header("Authorization", "Bearer $outsiderToken"),
                ).andDo(print())
                .andExpect(status().isForbidden)
        }
    }

    @Nested
    @DisplayName("PUT /api/channels/{channelId}/read-position")
    inner class UpdateReadPosition {
        @Test
        @DisplayName("읽음 위치 업데이트 성공")
        fun shouldUpdateReadPosition() {
            val request = UpdateReadPositionRequest(lastReadPostId = post2.id)

            mockMvc
                .perform(
                    put("/api/channels/${channel.id}/read-position")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)),
                ).andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))

            // Verify saved in database
            val saved = readPositionRepository.findByUserIdAndChannelId(member.id, channel.id)
            assert(saved != null)
            assert(saved!!.lastReadPostId == post2.id)
        }

        @Test
        @DisplayName("읽음 위치 재업데이트 성공")
        fun shouldReUpdateReadPosition() {
            // First update
            val request1 = UpdateReadPositionRequest(lastReadPostId = post1.id)
            mockMvc
                .perform(
                    put("/api/channels/${channel.id}/read-position")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request1)),
                ).andExpect(status().isOk)

            // Second update
            val request2 = UpdateReadPositionRequest(lastReadPostId = post3.id)
            mockMvc
                .perform(
                    put("/api/channels/${channel.id}/read-position")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request2)),
                ).andDo(print())
                .andExpect(status().isOk)

            // Verify updated
            val saved = readPositionRepository.findByUserIdAndChannelId(member.id, channel.id)
            assert(saved != null)
            assert(saved!!.lastReadPostId == post3.id)
        }

        @Test
        @DisplayName("권한 없는 채널 접근 시 403 Forbidden")
        fun shouldReturn403WhenNoAccess() {
            val request = UpdateReadPositionRequest(lastReadPostId = post1.id)

            mockMvc
                .perform(
                    put("/api/channels/${channel.id}/read-position")
                        .header("Authorization", "Bearer $outsiderToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)),
                ).andDo(print())
                .andExpect(status().isForbidden)
        }
    }

    @Nested
    @DisplayName("GET /api/channels/{channelId}/unread-count")
    inner class GetUnreadCount {
        @Test
        @DisplayName("첫 방문 시 전체 게시글 개수 반환")
        fun shouldReturnTotalCountOnFirstVisit() {
            mockMvc
                .perform(
                    get("/api/channels/${channel.id}/unread-count")
                        .header("Authorization", "Bearer $memberToken"),
                ).andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").value(3)) // post1, post2, post3
        }

        @Test
        @DisplayName("읽음 위치 이후 게시글 개수 반환")
        fun shouldReturnUnreadCount() {
            // Given: post1까지 읽음
            val request = UpdateReadPositionRequest(lastReadPostId = post1.id)
            mockMvc
                .perform(
                    put("/api/channels/${channel.id}/read-position")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)),
                ).andExpect(status().isOk)

            // When & Then: 읽지 않은 글 2개 (post2, post3)
            mockMvc
                .perform(
                    get("/api/channels/${channel.id}/unread-count")
                        .header("Authorization", "Bearer $memberToken"),
                ).andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").value(2))
        }

        @Test
        @DisplayName("모두 읽은 경우 0 반환")
        fun shouldReturnZeroWhenAllRead() {
            // Given: 마지막 게시글까지 읽음
            val request = UpdateReadPositionRequest(lastReadPostId = post3.id)
            mockMvc
                .perform(
                    put("/api/channels/${channel.id}/read-position")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)),
                ).andExpect(status().isOk)

            // When & Then: 읽지 않은 글 0개
            mockMvc
                .perform(
                    get("/api/channels/${channel.id}/unread-count")
                        .header("Authorization", "Bearer $memberToken"),
                ).andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").value(0))
        }
    }

    @Nested
    @DisplayName("GET /api/channels/unread-counts")
    inner class GetUnreadCounts {
        private lateinit var channel2: Channel

        @BeforeEach
        fun setUpChannel2() {
            // Create second channel
            val autoGeneratedChannels = channelRepository.findByGroup_Id(group.id)
            channel2 =
                autoGeneratedChannels.firstOrNull { ch -> ch.type == ChannelType.ANNOUNCEMENT }
                    ?: throw IllegalStateException("Auto-generated ANNOUNCEMENT channel not found")
        }

        @Test
        @DisplayName("여러 채널의 읽지 않은 글 개수 일괄 조회")
        fun shouldReturnUnreadCountsForMultipleChannels() {
            // Given: channel1에 post1까지 읽음
            val request1 = UpdateReadPositionRequest(lastReadPostId = post1.id)
            mockMvc
                .perform(
                    put("/api/channels/${channel.id}/read-position")
                        .header("Authorization", "Bearer $memberToken")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request1)),
                ).andExpect(status().isOk)

            // When & Then: 2개 채널 일괄 조회
            mockMvc
                .perform(
                    get("/api/channels/unread-counts?channelIds=${channel.id},${channel2.id}")
                        .header("Authorization", "Bearer $memberToken"),
                ).andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray)
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[?(@.channelId == ${channel.id})].unreadCount").value(2)) // post2, post3
                .andExpect(jsonPath("$.data[?(@.channelId == ${channel2.id})].unreadCount").value(0)) // no posts
        }

        @Test
        @DisplayName("접근 불가한 채널은 필터링됨")
        fun shouldFilterInaccessibleChannels() {
            // When: outsider가 채널 조회 시도
            mockMvc
                .perform(
                    get("/api/channels/unread-counts?channelIds=${channel.id},${channel2.id}")
                        .header("Authorization", "Bearer $outsiderToken"),
                ).andDo(print())
                .andExpect(status().isOk)
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray)
                .andExpect(jsonPath("$.data.length()").value(0)) // 접근 불가하므로 빈 배열
        }
    }
}
