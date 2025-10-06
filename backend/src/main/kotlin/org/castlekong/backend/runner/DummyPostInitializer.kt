package org.castlekong.backend.runner

import org.castlekong.backend.entity.ChannelType
import org.castlekong.backend.entity.Post
import org.castlekong.backend.entity.PostType
import org.castlekong.backend.repository.ChannelRepository
import org.castlekong.backend.repository.PostRepository
import org.castlekong.backend.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.boot.context.event.ApplicationReadyEvent
import org.springframework.context.annotation.Profile
import org.springframework.context.event.EventListener
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

/**
 * TODO: 배포 시 이 파일 삭제 필요
 *
 * Event listener that creates dummy posts for development purposes.
 *
 * This listener executes after all ApplicationRunners complete and creates 9 dummy posts
 * in the Hansin University announcement channel:
 * - 10/4: 3 posts (5 lines, 15 lines, 30 lines)
 * - 10/5: 3 posts (5 lines, 15 lines, 30 lines)
 * - 10/6: 3 posts (5 lines, 15 lines, 30 lines)
 *
 * Idempotency: Checks for existing [DUMMY_POST] marker to avoid duplicates.
 * Author: castlekong1019@gmail.com (user id=1)
 */
@Component
@Profile("!prod")
class DummyPostInitializer(
    private val userRepository: UserRepository,
    private val channelRepository: ChannelRepository,
    private val postRepository: PostRepository,
) {
    private val logger = LoggerFactory.getLogger(DummyPostInitializer::class.java)

    @EventListener(ApplicationReadyEvent::class)
    @Transactional
    fun initializeDummyPosts() {
        logger.info("=== Starting Dummy Post Initialization Runner ===")

        // Check if dummy posts already exist
        val existingDummyPosts = postRepository.findAll().filter { it.content.contains("[DUMMY_POST]") }
        if (existingDummyPosts.isNotEmpty()) {
            logger.info("Dummy posts already exist (${existingDummyPosts.size} found). Skipping initialization.")
            return
        }

        // Step 1: Find author (castlekong1019@gmail.com)
        val author = userRepository.findByEmail("castlekong1019@gmail.com")
        if (author.isEmpty) {
            logger.warn("Author user castlekong1019@gmail.com not found. Skipping dummy post creation.")
            return
        }
        val authorUser = author.get()
        logger.info("Found author: ${authorUser.email} (id=${authorUser.id})")

        // Step 2: Find Hansin University announcement channel
        val allChannels = channelRepository.findAll()
        logger.info("Total channels in DB: ${allChannels.size}")
        allChannels.forEach { channel ->
            logger.info("Channel: id=${channel.id}, name=${channel.name}, type=${channel.type}, groupId=${channel.group.id}")
        }

        val announcementChannel =
            allChannels
                .firstOrNull { it.group.id == 1L && it.type == ChannelType.ANNOUNCEMENT }

        if (announcementChannel == null) {
            logger.warn("Hansin University announcement channel not found. Skipping dummy post creation.")
            return
        }
        logger.info("Found announcement channel: ${announcementChannel.name} (id=${announcementChannel.id})")

        // Step 3: Create dummy posts
        val postsToCreate =
            listOf(
                // 10/4 posts
                Triple(LocalDateTime.of(2025, 10, 4, 9, 0), 5, "2025학년도 1학기 수강신청 안내"),
                Triple(LocalDateTime.of(2025, 10, 4, 14, 30), 15, "학생회관 공사로 인한 출입 제한 안내"),
                Triple(LocalDateTime.of(2025, 10, 4, 18, 0), 30, "2025학년도 신입생 오리엔테이션 프로그램 상세 안내"),
                // 10/5 posts
                Triple(LocalDateTime.of(2025, 10, 5, 10, 0), 5, "도서관 임시 휴관 안내"),
                Triple(LocalDateTime.of(2025, 10, 5, 13, 0), 15, "2025-1학기 장학금 신청 기간 안내"),
                Triple(LocalDateTime.of(2025, 10, 5, 16, 30), 30, "2025학년도 취업 및 진로 특강 시리즈 안내"),
                // 10/6 posts
                Triple(LocalDateTime.of(2025, 10, 6, 11, 0), 5, "학생식당 메뉴 변경 안내"),
                Triple(LocalDateTime.of(2025, 10, 6, 15, 0), 15, "2025-1학기 중간고사 시험 일정 안내"),
                Triple(LocalDateTime.of(2025, 10, 6, 19, 0), 30, "2025학년도 하계 해외 교환학생 프로그램 모집 안내"),
            )

        postsToCreate.forEachIndexed { index, (date, lines, title) ->
            val content = generateDummyContent(title, lines)
            val post =
                Post(
                    channel = announcementChannel,
                    author = authorUser,
                    content = content,
                    type = PostType.ANNOUNCEMENT,
                    isPinned = false,
                    createdAt = date,
                    updatedAt = date,
                )
            postRepository.save(post)
            logger.info("Created dummy post ${index + 1}/9: $title ($lines lines, date=${date.toLocalDate()})")
        }

        logger.info("=== Dummy Post Initialization Completed Successfully ===")
    }

    /**
     * Generates dummy content with the specified number of lines.
     *
     * @param title The title of the post
     * @param lineCount Number of lines to generate
     * @return Generated dummy content with [DUMMY_POST] marker
     */
    private fun generateDummyContent(
        title: String,
        lineCount: Int,
    ): String {
        val lines = mutableListOf<String>()
        lines.add("[DUMMY_POST]")
        lines.add("# $title")
        lines.add("")

        when (lineCount) {
            5 -> {
                lines.add("안녕하세요, 학생 여러분.")
                lines.add("다음 사항을 공지하오니 참고하시기 바랍니다.")
                lines.add("자세한 내용은 학교 홈페이지를 참조해주세요.")
                lines.add("")
                lines.add("문의: 학생처 (031-379-0001)")
            }

            15 -> {
                lines.add("안녕하세요, 학생 여러분.")
                lines.add("")
                lines.add("다음 사항에 대해 안내드립니다:")
                lines.add("")
                lines.add("## 주요 내용")
                lines.add("1. 첫 번째 안내사항입니다.")
                lines.add("2. 두 번째 안내사항입니다.")
                lines.add("3. 세 번째 안내사항입니다.")
                lines.add("")
                lines.add("## 유의사항")
                lines.add("- 기한을 꼭 지켜주시기 바랍니다.")
                lines.add("- 문의사항은 담당 부서로 연락주세요.")
                lines.add("")
                lines.add("감사합니다.")
                lines.add("")
                lines.add("문의: 학생처 (031-379-0001)")
            }

            30 -> {
                lines.add("안녕하세요, 학생 여러분.")
                lines.add("")
                lines.add("다음 사항에 대해 상세히 안내드립니다:")
                lines.add("")
                lines.add("## 1. 개요")
                lines.add("본 공지는 학생 여러분께 중요한 정보를 전달하기 위한 것입니다.")
                lines.add("모든 학생은 본 공지 내용을 숙지하시기 바랍니다.")
                lines.add("")
                lines.add("## 2. 주요 내용")
                lines.add("### 2.1 첫 번째 항목")
                lines.add("- 세부 내용 1-1")
                lines.add("- 세부 내용 1-2")
                lines.add("- 세부 내용 1-3")
                lines.add("")
                lines.add("### 2.2 두 번째 항목")
                lines.add("- 세부 내용 2-1")
                lines.add("- 세부 내용 2-2")
                lines.add("- 세부 내용 2-3")
                lines.add("")
                lines.add("### 2.3 세 번째 항목")
                lines.add("- 세부 내용 3-1")
                lines.add("- 세부 내용 3-2")
                lines.add("- 세부 내용 3-3")
                lines.add("")
                lines.add("## 3. 신청/참여 방법")
                lines.add("홈페이지를 통해 온라인으로 신청하실 수 있습니다.")
                lines.add("자세한 절차는 첨부된 안내문을 참고해주세요.")
                lines.add("")
                lines.add("## 4. 문의처")
                lines.add("- 담당부서: 학생처")
                lines.add("- 전화번호: 031-379-0001")
                lines.add("- 이메일: student@hs.ac.kr")
            }
        }

        return lines.joinToString("\n")
    }
}
