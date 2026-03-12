package com.univgroup.domain.content.repository

import com.univgroup.domain.content.entity.Comment
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface CommentRepository : JpaRepository<Comment, Long> {
    // ===== 게시글별 조회 =====

    @Query(
        """
        SELECT c FROM Comment c
        JOIN FETCH c.author
        WHERE c.post.id = :postId
        AND c.parentComment IS NULL
        ORDER BY c.createdAt ASC
        """,
    )
    fun findRootCommentsByPostId(
        @Param("postId") postId: Long,
        pageable: Pageable,
    ): Page<Comment>

    @Query(
        """
        SELECT c FROM Comment c
        JOIN FETCH c.author
        WHERE c.post.id = :postId
        ORDER BY c.createdAt ASC
        """,
    )
    fun findAllByPostIdWithAuthor(
        @Param("postId") postId: Long,
    ): List<Comment>

    // ===== 대댓글 조회 =====

    @Query(
        """
        SELECT c FROM Comment c
        JOIN FETCH c.author
        WHERE c.parentComment.id = :parentId
        ORDER BY c.createdAt ASC
        """,
    )
    fun findRepliesByParentId(
        @Param("parentId") parentId: Long,
    ): List<Comment>

    fun countByParentCommentId(parentId: Long): Long

    // ===== 작성자별 조회 =====

    fun findByAuthorId(
        authorId: Long,
        pageable: Pageable,
    ): Page<Comment>

    // ===== 삭제 =====

    fun deleteAllByPostId(postId: Long)

    // ===== 통계 =====

    fun countByPostId(postId: Long): Long

    fun countByAuthorId(authorId: Long): Long

    @Query(
        """
        SELECT c.post.id, COUNT(c)
        FROM Comment c
        WHERE c.post.id IN :postIds
        AND c.isDeleted = false
        GROUP BY c.post.id
        """,
    )
    fun countByPostIds(
        @Param("postIds") postIds: List<Long>,
    ): List<Array<Any>>
}
