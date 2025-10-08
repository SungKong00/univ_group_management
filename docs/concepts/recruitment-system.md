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

## 구현 상태 (2025-10-06)
| 항목 | 구현 여부 | 비고 |
|------|-----------|------|
| 단일 활성 모집 제한 | ✅ | 그룹당 OPEN 1개 검사 로직 존재 |
| 모집 CRUD | ✅ | DRAFT → OPEN → CLOSED 전환 지원 |
| 조기 마감 | ✅ | PATCH /close 엔드포인트 |
| 지원서 제출/조회 | ✅ | 중복 제출 방지 검사 |
| 지원서 심사(승인/거절) | ✅ | 승인 시 그룹 자동 가입 처리 |
| 지원서 철회 | ✅ | 지원자 본인만 삭제(철회) |
| 아카이브 조회 | ✅ | CLOSED 상태 포함 목록 (`/archive`) |
| JPA Dirty Checking 최적화 | ✅ | data class → class 전환, var 필드 직접 수정 |
| N+1 문제 해결 | ✅ | FETCH JOIN 쿼리 추가 (findByIdWithRelations) |
| 통계 엔드포인트 | ⏳ | `/stats` 설계만 존재 (집계 로직 미구현) |
| 자동 마감 배치 | ⏳ | 예약 작업 설계 예정 (Quartz/스케줄러) |
| 알림 시스템 연동 | ❌ | Notification 모듈 미구현 |
| 자동 승인(autoApprove) | ⏳ | 필드 존재 / 로직 단순화(미사용) |

## 향후 계획
- 통계: 지원자 수, 승인율, 평균 처리 시간 계산 캐시 (Redis 예정)
- 자동 마감: 마감일 도달 시 상태 전환 + 통계 스냅샷
- 알림: 생성/지원/심사/마감 이벤트 기반 푸시
- 질문 템플릿: 그룹별 자주 쓰는 질문 Preset 저장/재사용

## 권한 체계 요약 (정리)
| 기능 | 필요 권한 | 추가 조건 |
|------|-----------|-----------|
| 모집 생성/수정/삭제 | RECRUITMENT_MANAGE | 그룹 멤버여야 함 |
| 모집 조회(활성) | (없음) | 모든 사용자 조회 가능 |
| 지원서 제출 | (없음) | 이미 멤버면 불가 |
| 지원서 목록/심사 | RECRUITMENT_MANAGE | 해당 그룹 소속 |
| 지원서 상세 | RECRUITMENT_MANAGE 또는 본인 |  |
| 지원서 철회 | 본인 | 상태 PENDING 일 때 |
| 아카이브 조회 | RECRUITMENT_MANAGE |  |

## 데이터 모델

### GroupRecruitment (모집 게시글)
```kotlin
class GroupRecruitment(
    val id: Long,
    val group: Group,                    // 모집하는 그룹 (불변)
    val createdBy: User,                 // 작성자 (불변)
    var title: String,                   // 모집 제목 (수정 가능)
    var content: String?,                // 모집 내용 (수정 가능)
    var maxApplicants: Int?,             // 최대 지원자 수 (수정 가능)
    val recruitmentStartDate: LocalDateTime, // 모집 시작일 (불변)
    var recruitmentEndDate: LocalDateTime?,  // 모집 마감일 (수정 가능)
    var status: RecruitmentStatus,       // 모집 상태 (수정 가능)
    var autoApprove: Boolean,            // 자동 승인 여부 (수정 가능)
    var showApplicantCount: Boolean,     // 지원자 수 공개 여부 (수정 가능)
    var applicationQuestions: List<String>, // 지원서 질문 (수정 가능)
    val createdAt: LocalDateTime,
    var updatedAt: LocalDateTime,
    var closedAt: LocalDateTime?         // 마감 시점 (수정 가능)
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

## DTO 예시 (요약)
```jsonc
// 모집 생성 요청 (CreateRecruitmentRequest)
{
  "title": "2025 1학기 신입 기수 모집",
  "content": "활동 소개 ...",
  "maxApplicants": 30,
  "recruitmentEndDate": "2025-11-15T23:59:59",
  "autoApprove": false,
  "showApplicantCount": true,
  "applicationQuestions": ["지원 동기?", "관련 경험?"]
}

// 모집 응답 (RecruitmentResponse)
{
  "id": 12,
  "groupId": 7,
  "title": "2025 1학기 신입 기수 모집",
  "status": "OPEN",
  "maxApplicants": 30,
  "currentApplicants": 5,
  "recruitmentStartDate": "2025-10-01T10:11:12",
  "recruitmentEndDate": "2025-11-15T23:59:59",
  "showApplicantCount": true,
  "applicationQuestions": ["지원 동기?", "관련 경험?"],
  "createdAt": "2025-10-01T10:11:12",
  "updatedAt": "2025-10-01T10:11:12"
}

