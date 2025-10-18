# 테스트 데이터 참조 가이드 (Test Data Reference)

## 개요

테스트 환경에서 사용되는 모든 사용자, 그룹, 권한 정보를 관리하는 문서입니다. TestDataRunner가 자동으로 생성하는 테스트 데이터의 구조를 이해하고 테스트 시나리오 작성에 활용할 수 있습니다.

## TestDataRunner 실행 순서

```
Phase 1: 사용자 생성 (Google OAuth 시뮬레이션)
  ↓
Phase 2: 커스텀 그룹 생성
  ↓
Phase 3: 그룹 멤버십 및 역할 관리
  ↓
Phase 4: 모집 공고 및 지원서 생성
  ↓
Phase 5: 장소 생성 및 사용 권한 관리
  ↓
Phase 6: 장소 운영 시간 생성
  ↓
Phase 7: 페르소나별 시간표 생성
  ↓
Phase 8: 그룹 캘린더 일정 및 장소 예약 생성
```

## 테스트 사용자 정보

### 사용자 목록

| ID | 이메일 | 이름 | 닉네임 | 학번 | 소속 계열 | 소속 학과 | 학년 | 역할 |
|----|--------|------|--------|------|----------|----------|------|------|
| - | testuser1@hs.ac.kr | TestUser1 | TU1 | 20250011 | AI/SW계열 | AI/SW학과 | 1학년 | STUDENT |
| - | testuser2@hs.ac.kr | TestUser2 | TU2 | 20250012 | AI/SW계열 | (선택안함) | 2학년 | STUDENT |
| - | testuser3@hs.ac.kr | TestUser3 | TU3 | 20250013 | AI/SW계열 | AI시스템반도체학과 | 3학년 | STUDENT |
| - | professor1@hs.ac.kr | Professor1 | Prof1 | P00001 | AI/SW계열 | AI/SW학과 | 0학년 | PROFESSOR |

> **참고**: ID는 실행 시 동적으로 할당됩니다. 이메일로 사용자를 식별하는 것을 권장합니다.

### 사용자별 그룹 멤버십

#### TestUser1 (testuser1@hs.ac.kr)
- **자동 가입 그룹**: 한신대학교, AI/SW계열, AI/SW학과 (프로필 제출 시 자동)
- **생성한 그룹**: 코딩 동아리 'DevCrew' (그룹장 역할)
- **지원한 모집**: 학생회 2025년 2학기 신입 부원 모집
- **권한**: DevCrew 그룹의 모든 권한 (OWNER)

#### TestUser2 (testuser2@hs.ac.kr)
- **자동 가입 그룹**: 한신대학교, AI/SW계열 (학과 선택 안함)
- **생성한 그룹**: 학생회 (그룹장 역할)
- **작성한 모집**: 학생회 2025년 2학기 신입 부원 모집
- **관리하는 장소**: 학생회실 (학생회관 201호), 세미나실 (60주년 기념관 101호)
- **권한**: 학생회 그룹의 모든 권한 (OWNER)

#### TestUser3 (testuser3@hs.ac.kr)
- **자동 가입 그룹**: 한신대학교, AI/SW계열, AI시스템반도체학과 (프로필 제출 시 자동)
- **수동 가입 그룹**: 학생회 (커스텀 역할: 학생회 간부)
- **역할**: 학생회 간부 (CHANNEL_MANAGE, RECRUITMENT_MANAGE, CALENDAR_MANAGE 권한)

#### Professor1 (professor1@hs.ac.kr)
- **자동 가입 그룹**: 한신대학교, AI/SW계열, AI/SW학과 (프로필 제출 시 자동)
- **역할**: AI/SW학과 그룹의 교수

## 테스트 그룹 정보

### 기본 그룹 (data.sql에서 생성)

