package com.univgroup.domain.content.repository

import com.univgroup.domain.content.entity.Post
import com.univgroup.domain.content.entity.PostType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface PostRepository : JpaRepository<Post, Long> {
    // ===== 채널별 조회 =====

    fun findByChannelId(
        channelId: Long,
        pageable: Pageable,
    ): Page<Post>

    @Query(
        """
        SELECT p FROM Post p
        JOIN FETCH p.author
        WHERE p.channel.id = :channelId
        ORDER BY p.isPinned DESC, p.createdAt DESC
        """,
    )
    fun findByChannelIdWithAuthor(
        @Param("channelId") channelId: Long,
        pageable: Pageable,
    ): Page<Post>

    // ===== 유형별 조회 =====

    fun findByChannelIdAndType(
        channelId: Long,
        type: PostType,
        pageable: Pageable,
    ): Page<Post>

    @Query(
        """
        SELECT p FROM Post p
        WHERE p.channel.id = :channelId
        AND p.isPinned = true
        ORDER BY p.createdAt DESC
        """,
    )
    fun findPinnedPosts(
        @Param("channelId") channelId: Long,
    ): List<Post>

    // ===== 작성자별 조회 =====

    fun findByAuthorId(
        authorId: Long,
        pageable: Pageable,
    ): Page<Post>

    @Query(
        """
        SELECT p FROM Post p
        JOIN FETCH p.channel
        WHERE p.author.id = :authorId
        ORDER BY p.createdAt DESC
        """,
    )
    fun findByAuthorIdWithChannel(
        @Param("authorId") authorId: Long,
        pageable: Pageable,
    ): Page<Post>

    // ===== 검색 =====

    @Query(
        """
        SELECT p FROM Post p
        WHERE p.channel.id = :channelId
        AND LOWER(p.content) LIKE LOWER(CONCAT('%', :keyword, '%'))
        ORDER BY p.createdAt DESC
        """,
    )
    fun searchInChannel(
        @Param("channelId") channelId: Long,
        @Param("keyword") keyword: String,
        pageable: Pageable,
    ): Page<Post>

    // ===== 조회수 증가 =====

    @Modifying
    @Query("UPDATE Post p SET p.viewCount = p.viewCount + 1 WHERE p.id = :postId")
    fun incrementViewCount(
        @Param("postId") postId: Long,
    )

    // ===== 삭제 =====

    fun deleteAllByChannelId(channelId: Long)

    // ===== 통계 =====

    fun countByChannelId(channelId: Long): Long

    fun countByAuthorId(authorId: Long): Long
}
