# Database Design (Entity Relationship Diagram)

This document outlines the current database schema implementation status. 

**⚠️ 현재 구현 상태**: 문서 기반 엔티티 정리 완료 (2025-09-12)
- GroupInvite 엔티티 삭제 (문서에 정의되지 않음)
- GroupPermission을 기존 14개 권한으로 축소
- Group, Channel, Post, Comment 엔티티 확장 구현 완료

## High-Level Summary

현재 구현된 도메인:
1.  **Users**: 기본 사용자 관리 (Google OAuth2 인증, GlobalRole)
2.  **Group Auth Scaffolding**: 그룹/멤버/그룹역할/권한 카탈로그 스키마 기본 골격
3.  **Groups & Content**: 그룹 상세, 채널, 게시글, 댓글 관리 (엔티티 구현 완료)

계획된 도메인 (미구현):
4.  **Recruitment & System**: 모집 공고, 태그, 알림 시스템 (엔티티 미구현)

---

## 1. Users (현재 구현됨)

### User (사용자) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 사용자 고유 번호 |
| `email` | VARCHAR(100) | Not Null, **Unique** | 이메일 주소 (Google OAuth2 로그인) |
| `name` | VARCHAR(50) | Not Null | 실명 |
| `nickname` | VARCHAR(50) | | 사용자 닉네임 |
| `profile_image_url` | VARCHAR(500) | | 프로필 이미지 URL |
| `bio` | VARCHAR(500) | | 자기소개 |
| `password_hash` | VARCHAR(255) | Not Null | 패스워드 해시 (현재 사용되지 않음) |
| `global_role` | ENUM | Not Null | 전역 역할 (STUDENT, PROFESSOR, ADMIN) |
| `profile_completed` | BOOLEAN | Not Null | 프로필 완성 여부 (기본값: false) |
| `email_verified` | BOOLEAN | Not Null | 이메일 인증 여부 (기본값: true, OTP는 후순위) |
| `department` | VARCHAR(100) | | 학과 |
| `student_no` | VARCHAR(30) | | 학번 |
| `school_email` | VARCHAR(100) | | 학교 이메일 (도메인 `hs.ac.kr` 권장) |
| `professor_status` | ENUM | | 교수 승인 상태 (PENDING, APPROVED, REJECTED) |
| `is_active` | BOOLEAN | Not Null | 계정 활성화 상태 |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

**최근 업데이트 (2025-09-13):**
- ✅ 온보딩 단일 화면 대응 필드 추가: `department`, `student_no`, `school_email`, `professor_status`
- ✅ `email_verified` 기본값 true (메일 인증은 MVP 말로 이연)
- ✅ UserResponse에 확장 필드 노출
  
과거 업데이트 (2025-09-11):
- nickname, profile_image_url, bio 필드 추가
- profile_completed 필드 추가 (회원가입 플로우 제어용)
- email_verified 필드 추가

---

## 2. Group Auth Scaffolding (부분 구현)

### Group (그룹) - ✅ 확장 구현됨
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 그룹 고유 번호 |
| `name` | VARCHAR(100) | Not Null, **Unique** | 그룹 이름 |
| `description` | VARCHAR(500) | | 그룹 소개 |
| `profile_image_url` | VARCHAR(500) | | 그룹 프로필 이미지 URL |
| `owner_id` | BIGINT | Not Null, **FK** (User.id) | 그룹 소유자 ID |
| `visibility` | ENUM | Not Null | 공개 설정 (PUBLIC, PRIVATE, INVITE_ONLY) |
| `is_recruiting` | BOOLEAN | Not Null | 모집 중 여부 |
| `max_members` | INT | | 최대 멤버 수 제한 |
| `tags` | ElementCollection | | 그룹 태그 집합 |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |
| `deleted_at` | DATETIME | | 소프트 삭제 일시 (30일 보존 후 영구 삭제) |

### GroupRole (그룹 역할) - ✅ 구현됨
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 역할 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 소속 그룹 |
| `name` | VARCHAR(50) | Not Null | 역할 이름 (그룹별 유니크) |
| `is_system_role` | BOOLEAN | Not Null | 시스템 역할 여부 (기본값: false) |
| `permissions` | ElementCollection | | 권한 집합 (group_role_permissions 테이블)

### GroupMember (그룹 멤버) - ✅ 구현됨
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 멤버 관계 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 그룹 ID (사용자별 유니크) |
| `user_id` | BIGINT | Not Null, **FK** (User.id) | 사용자 ID |
| `role_id` | BIGINT | Not Null, **FK** (GroupRole.id) | 그룹 내 역할 ID |
| `joined_at` | DATETIME | Not Null | 가입 일시 (기본값: 현재 시간) |

### GroupMemberPermissionOverride (개인 권한 오버라이드) - ✅ 추가
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 오버라이드 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 그룹 ID |
| `user_id` | BIGINT | Not Null, **FK** (User.id) | 사용자 ID |
| `allowed_permissions` | ElementCollection | | 추가로 허용된 권한 (열거형 컬렉션) |
| `denied_permissions` | ElementCollection | | 명시적으로 차단된 권한 (열거형 컬렉션) |

유효 권한 계산: `effective = role.permissions ∪ allowed − denied`.

