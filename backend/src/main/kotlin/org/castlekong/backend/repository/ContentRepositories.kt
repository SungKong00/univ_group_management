package org.castlekong.backend.repository

import org.castlekong.backend.entity.Channel
import org.castlekong.backend.entity.Comment
import org.castlekong.backend.entity.Post
import org.castlekong.backend.entity.Workspace
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface ChannelRepository : JpaRepository<Channel, Long> {
    fun findByGroup_Id(groupId: Long): List<Channel>
    fun findByWorkspace_Id(workspaceId: Long): List<Channel>
}

@Repository
interface PostRepository : JpaRepository<Post, Long> {
    fun findByChannel_Id(channelId: Long): List<Post>
}

@Repository
interface CommentRepository : JpaRepository<Comment, Long> {
    fun findByPost_Id(postId: Long): List<Comment>
}

@Repository
interface WorkspaceRepository : JpaRepository<Workspace, Long> {
    fun findByGroup_Id(groupId: Long): List<Workspace>
}
