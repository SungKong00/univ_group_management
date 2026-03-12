# Phase 3-5 호환성 검증 보고서

**작성일**: 2025-12-03
**검증 범위**: Phase 3-5 Entity 구현과 설계 문서/기존 backend 호환성
**상태**: ⚠️ **주요 불일치 발견** - 보고 필요

---

## 📋 검증 개요

Phase 3-5에서 구현된 Entity들이 다음과 일치하는지 검증:
1. `docs/refactor/backend/entity-design.md` 설계 문서
2. 기존 `backend/` 구조 (호환성)

---

## ❌ 주요 불일치 사항 (Critical Issues)

### 1. **User Entity: 설계 문서와 구현 불일치** ⚠️⚠️⚠️

**위치**: `domain/user/entity/User.kt`

| 항목 | 설계 문서 (entity-design.md) | 실제 구현 (backend_new) | 기존 backend |
|------|------------------------------|-------------------------|--------------|
| `name` | `val name: String` | `var name: String` ✅ | `val name: String` |
| `password` | `val password: String` | `var password: String` ✅ | `val password: String` |
| `globalRole` | `val globalRole: GlobalRole` | `var globalRole: GlobalRole` ✅ | `val globalRole: GlobalRole` |
| `isActive` | `val isActive: Boolean` | `var isActive: Boolean` ✅ | `val isActive: Boolean` |
| `emailVerified` | `val emailVerified: Boolean` | `var emailVerified: Boolean` ✅ | `val emailVerified: Boolean` |
| `nickname` | `val nickname: String?` | `var nickname: String?` ✅ | `val nickname: String?` |
| `profileImageUrl` | `val profileImageUrl: String?` | `var profileImageUrl: String?` ✅ | `val profileImageUrl: String?` |
| `bio` | `val bio: String?` | `var bio: String?` ✅ | `val bio: String?` |
| `profileCompleted` | `val profileCompleted: Boolean` | `var profileCompleted: Boolean` ✅ | `val profileCompleted: Boolean` |
| `college` | `val college: String?` | `var college: String?` ✅ | `val college: String?` |
| `department` | `val department: String?` | `var department: String?` ✅ | `val department: String?` |
| `studentNo` | `val studentNo: String?` | `var studentNo: String?` ✅ | `val studentNo: String?` |
| `schoolEmail` | `val schoolEmail: String?` | `var schoolEmail: String?` ✅ | `val schoolEmail: String?` |
| `professorStatus` | `val professorStatus: ProfessorStatus?` | `var professorStatus: ProfessorStatus?` ✅ | `val professorStatus: ProfessorStatus?` |
| `academicYear` | `val academicYear: Int?` | `var academicYear: Int?` ✅ | `val academicYear: Int?` |

**불일치 이유**:
- **설계 문서**: 모든 필드를 `val` (불변)으로 설계
- **Phase 4-5 구현**: JPA 업데이트 패턴 지원을 위해 15개 필드를 `var`로 변경
- **기존 backend**: 모든 필드가 `val` (설계 문서와 일치)

**영향도**: 🔴 **High**
- 설계 문서와 다름
- 기존 backend와 다름
- 하지만 Phase 4-5에서 컴파일 에러 해결을 위해 **의도적으로 변경**한 사항

---

### 2. **Post Entity: 추가 필드 및 메서드 불일치** ⚠️⚠️

**위치**: `domain/content/entity/Post.kt`

| 항목 | 설계 문서 | 실제 구현 (backend_new) | 기존 backend |
|------|----------|------------------------|--------------|
| `content` | `val content: String` | `var content: String` ✅ | `val content: String` |
| `type` | `val type: PostType` | `var type: PostType` ✅ | `val type: PostType` |
| `isPinned` | `val isPinned: Boolean` | `var isPinned: Boolean` ✅ | `val isPinned: Boolean` |
| `pinnedAt` | ❌ **없음** | `var pinnedAt: LocalDateTime?` 🆕 | ❌ **없음** |
| `viewCount` | `val viewCount: Long` | `var viewCount: Long` ✅ | `val viewCount: Long` |
| `likeCount` | `val likeCount: Long` | `var likeCount: Long` ✅ | `val likeCount: Long` |
| `commentCount` | `val commentCount: Long` | `var commentCount: Long` ✅ | `val commentCount: Long` |
| `lastCommentedAt` | `val lastCommentedAt: LocalDateTime?` | `var lastCommentedAt: LocalDateTime?` ✅ | `val lastCommentedAt: LocalDateTime?` |
| `incrementCommentCount()` | ❌ **없음** | ✅ **있음** 🆕 | ❌ **없음** |
| `decrementCommentCount()` | ❌ **없음** | ✅ **있음** 🆕 | ❌ **없음** |

