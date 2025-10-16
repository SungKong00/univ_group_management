package org.castlekong.backend.runner

import org.castlekong.backend.dto.CreateApplicationRequest
import org.castlekong.backend.dto.CreateGroupRequest
import org.castlekong.backend.dto.CreateGroupRoleRequest
import org.castlekong.backend.dto.CreatePersonalScheduleRequest
import org.castlekong.backend.dto.CreatePlaceRequest
import org.castlekong.backend.dto.CreateRecruitmentRequest
import org.castlekong.backend.dto.RequestUsageRequest
import org.castlekong.backend.dto.SignupProfileRequest
import org.castlekong.backend.dto.UpdateUsageStatusRequest
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.UsageStatus
import org.castlekong.backend.entity.User
import org.castlekong.backend.service.GoogleUserInfo
import org.castlekong.backend.service.GroupManagementService
import org.castlekong.backend.service.GroupMemberService
import org.castlekong.backend.service.GroupRoleService
import org.castlekong.backend.service.PersonalScheduleService
import org.castlekong.backend.service.PlaceService
import org.castlekong.backend.service.PlaceUsageGroupService
import org.castlekong.backend.service.RecruitmentService
import org.castlekong.backend.service.UserService
import org.slf4j.LoggerFactory
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.core.annotation.Order
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional
import java.time.DayOfWeek
import java.time.LocalDateTime
import java.time.LocalTime

/**
 * TestDataRunner - 테스트 데이터 자동 생성
 *
 * 실제 Google OAuth 로그인 플로우를 시뮬레이션하여 테스트 사용자를 생성합니다.
 * - Google 로그인 시뮬레이션 (findOrCreateUser)
 * - 회원가입 프로필 제출 (submitSignupProfile)
 * - 서비스 레이어를 통한 모든 데이터 생성 (데이터 정합성 보장)
 *
 * 실행 순서:
 * 1. Google OAuth 시뮬레이션으로 3명의 사용자 생성
 * 2. 회원가입 프로필 제출 (자동 그룹 가입 포함)
 * 3. 커스텀 그룹 생성 및 멤버 추가
 * 4. 커스텀 역할 생성 및 할당
 * 5. 모집 공고 및 지원서 생성
 * 6. 장소 생성 및 사용 권한 관리
 * 7. 페르소나별 시간표 생성
 *
 * @Order(2) - GroupInitializationRunner 이후 실행
 */
