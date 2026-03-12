package com.univgroup.domain.content.entity

import com.univgroup.domain.user.entity.User
import io.mockk.mockk
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import java.time.LocalDateTime

/**
 * Comment Entity 단위 테스트
 *
 * 검증 항목:
 * - softDelete: 댓글 삭제 처리 (isDeleted=true, content 변경, updatedAt 갱신)
 * - getReplyCount: 대댓글 수 조회 (현재는 0 반환)
 */
@DisplayName("Comment Entity 단위 테스트")
class CommentTest {

    private lateinit var testComment: Comment
    private lateinit var testPost: Post
    private lateinit var testAuthor: User

    @BeforeEach
    fun setUp() {
        // Mock 객체 생성
        testPost = mockk(relaxed = true)
        testAuthor = mockk(relaxed = true)

        // 테스트용 Comment 생성
        testComment = Comment(
            id = 1L,
            post = testPost,
            author = testAuthor,
            content = "원본 댓글 내용",
            isDeleted = false
        )
    }

    @Test
    @DisplayName("softDelete: isDeleted가 true로 변경되어야 한다")
    fun `softDelete should set isDeleted to true`() {
        // Given
        assertThat(testComment.isDeleted).isFalse

        // When
        testComment.softDelete()

        // Then
        assertThat(testComment.isDeleted).isTrue
    }

    @Test
    @DisplayName("softDelete: content가 삭제 메시지로 변경되어야 한다")
    fun `softDelete should replace content with deleted message`() {
        // Given
        val originalContent = testComment.content

        // When
        testComment.softDelete()

        // Then
        assertThat(testComment.content).isNotEqualTo(originalContent)
        assertThat(testComment.content).isEqualTo("[삭제된 댓글입니다]")
    }

    @Test
    @DisplayName("softDelete: updatedAt이 현재 시간으로 갱신되어야 한다")
    fun `softDelete should update updatedAt to current time`() {
        // Given
        val beforeDelete = LocalDateTime.now()
        Thread.sleep(10) // 시간 차이 보장

        // When
        testComment.softDelete()

        // Then
        assertThat(testComment.updatedAt).isAfterOrEqualTo(beforeDelete)
        assertThat(testComment.updatedAt).isBeforeOrEqualTo(LocalDateTime.now())
    }

    @Test
    @DisplayName("softDelete: 여러 번 호출해도 안전해야 한다")
    fun `softDelete should be idempotent when called multiple times`() {
        // When
        testComment.softDelete()
        val firstUpdatedAt = testComment.updatedAt
        Thread.sleep(10) // 시간 차이 보장
        testComment.softDelete()

        // Then
        assertThat(testComment.isDeleted).isTrue
        assertThat(testComment.content).isEqualTo("[삭제된 댓글입니다]")
        assertThat(testComment.updatedAt).isAfterOrEqualTo(firstUpdatedAt)
    }

    @Test
    @DisplayName("softDelete: 삭제 전후 모든 필드가 올바르게 변경되어야 한다")
    fun `softDelete should correctly update all related fields`() {
        // Given
        assertThat(testComment.isDeleted).isFalse
        assertThat(testComment.content).isEqualTo("원본 댓글 내용")

        // When
        testComment.softDelete()

        // Then
        assertThat(testComment.isDeleted).isTrue
        assertThat(testComment.content).isEqualTo("[삭제된 댓글입니다]")
        assertThat(testComment.updatedAt).isNotNull
    }

    @Test
    @DisplayName("getReplyCount: 기본값으로 0을 반환해야 한다")
    fun `getReplyCount should return zero by default`() {
        // When
        val replyCount = testComment.getReplyCount()

        // Then
        assertThat(replyCount).isEqualTo(0L)
    }

    @Test
    @DisplayName("getReplyCount: 삭제된 댓글도 0을 반환해야 한다")
    fun `getReplyCount should return zero even for deleted comment`() {
        // Given
        testComment.softDelete()

        // When
        val replyCount = testComment.getReplyCount()

        // Then
        assertThat(replyCount).isEqualTo(0L)
    }

    @Test
    @DisplayName("생성자: 기본값이 올바르게 설정되어야 한다")
    fun `constructor should set default values correctly`() {
        // Given & When
        val newComment = Comment(
            post = testPost,
            author = testAuthor,
            content = "새 댓글"
        )

        // Then
        assertThat(newComment.isDeleted).isFalse
        assertThat(newComment.likeCount).isEqualTo(0L)
        assertThat(newComment.parentComment).isNull()
        assertThat(newComment.createdAt).isNotNull
        assertThat(newComment.updatedAt).isNotNull
    }

    @Test
    @DisplayName("softDelete: 원본 내용이 한글/영문/이모지 혼합이어도 정상 처리되어야 한다")
    fun `softDelete should work with unicode content including emoji`() {
        // Given
        val unicodeComment = Comment(
            post = testPost,
            author = testAuthor,
            content = "안녕하세요! Hello 👋 こんにちは"
        )

        // When
        unicodeComment.softDelete()

        // Then
        assertThat(unicodeComment.isDeleted).isTrue
        assertThat(unicodeComment.content).isEqualTo("[삭제된 댓글입니다]")
    }
}