| ID | 그룹명 | 그룹 타입 | 부모 그룹 | 소유자 |
|----|--------|-----------|-----------|--------|
| 1 | 한신대학교 | UNIVERSITY | - | castlekong1019@gmail.com |
| 2 | AI/SW계열 | COLLEGE | 한신대학교 | castlekong1019@gmail.com |
| 3 | 경영/미디어계열 | COLLEGE | 한신대학교 | castlekong1019@gmail.com |
| 11 | AI시스템반도체학과 | DEPARTMENT | AI/SW계열 | castlekong1019@gmail.com |
| 12 | 미디어영상광고홍보학과 | DEPARTMENT | 경영/미디어계열 | castlekong1019@gmail.com |
| 13 | AI/SW학과 | DEPARTMENT | AI/SW계열 | castlekong1019@gmail.com |

### 커스텀 그룹 (TestDataRunner에서 생성)

| 그룹명 | 그룹 타입 | 부모 그룹 | 소유자 | 설명 | 태그 |
|--------|-----------|-----------|--------|------|------|
| 코딩 동아리 'DevCrew' | AUTONOMOUS | 한신대학교 | TestUser1 | 코딩과 개발을 사랑하는 사람들의 모임 | 코딩, 개발, 스터디 |
| 학생회 | OFFICIAL | 한신대학교 | TestUser2 | 한신대학교 총학생회 | 학생회, 공식 |

## 테스트 역할 정보

### 시스템 역할 (모든 그룹에 자동 생성)

| 역할명 | 우선순위 | 권한 | 수정 가능 |
|--------|---------|------|----------|
| 그룹장 | 100 | 모든 권한 | ❌ (불변) |
| 교수 | 90 | 대부분의 권한 | ❌ (불변) |
| 멤버 | 10 | 기본 권한 | ❌ (불변) |

### 커스텀 역할

#### 학생회 그룹
| 역할명 | 우선순위 | 권한 | 할당된 사용자 |
|--------|---------|------|--------------|
| 학생회 간부 | 50 | CHANNEL_MANAGE, RECRUITMENT_MANAGE, CALENDAR_MANAGE | TestUser3 |

## 테스트 모집 정보

| 모집 제목 | 그룹 | 작성자 | 마감일 | 질문 | 지원자 |
|-----------|------|--------|--------|------|--------|
| 학생회 2025년 2학기 신입 부원 모집 | 학생회 | TestUser2 | +2주 | 1. 자기소개를 해주세요.<br>2. 학생회에서 하고 싶은 일은 무엇인가요? | TestUser1 |

### 지원서 정보

**지원자**: TestUser1
- **지원 동기**: "학생 사회에 기여하고 싶습니다."
- **답변 1**: "안녕하세요, TestUser1입니다. 코딩을 좋아하고 학생회 활동에 관심이 많습니다."
- **답변 2**: "IT 인프라 개선 및 학생들을 위한 웹 서비스 개발을 하고 싶습니다."

## 테스트 장소 정보

| 장소명 | 건물 | 호수 | 별칭 | 수용 인원 | 관리 그룹 | 사용 승인 그룹 |
|--------|------|------|------|----------|-----------|---------------|
| 학생회관 201호 | 학생회관 | 201호 | 학생회실 | 25명 | 학생회 | DevCrew (승인됨) |
| 60주년 기념관 101호 | 60주년 기념관 | 101호 | 세미나실 | 50명 | 학생회 | AI/SW계열, AI/SW학과, AI시스템반도체학과 (승인됨) |

### 장소 사용 요청 정보

- **요청 그룹**: DevCrew, AI/SW계열, AI/SW학과, AI시스템반도체학과
- **요청자**: TestUser1, castlekong1019@gmail.com
- **사용 이유**: 스터디, 학과 행사, 세미나, 프로젝트 등
- **승인 상태**: APPROVED
- **승인자**: TestUser2

## 테스트 시간표(Personal Schedule) 정보

### TestUser1 - CS 전공 중심 (1학년)

| 과목명 | 요일 | 시간 | 장소 | 색상 |
|--------|------|------|------|------|
| 프로그래밍 1 | 월 | 09:00-10:30 | 학습관 201호 | #2196F3 (파란색) |
| 자료구조 | 수 | 10:30-12:00 | 학습관 301호 | #4CAF50 (초록색) |
| 알고리즘 | 금 | 14:00-15:30 | 학습관 201호 | #FF9800 (주황색) |
| DevCrew 코딩 스터디 | 목 | 18:00-20:00 | 학생회실 | #9C27B0 (보라색) |

