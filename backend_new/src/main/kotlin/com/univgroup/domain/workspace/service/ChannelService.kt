package com.univgroup.domain.workspace.service

import com.univgroup.domain.workspace.entity.Channel
import com.univgroup.domain.workspace.entity.ChannelType
import com.univgroup.domain.workspace.repository.ChannelRepository
import com.univgroup.domain.permission.repository.ChannelRoleBindingRepository
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.ResourceNotFoundException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * 채널 서비스
 *
 * 채널 관련 비즈니스 로직을 담당한다.
 */
@Service
@Transactional(readOnly = true)
class ChannelService(
    private val channelRepository: ChannelRepository,
    private val channelRoleBindingRepository: ChannelRoleBindingRepository,
) {
    // ========== 조회 ==========

    fun findById(channelId: Long): Channel? {
        return channelRepository.findById(channelId).orElse(null)
    }

    fun getById(channelId: Long): Channel {
        return channelRepository.findById(channelId).orElseThrow {
            ResourceNotFoundException(
                ErrorCode.WORKSPACE_CHANNEL_NOT_FOUND,
                "채널을 찾을 수 없습니다: $channelId",
            )
        }
    }

    /**
     * 워크스페이스의 채널 목록 조회
     */
    fun getChannelsByWorkspace(workspaceId: Long): List<Channel> {
        return channelRepository.findByWorkspaceIdOrderByDisplayOrder(workspaceId)
    }

    /**
     * 그룹의 모든 채널 조회
     */
    fun getChannelsByGroup(groupId: Long): List<Channel> {
        return channelRepository.findByGroupIdWithWorkspace(groupId)
    }

    /**
     * 워크스페이스의 공지사항 채널 조회 (기존 기본 채널 대체)
     */
    fun getAnnouncementChannels(workspaceId: Long): List<Channel> {
        return channelRepository.findByWorkspaceIdAndType(workspaceId, ChannelType.ANNOUNCEMENT)
    }

    /**
     * 워크스페이스의 채널 유형별 조회
     */
    fun getChannelsByType(
        workspaceId: Long,
        type: ChannelType,
    ): List<Channel> {
        return channelRepository.findByWorkspaceIdAndType(workspaceId, type)
    }

    // ========== 생성/수정/삭제 ==========

    /**
     * 채널 생성
     */
    @Transactional
    fun createChannel(channel: Channel): Channel {
        // 중복 이름 체크 - Group 단위로 체크 (Workspace는 optional)
        if (channelRepository.existsByGroupIdAndName(channel.group.id!!, channel.name)) {
            throw IllegalArgumentException("이미 존재하는 채널 이름입니다: ${channel.name}")
        }

        return channelRepository.save(channel)
    }

    /**
     * 채널 수정
     */
    @Transactional
    fun updateChannel(
        channelId: Long,
        updateFn: (Channel) -> Unit,
    ): Channel {
        val channel = getById(channelId)
        updateFn(channel)
        return channelRepository.save(channel)
    }

    /**
     * 채널 삭제
     */
    @Transactional
    fun deleteChannel(channelId: Long) {
        val channel = getById(channelId)

        // Note: isDefault field was removed from Entity design
        // Default channel check should be done at business logic level if needed

        // 채널 권한 바인딩 먼저 삭제
        channelRoleBindingRepository.deleteByChannelId(channelId)

        channelRepository.delete(channel)
    }

    // ========== 순서 관리 ==========

    /**
     * 채널 순서 변경
     */
    @Transactional
    fun reorderChannels(
        workspaceId: Long,
        channelIds: List<Long>,
    ) {
        val channels = channelRepository.findByWorkspaceId(workspaceId)
        val channelMap = channels.associateBy { it.id }

        channelIds.forEachIndexed { index, channelId ->
            channelMap[channelId]?.let { channel ->
                channel.displayOrder = index
                channelRepository.save(channel)
            }
        }
    }

    // ========== 통계 ==========

    fun getChannelCount(workspaceId: Long): Long {
        return channelRepository.countByWorkspaceId(workspaceId)
    }
}
