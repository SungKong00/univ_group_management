package com.univgroup.domain.content.entity

import com.univgroup.domain.user.entity.User
import com.univgroup.domain.workspace.entity.Channel
import com.univgroup.domain.workspace.entity.Workspace
import com.univgroup.domain.group.entity.Group
import io.mockk.mockk
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import java.time.LocalDateTime

/**
 * Post Entity 단위 테스트
 *
 * 검증 항목:
 * - incrementCommentCount: 댓글 수 증가 및 lastCommentedAt 업데이트
 * - decrementCommentCount: 댓글 수 감소 (0 이하로 내려가지 않음)
 */
@DisplayName("Post Entity 단위 테스트")
class PostTest {

    private lateinit var testPost: Post
    private lateinit var testChannel: Channel
    private lateinit var testAuthor: User

    @BeforeEach
    fun setUp() {
        // Mock 객체 생성 (연관 Entity는 Mock으로 처리)
        testChannel = mockk(relaxed = true)
        testAuthor = mockk(relaxed = true)

        // 테스트용 Post 생성
        testPost = Post(
            id = 1L,
            channel = testChannel,
            author = testAuthor,
            content = "테스트 게시글 내용",
            type = PostType.GENERAL,
            commentCount = 0,
            lastCommentedAt = null
        )
    }

    @Test
    @DisplayName("incrementCommentCount: 댓글 수가 1 증가해야 한다")
    fun `incrementCommentCount should increase comment count by 1`() {
        // Given
        val initialCount = testPost.commentCount

        // When
        testPost.incrementCommentCount()

        // Then
        assertThat(testPost.commentCount).isEqualTo(initialCount + 1)
    }

    @Test
    @DisplayName("incrementCommentCount: lastCommentedAt이 현재 시간으로 업데이트되어야 한다")
    fun `incrementCommentCount should update lastCommentedAt to current time`() {
        // Given
        val beforeCall = LocalDateTime.now()

        // When
        testPost.incrementCommentCount()

        // Then
        assertThat(testPost.lastCommentedAt).isNotNull
        assertThat(testPost.lastCommentedAt).isAfterOrEqualTo(beforeCall)
        assertThat(testPost.lastCommentedAt).isBeforeOrEqualTo(LocalDateTime.now())
    }

    @Test
    @DisplayName("incrementCommentCount: 여러 번 호출 시 누적 증가해야 한다")
    fun `incrementCommentCount should accumulate when called multiple times`() {
        // Given
        val initialCount = testPost.commentCount

        // When
        testPost.incrementCommentCount()
        testPost.incrementCommentCount()
        testPost.incrementCommentCount()

        // Then
        assertThat(testPost.commentCount).isEqualTo(initialCount + 3)
    }

    @Test
    @DisplayName("incrementCommentCount: lastCommentedAt이 null에서 업데이트되어야 한다")
    fun `incrementCommentCount should update lastCommentedAt from null`() {
        // Given
        assertThat(testPost.lastCommentedAt).isNull()

        // When
        testPost.incrementCommentCount()

        // Then
        assertThat(testPost.lastCommentedAt).isNotNull
    }

    @Test
    @DisplayName("decrementCommentCount: 댓글 수가 1 감소해야 한다")
    fun `decrementCommentCount should decrease comment count by 1`() {
        // Given
        testPost.commentCount = 5

        // When
        testPost.decrementCommentCount()

        // Then
        assertThat(testPost.commentCount).isEqualTo(4)
    }

    @Test
    @DisplayName("decrementCommentCount: 댓글 수가 0일 때 감소하지 않아야 한다")
    fun `decrementCommentCount should not go below zero`() {
        // Given
        testPost.commentCount = 0

        // When
        testPost.decrementCommentCount()

        // Then
        assertThat(testPost.commentCount).isEqualTo(0)
    }

    @Test
    @DisplayName("decrementCommentCount: 댓글 수가 1일 때 0으로 감소해야 한다")
    fun `decrementCommentCount should decrease to zero from 1`() {
        // Given
        testPost.commentCount = 1

        // When
        testPost.decrementCommentCount()

        // Then
        assertThat(testPost.commentCount).isEqualTo(0)
    }

    @Test
    @DisplayName("decrementCommentCount: 여러 번 호출 시 0 이하로 내려가지 않아야 한다")
    fun `decrementCommentCount should not go negative even when called multiple times`() {
        // Given
        testPost.commentCount = 1

        // When
        testPost.decrementCommentCount()
        testPost.decrementCommentCount()
        testPost.decrementCommentCount()

        // Then
        assertThat(testPost.commentCount).isEqualTo(0)
    }

    @Test
    @DisplayName("incrementCommentCount & decrementCommentCount: 교차 호출 시 올바르게 동작해야 한다")
    fun `incrementCommentCount and decrementCommentCount should work correctly when interleaved`() {
        // Given
        testPost.commentCount = 0

        // When
        testPost.incrementCommentCount() // 1
        testPost.incrementCommentCount() // 2
        testPost.decrementCommentCount() // 1
        testPost.incrementCommentCount() // 2
        testPost.decrementCommentCount() // 1
        testPost.decrementCommentCount() // 0

        // Then
        assertThat(testPost.commentCount).isEqualTo(0)
    }
}
