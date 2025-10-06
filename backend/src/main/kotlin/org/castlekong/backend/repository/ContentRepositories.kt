package org.castlekong.backend.repository

import org.castlekong.backend.entity.Channel
import org.castlekong.backend.entity.ChannelType
import org.castlekong.backend.entity.Comment
import org.castlekong.backend.entity.Post
import org.castlekong.backend.entity.Workspace
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime

@Repository
interface ChannelRepository : JpaRepository<Channel, Long> {
    @Suppress("FunctionNaming")
    fun findByGroup_Id(groupId: Long): List<Channel>

    @Suppress("FunctionNaming")
    fun findByWorkspace_Id(workspaceId: Long): List<Channel>

    fun findByGroupIdAndType(
        groupId: Long,
        type: ChannelType,
    ): List<Channel>

    fun findByGroupIdOrderByDisplayOrder(groupId: Long): List<Channel>

    // 추가: 채널 개수 카운트
    @Suppress("FunctionNaming")
    fun countByGroup_Id(groupId: Long): Long

    // 배치 삭제 메서드
    @Modifying
    @Query("DELETE FROM Channel c WHERE c.group.id IN :groupIds")
    fun deleteByGroupIds(
        @Param("groupIds") groupIds: List<Long>,
    ): Int

    @Query("SELECT c.id FROM Channel c WHERE c.group.id IN :groupIds")
    fun findChannelIdsByGroupIds(
        @Param("groupIds") groupIds: List<Long>,
    ): List<Long>
}

@Repository
interface PostRepository : JpaRepository<Post, Long> {
    @Suppress("FunctionNaming")
    fun findByChannel_Id(channelId: Long): List<Post>

    @Query("SELECT p FROM Post p WHERE p.channel.id IN :channelIds ORDER BY p.createdAt DESC")
    fun findByChannelIdInOrderByCreatedAtDesc(
        @Param("channelIds") channelIds: List<Long>,
    ): List<Post>

    @Modifying
    @Query(
        """
        UPDATE Post p
        SET p.commentCount = CASE WHEN :delta < 0 AND p.commentCount + :delta < 0 THEN 0 ELSE p.commentCount + :delta END,
            p.lastCommentedAt = :lastCommentedAt
        WHERE p.id = :postId
        """,
    )
    fun updateCommentStats(
        @Param("postId") postId: Long,
        @Param("delta") delta: Long,
        @Param("lastCommentedAt") lastCommentedAt: LocalDateTime?,
    ): Int

    // 배치 삭제 메서드
    @Modifying
    @Query("DELETE FROM Post p WHERE p.channel.id IN :channelIds")
    fun deleteByChannelIds(
        @Param("channelIds") channelIds: List<Long>,
    ): Int

    @Query("SELECT p.id FROM Post p WHERE p.channel.id IN :channelIds")
    fun findPostIdsByChannelIds(
        @Param("channelIds") channelIds: List<Long>,
    ): List<Long>
}

@Repository
interface CommentRepository : JpaRepository<Comment, Long> {
    @Suppress("FunctionNaming")
    fun findByPost_Id(postId: Long): List<Comment>

    @Suppress("FunctionNaming")
    fun findTop1ByPost_IdOrderByCreatedAtDesc(postId: Long): Comment?

    // 배치 삭제 메서드
    @Modifying
    @Query("DELETE FROM Comment c WHERE c.post.id IN :postIds")
    fun deleteByPostIds(
        @Param("postIds") postIds: List<Long>,
    ): Int
}

@Repository
interface WorkspaceRepository : JpaRepository<Workspace, Long> {
    @Suppress("FunctionNaming")
    fun findByGroup_Id(groupId: Long): List<Workspace>

    // 배치 삭제 메서드
    @Modifying
    @Query("DELETE FROM Workspace w WHERE w.group.id IN :groupIds")
    fun deleteByGroupIds(
        @Param("groupIds") groupIds: List<Long>,
    ): Int
}
