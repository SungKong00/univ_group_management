# Database Design (Entity Relationship Diagram)

This document outlines the current database schema implementation status. 

**⚠️ 현재 구현 상태**: User 전역 역할 리팩터링 및 그룹 권한 스캐폴딩이 반영되었습니다.

## High-Level Summary

현재 구현된 도메인:
1.  **Users**: 기본 사용자 관리 (Google OAuth2 인증, GlobalRole)
2.  **Group Auth Scaffolding**: 그룹/멤버/그룹역할/권한 카탈로그 스키마 기본 골격

계획된 도메인 (부분/미구현):
3.  **Groups & Content**: 그룹 상세, 채널, 게시글, 댓글 관리 (API/로직 미구현)
4.  **Recruitment & System**: 모집 공고, 태그, 알림 시스템

---

## 1. Users (현재 구현됨)

### User (사용자) - ✅ 구현됨
**실제 구현된 스키마:**
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 사용자 고유 번호 |
| `email` | VARCHAR(100) | Not Null, **Unique** | 이메일 주소 (Google OAuth2 로그인) |
| `name` | VARCHAR(50) | Not Null | 실명 |
| `nickname` | VARCHAR(30) | | 사용자 닉네임 |
| `profile_image_url` | VARCHAR(500) | | 프로필 이미지 URL |
| `bio` | VARCHAR(500) | | 자기소개 |
| `password_hash` | VARCHAR(255) | Not Null | 패스워드 해시 (현재 사용되지 않음) |
| `global_role` | ENUM | Not Null | 전역 역할 (STUDENT, PROFESSOR, ADMIN) |
| `profile_completed` | BOOLEAN | Not Null | 프로필 완성 여부 (기본값: false) |
| `email_verified` | BOOLEAN | Not Null | 이메일 인증 여부 (기본값: false) |
| `is_active` | BOOLEAN | Not Null | 계정 활성화 상태 |
| `created_at` | DATETIME | Not Null | 생성 일시 |
| `updated_at` | DATETIME | Not Null | 수정 일시 |

**최근 업데이트 (2025-09-11):**
- ✅ nickname, profile_image_url, bio 필드 추가
- ✅ profile_completed 필드 추가 (회원가입 플로우 제어용)
- ✅ email_verified 필드 추가 (향후 이메일 인증 기능용)
- password_hash 필드 존재 (Google OAuth2만 사용하므로 실제로는 사용되지 않음)

---

## 2. Group Auth Scaffolding (부분 구현)

### Group (그룹) - ✅ 스키마 추가
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 그룹 고유 번호 |
| `name` | VARCHAR(100) | Not Null, **Unique** | 그룹 이름 |

### GroupRole (그룹 역할) - ✅ 스키마 추가
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 역할 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 소속 그룹 |
| `name` | VARCHAR(50) | Not Null | 역할 이름 (OWNER/ADVISOR/MEMBER/커스텀) |
| `is_system_role` | BOOLEAN | Not Null | 시스템 역할 여부 |

### GroupRolePermission (역할-권한 집합) - ✅ 스키마 추가
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `group_role_id` | BIGINT | **FK** (GroupRole.id) | 그룹 역할 ID |
| `permission` | VARCHAR(50) | Not Null | 권한 키 (Enum: GROUP_MANAGE 등) |

### GroupMember (그룹 멤버) - ✅ 스키마 추가
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 멤버 관계 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 그룹 ID |
| `user_id` | BIGINT | Not Null, **FK** (User.id) | 사용자 ID |
| `role_id` | BIGINT | Not Null, **FK** (GroupRole.id) | 그룹 내 역할 ID |
| `joined_at` | DATETIME | Not Null | 가입 일시 |

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

## 3. Groups & Content (미구현) ❌

**⚠️ 주의**: 아래 엔티티들은 모두 미구현 상태입니다.

### Group (그룹) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 그룹 고유 번호 |
| `parent_id` | BIGINT | **FK** (self-reference) | 상위 그룹 ID (계층 구조) |
| `name` | VARCHAR(100) | Not Null | 그룹 이름 |
| `description` | TEXT | | 그룹 소개 |
| `created_at` | DATETIME | Not Null | 생성 일시 |

### Channel (채널) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 채널 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 채널이 속한 그룹 ID |
| `name` | VARCHAR(100) | Not Null | 채널 이름 (예: 공지사항) |

### Post (게시글) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 게시글 고유 번호 |
| `channel_id` | BIGINT | Not Null, **FK** (Channel.id) | 게시글이 등록된 채널 ID |
| `author_id` | BIGINT | Not Null, **FK** (User.id) | 작성자 ID |
| `title` | VARCHAR(255) | Not Null | 제목 |
| `content` | TEXT | Not Null | 내용 |
| `created_at` | DATETIME | Not Null | 생성 일시 |

### Comment (댓글) - ❌ 미구현
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 댓글 고유 번호 |
| `post_id` | BIGINT | Not Null, **FK** (Post.id) | 부모 게시글 ID |
| `author_id` | BIGINT | Not Null, **FK** (User.id) | 작성자 ID |
| `parent_comment_id` | BIGINT | **FK** (self-reference) | 부모 댓글 ID (대댓글 구조) |
| `content` | TEXT | Not Null | 내용 |
| `created_at` | DATETIME | Not Null | 생성 일시 |

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
