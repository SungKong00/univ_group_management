# 모집 시스템 (Recruitment System)

## 개요

일반 유저가 그룹에 가입하기 위해 지원할 수 있는 시스템입니다. 그룹은 모집 게시글을 작성하여 신규 멤버를 모집하고, 유저들의 지원서를 관리할 수 있습니다.

## 핵심 비즈니스 규칙

### 모집 게시글 관리
- **그룹당 하나의 모집**: 각 그룹은 동시에 하나의 활성 모집 게시글만 가질 수 있음
- **마감일 설정**: 모집 생성 시 마감일을 지정할 수 있음 (선택사항)
- **조기 마감**: 권한자가 마감일 전에 모집을 조기 마감할 수 있음
- **지원자 수 공개**: 현재 지원자 수를 공개할지 선택 가능

### 지원서 관리
- **중복 지원 방지**: 동일한 모집에 대해 한 번만 지원 가능
- **지원서 상태**: PENDING, APPROVED, REJECTED, WITHDRAWN
- **지원자 철회**: 지원자가 직접 지원서를 철회할 수 있음
- **자동 그룹 가입**: 지원서 승인 시 해당 그룹에 자동으로 가입됨

### 아카이브 시스템
- **마감된 모집**: 마감된 모집 게시글은 자동으로 아카이브로 이동
- **권한자 전용**: 아카이브는 모집 권한을 가진 사용자만 조회 가능
- **이력 관리**: 과거 모집 이력 및 지원서 데이터 보관

## 권한 체계

### 모집 관련 권한
- **RECRUITMENT_MANAGE**: 모집 게시글 작성, 수정, 삭제, 조기 마감, 지원서 심사
- **일반 유저**: 공개된 모집 게시글 조회, 지원서 제출

### 권한별 기능
```
RECRUITMENT_MANAGE 권한자:
├── 모집 게시글 작성/수정/삭제
├── 모집 조기 마감
├── 지원서 목록 조회
├── 지원서 심사 (승인/거부)
├── 아카이브 조회
└── 모집 통계 조회

일반 유저:
├── 공개 모집 게시글 조회
├── 그룹 가입 지원서 제출
├── 본인 지원서 조회/철회
└── 공개된 지원자 수 조회 (설정에 따라)
```

## 데이터 모델

### GroupRecruitment (모집 게시글)
```kotlin
data class GroupRecruitment(
    val id: Long,
    val group: Group,                    // 모집하는 그룹
    val createdBy: User,                 // 작성자
    val title: String,                   // 모집 제목
    val content: String?,                // 모집 내용
    val maxApplicants: Int?,             // 최대 지원자 수
    val recruitmentStartDate: LocalDateTime, // 모집 시작일
    val recruitmentEndDate: LocalDateTime?,  // 모집 마감일
    val status: RecruitmentStatus,       // 모집 상태
    val autoApprove: Boolean,            // 자동 승인 여부
    val showApplicantCount: Boolean,     // 지원자 수 공개 여부
    val applicationQuestions: List<String>, // 지원서 질문
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val closedAt: LocalDateTime?         // 마감 시점
)

enum class RecruitmentStatus {
    DRAFT,      // 임시저장
    OPEN,       // 모집 중
    CLOSED,     // 모집 마감
    CANCELLED   // 모집 취소
}
```

### RecruitmentApplication (지원서)
```kotlin
data class RecruitmentApplication(
    val id: Long,
    val recruitment: GroupRecruitment,   // 모집 게시글
    val applicant: User,                 // 지원자
    val motivation: String?,             // 지원 동기
    val questionAnswers: Map<Int, String>, // 질문별 답변
    val status: ApplicationStatus,       // 지원서 상태
    val reviewedBy: User?,              // 심사자
    val reviewedAt: LocalDateTime?,     // 심사 시점
    val reviewComment: String?,         // 심사 코멘트
    val appliedAt: LocalDateTime,       // 지원 시점
    val updatedAt: LocalDateTime
)

enum class ApplicationStatus {
    PENDING,    // 검토 대기
    APPROVED,   // 승인됨 (그룹 가입)
    REJECTED,   // 거부됨
    WITHDRAWN   // 지원자가 철회
}
```

