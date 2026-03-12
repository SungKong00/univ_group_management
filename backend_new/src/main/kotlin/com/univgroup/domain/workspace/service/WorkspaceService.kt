package com.univgroup.domain.workspace.service

import com.univgroup.domain.workspace.entity.Workspace
import com.univgroup.domain.workspace.repository.ChannelRepository
import com.univgroup.domain.workspace.repository.WorkspaceRepository
import com.univgroup.shared.dto.ErrorCode
import com.univgroup.shared.exception.ResourceNotFoundException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * 워크스페이스 서비스
 *
 * 워크스페이스 관련 비즈니스 로직을 담당한다.
 */
@Service
@Transactional(readOnly = true)
class WorkspaceService(
    private val workspaceRepository: WorkspaceRepository,
    private val channelRepository: ChannelRepository,
) {
    // ========== 조회 ==========

    fun findById(workspaceId: Long): Workspace? {
        return workspaceRepository.findById(workspaceId).orElse(null)
    }

    fun getById(workspaceId: Long): Workspace {
        return workspaceRepository.findById(workspaceId).orElseThrow {
            ResourceNotFoundException(
                ErrorCode.WORKSPACE_NOT_FOUND,
                "워크스페이스를 찾을 수 없습니다: $workspaceId",
            )
        }
    }

    /**
     * 그룹의 워크스페이스 목록 조회
     */
    fun getWorkspacesByGroup(groupId: Long): List<Workspace> {
        return workspaceRepository.findByGroupIdOrderByDisplayOrder(groupId)
    }

    /**
     * 그룹의 첫 번째 워크스페이스 조회 (displayOrder 기준)
     */
    fun getDefaultWorkspace(groupId: Long): Workspace? {
        return workspaceRepository.findByGroupIdOrderByDisplayOrder(groupId).firstOrNull()
    }

    // ========== 생성/수정/삭제 ==========

    /**
     * 워크스페이스 생성
     */
    @Transactional
    fun createWorkspace(workspace: Workspace): Workspace {
        // 중복 이름 체크
        if (workspaceRepository.existsByGroupIdAndName(workspace.group.id!!, workspace.name)) {
            throw IllegalArgumentException("이미 존재하는 워크스페이스 이름입니다: ${workspace.name}")
        }

        return workspaceRepository.save(workspace)
    }

    /**
     * 워크스페이스 수정
     */
    @Transactional
    fun updateWorkspace(
        workspaceId: Long,
        updateFn: (Workspace) -> Unit,
    ): Workspace {
        val workspace = getById(workspaceId)
        updateFn(workspace)
        return workspaceRepository.save(workspace)
    }

    /**
     * 워크스페이스 삭제
     */
    @Transactional
    fun deleteWorkspace(workspaceId: Long) {
        val workspace = getById(workspaceId)

        // 그룹의 유일한 워크스페이스인지 확인
        val workspaceCount = getWorkspaceCount(workspace.group.id!!)
        if (workspaceCount <= 1) {
            throw IllegalStateException("마지막 워크스페이스는 삭제할 수 없습니다")
        }

        // 채널 먼저 삭제
        channelRepository.deleteAllByWorkspaceId(workspaceId)

        workspaceRepository.delete(workspace)
    }

    // ========== 통계 ==========

    fun getWorkspaceCount(groupId: Long): Long {
        return workspaceRepository.countByGroupId(groupId)
    }

    fun getChannelCount(workspaceId: Long): Long {
        return channelRepository.countByWorkspaceId(workspaceId)
    }
}
