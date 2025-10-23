# 도메인 모델 설계

백엔드 시스템의 핵심 엔티티와 관계를 설명합니다.

## 개요

사용자(User)와 그룹(Group)을 중심으로 계층적 콘텐츠 구조를 형성합니다.
2단계 권한 모델(Group-Level + Channel-Level)로 세분화된 접근 제어를 지원합니다.

## 핵심 엔티티 관계

```
User [1:N] GroupMember [N:1] Group [1:1] Workspace [1:N] Channel [1:N] Post [1:N] Comment
                             ↓ (Self-join)
                          Group (parent)
                             ↓
                        GroupRole [1:N] GroupMember
                             ↓
                    GroupPermission (Set)
```

## 주요 설계 원칙

1. **계층적 그룹**: Group의 `parent` 필드로 대학→단과대학→학과 구조
2. **역할 기반 권한(RBAC)**: User가 아닌 GroupRole 중심으로 권한 관리
3. **2단계 권한 모델**:
   - L1(그룹 전체): GroupRole → GroupPermission
   - L2(채널별): ChannelRoleBinding → ChannelPermission
4. **콘텐츠 계층**: Group → Workspace → Channel → Post → Comment (Top-down)

## 코드 참조

**Entity 파일:**
- `backend/src/main/kotlin/org/castlekong/backend/entity/User.kt`
- `backend/src/main/kotlin/org/castlekong/backend/entity/Group.kt`
- `backend/src/main/kotlin/org/castlekong/backend/entity/GroupMember.kt`
- `backend/src/main/kotlin/org/castlekong/backend/entity/GroupRole.kt`
- `backend/src/main/kotlin/org/castlekong/backend/entity/Channel.kt`
- `backend/src/main/kotlin/org/castlekong/backend/entity/Post.kt`

**관계 메서드:**
- `GroupRole` 의 `permissions` (@ElementCollection)
- `ChannelRoleBinding` 의 권한 매핑

## 특수 엔티티

**프로세스 관련:**
- `GroupJoinRequest` - 가입 신청 기록
- `SubGroupRequest` - 하위 그룹 생성 신청
- `EmailVerification` - 학교 이메일 인증

## 관련 문서

- [권한 시스템](../concepts/permission-system.md) - RBAC 개념
- [그룹 계층](../concepts/group-hierarchy.md) - 계층 구조 상세
- [API 참조](../implementation/api-reference.md) - 엔티티 관련 API
- [DB 참조](../implementation/database-reference.md) - 스키마 세부사항