// 지원서 제출 (ApplicationCreateRequest)
{
  "motivation": "서비스 기획 역량 성장",
  "questionAnswers": {
    "0": "학교 프로젝트 경험",
    "1": "AI 경진대회 수상"
  }
}

// 지원서 응답 (ApplicationResponse)
{
  "id": 55,
  "recruitmentId": 12,
  "applicant": {"id": 21, "nickname": "학생A"},
  "status": "PENDING",
  "motivation": "서비스 기획 역량 성장",
  "questionAnswers": {"0": "학교 프로젝트 경험", "1": "AI 경진대회 수상"},
  "reviewedBy": null,
  "reviewComment": null,
  "appliedAt": "2025-10-01T11:22:33"
}
```

## 상태 전이 다이어그램 (개요)
```
DRAFT --(OPEN 요청)--> OPEN --(마감일/조기마감)--> CLOSED
                         └--(삭제)--> (제거)
```

## 주요 검증 로직
- 단일 활성 모집: `SELECT COUNT(*) WHERE group_id=? AND status='OPEN'` > 0 이면 생성/OPEN 전환 차단
- 중복 지원: `applicationRepository.existsByRecruitmentIdAndApplicantIdAndStatusNotWithdrawn`
- 승인 시 그룹 멤버십: 멤버가 아니면 GroupMember 생성 + 기본 역할(Member) 부여
- 철회: 상태가 PENDING 아니면 409 반환

## 에러 코드 (추가 제안)
| 코드 | 상황 | HTTP |
|------|------|------|
| RECRUITMENT_ALREADY_OPEN | 이미 OPEN 존재 | 409 |
| RECRUITMENT_CLOSED | 마감된 모집 접근 | 400 |
| APPLICATION_DUPLICATE | 중복 지원 | 409 |
| APPLICATION_NOT_PENDING | PENDING 아님 | 409 |

## API 매핑 표
| 엔드포인트 | 메서드 | 설명 | 요청 DTO | 응답 DTO | 권한 |
|-----------|--------|------|----------|----------|------|
| /groups/{groupId}/recruitments | POST | 모집 생성 | CreateRecruitmentRequest | RecruitmentResponse | RECRUITMENT_MANAGE |
| /groups/{groupId}/recruitments | GET | 활성 모집 조회 | - | RecruitmentResponse | - |
| /recruitments/{id} | PUT | 모집 수정 | UpdateRecruitmentRequest | RecruitmentResponse | RECRUITMENT_MANAGE |
| /recruitments/{id}/close | PATCH | 조기 마감 | - | RecruitmentResponse | RECRUITMENT_MANAGE |
| /recruitments/{id} | DELETE | 모집 삭제 | - | - | RECRUITMENT_MANAGE |
| /groups/{groupId}/recruitments/archive | GET | 아카이브 목록 | paging | List<RecruitmentSummary> | RECRUITMENT_MANAGE |
| /recruitments/public | GET | 공개 모집 검색 | 필터(q,status) | Page<RecruitmentSummary> | - |
| /recruitments/{id}/applications | POST | 지원서 제출 | ApplicationCreateRequest | ApplicationResponse | - |
| /recruitments/{id}/applications | GET | 지원서 목록 | paging | Page<ApplicationResponse> | RECRUITMENT_MANAGE |
| /applications/{id} | GET | 지원서 상세 | - | ApplicationResponse | 권한자/본인 |
| /applications/{id}/review | PATCH | 지원서 심사 | ApplicationReviewRequest | ApplicationResponse | RECRUITMENT_MANAGE |
| /applications/{id} | DELETE | 지원서 철회 | - | - | 본인 |
| /recruitments/{id}/stats | GET | 통계 조회 | - | RecruitmentStatsResponse | RECRUITMENT_MANAGE |

## 통계 응답(예시, 예정)
```json
{
  "recruitmentId": 12,
  "total": 20,
  "approved": 8,
  "rejected": 5,
  "pending": 7,
  "averageReviewTimeSeconds": 86400
}
```

## 관련 문서

### 개념 문서
- [권한 시스템](permission-system.md)
- [그룹 계층](group-hierarchy.md)
- [도메인 개요](domain-overview.md)

### 구현 가이드
- [백엔드 가이드](../implementation/backend-guide.md)
- [API 참조](../implementation/api-reference.md)
- [데이터베이스 설계](../implementation/database-reference.md)