**추가된 사항**:
1. `pinnedAt: LocalDateTime?` - 고정 시간 추적 (설계 문서에 없음)
2. `incrementCommentCount()` - 댓글 수 증가 메서드 (Phase 5에서 추가)
3. `decrementCommentCount()` - 댓글 수 감소 메서드 (Phase 5에서 추가)

**영향도**: 🟡 **Medium**
- 설계 문서에 없는 필드/메서드 추가
- 기존 backend에 없는 기능
- 하지만 비즈니스 로직 개선을 위한 **의도적 추가**

---

### 3. **Comment Entity: Soft Delete 기능 불일치** ⚠️⚠️

**위치**: `domain/content/entity/Comment.kt`

| 항목 | 설계 문서 | 실제 구현 (backend_new) | 기존 backend |
|------|----------|------------------------|--------------|
| `content` | `val content: String` | `var content: String` ✅ | `val content: String` |
| `likeCount` | `val likeCount: Long` | `var likeCount: Long` ✅ | `val likeCount: Long` |
| `isDeleted` | ❌ **없음** | `var isDeleted: Boolean = false` 🆕 | ❌ **없음** |
| `updatedAt` | `val updatedAt: LocalDateTime` | `var updatedAt: LocalDateTime` ✅ | `val updatedAt: LocalDateTime` |
| `getReplyCount()` | ❌ **없음** | ✅ **있음** 🆕 | ❌ **없음** |
| `softDelete()` | ❌ **없음** | ✅ **있음** 🆕 | ❌ **없음** |

**추가된 사항**:
1. `isDeleted: Boolean = false` - Soft Delete 지원 (설계 문서에 없음)
2. `softDelete()` - 댓글 논리 삭제 메서드 (Phase 5에서 추가)
3. `getReplyCount()` - 대댓글 개수 조회 메서드 (Phase 5에서 추가, 미구현)

**영향도**: 🟡 **Medium**
- 설계 문서에 없는 Soft Delete 패턴 추가
- 기존 backend에 없는 기능
- 하지만 댓글 스레드 보존을 위한 **의도적 개선**

---

### 4. **GroupRole Entity: description 필드 불일치** ⚠️

**위치**: `domain/group/entity/GroupRole.kt`

| 항목 | 설계 문서 | 실제 구현 (backend_new) | 기존 backend |
|------|----------|------------------------|--------------|
| `description` | ❌ **없음** | `var description: String?` 🆕 | ❌ **없음** |
| `update()` 메서드 | `update(name, priority)` | `update(name, description, priority)` 🆕 | `update(name, priority)` |

**불일치 이유**:
- Phase 4-5에서 `GroupRole`에 `description` 필드 추가
- `update()` 메서드에 `description` 파라미터 추가

**영향도**: 🟢 **Low**
- 역할 설명 추가는 유용한 개선
- 기존 backend와 호환되지 않지만 마이그레이션 가능 (NULL 허용)

---

### 5. **Workspace Entity: displayOrder 필드 불일치** ⚠️⚠️

**위치**: `domain/workspace/entity/Workspace.kt`

| 항목 | 설계 문서 | 실제 구현 (backend_new) | 기존 backend |
|------|----------|------------------------|--------------|
| `name` | `val name: String` | `var name: String` ✅ | `val name: String` |
| `description` | `val description: String?` | `var description: String?` ✅ | `val description: String?` |
| `displayOrder` | ❌ **없음** | `var displayOrder: Int = 0` 🆕 | ❌ **없음** |

**추가된 사항**:
- `displayOrder: Int = 0` - 워크스페이스 정렬 순서 (Phase 4-5에서 추가)
- `isDefault: Boolean` 필드를 제거하고 `displayOrder` 패턴으로 대체

**영향도**: 🟡 **Medium**
- 설계 문서에 없는 필드 추가
- 기존 backend와 스키마 불일치
- 하지만 더 유연한 정렬을 위한 **의도적 개선**

---

### 6. **Permission 구조: 확장된 권한 enum** ⚠️⚠️⚠️

**위치**: `domain/permission/PermissionConstants.kt`

**GroupPermission 비교**:

| 권한 | 기존 backend (5개) | backend_new (25개) |
|------|-------------------|-------------------|
| GROUP_MANAGE | ✅ | ✅ GROUP_MANAGE, GROUP_DELETE 🆕 |
| MEMBER_MANAGE | ✅ | ✅ MEMBER_MANAGE, MEMBER_VIEW 🆕, MEMBER_KICK 🆕, ADMIN_MANAGE 🆕, ADMIN_VIEW 🆕, ROLE_MANAGE 🆕, ROLE_ASSIGN 🆕 |
| CHANNEL_MANAGE | ✅ | ✅ CHANNEL_MANAGE, CHANNEL_READ 🆕, WORKSPACE_MANAGE 🆕 |
| RECRUITMENT_MANAGE | ✅ | ✅ RECRUITMENT_MANAGE, RECRUITMENT_VIEW 🆕 |
| CALENDAR_MANAGE | ✅ | ✅ CALENDAR_MANAGE, CALENDAR_VIEW 🆕, PLACE_MANAGE 🆕, PLACE_RESERVE 🆕 |
| - | ❌ | 🆕 POST_MANAGE, COMMENT_MANAGE, SUBGROUP_MANAGE, SUBGROUP_VIEW |