## API 설계

### 모집 게시글 API
```
POST   /api/groups/{groupId}/recruitments      # 모집 게시글 작성
GET    /api/groups/{groupId}/recruitments      # 활성 모집 게시글 조회
PUT    /api/recruitments/{recruitmentId}       # 모집 게시글 수정
DELETE /api/recruitments/{recruitmentId}       # 모집 게시글 삭제
PATCH  /api/recruitments/{recruitmentId}/close # 모집 조기 마감

GET    /api/groups/{groupId}/recruitments/archive # 아카이브 조회 (권한자만)
GET    /api/recruitments/public                   # 공개 모집 게시글 검색
```

### 지원서 API
```
POST   /api/recruitments/{recruitmentId}/applications    # 그룹 가입 지원서 제출
GET    /api/recruitments/{recruitmentId}/applications    # 지원서 목록 (권한자)
GET    /api/applications/{applicationId}                 # 지원서 상세 조회
PATCH  /api/applications/{applicationId}/review          # 지원서 심사
DELETE /api/applications/{applicationId}                 # 지원서 철회
```

## 비즈니스 플로우

### 모집 생성 플로우
1. **권한 확인**: RECRUITMENT_MANAGE 권한 검증
2. **기존 모집 확인**: 해당 그룹에 활성 모집이 있는지 확인
3. **모집 게시글 생성**: 내용, 마감일, 공개 설정 등 저장
4. **상태 관리**: OPEN 상태로 설정하여 활성화

### 그룹 가입 지원 플로우
1. **모집 상태 확인**: 모집이 활성 상태인지 확인
2. **중복 지원 확인**: 동일한 모집에 이미 지원했는지 확인
3. **마감일 확인**: 현재 시점이 마감일 이전인지 확인
4. **지원서 저장**: PENDING 상태로 지원서 생성

### 지원서 심사 플로우
1. **권한 확인**: RECRUITMENT_MANAGE 권한 검증
2. **상태 변경**: APPROVED 또는 REJECTED로 상태 업데이트
3. **심사 정보 기록**: 심사자, 심사 시점, 코멘트 저장
4. **자동 그룹 가입**: 승인 시 해당 그룹에 자동 가입 처리

### 모집 마감 플로우
1. **자동 마감**: 마감일 도달 시 배치 작업으로 자동 마감
2. **조기 마감**: 권한자가 수동으로 조기 마감 실행
3. **아카이브 이동**: CLOSED 상태로 변경 후 아카이브에서 관리
4. **통계 생성**: 모집 결과 요약 데이터 생성

## 제약사항

### 비즈니스 제약
- 그룹당 동시에 하나의 활성 모집만 가능
- 마감된 모집의 지원서는 수정 불가
- 아카이브 데이터는 90일간 보관 후 삭제
- 이미 그룹 멤버인 유저는 해당 그룹에 지원 불가

### 기술적 제약
- 지원서 첨부파일: 5MB 이하
- 모집 게시글 내용: 10,000자 이하
- 지원서 답변: 각 질문당 1,000자 이하

## 알림 시스템 (향후 구현)

### 알림 대상
- **모집 게시글 생성**: 그룹 관련 유저에게 알림
- **지원서 제출**: 모집 권한자에게 알림
- **지원서 심사 결과**: 지원자에게 알림
- **모집 마감 임박**: 모집 권한자에게 알림

## 관련 문서

### 개념 문서
- [권한 시스템](permission-system.md)
- [그룹 계층](group-hierarchy.md)
- [도메인 개요](domain-overview.md)

### 구현 가이드
- [백엔드 가이드](../implementation/backend-guide.md)
- [API 참조](../implementation/api-reference.md)
- [데이터베이스 설계](../implementation/database-reference.md)