**특징**: 프로그래밍 기초부터 고급까지 CS 핵심 과목 중심, 저녁 시간 스터디 활동

### TestUser2 - 교양과목 + 학생회 활동 (2학년)

| 과목명 | 요일 | 시간 | 장소 | 색상 |
|--------|------|------|------|------|
| 과학과 문명 | 화 | 09:00-10:30 | 강의동 101호 | #2196F3 (파란색) |
| 역사와 철학 | 목 | 10:30-12:00 | 강의동 205호 | #4CAF50 (초록색) |
| 학생회 정기회의 | 수 | 14:00-17:00 | 학생회실 | #F44336 (빨간색) |
| 학생회 사무시간 | 금 | 13:00-14:00 | 학생회실 | #FF5722 (짙은주황색) |

**특징**: 교양과목으로 문화/교양 소양 쌓기, 학생회 회의/사무 시간으로 바쁜 일정

### TestUser3 - 반도체 전공 + 학생회 활동 (3학년)

| 과목명 | 요일 | 시간 | 장소 | 색상 |
|--------|------|------|------|------|
| 반도체 공학 개론 | 월 | 11:00-12:30 | 공과관 501호 | #2196F3 (파란색) |
| 전자회로 설계 | 수 | 09:00-10:30 | 공과관 502호 | #4CAF50 (초록색) |
| 반도체 실험 | 금 | 14:00-15:30 | 공과관 Lab | #FF9800 (주황색) |
| 학생회 간부 회의 | 화 | 16:00-18:00 | 학생회실 | #F44336 (빨간색) |
| 학생회 업무 시간 | 목 | 12:00-13:00 | 학생회실 | #FF5722 (짙은주황색) |

**특징**: 반도체 전공으로 심화 기술 습득, 학생회 간부로 상당한 업무 시간

## 테스트 캘린더 및 예약 정보

| 이벤트 제목 | 그룹 | 유형 | 장소 | 예약자 | 날짜/시간 |
|---|---|---|---|---|---|
| 주간 알고리즘 스터디 | DevCrew | 비공식 (반복) | 온라인 (텍스트) | TestUser1 | 매주 월요일 19:00-21:00 |
| 총학생회 정기 회의 | 학생회 | 공식 (반복) | 학생회실 | TestUser2 | 매주 수요일 17:00-18:30 |
| 임시 회의 | 학생회 | 비공식 | 학생회실 | TestUser3 | 다음 주 화요일 13:00-14:00 |
| 팀 프로젝트 회의 | DevCrew | 비공식 | 학교 근처 카페 (텍스트) | TestUser1 | 다음 주 수요일 15:00-17:00 |
| AI/SW계열 개강 총회 | AI/SW계열 | 공식 | 세미나실 | castlekong1019@gmail.com | 다음 주 월요일 18:00-20:00 |
| 자료구조 특강 | AI/SW학과 | 공식 | 세미나실 | castlekong1019@gmail.com | 다음 주 화요일 15:00-17:00 |
| 졸업 프로젝트 회의 | AI시스템반도체학과 | 비공식 | 세미나실 | castlekong1019@gmail.com | 다음 주 수요일 10:00-12:00 |
| DevCrew 정기 스터디 | DevCrew | 비공식 (반복) | 학생회실 | TestUser1 | 매주 월요일 19:00-21:00 (10/27~11/24) |
| 학생회 정기 회의 | 학생회 | 공식 (반복) | 학생회실 | TestUser2 | 매주 화요일 17:00-18:30 (10/28~11/25) |
| 알고리즘 경진대회 대비 특강 | AI/SW학과 | 공식 | 세미나실 | castlekong1019@gmail.com | 10/29 14:00-16:00 |
| 코딩 테스트 스터디 | AI/SW학과 | 비공식 | 세미나실 | castlekong1019@gmail.com | 11/05 14:00-16:00 |
| 졸업생 멘토링 | AI/SW학과 | 공식 | 세미나실 | castlekong1019@gmail.com | 11/19 14:00-16:00 |
| 임베디드 시스템 프로젝트 회의 | AI시스템반도체학과 | 비공식 | 세미나실 | castlekong1019@gmail.com | 10/30 10:00-12:00 |
| 반도체 설계 공모전 준비 | AI시스템반도체학과 | 비공식 | 세미나실 | castlekong1019@gmail.com | 11/13 10:00-12:00 |
| 캡스톤 디자인 최종 발표 준비 | AI시스템반도체학과 | 공식 | 세미나실 | castlekong1019@gmail.com | 11/27 10:00-12:00 |