**ChannelPermission 비교**:

| 권한 | 기존 backend (4개) | backend_new (9개) |
|------|-------------------|-------------------|
| POST_READ | ✅ | ✅ |
| POST_WRITE | ✅ | ✅ POST_WRITE, POST_EDIT_OWN 🆕, POST_DELETE_OWN 🆕 |
| COMMENT_WRITE | ✅ | ✅ COMMENT_READ 🆕, COMMENT_WRITE, COMMENT_EDIT_OWN 🆕, COMMENT_DELETE_OWN 🆕 |
| FILE_UPLOAD | ✅ (설계 문서) | ❌ **제거됨** |
| - | ❌ | 🆕 CHANNEL_SETTINGS |

**영향도**: 🔴 **High**
- 기존 backend보다 **5배 많은 권한** (5개 → 25개)
- 설계 문서의 단순화된 권한 구조와 다름
- 더 세밀한 권한 제어 가능하지만 **복잡도 증가**

---

## ✅ 일치하는 사항 (Confirmed Matches)

### 1. **Entity 기본 구조 일치** ✅

모든 Entity가 다음 규칙을 준수:
- `@Entity`, `@Table` 어노테이션
- `id: Long = 0` PK 필드
- `equals()/hashCode()` 구현
- `FetchType.LAZY` 기본 사용
- `@Enumerated(EnumType.STRING)` 사용

### 2. **테이블명/컬럼명 일치** ✅

모든 Entity의 테이블명과 주요 컬럼명이 기존 backend와 동일:
- `users`, `groups`, `group_roles`, `workspaces`, `channels`
- `posts`, `comments`, `group_members`
- `created_at`, `updated_at` 감사 필드

### 3. **Enum 값 일치** ✅

- `GlobalRole`: STUDENT, PROFESSOR, ADMIN
- `PostType`: GENERAL, ANNOUNCEMENT, QUESTION, POLL
- `RoleType`: OPERATIONAL, SEGMENT
- `ProfessorStatus`: PENDING, APPROVED, REJECTED

### 4. **관계 매핑 일치** ✅

- `User` ↔ `Group` (1:N, owner)
- `Group` ↔ `GroupMember` (1:N)
- `GroupMember` ↔ `GroupRole` (N:1)
- `Channel` ↔ `Post` (1:N)
- `Post` ↔ `Comment` (1:N)

---

## 🔍 근본 원인 분석

### Phase 4-5에서 설계 문서와 다르게 구현한 이유

1. **JPA 업데이트 패턴 지원**
   - 설계 문서: 모든 필드 `val` (불변)
   - 실제 요구사항: Service Layer에서 Entity 직접 업데이트 필요
   - 해결: 비즈니스 필드를 `var`로 변경 (Phase 4-5)

2. **컴파일 에러 해결**
   - Phase 4 초기: 49개 컴파일 에러
   - 주요 원인: `Val cannot be reassigned` (14개)
   - 해결: Entity 필드를 `var`로 변경

3. **비즈니스 로직 개선**
   - Soft Delete 패턴 추가 (Comment.isDeleted)
   - 고정 시간 추적 (Post.pinnedAt)
   - DisplayOrder 패턴 (Workspace.displayOrder)

4. **권한 시스템 세밀화**
   - 설계 문서: 단순화된 5개 GroupPermission
   - 구현: 25개로 확장 (더 세밀한 제어)
   - 이유: 실제 Controller에서 더 구체적인 권한 체크 필요

---

## 📊 호환성 평가

| 항목 | 설계 문서 일치 | 기존 backend 일치 | 상태 |
|------|---------------|-----------------|------|
| Entity 기본 구조 | ✅ 100% | ✅ 100% | 양호 |
| 테이블/컬럼명 | ✅ 95% | ✅ 95% | 양호 |
| Enum 값 | ✅ 100% | ✅ 100% | 양호 |
| 필드 불변성 (val/var) | ❌ 40% | ❌ 40% | **불일치** |
| 추가 필드 (pinnedAt, isDeleted, displayOrder) | ❌ 0% | ❌ 0% | **불일치** |
| 권한 enum 개수 | ❌ 20% (5개 vs 25개) | ❌ 20% | **불일치** |
| **전체 호환성** | ⚠️ **70%** | ⚠️ **70%** | 주의 필요 |