@Component
@Order(2)
class TestDataRunner(
    private val userService: UserService,
    private val groupManagementService: GroupManagementService,
    private val groupMemberService: GroupMemberService,
    private val groupRoleService: GroupRoleService,
    private val recruitmentService: RecruitmentService,
    private val placeService: PlaceService,
    private val placeUsageGroupService: PlaceUsageGroupService,
    private val personalScheduleService: PersonalScheduleService,
) : ApplicationRunner {
    private val logger = LoggerFactory.getLogger(TestDataRunner::class.java)

    @Transactional
    override fun run(args: ApplicationArguments) {
        // 중복 실행 방지 체크
        if (shouldSkipExecution()) {
            logger.info("=== Test data already exists, skipping TestDataRunner ===")
            return
        }

        logger.info("=== Starting Test Data Creation ===")

        try {
            // Phase 1: 사용자 생성 (Google OAuth 시뮬레이션 + 회원가입 프로필 제출)
            val users = createTestUsers()

            // Phase 2: 커스텀 그룹 생성
            val customGroups = createCustomGroups(users)

            // Phase 3: 그룹 멤버십 및 역할 관리
            setupGroupMemberships(users, customGroups)

            // Phase 4: 모집 공고 및 지원서
            createRecruitments(users, customGroups)

            // Phase 5: 장소 생성 및 사용 권한
            createPlaces(users, customGroups)

            // Phase 6: 페르소나별 시간표 생성
            createPersonalSchedules(users)

            logger.info("=== Test Data Creation Completed Successfully ===")
        } catch (e: Exception) {
            logger.error("=== Test Data Creation Failed ===", e)
            throw e
        }
    }

    /**
     * 중복 실행 방지 체크
     * 특정 테스트 그룹이 이미 존재하면 true 반환
     */
    private fun shouldSkipExecution(): Boolean {
        return groupManagementService.getAllGroups().any { it.name == "코딩 동아리 'DevCrew'" }
    }

    /**
     * Phase 1: 테스트 사용자 생성
     *
     * Google OAuth 로그인 플로우를 시뮬레이션:
     * 1. Google 사용자 정보로 사용자 생성 (findOrCreateUser)
     * 2. 회원가입 프로필 제출 (submitSignupProfile)
     *    - 자동으로 선택한 학과/계열 + 상위 그룹에 가입됨
     *
     * @return 생성된 사용자 목록
     */
    private fun createTestUsers(): TestUsers {
        logger.info("[1/5] Creating test users (Google OAuth simulation + Profile submission)...")

        // User 1: TestUser1 (AI/SW학과)
        val user1 =
            simulateGoogleLoginAndSignup(
                email = "testuser1@hs.ac.kr",
                name = "TestUser1",
                nickname = "TU1",
                college = "AI/SW계열",
                dept = "AI/SW학과",
                studentNo = "20250011",
                academicYear = 1,
            )

        // User 2: TestUser2 (AI/SW계열 - 학과 선택 안함)
        val user2 =
            simulateGoogleLoginAndSignup(
                email = "testuser2@hs.ac.kr",
                name = "TestUser2",
                nickname = "TU2",
                college = "AI/SW계열",
                dept = null,
                studentNo = "20250012",
                academicYear = 2,
            )

        // User 3: TestUser3 (AI시스템반도체학과)
        val user3 =
            simulateGoogleLoginAndSignup(
                email = "testuser3@hs.ac.kr",
                name = "TestUser3",
                nickname = "TU3",
                college = "AI/SW계열",
                dept = "AI시스템반도체학과",
                studentNo = "20250013",
                academicYear = 3,
            )

        logger.info("-> SUCCESS: Created 3 test users with profile completion")
        logger.info("   - ${user1.email} (${user1.department})")
        logger.info("   - ${user2.email} (${user2.college})")
        logger.info("   - ${user3.email} (${user3.department})")

        return TestUsers(user1, user2, user3)
    }

    /**
     * Google OAuth 로그인 및 회원가입 프로필 제출 시뮬레이션
     *
     * @param email 이메일
     * @param name 이름
     * @param nickname 닉네임
     * @param college 계열 (선택)
     * @param dept 학과 (선택)
     * @param studentNo 학번
     * @param academicYear 학년
     * @return 생성 및 프로필 완료된 사용자
     */
    private fun simulateGoogleLoginAndSignup(
        email: String,
        name: String,
        nickname: String,
        college: String?,
        dept: String?,
        studentNo: String,
        academicYear: Int,
    ): User {
        // Step 1: Google OAuth 시뮬레이션 - findOrCreateUser 호출
        val googleUserInfo =
            GoogleUserInfo(
                email = email,
                name = name,
                profileImageUrl = null,
            )

        val createdUser = userService.findOrCreateUser(googleUserInfo)
        logger.debug("   -> Google OAuth simulated for: $email (userId=${createdUser.id})")

        // Step 2: 회원가입 프로필 제출 - submitSignupProfile 호출
        val profileRequest =
            SignupProfileRequest(
                name = name,
                nickname = nickname,
                college = college,
                dept = dept,
                studentNo = studentNo,
                academicYear = academicYear,
                schoolEmail = email,
                role = "STUDENT",
            )

        val completedUser = userService.submitSignupProfile(createdUser.id!!, profileRequest)
        logger.debug("   -> Profile submitted for: $email (auto-joined to groups)")

        return completedUser
    }

    /**
     * Phase 2: 커스텀 그룹 생성
     *
     * @param users 테스트 사용자들
     * @return 생성된 커스텀 그룹 정보
     */
    private fun createCustomGroups(users: TestUsers): CustomGroups {
        logger.info("[2/5] Creating custom groups...")

        // 코딩 동아리 (user1이 그룹장)
        val devCrewGroup =
            safeExecute("Creating DevCrew group") {
                groupManagementService.createGroup(
                    CreateGroupRequest(
                        name = "코딩 동아리 'DevCrew'",
                        // 한신대학교
                        parentId = 1,
                        university = "한신대학교",
                        college = null,
                        department = null,
                        groupType = GroupType.AUTONOMOUS,
                        description = "코딩과 개발을 사랑하는 사람들의 모임",
                        tags = setOf("코딩", "개발", "스터디"),
                    ),
                    users.user1.id!!,
                )
            }

        // 학생회 (user2가 그룹장)
        val studentCouncilGroup =
            safeExecute("Creating Student Council group") {
                groupManagementService.createGroup(
                    CreateGroupRequest(
                        name = "학생회",
                        // 한신대학교
                        parentId = 1,
                        university = "한신대학교",
                        college = null,
                        department = null,
                        groupType = GroupType.OFFICIAL,
                        description = "한신대학교 총학생회",
                        tags = setOf("학생회", "공식"),
                    ),
                    users.user2.id!!,
                )
            }

        logger.info("-> SUCCESS: Created custom groups")
        logger.info("   - ${devCrewGroup.name} (owner: ${users.user1.email})")
        logger.info("   - ${studentCouncilGroup.name} (owner: ${users.user2.email})")

        return CustomGroups(devCrewGroup.id, studentCouncilGroup.id)
    }

    /**
     * Phase 3: 그룹 멤버십 및 역할 관리
     *
     * @param users 테스트 사용자들
     * @param groups 커스텀 그룹들
     */
    private fun setupGroupMemberships(
        users: TestUsers,
        groups: CustomGroups,
    ) {
        logger.info("[3/5] Setting up group memberships and roles...")

        // user3를 학생회에 추가
        safeExecute("Adding user3 to Student Council") {
            groupMemberService.joinGroup(groups.studentCouncilId, users.user3.id!!)
        }

        // 학생회에 커스텀 역할 생성 (학생회 간부)
        val executiveRole =
            safeExecute("Creating custom role '학생회 간부'") {
                groupRoleService.createGroupRole(
                    groups.studentCouncilId,
                    CreateGroupRoleRequest(
                        name = "학생회 간부",
                        permissions =
                            setOf(
                                GroupPermission.CHANNEL_MANAGE.name,
                                GroupPermission.RECRUITMENT_MANAGE.name,
                            ),
                        priority = 50,
                    ),
                    users.user2.id!!,
                )
            }

        // user3에게 커스텀 역할 할당
        safeExecute("Assigning '학생회 간부' role to user3") {
            groupMemberService.updateMemberRole(
                groups.studentCouncilId,
                users.user3.id!!,
                executiveRole.id,
                users.user2.id!!,
            )
        }

        logger.info("-> SUCCESS: Configured memberships and roles")
    }

    /**
     * Phase 4: 모집 공고 및 지원서 생성
     *
     * @param users 테스트 사용자들
     * @param groups 커스텀 그룹들
     */
    private fun createRecruitments(
        users: TestUsers,
        groups: CustomGroups,
    ) {
        logger.info("[4/5] Creating recruitments and applications...")

        // 학생회 모집 공고 생성 (user2가 작성)
        val recruitment =
            safeExecute("Creating recruitment post") {
                recruitmentService.createRecruitment(
                    groups.studentCouncilId,
                    CreateRecruitmentRequest(
                        title = "학생회 2025년 2학기 신입 부원 모집",
                        content = "열정 넘치는 신입 부원을 모집합니다!",
                        recruitmentEndDate = LocalDateTime.now().plusWeeks(2),
                        applicationQuestions = listOf("자기소개를 해주세요.", "학생회에서 하고 싶은 일은 무엇인가요?"),
                    ),
                    users.user2.id!!,
                )
            }

        // user1이 지원서 제출
        safeExecute("User1 submitting application") {
            recruitmentService.submitApplication(
                recruitment.id,
                CreateApplicationRequest(
                    motivation = "학생 사회에 기여하고 싶습니다.",
                    questionAnswers =
                        mapOf(
                            0 to "안녕하세요, TestUser1입니다. 코딩을 좋아하고 학생회 활동에 관심이 많습니다.",
                            1 to "IT 인프라 개선 및 학생들을 위한 웹 서비스 개발을 하고 싶습니다.",
                        ),
                ),
                users.user1.id!!,
            )
        }

        logger.info("-> SUCCESS: Created recruitment and application")
    }

    /**
     * Phase 5: 장소 생성 및 사용 권한 관리
     *
     * @param users 테스트 사용자들
     * @param groups 커스텀 그룹들
     */
    private fun createPlaces(
        users: TestUsers,
        groups: CustomGroups,
    ) {
        logger.info("[5/5] Creating places and managing usage permissions...")

        // 학생회실 장소 생성 (user2가 관리)
        val labPlace =
            safeExecute("Creating place '학생회실'") {
                placeService.createPlace(
                    users.user2,
                    CreatePlaceRequest(
                        managingGroupId = groups.studentCouncilId,
                        building = "학생회관",
                        roomNumber = "201호",
                        alias = "학생회실",
                        capacity = 25,
                    ),
                )
            }

        // DevCrew 그룹이 학생회실 사용 요청 (user1이 요청)
        safeExecute("DevCrew requesting place usage") {
            placeUsageGroupService.requestUsage(
                users.user1,
                labPlace.id,
                RequestUsageRequest(
                    groupId = groups.devCrewId,
                    reason = "매주 목요일 저녁 코딩 스터디를 위해 사용하고 싶습니다.",
                ),
            )
        }

        // 학생회에서 사용 승인 (user2가 승인)
        safeExecute("Student Council approving place usage") {
            placeUsageGroupService.updateUsageStatus(
                users.user2,
                labPlace.id,
                groups.devCrewId,
                UpdateUsageStatusRequest(status = UsageStatus.APPROVED),
            )
        }

        logger.info("-> SUCCESS: Created place and managed usage permissions")
    }

    /**
     * Phase 6: 페르소나별 시간표 생성
     *
     * 각 사용자의 특징과 페르소나에 맞는 시간표를 생성합니다.
     * - TestUser1: 프로그래밍, 자료구조, 알고리즘 등 CS 전공 과목
     * - TestUser2: 교양/선택 과목 + 학생회 활동 시간
     * - TestUser3: 반도체 전공 과목 + 학생회 활동 시간
     *
     * @param users 테스트 사용자들
     */
    private fun createPersonalSchedules(users: TestUsers) {
        logger.info("[6/6] Creating personal schedules based on user personas...")

        // TestUser1: CS 전공 과목 (프로그래밍 중심)
        safeExecute("Creating schedules for TestUser1 (CS courses)") {
            // 월요일 09:00-10:30 프로그래밍
            personalScheduleService.createSchedule(
                users.user1,
                CreatePersonalScheduleRequest(
                    title = "프로그래밍 1",
                    dayOfWeek = DayOfWeek.MONDAY,
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(10, 30),
                    location = "학습관 201호",
                    color = "#2196F3",
                ),
            )

            // 수요일 10:30-12:00 자료구조
            personalScheduleService.createSchedule(
                users.user1,
                CreatePersonalScheduleRequest(
                    title = "자료구조",
                    dayOfWeek = DayOfWeek.WEDNESDAY,
                    startTime = LocalTime.of(10, 30),
                    endTime = LocalTime.of(12, 0),
                    location = "학습관 301호",
                    color = "#4CAF50",
                ),
            )

            // 금요일 14:00-15:30 알고리즘
            personalScheduleService.createSchedule(
                users.user1,
                CreatePersonalScheduleRequest(
                    title = "알고리즘",
                    dayOfWeek = DayOfWeek.FRIDAY,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 30),
                    location = "학습관 201호",
                    color = "#FF9800",
                ),
            )

            // 목요일 18:00-20:00 DevCrew 코딩 스터디
            personalScheduleService.createSchedule(
                users.user1,
                CreatePersonalScheduleRequest(
                    title = "DevCrew 코딩 스터디",
                    dayOfWeek = DayOfWeek.THURSDAY,
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    location = "학생회실",
                    color = "#9C27B0",
                ),
            )
        }

        // TestUser2: 교양과목 + 학생회 활동
        safeExecute("Creating schedules for TestUser2 (Liberal arts + Student council)") {
            // 화요일 09:00-10:30 교양 과학
            personalScheduleService.createSchedule(
                users.user2,
                CreatePersonalScheduleRequest(
                    title = "과학과 문명",
                    dayOfWeek = DayOfWeek.TUESDAY,
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(10, 30),
                    location = "강의동 101호",
                    color = "#2196F3",
                ),
            )

            // 목요일 10:30-12:00 교양 인문학
            personalScheduleService.createSchedule(
                users.user2,
                CreatePersonalScheduleRequest(
                    title = "역사와 철학",
                    dayOfWeek = DayOfWeek.THURSDAY,
                    startTime = LocalTime.of(10, 30),
                    endTime = LocalTime.of(12, 0),
                    location = "강의동 205호",
                    color = "#4CAF50",
                ),
            )

            // 수요일 14:00-17:00 학생회 정기회의
            personalScheduleService.createSchedule(
                users.user2,
                CreatePersonalScheduleRequest(
                    title = "학생회 정기회의",
                    dayOfWeek = DayOfWeek.WEDNESDAY,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(17, 0),
                    location = "학생회실",
                    color = "#F44336",
                ),
            )

            // 금요일 13:00-14:00 학생회 사무시간
            personalScheduleService.createSchedule(
                users.user2,
                CreatePersonalScheduleRequest(
                    title = "학생회 사무시간",
                    dayOfWeek = DayOfWeek.FRIDAY,
                    startTime = LocalTime.of(13, 0),
                    endTime = LocalTime.of(14, 0),
                    location = "학생회실",
                    color = "#FF5722",
                ),
            )
        }

        // TestUser3: 반도체 전공 + 학생회 활동
        safeExecute("Creating schedules for TestUser3 (Semiconductor + Student council)") {
            // 월요일 11:00-12:30 반도체 공학
            personalScheduleService.createSchedule(
                users.user3,
                CreatePersonalScheduleRequest(
                    title = "반도체 공학 개론",
                    dayOfWeek = DayOfWeek.MONDAY,
                    startTime = LocalTime.of(11, 0),
                    endTime = LocalTime.of(12, 30),
                    location = "공과관 501호",
                    color = "#2196F3",
                ),
            )

            // 수요일 09:00-10:30 전자회로
            personalScheduleService.createSchedule(
                users.user3,
                CreatePersonalScheduleRequest(
                    title = "전자회로 설계",
                    dayOfWeek = DayOfWeek.WEDNESDAY,
                    startTime = LocalTime.of(9, 0),
                    endTime = LocalTime.of(10, 30),
                    location = "공과관 502호",
                    color = "#4CAF50",
                ),
            )

            // 금요일 14:00-15:30 반도체 실험
            personalScheduleService.createSchedule(
                users.user3,
                CreatePersonalScheduleRequest(
                    title = "반도체 실험",
                    dayOfWeek = DayOfWeek.FRIDAY,
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(15, 30),
                    location = "공과관 Lab",
                    color = "#FF9800",
                ),
            )

            // 화요일 16:00-18:00 학생회 간부 회의
            personalScheduleService.createSchedule(
                users.user3,
                CreatePersonalScheduleRequest(
                    title = "학생회 간부 회의",
                    dayOfWeek = DayOfWeek.TUESDAY,
                    startTime = LocalTime.of(16, 0),
                    endTime = LocalTime.of(18, 0),
                    location = "학생회실",
                    color = "#F44336",
                ),
            )

            // 목요일 12:00-13:00 학생회 업무 (사무시간)
            personalScheduleService.createSchedule(
                users.user3,
                CreatePersonalScheduleRequest(
                    title = "학생회 업무 시간",
                    dayOfWeek = DayOfWeek.THURSDAY,
                    startTime = LocalTime.of(12, 0),
                    endTime = LocalTime.of(13, 0),
                    location = "학생회실",
                    color = "#FF5722",
                ),
            )
        }

        logger.info("-> SUCCESS: Created personal schedules")
        logger.info("   - TestUser1: 4 CS courses (프로그래밍, 자료구조, 알고리즘, 스터디)")
        logger.info("   - TestUser2: 4 schedules (교양과목 + 학생회)")
        logger.info("   - TestUser3: 5 schedules (반도체전공 + 학생회)")
    }

    /**
     * 안전한 실행 래퍼 - 에러 로깅 및 재발생
     *
     * @param description 작업 설명
     * @param action 실행할 작업
     * @return 작업 결과
     */
    private fun <T> safeExecute(
        description: String,
        action: () -> T,
    ): T {
        return try {
            val result = action()
            logger.debug("   -> $description: SUCCESS")
            result
        } catch (e: Exception) {
            logger.error("   -> $description: FAILED", e)
            throw RuntimeException("[$description] ${e.message}", e)
        }
    }

    /**
     * 테스트 사용자 데이터 클래스
     */
    private data class TestUsers(
        val user1: User,
        val user2: User,
        val user3: User,
    )

    /**
     * 커스텀 그룹 정보 데이터 클래스
     */
    private data class CustomGroups(
        val devCrewId: Long,
        val studentCouncilId: Long,
    )
}