## 테스트 시나리오별 활용

### 권한 테스트 시나리오
```kotlin
// 그룹장 권한 테스트: TestUser1이 DevCrew 그룹 관리
groupManagementService.updateGroup(devCrewId, request, user1Id) // ✅ 성공

// 일반 멤버 권한 테스트: TestUser3이 학생회 그룹 관리 시도
groupManagementService.updateGroup(studentCouncilId, request, user3Id) // ❌ 실패

// 커스텀 역할 권한 테스트: TestUser3이 학생회 채널 관리
channelService.createChannel(workspaceId, request, user3Id) // ✅ 성공 (CHANNEL_MANAGE 권한)
```

### 모집 테스트 시나리오
```kotlin
// 모집 공고 작성 권한: TestUser2 (학생회 그룹장)
recruitmentService.createRecruitment(studentCouncilId, request, user2Id) // ✅

// 지원서 제출: TestUser1
recruitmentService.submitApplication(recruitmentId, request, user1Id) // ✅

// 지원서 조회 권한: TestUser3 (학생회 간부, RECRUITMENT_MANAGE 권한)
recruitmentService.getApplications(recruitmentId, user3Id) // ✅
```

### 장소 관리 테스트 시나리오
```kotlin
// 장소 생성: TestUser2 (학생회 그룹장)
placeService.createPlace(user2, request) // ✅

// 장소 사용 요청: TestUser1 (DevCrew 그룹장)
placeUsageGroupService.requestUsage(user1, placeId, request) // ✅

// 장소 사용 승인: TestUser2 (관리 그룹의 그룹장)
placeUsageGroupService.updateUsageStatus(user2, placeId, groupId, request) // ✅
```

## 테스트 데이터 확장 가이드

### 새 사용자 추가
```kotlin
val newUser = simulateGoogleLoginAndSignup(
    email = "testuser4@hs.ac.kr",
    name = "TestUser4",
    nickname = "TU4",
    college = "AI/SW계열",
    dept = "AI/SW학과",
    studentNo = "20250014",
    academicYear = 1
)
```

### 새 그룹 추가
```kotlin
val newGroup = groupManagementService.createGroup(
    CreateGroupRequest(
        name = "새 동아리",
        parentId = 1, // 한신대학교
        university = "한신대학교",
        groupType = GroupType.AUTONOMOUS,
        description = "설명",
        tags = setOf("태그1", "태그2")
    ),
    ownerId
)
```

## 주의사항

1. **중복 실행 방지**: TestDataRunner는 "코딩 동아리 'DevCrew'" 그룹이 이미 존재하면 스킵됩니다
2. **실행 순서**: GroupInitializationRunner(@Order(1)) 이후에 TestDataRunner(@Order(2))가 실행됩니다
3. **서비스 레이어 사용**: 모든 데이터는 서비스 레이어를 통해 생성되어 데이터 정합성이 보장됩니다
4. **트랜잭션**: @Transactional로 묶여 있어 에러 시 전체 롤백됩니다

## 관련 문서

- **테스트 전략**: [testing-strategy.md](testing-strategy.md)
- **데이터베이스 참조**: [../implementation/database-reference.md](../implementation/database-reference.md)
- **권한 시스템**: [../concepts/permission-system.md](../concepts/permission-system.md)
- **모집 시스템**: [../concepts/recruitment-system.md](../concepts/recruitment-system.md)
- **장소 관리**: [../concepts/calendar-place-management.md](../concepts/calendar-place-management.md)