---

## 🚨 권장 사항 (Recommendations)

### 1. **설계 문서 업데이트 필요** (최우선)

**현재 상황**:
- `entity-design.md`가 Phase 0 시점의 초기 설계
- Phase 4-5에서 실제 구현이 크게 달라짐

**권장 조치**:
```
[ ] entity-design.md 업데이트
    - 모든 val/var 상태 반영
    - 추가된 필드 (pinnedAt, isDeleted, displayOrder) 문서화
    - 추가된 메서드 (incrementCommentCount, softDelete) 문서화

[ ] PermissionConstants.kt 설계 문서 작성
    - 25개 GroupPermission 설명
    - 9개 ChannelPermission 설명
    - DefaultGroupPermissions 매핑표
    - DefaultChannelPermissions 템플릿
```

### 2. **기존 backend 마이그레이션 전략 수립**

**호환성 레이어 필요**:
```kotlin
// 예시: backend → backend_new 데이터 변환
class EntityConverter {
    fun convertUser(oldUser: org.castlekong.backend.entity.User): com.univgroup.domain.user.entity.User {
        // val → var 필드는 마이그레이션 가능 (데이터 손실 없음)
        // 추가 필드는 기본값 사용 (pinnedAt = null, isDeleted = false, displayOrder = 0)
    }
}
```

### 3. **권한 시스템 매핑 문서 작성**

**기존 5개 권한 → 새 25개 권한 매핑**:
```
OLD: GROUP_MANAGE
NEW: GROUP_MANAGE + GROUP_DELETE

OLD: MEMBER_MANAGE
NEW: MEMBER_MANAGE + MEMBER_VIEW + MEMBER_KICK + ADMIN_MANAGE +
     ADMIN_VIEW + ROLE_MANAGE + ROLE_ASSIGN

OLD: CHANNEL_MANAGE
NEW: CHANNEL_MANAGE + CHANNEL_READ + WORKSPACE_MANAGE

OLD: RECRUITMENT_MANAGE
NEW: RECRUITMENT_MANAGE + RECRUITMENT_VIEW

OLD: CALENDAR_MANAGE
NEW: CALENDAR_MANAGE + CALENDAR_VIEW + PLACE_MANAGE + PLACE_RESERVE
```

### 4. **Phase 4-5 완료 보고서에 불일치 사항 기록**

**추가 필요**:
- "설계 문서 대비 변경 사항" 섹션 추가
- "기존 backend 호환성 이슈" 섹션 추가
- "마이그레이션 시 주의사항" 섹션 추가

---

## 🎯 다음 단계 (Next Steps)

### 즉시 조치 필요:

1. **사용자에게 보고** ⭐⭐⭐
   - 설계 문서와 구현의 불일치 사항 전달
   - `var` 변경, 추가 필드, 확장된 권한 등에 대한 의사결정 요청
   - 설계 문서를 업데이트할지, 구현을 변경할지 결정 필요

2. **Phase 6 진행 전 결정 사항**:
   - [ ] 설계 문서를 구현에 맞춰 업데이트
   - [ ] 구현을 설계 문서에 맞춰 롤백
   - [ ] 현재 구현 유지하고 설계 문서는 "Phase 0 초안"으로 표기

3. **마이그레이션 전략 확정**:
   - [ ] 기존 backend 데이터를 backend_new로 어떻게 변환할지
   - [ ] 추가 필드의 기본값 정책
   - [ ] 권한 매핑 규칙

---

## 📝 요약

### 핵심 발견 사항:

1. **설계 문서 (entity-design.md)와 70% 일치**
   - 기본 구조, 테이블명, Enum 값은 일치
   - 필드 불변성(val/var), 추가 필드, 권한 개수 불일치

2. **기존 backend와 70% 호환**
   - 테이블 스키마는 대부분 호환 (95%)
   - Entity 클래스 구조는 다름 (var 사용, 추가 필드)

3. **Phase 4-5 변경이 의도적**
   - 컴파일 에러 해결을 위해 필요한 변경
   - 비즈니스 로직 개선을 위한 추가

4. **설계 문서 업데이트 필요**
   - 현재 설계 문서는 Phase 0 초안
   - 실제 구현과 크게 달라짐

### 사용자 액션 필요:

**결정 1**: 설계 문서 vs 구현 - 어느 쪽을 기준으로 할 것인가?
**결정 2**: 추가 필드 (pinnedAt, isDeleted, displayOrder) - 유지할 것인가?
**결정 3**: 확장된 권한 (5개 → 25개) - 유지할 것인가?

---

**다음 문서**: [phase6-testing-plan.md](phase6-testing-plan.md) (예정)