### GroupPermission (권한 열거형) - ✅ 구현됨
**현재 정의된 14개 권한:**
- `GROUP_MANAGE`: 그룹 관리 권한
- `MEMBER_READ`: 멤버 조회 권한
- `MEMBER_APPROVE`: 멤버 승인 권한
- `MEMBER_KICK`: 멤버 제명 권한
- `ROLE_MANAGE`: 역할 관리 권한
- `CHANNEL_READ`: 채널 읽기 권한
- `CHANNEL_WRITE`: 채널 쓰기 권한
- `POST_CREATE`: 게시글 작성 권한
- `POST_UPDATE_OWN`: 자신의 게시글 수정 권한
- `POST_DELETE_OWN`: 자신의 게시글 삭제 권한
- `POST_DELETE_ANY`: 모든 게시글 삭제 권한
- `RECRUITMENT_CREATE`: 모집 공고 작성 권한
- `RECRUITMENT_UPDATE`: 모집 공고 수정 권한
- `RECRUITMENT_DELETE`: 모집 공고 삭제 권한

---

### JoinRequest (가입 신청) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 가입 신청 고유 번호 |
| `user_id` | BIGINT | Not Null, **FK** (User.id) | 신청한 사용자 ID |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 신청한 그룹 ID |
| `status` | VARCHAR(20) | Not Null | 상태 ('PENDING', 'APPROVED', 'REJECTED') |
| `created_at` | DATETIME | Not Null | 신청 일시 |

---

## 3. Groups & Content - ✅ 구현됨

**최근 업데이트 (2025-09-12):** 문서 정의에 따른 엔티티 정리 완료
- GroupInvite 엔티티 삭제 (문서에 정의되지 않음)
- GroupPermission을 기존 14개 권한으로 복구
- Group, Channel, Post, Comment 엔티티는 확장된 기능과 함께 구현 완료

### Group (그룹) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 그룹 고유 번호 |
| `name` | VARCHAR(100) | Not Null, **Unique** | 그룹 이름 |
| `description` | VARCHAR(500) | | 그룹 소개 |
| `profile_image_url` | VARCHAR(500) | | 그룹 프로필 이미지 URL |
| `owner_id` | BIGINT | Not Null, **FK** (User.id) | 그룹 소유자 ID |
| `visibility` | ENUM | Not Null | 공개 설정 (PUBLIC, PRIVATE, INVITE_ONLY) |
| `is_recruiting` | BOOLEAN | Not Null | 모집 중 여부 (기본값: false) |
| `max_members` | INT | | 최대 멤버 수 제한 |
| `tags` | ElementCollection | | 그룹 태그 집합 (group_tags 테이블) |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

### Channel (채널) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 채널 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 채널이 속한 그룹 ID |
| `name` | VARCHAR(100) | Not Null | 채널 이름 (그룹별 유니크) |
| `description` | VARCHAR(500) | | 채널 설명 |
| `type` | ENUM | Not Null | 채널 타입 (TEXT, VOICE, ANNOUNCEMENT, FILE_SHARE) |
| `is_private` | BOOLEAN | Not Null | 비공개 채널 여부 (기본값: false) |
| `display_order` | INT | Not Null | 채널 정렬 순서 |
| `created_by` | BIGINT | Not Null, **FK** (User.id) | 채널 생성자 ID |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

### Post (게시글) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 게시글 고유 번호 |
| `channel_id` | BIGINT | Not Null, **FK** (Channel.id) | 게시글이 등록된 채널 ID |
| `author_id` | BIGINT | Not Null, **FK** (User.id) | 작성자 ID |
| `title` | VARCHAR(200) | Not Null | 제목 |
| `content` | TEXT | Not Null | 내용 |
| `type` | ENUM | Not Null | 게시글 타입 (GENERAL, ANNOUNCEMENT, QUESTION, POLL, FILE_SHARE) |
| `is_pinned` | BOOLEAN | Not Null | 고정 여부 (기본값: false) |
| `view_count` | BIGINT | Not Null | 조회수 (기본값: 0) |
| `like_count` | BIGINT | Not Null | 좋아요 수 (기본값: 0) |
| `attachments` | ElementCollection | | 첨부 파일 URL 집합 (post_attachments 테이블) |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

### Comment (댓글) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 댓글 고유 번호 |
| `post_id` | BIGINT | Not Null, **FK** (Post.id) | 부모 게시글 ID |
| `author_id` | BIGINT | Not Null, **FK** (User.id) | 작성자 ID |
| `content` | TEXT | Not Null | 내용 |
| `parent_comment_id` | BIGINT | **FK** (self-reference) | 부모 댓글 ID (대댓글 구조) |
| `like_count` | BIGINT | Not Null | 좋아요 수 (기본값: 0) |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

---

## 4. Recruitment & System (미구현) ❌

**⚠️ 주의**: 아래 엔티티들은 모두 미구현 상태입니다.

### RecruitmentPost (모집 공고) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 모집 공고 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 공고를 게시한 그룹 ID |
| `title` | VARCHAR(255) | Not Null | 제목 |
| `content` | TEXT | Not Null | 본문 |
| `start_date` | DATE | Not Null | 모집 시작일 |
| `end_date` | DATE | Not Null | 모집 종료일 |
| `status` | VARCHAR(20) | Not Null | 상태 ('ACTIVE', 'CLOSED') |

### Tag (태그) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 태그 고유 번호 |
| `name` | VARCHAR(50) | Not Null, **Unique** | 태그 이름 (예: #스터디) |

### PostTag (공고-태그 매핑) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `post_id` | BIGINT | **PK**, **FK** (RecruitmentPost.id) | 모집 공고 ID |
| `tag_id` | BIGINT | **PK**, **FK** (Tag.id) | 태그 ID |

### Notification (알림) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 알림 고유 번호 |
| `recipient_id` | BIGINT | Not Null, **FK** (User.id) | 알림을 받는 사용자 ID |
| `type` | VARCHAR(50) | Not Null | 알림 종류 (예: `JOIN_APPROVED`) |
| `content` | VARCHAR(255) | Not Null | 알림 내용 |
| `is_read` | BOOLEAN | Not Null | 읽음 여부 |
| `created_at` | DATETIME | Not Null | 생성 일시 |
