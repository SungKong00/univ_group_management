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

@Repository
interface ChannelRepository : JpaRepository<Channel, Long> {
    fun findByGroup_Id(groupId: Long): List<Channel>

    fun findByWorkspace_Id(workspaceId: Long): List<Channel>

    fun findByGroupIdAndType(
        groupId: Long,
        type: ChannelType,
    ): List<Channel>

    fun findByGroupIdOrderByDisplayOrder(groupId: Long): List<Channel>

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
    fun findByChannel_Id(channelId: Long): List<Post>

    @Query("SELECT p FROM Post p WHERE p.channel.id IN :channelIds ORDER BY p.createdAt DESC")
    fun findByChannelIdInOrderByCreatedAtDesc(
        @Param("channelIds") channelIds: List<Long>,
    ): List<Post>

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
    fun findByPost_Id(postId: Long): List<Comment>

    // 배치 삭제 메서드
    @Modifying
    @Query("DELETE FROM Comment c WHERE c.post.id IN :postIds")
    fun deleteByPostIds(
        @Param("postIds") postIds: List<Long>,
    ): Int
}

@Repository
interface WorkspaceRepository : JpaRepository<Workspace, Long> {
    fun findByGroup_Id(groupId: Long): List<Workspace>

    // 배치 삭제 메서드
    @Modifying
    @Query("DELETE FROM Workspace w WHERE w.group.id IN :groupIds")
    fun deleteByGroupIds(
        @Param("groupIds") groupIds: List<Long>,
    ): Int
}
