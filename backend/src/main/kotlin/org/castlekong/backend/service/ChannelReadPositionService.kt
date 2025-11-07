package org.castlekong.backend.service

import org.castlekong.backend.dto.ChannelReadPositionResponse
import org.castlekong.backend.dto.UnreadCountResponse
import org.castlekong.backend.dto.UpdateReadPositionRequest
import org.castlekong.backend.entity.ChannelPermission
import org.castlekong.backend.entity.ChannelReadPosition
import org.castlekong.backend.exception.BusinessException
import org.castlekong.backend.exception.ErrorCode
import org.castlekong.backend.repository.ChannelReadPositionRepository
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.GroupMemberRepository
import org.castlekong.backend.repository.PostRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
@Transactional(readOnly = true)
class ChannelReadPositionService(
    private val readPositionRepository: ChannelReadPositionRepository,
    private val postRepository: PostRepository,
    private val channelRepository: ChannelRepository,
    private val groupMemberRepository: GroupMemberRepository,
    private val channelPermissionService: ChannelPermissionManagementService,
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    /**
     * 읽음 위치 조회
     * 권한: 채널에 접근 가능한 멤버만 조회 가능
     */
    fun getReadPosition(
        userId: Long,
        channelId: Long,
    ): ChannelReadPositionResponse? {
        // 1. 채널 접근 권한 확인 (POST_READ 권한)
        checkChannelAccess(userId, channelId)

        // 2. 읽음 위치 조회
        return readPositionRepository.findByUserIdAndChannelId(userId, channelId)
            ?.let { ChannelReadPositionResponse(it.lastReadPostId, it.updatedAt) }
    }

    /**
     * 읽음 위치 업데이트
     * 채널 이탈 시 클라이언트가 호출
     */
    @Transactional
    fun updateReadPosition(
        userId: Long,
        channelId: Long,
        request: UpdateReadPositionRequest,
    ) {
        // 1. 채널 접근 권한 확인
        checkChannelAccess(userId, channelId)

        // 2. lastReadPostId 검증: 게시글이 해당 채널에 속하는지 확인
        if (request.lastReadPostId > 0) {
            val post =
                postRepository.findById(request.lastReadPostId)
                    .orElseThrow {
                        logger.warn(
                            "Post not found: userId={}, channelId={}, lastReadPostId={}",
                            userId,
                            channelId,
                            request.lastReadPostId,
                        )
                        BusinessException(ErrorCode.POST_NOT_FOUND)
                    }

            if (post.channel.id != channelId) {
                logger.warn(
                    "ReadPosition mismatch detected: userId={}, channelId={}, lastReadPostId={} belongs to channelId={}",
                    userId,
                    channelId,
                    request.lastReadPostId,
                    post.channel.id,
                )
                throw BusinessException(ErrorCode.INVALID_REQUEST)
            }
        }

        // 3. 기존 레코드 조회 또는 새로 생성
        val position =
            readPositionRepository.findByUserIdAndChannelId(userId, channelId)
                ?.also {
                    it.lastReadPostId = request.lastReadPostId
                    it.updatedAt = LocalDateTime.now()
                }
                ?: ChannelReadPosition(
                    userId = userId,
                    channelId = channelId,
                    lastReadPostId = request.lastReadPostId,
                )

        readPositionRepository.save(position)
        logger.debug(
            "Updated read position: userId={}, channelId={}, lastReadPostId={}",
            userId,
            channelId,
            request.lastReadPostId,
        )
    }

    /**
     * 읽지 않은 글 개수 조회 (뱃지용)
     */
    fun getUnreadCount(
        userId: Long,
        channelId: Long,
    ): Int {
        // 1. 채널 접근 권한 확인
        checkChannelAccess(userId, channelId)

        // 2. 읽음 위치 조회
        val readPosition = readPositionRepository.findByUserIdAndChannelId(userId, channelId)
        if (readPosition == null) {
            // 첫 방문 시 전체 개수 반환
            return postRepository.countByChannel_Id(channelId).toInt()
        }

        // 3. lastReadPostId 이후 게시글 개수 조회
        return postRepository.countByChannelIdAndIdGreaterThan(channelId, readPosition.lastReadPostId).toInt()
    }

    /**
     * 여러 채널의 읽지 않은 글 개수 일괄 조회 (최적화)
     * 채널 목록 화면에서 뱃지 표시용
     */
    fun getUnreadCountsForChannels(
        userId: Long,
        channelIds: List<Long>,
    ): List<UnreadCountResponse> {
        if (channelIds.isEmpty()) return emptyList()

        // 1. 권한 있는 채널만 필터링
        val accessibleChannels = filterAccessibleChannels(userId, channelIds)

        // 2. 읽음 위치 일괄 조회
        val readPositions =
            readPositionRepository.findAllByUserIdAndChannelIdIn(userId, accessibleChannels)
                .associateBy { it.channelId }

        // 3. 각 채널별 읽지 않은 글 개수 계산
        return accessibleChannels.map { channelId ->
            val lastReadPostId = readPositions[channelId]?.lastReadPostId ?: 0
            val unreadCount =
                if (lastReadPostId == 0L) {
                    postRepository.countByChannel_Id(channelId).toInt()
                } else {
                    postRepository.countByChannelIdAndIdGreaterThan(channelId, lastReadPostId).toInt()
                }
            UnreadCountResponse(channelId, unreadCount)
        }
    }

    /**
     * 채널 접근 권한 확인
     * POST_READ 권한이 있는지 확인
     */
    private fun checkChannelAccess(
        userId: Long,
        channelId: Long,
    ) {
        val channel =
            channelRepository.findById(channelId)
                .orElseThrow { BusinessException(ErrorCode.CHANNEL_NOT_FOUND) }

        // 그룹 멤버십 확인
        groupMemberRepository.findByGroupIdAndUserId(channel.group.id, userId)
            .orElseThrow { BusinessException(ErrorCode.FORBIDDEN) }

        // 채널 POST_READ 권한 확인
        if (!channelPermissionService.hasChannelPermission(channelId, userId, ChannelPermission.POST_READ)) {
            throw BusinessException(ErrorCode.FORBIDDEN)
        }
    }

    /**
     * 접근 가능한 채널만 필터링 (배치 처리용)
     */
    private fun filterAccessibleChannels(
        userId: Long,
        channelIds: List<Long>,
    ): List<Long> =
        channelIds.filter { channelId ->
            try {
                checkChannelAccess(userId, channelId)
                true
            } catch (e: BusinessException) {
                logger.debug("User {} has no access to channel {}: {}", userId, channelId, e.message)
                false
            }
        }
}
