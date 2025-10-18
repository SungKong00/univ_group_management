package org.castlekong.backend.runner

import org.castlekong.backend.dto.CreateApplicationRequest
import org.castlekong.backend.dto.CreateGroupEventRequest
import org.castlekong.backend.dto.CreateGroupRequest
import org.castlekong.backend.dto.CreateGroupRoleRequest
import org.castlekong.backend.dto.CreatePersonalScheduleRequest
import org.castlekong.backend.dto.CreatePlaceRequest
import org.castlekong.backend.dto.CreateRecruitmentRequest
import org.castlekong.backend.dto.RecurrencePattern
import org.castlekong.backend.dto.RecurrenceType
import org.castlekong.backend.dto.RequestUsageRequest
import org.castlekong.backend.dto.SignupProfileRequest
import org.castlekong.backend.dto.UpdateUsageStatusRequest
import org.castlekong.backend.entity.GroupPermission
import org.castlekong.backend.entity.GroupType
import org.castlekong.backend.entity.PlaceAvailability
import org.castlekong.backend.entity.UsageStatus
import org.castlekong.backend.entity.User
import org.castlekong.backend.repository.PlaceAvailabilityRepository
import org.castlekong.backend.repository.PlaceRepository
import org.castlekong.backend.service.GoogleUserInfo
import org.castlekong.backend.service.GroupEventService
import org.castlekong.backend.service.GroupManagementService
import org.castlekong.backend.service.GroupMemberService
import org.castlekong.backend.service.GroupRoleService
import org.castlekong.backend.service.PersonalScheduleService
import org.castlekong.backend.service.PlaceReservationService
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
import java.time.LocalDate
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
 * 7. 장소 운영 시간 생성
 * 8. 페르소나별 시간표 생성
 * 9. 그룹 캘린더 일정 및 장소 예약 생성
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
    private val groupEventService: GroupEventService,
    private val placeReservationService: PlaceReservationService,
    private val placeAvailabilityRepository: PlaceAvailabilityRepository,
    private val placeRepository: PlaceRepository,
    private val permissionService: org.castlekong.backend.security.PermissionService,
) : ApplicationRunner {
    private val logger = LoggerFactory.getLogger(TestDataRunner::class.java)

    @Transactional
    override fun run(args: ApplicationArguments) {
        // 중복 실행 방지 체크
        if (shouldSkipExecution()) {
            logger.info("=== Test data already exists, skipping TestDataRunner ===")
            return
        }

        // Invalidate permission cache
        permissionService.invalidateGroup(1)
        permissionService.invalidateGroup(2)
        permissionService.invalidateGroup(3)
        permissionService.invalidateGroup(11)
        permissionService.invalidateGroup(12)
        permissionService.invalidateGroup(13)

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
            val customPlaces = createPlaces(users, customGroups)

            // Phase 6: 장소 운영 시간 생성
            createPlaceAvailabilities(customPlaces)

            // Phase 7: 페르소나별 시간표 생성
            createPersonalSchedules(users)

            // Phase 8: 그룹 캘린더 일정 및 장소 예약 생성
            createCalendarEventsAndReservations(users, customGroups, customPlaces)

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
        logger.info("[1/7] Creating test users (Google OAuth simulation + Profile submission)...")

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
                role = "STUDENT",
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
                role = "STUDENT",
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
                role = "STUDENT",
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
        role: String = "STUDENT",
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
                role = role,
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
        logger.info("[2/7] Creating custom groups...")

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
        logger.info("[3/7] Setting up group memberships and roles...")

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
                                GroupPermission.CALENDAR_MANAGE.name,
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
        logger.info("[4/7] Creating recruitments and applications...")

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
    ): CustomPlaces {
        logger.info("[5/7] Creating places and managing usage permissions...")

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

        // 세미나실 장소 생성 (user2가 관리)
        val seminarRoom =
            safeExecute("Creating place '세미나실'") {
                placeService.createPlace(
                    users.user2,
                    CreatePlaceRequest(
                        managingGroupId = groups.studentCouncilId,
                        building = "60주년 기념관",
                        roomNumber = "101호",
                        alias = "세미나실",
                        capacity = 50,
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

        // AI/SW학과 그룹이 세미나실 사용 요청
        safeExecute("AI/SW department requesting seminar room usage") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            placeUsageGroupService.requestUsage(
                owner!!,
                seminarRoom.id,
                RequestUsageRequest(
                    groupId = 13, // AI/SW학과 그룹 ID
                    reason = "학과 특강 및 세미나를 위해 사용하고 싶습니다.",
                ),
            )
        }

        // 학생회에서 AI/SW학과 사용 승인
        safeExecute("Student Council approving AI/SW department usage") {
            placeUsageGroupService.updateUsageStatus(
                users.user2,
                seminarRoom.id,
                13, // AI/SW학과 그룹 ID
                UpdateUsageStatusRequest(status = UsageStatus.APPROVED),
            )
        }

        // AI/SW계열 그룹이 세미나실 사용 요청
        safeExecute("AI/SW college requesting seminar room usage") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            placeUsageGroupService.requestUsage(
                owner!!,
                seminarRoom.id,
                RequestUsageRequest(
                    groupId = 2, // AI/SW계열 그룹 ID
                    reason = "계열 단위 행사를 위해 사용하고 싶습니다.",
                ),
            )
        }

        // 학생회에서 AI/SW계열 사용 승인
        safeExecute("Student Council approving AI/SW college usage") {
            placeUsageGroupService.updateUsageStatus(
                users.user2,
                seminarRoom.id,
                2, // AI/SW계열 그룹 ID
                UpdateUsageStatusRequest(status = UsageStatus.APPROVED),
            )
        }

        // AI시스템반도체학과 그룹이 세미나실 사용 요청
        safeExecute("AI/Semiconductor department requesting seminar room usage") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            placeUsageGroupService.requestUsage(
                owner!!,
                seminarRoom.id,
                RequestUsageRequest(
                    groupId = 11, // AI시스템반도체학과 그룹 ID
                    reason = "전공 스터디 및 프로젝트를 위해 사용하고 싶습니다.",
                ),
            )
        }

        // 학생회에서 AI시스템반도체학과 사용 승인
        safeExecute("Student Council approving AI/Semiconductor department usage") {
            placeUsageGroupService.updateUsageStatus(
                users.user2,
                seminarRoom.id,
                11, // AI시스템반도체학과 그룹 ID
                UpdateUsageStatusRequest(status = UsageStatus.APPROVED),
            )
        }



        logger.info("-> SUCCESS: Created place and managed usage permissions")
        return CustomPlaces(labPlace.id, seminarRoom.id)
    }

    /**
     * Phase 6: 장소 운영 시간 생성
     *
     * @param places 커스텀 장소들
     */
    private fun createPlaceAvailabilities(places: CustomPlaces) {
        logger.info("[6/7] Creating place availabilities...")

        val labPlace = placeRepository.findById(places.labPlaceId).orElseThrow()
        val seminarRoom = placeRepository.findById(places.seminarRoomId).orElseThrow()

        safeExecute("Creating availabilities for '학생회실'") {
            val weekdays = listOf(DayOfWeek.MONDAY, DayOfWeek.TUESDAY, DayOfWeek.WEDNESDAY, DayOfWeek.THURSDAY, DayOfWeek.FRIDAY)
            weekdays.forEach {
                placeAvailabilityRepository.save(
                    PlaceAvailability(
                        place = labPlace,
                        dayOfWeek = it,
                        startTime = LocalTime.of(9, 0),
                        endTime = LocalTime.of(22, 0)
                    )
                )
            }
        }

        safeExecute("Creating availabilities for '세미나실'") {
            val weekdays = listOf(DayOfWeek.MONDAY, DayOfWeek.TUESDAY, DayOfWeek.WEDNESDAY, DayOfWeek.THURSDAY, DayOfWeek.FRIDAY)
            weekdays.forEach {
                placeAvailabilityRepository.save(
                    PlaceAvailability(
                        place = seminarRoom,
                        dayOfWeek = it,
                        startTime = LocalTime.of(9, 0),
                        endTime = LocalTime.of(22, 0)
                    )
                )
            }
        }

        logger.info("-> SUCCESS: Created place availabilities")
    }


    /**
     * Phase 7: 페르소나별 시간표 생성
     *
     * 각 사용자의 특징과 페르소나에 맞는 시간표를 생성합니다.
     * - TestUser1: 프로그래밍, 자료구조, 알고리즘 등 CS 전공 과목
     * - TestUser2: 교양/선택 과목 + 학생회 활동 시간
     * - TestUser3: 반도체 전공 과목 + 학생회 활동 시간
     *
     * @param users 테스트 사용자들
     */
    private fun createPersonalSchedules(users: TestUsers) {
        logger.info("[7/8] Creating personal schedules based on user personas...")

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
     * Phase 8: 그룹 캘린더 일정 및 장소 예약 생성
     *
     * @param users 테스트 사용자들
     * @param groups 커스텀 그룹들
     * @param places 커스텀 장소들
     */
    private fun createCalendarEventsAndReservations(
        users: TestUsers,
        groups: CustomGroups,
        places: CustomPlaces,
    ) {
        logger.info("[8/8] Creating group calendar events and reservations...")

        val owner = userService.findByEmail("castlekong1019@gmail.com")

        // 시나리오 1: 간단한 그룹 이벤트 (DevCrew)
        safeExecute("Creating simple group event for DevCrew") {
            groupEventService.createEvent(
                users.user1,
                groups.devCrewId,
                CreateGroupEventRequest(
                    title = "주간 알고리즘 스터디",
                    description = "매주 월요일에 진행되는 알고리즘 스터디입니다.",
                    locationText = "온라인",
                    startDate = LocalDate.now().plusDays(1),
                    endDate = LocalDate.now().plusMonths(1),
                    startTime = LocalTime.of(19, 0),
                    endTime = LocalTime.of(21, 0),
                    isOfficial = false,
                    color = "#03A9F4",
                    recurrence = RecurrencePattern(
                        type = RecurrenceType.WEEKLY,
                        daysOfWeek = listOf(DayOfWeek.MONDAY)
                    )
                )
            )
        }

        // 시나리오 2: 장소 예약이 포함된 공식 그룹 이벤트 (총학생회)
        safeExecute("Creating official group event with place reservation for Student Council") {
            groupEventService.createEvent(
                users.user2,
                groups.studentCouncilId,
                CreateGroupEventRequest(
                    title = "총학생회 정기 회의",
                    description = "매주 수요일에 진행되는 총학생회 정기 회의입니다.",
                    placeId = places.labPlaceId,
                    startDate = LocalDate.now().plusDays(1),
                    endDate = LocalDate.now().plusMonths(1),
                    startTime = LocalTime.of(17, 0),
                    endTime = LocalTime.of(18, 30),
                    isOfficial = true,
                    color = "#E91E63",
                    recurrence = RecurrencePattern(
                        type = RecurrenceType.WEEKLY,
                        daysOfWeek = listOf(DayOfWeek.WEDNESDAY)
                    )
                )
            )
        }

        // 시나리오 3: 그룹 이벤트 없는 장소 예약 (총학생회)
        safeExecute("Creating a direct place reservation for Student Council") {
            val event = groupEventService.createEvent(
                users.user3,
                groups.studentCouncilId,
                CreateGroupEventRequest(
                    title = "임시 회의",
                    description = "긴급 회의",
                    placeId = places.labPlaceId,
                    startDate = LocalDate.now().plusDays(2),
                    endDate = LocalDate.now().plusDays(2),
                    startTime = LocalTime.of(13, 0),
                    endTime = LocalTime.of(14, 0),
                    isOfficial = false,
                    color = "#FFC107"
                )
            )
        }

        // 시나리오 4: 예약 불가능한 장소가 포함된 그룹 이벤트
        safeExecute("Creating group event with a non-reservable location text") {
            groupEventService.createEvent(
                users.user1,
                groups.devCrewId,
                CreateGroupEventRequest(
                    title = "팀 프로젝트 회의",
                    description = "학교 근처 카페에서 진행",
                    locationText = "학교 근처 카페",
                    startDate = LocalDate.now().plusDays(3),
                    endDate = LocalDate.now().plusDays(3),
                    startTime = LocalTime.of(15, 0),
                    endTime = LocalTime.of(17, 0),
                    isOfficial = false,
                    color = "#795548"
                )
            )
        }

        // 시나리오 5: AI/SW계열 개강 총회 (공식 행사)
        safeExecute("Creating official event for AI/SW college") {
            val nextMonday = LocalDate.now().plusWeeks(1).with(DayOfWeek.MONDAY)
            groupEventService.createEvent(
                owner!!,
                2, // AI/SW계열 그룹 ID
                CreateGroupEventRequest(
                    title = "AI/SW계열 개강 총회",
                    description = "2025년 2학기 개강 총회입니다. 모든 계열 학생들은 참석해주세요.",
                    placeId = places.seminarRoomId,
                    startDate = nextMonday,
                    endDate = nextMonday,
                    startTime = LocalTime.of(18, 0),
                    endTime = LocalTime.of(20, 0),
                    isOfficial = true,
                    color = "#8BC34A"
                )
            )
        }

        // 시나리오 6: AI/SW학과 자료구조 특강 (세미나)
        safeExecute("Creating seminar for AI/SW department") {
            val nextTuesday = LocalDate.now().plusWeeks(1).with(DayOfWeek.TUESDAY)
            groupEventService.createEvent(
                owner!!,
                13, // AI/SW학과 그룹 ID
                CreateGroupEventRequest(
                    title = "자료구조 특강",
                    description = "외부 전문가를 초빙하여 진행하는 자료구조 특강입니다.",
                    placeId = places.seminarRoomId,
                    startDate = nextTuesday,
                    endDate = nextTuesday,
                    startTime = LocalTime.of(15, 0),
                    endTime = LocalTime.of(17, 0),
                    isOfficial = true,
                    color = "#00BCD4"
                )
            )
        }

        // 시나리오 7: AI시스템반도체학과 프로젝트를 위한 장소 예약
        safeExecute("Creating direct reservation for AI/Semiconductor department") {
            val nextWednesday = LocalDate.now().plusWeeks(1).with(DayOfWeek.WEDNESDAY)
            groupEventService.createEvent(
                owner!!,
                11, // AI시스템반도체학과 그룹 ID
                CreateGroupEventRequest(
                    title = "졸업 프로젝트 회의",
                    description = "캡스톤 디자인 팀 프로젝트 회의",
                    placeId = places.seminarRoomId,
                    startDate = nextWednesday,
                    endDate = nextWednesday,
                    startTime = LocalTime.of(10, 0),
                    endTime = LocalTime.of(12, 0),
                    isOfficial = false,
                    color = "#FF9800"
                )
            )
        }

        // DevCrew 그룹 추가 일정
        safeExecute("Creating additional events for DevCrew") {
            groupEventService.createEvent(
                users.user1,
                groups.devCrewId,
                CreateGroupEventRequest(
                    title = "DevCrew 정기 스터디",
                    placeId = places.labPlaceId,
                    startDate = LocalDate.of(2025, 10, 27),
                    endDate = LocalDate.of(2025, 11, 24),
                    startTime = LocalTime.of(19, 0),
                    endTime = LocalTime.of(21, 0),
                    isOfficial = false,
                    color = "#03A9F4",
                    recurrence = RecurrencePattern(
                        type = RecurrenceType.WEEKLY,
                        daysOfWeek = listOf(DayOfWeek.MONDAY)
                    )
                )
            )
        }

        // 학생회 그룹 추가 일정
        safeExecute("Creating additional events for Student Council") {
            groupEventService.createEvent(
                users.user2,
                groups.studentCouncilId,
                CreateGroupEventRequest(
                    title = "학생회 정기 회의",
                    placeId = places.labPlaceId,
                    startDate = LocalDate.of(2025, 10, 28),
                    endDate = LocalDate.of(2025, 11, 25),
                    startTime = LocalTime.of(17, 0),
                    endTime = LocalTime.of(18, 30),
                    isOfficial = true,
                    color = "#E91E63",
                    recurrence = RecurrencePattern(
                        type = RecurrenceType.WEEKLY,
                        daysOfWeek = listOf(DayOfWeek.TUESDAY)
                    )
                )
            )
        }

        // AI/SW학과 그룹 추가 일정
        safeExecute("Creating additional events for AI/SW department") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            groupEventService.createEvent(
                owner!!,
                13, // AI/SW학과 그룹 ID
                CreateGroupEventRequest(
                    title = "알고리즘 경진대회 대비 특강",
                    placeId = places.seminarRoomId,
                    startDate = LocalDate.of(2025, 10, 29),
                    endDate = LocalDate.of(2025, 10, 29),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = true,
                    color = "#00BCD4"
                )
            )
            groupEventService.createEvent(
                owner!!,
                13, // AI/SW학과 그룹 ID
                CreateGroupEventRequest(
                    title = "코딩 테스트 스터디",
                    placeId = places.seminarRoomId,
                    startDate = LocalDate.of(2025, 11, 5),
                    endDate = LocalDate.of(2025, 11, 5),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = false,
                    color = "#00BCD4"
                )
            )
            groupEventService.createEvent(
                owner!!,
                13, // AI/SW학과 그룹 ID
                CreateGroupEventRequest(
                    title = "졸업생 멘토링",
                    placeId = places.seminarRoomId,
                    startDate = LocalDate.of(2025, 11, 19),
                    endDate = LocalDate.of(2025, 11, 19),
                    startTime = LocalTime.of(14, 0),
                    endTime = LocalTime.of(16, 0),
                    isOfficial = true,
                    color = "#00BCD4"
                )
            )
        }

        // AI시스템반도체학과 그룹 추가 일정
        safeExecute("Creating additional events for AI/Semiconductor department") {
            val owner = userService.findByEmail("castlekong1019@gmail.com")
            groupEventService.createEvent(
                owner!!,
                11, // AI시스템반도체학과 그룹 ID
                CreateGroupEventRequest(
                    title = "임베디드 시스템 프로젝트 회의",
                    placeId = places.seminarRoomId,
                    startDate = LocalDate.of(2025, 10, 30),
                    endDate = LocalDate.of(2025, 10, 30),
                    startTime = LocalTime.of(10, 0),
                    endTime = LocalTime.of(12, 0),
                    isOfficial = false,
                    color = "#FF9800"
                )
            )
            groupEventService.createEvent(
                owner!!,
                11, // AI시스템반도체학과 그룹 ID
                CreateGroupEventRequest(
                    title = "반도체 설계 공모전 준비",
                    placeId = places.seminarRoomId,
                    startDate = LocalDate.of(2025, 11, 13),
                    endDate = LocalDate.of(2025, 11, 13),
                    startTime = LocalTime.of(10, 0),
                    endTime = LocalTime.of(12, 0),
                    isOfficial = false,
                    color = "#FF9800"
                )
            )
            groupEventService.createEvent(
                owner!!,
                11, // AI시스템반도체학과 그룹 ID
                CreateGroupEventRequest(
                    title = "캡스톤 디자인 최종 발표 준비",
                    placeId = places.seminarRoomId,
                    startDate = LocalDate.of(2025, 11, 27),
                    endDate = LocalDate.of(2025, 11, 27),
                    startTime = LocalTime.of(10, 0),
                    endTime = LocalTime.of(12, 0),
                    isOfficial = true,
                    color = "#FF9800"
                )
            )
        }

        logger.info("-> SUCCESS: Created group calendar events and reservations")
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

    /**
     * 커스텀 장소 정보 데이터 클래스
     */
    private data class CustomPlaces(
        val labPlaceId: Long,
        val seminarRoomId: Long,
    )
}
