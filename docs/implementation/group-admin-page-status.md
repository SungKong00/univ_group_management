# 그룹 관리자 페이지 구현 상태

> **현재 상태**: Phase 2 진행 중 (핵심 기능 구현)

## 📊 진행률

- [x] Phase 1: UI 스캐폴딩 (100%)
- [ ] Phase 2: 핵심 기능 구현 (진행 중 - 약 75%)
  - [x] 그룹 정보 수정
  - [x] 멤버 목록 페이지 연동
  - [x] 멤버 관리 백엔드 연동 (Phase 1)
  - [x] 역할 관리 및 가입 신청 백엔드 연동 (Phase 2)
  - [ ] 그룹 삭제
  - [ ] 채널 관리
  - [ ] 모집 관리

---

## ✅ 완료된 작업

### Phase 2 (진행 중)

#### 1. 그룹 정보 수정 기능 구현
- **상태**: **완료**
- **내용**:
    - `showEditGroupDialog`를 통해 그룹 이름, 설명, 모집 여부, 태그를 수정하는 다이얼로그를 제공합니다.
    - 백엔드 연동을 위해 `GroupService`에 `updateGroup` 메서드와 `UpdateGroupRequest` 모델을 추가했습니다. (`PUT /api/groups/{id}`)
    - 수정 성공 시 `myGroupsProvider`를 invalidate하여 그룹 목록을 갱신합니다.
- **파일**:
    - `frontend/lib/presentation/widgets/dialogs/edit_group_dialog.dart` (신규)
    - `frontend/lib/core/services/group_service.dart` (수정)
    - `frontend/lib/core/models/group_models.dart` (수정)

#### 2. 멤버 목록 페이지 연동
- **상태**: **완료**
- **내용**:
    - '멤버 목록' 액션 카드 클릭 시, `WorkspaceState`를 변경하여 `MemberManagementPage`로 화면을 전환합니다.
    - `WorkspaceView`에 `memberManagement`를 추가하여 새로운 페이지 뷰를 정의했습니다.
- **파일**:
    - `frontend/lib/presentation/pages/group/group_admin_page.dart` (수정)
    - `frontend/lib/presentation/providers/workspace_state_provider.dart` (수정)
    - `frontend/lib/presentation/pages/member_management/member_management_page.dart` (신규)

#### 5. 멤버 관리 백엔드 연동 (Phase 1, 2025-10-09)
- **상태**: **완료**
- **내용**:
    - **MemberRepository API 구현** (`ApiMemberRepository`)
        - `getMembers(groupId)` - GET /api/groups/{groupId}/members
        - `updateMemberRole(groupId, userId, roleId)` - PUT /api/groups/{groupId}/members/{userId}/role
        - `removeMember(groupId, userId)` - DELETE /api/groups/{groupId}/members/{userId}
        - 백엔드 응답(중첩 구조)을 프론트엔드 모델(평평한 구조)로 변환하는 `_parseGroupMember()` 메서드
    - **Provider 파라미터 수정**
        - `UpdateMemberRoleParams`: `memberId` (int) → `userId` (String), `roleId` 타입 int로 명시
        - `RemoveMemberParams`: `memberId` (int) → `userId` (String)
        - 백엔드 API 명세에 맞춰 userId 기반 호출로 변경
    - **멤버 강제 탈퇴 기능**
        - 확인 다이얼로그 구현 (되돌릴 수 없음 경고 포함)
        - API 연동 완료
        - 성공/실패 SnackBar 표시
    - **역할 변경 기능**
        - RoleDropdown에서 역할 선택 시 API 호출
        - roleId String → Int 파싱 처리
        - 성공/실패 SnackBar 표시
        - 자동 목록 갱신 (ref.invalidate)
- **파일**:
    - `frontend/lib/core/repositories/member_repository.dart` (수정 - ApiMemberRepository 추가)
    - `frontend/lib/core/repositories/repository_providers.dart` (수정 - ApiMemberRepository 사용)
    - `frontend/lib/presentation/pages/member_management/providers/member_list_provider.dart` (수정 - userId 파라미터)
    - `frontend/lib/presentation/pages/member_management/widgets/member_list_section.dart` (수정 - API 연동)

#### 6. 역할 관리 및 가입 신청 백엔드 연동 (Phase 2, 2025-10-09)
- **상태**: **완료**
- **내용**:
    - **RoleRepository API 구현** (`ApiRoleRepository`)
        - `getGroupRoles(groupId)` - GET /api/groups/{groupId}/roles
        - `createRole(groupId, name, description, permissions)` - POST /api/groups/{groupId}/roles
        - `updateRole(groupId, roleId, name, description, permissions)` - PUT /api/groups/{groupId}/roles/{roleId}
        - `deleteRole(groupId, roleId)` - DELETE /api/groups/{groupId}/roles/{roleId}
        - 백엔드 응답 파싱 및 GroupRole 모델 변환
    - **JoinRequestRepository API 구현** (`ApiJoinRequestRepository`)
        - `getPendingRequests(groupId)` - GET /api/groups/{groupId}/join-requests
        - `approveRequest(groupId, requestId, assignedRoleId)` - PATCH with decision: APPROVE
        - `rejectRequest(groupId, requestId)` - PATCH with decision: REJECT
    - **Repository Provider 변경**
        - `roleRepositoryProvider`: Mock → ApiRoleRepository로 전환
        - `joinRequestRepositoryProvider`: Mock → ApiJoinRequestRepository로 전환
    - **역할 생성 다이얼로그 구현** (신규 파일: `create_role_dialog.dart`)
        - 역할 이름 TextField (필수, 50자 제한)
        - 설명 TextField (선택, 200자 제한)
        - 4개 권한 체크박스 (GROUP_MANAGE, MEMBER_MANAGE, CHANNEL_MANAGE, RECRUITMENT_MANAGE)
        - 유효성 검증 (이름 빈 값, 권한 최소 1개 선택)
        - createRoleProvider 연동
        - 성공/실패 SnackBar 표시
    - **역할 수정 다이얼로그 구현** (신규 파일: `edit_role_dialog.dart`)
        - CreateRoleDialog와 동일한 UI 구조
        - 기존 역할 값으로 필드 미리 채우기
        - 시스템 역할 수정 방지 (isSystemRole 체크)
        - updateRoleProvider 연동
        - 성공/실패 SnackBar 표시
    - **RoleManagementSection 완성**
        - TODO 주석을 실제 다이얼로그 호출 코드로 대체
        - 역할 생성/수정/삭제 버튼에 API 연동 완료
        - 성공 시 자동 목록 갱신 (ref.invalidate)
- **기술적 결정사항**:
    - **API 파라미터 설계**: userId 기반 호출 방식 채택 (옵션 B)
        - 백엔드 GroupController.kt가 userId 파라미터 요구
        - 복합 인덱스 `(group_id, user_id)` 최적화 완료
        - 성능 차이 1-2ms로 무시 가능 (네트워크 지연에 비해 미미)
    - **중복 구현 방지 원칙**
        - 기존 UI 컴포넌트 수정 금지
        - 기존 Provider/모델 구조 유지
        - MemberRepository, EditGroupDialog 패턴 참고
- **파일**:
    - `frontend/lib/core/repositories/role_repository.dart` (수정 - ApiRoleRepository 추가)
    - `frontend/lib/core/repositories/join_request_repository.dart` (수정 - ApiJoinRequestRepository 추가)
    - `frontend/lib/core/repositories/repository_providers.dart` (수정 - Provider 전환)
    - `frontend/lib/presentation/widgets/dialogs/create_role_dialog.dart` (신규)
    - `frontend/lib/presentation/widgets/dialogs/edit_role_dialog.dart` (신규)
    - `frontend/lib/presentation/pages/member_management/widgets/role_management_section.dart` (수정)

#### 3. `GroupVisibility` 개념 제거
- **상태**: **완료**
- **내용**:
    - 백엔드 API 변경에 따라 프론트엔드 모델(`GroupMembership`) 및 관련 코드에서 `visibility` 속성을 제거했습니다.
    - '공개 범위 설정' 기능은 UI에 남아있으나, 기능적으로 폐기될 예정입니다.

#### 4. UI 리팩토링
- **상태**: **완료**
- **내용**:
    - `group_admin_page.dart` 내부에 있던 `_ActionCard`를 `widgets/cards/action_card.dart` 공용 위젯으로 분리하여 재사용성을 높였습니다.
    - `isDestructive` 속성을 추가하여 '삭제'와 같은 위험한 액션을 시각적으로 구분할 수 있도록 개선했습니다.

### Phase 1

- **GroupAdminPage UI 스캐폴딩**: 4개 관리 섹션(그룹 설정, 멤버, 채널, 모집)의 기본 구조와 권한 기반 렌더링을 구현했습니다.

---

## 🚀 다음 작업 (Phase 2 계속)

### 우선순위 1: 멤버 관리
1. ~~**멤버 목록 및 관리** (난이도: 상)~~ **✅ 완료 (2025-10-09)**
   - ~~실제 멤버 목록 조회, 역할 변경 드롭다운, 강제 탈퇴 기능 구현 필요.~~
   - 멤버 목록 조회, 역할 변경, 강제 탈퇴 기능 모두 백엔드 API 연동 완료
2. ~~**역할 관리 및 권한** (난이도: 상)~~ **✅ 완료 (2025-10-09)**
   - ~~커스텀 역할 생성, Permission-Centric 매트릭스 UI 구현.~~
   - 역할 생성/수정/삭제 다이얼로그 구현 및 백엔드 API 연동 완료
   - 4개 권한 체크박스 (GROUP_MANAGE, MEMBER_MANAGE, CHANNEL_MANAGE, RECRUITMENT_MANAGE) 구현
   - 시스템 역할 보호 로직 적용
   - **선택사항**: Permission-Centric 매트릭스 UI (고급 기능, 현재 미구현)
3. ~~**가입 신청 승인/거절** (난이도: 중)~~ **✅ 완료 (2025-10-09)**
   - ~~대기 중인 신청 목록, 승인/거절 버튼.~~
   - ~~백엔드 API: GET /api/groups/{groupId}/join-requests, PATCH /api/groups/{groupId}/join-requests/{requestId}~~
   - 가입 신청 목록 조회, 승인/거절 기능 백엔드 API 연동 완료

### 우선순위 2: 그룹 설정
4. **그룹 삭제** (난이도: 상)
   - 확인 다이얼로그 + 유예 기간 또는 즉시 삭제 로직 구현.
5. **~~그룹 공개 설정~~** (상태: `폐기됨`)
   - `GroupVisibility` 개념 제거로 인해 해당 기능은 구현하지 않습니다.

### 우선순위 3: 채널 및 모집 관리
- 채널 생성/목록/권한 설정
- 모집 공고 작성/지원자 관리
- (기존 계획과 동일)

---

## 📂 코드 위치

### 메인 페이지
- `frontend/lib/presentation/pages/group/group_admin_page.dart`
- `frontend/lib/presentation/pages/member_management/member_management_page.dart`

### 공용 위젯
- `frontend/lib/presentation/widgets/cards/action_card.dart`

### 다이얼로그
- `frontend/lib/presentation/widgets/dialogs/edit_group_dialog.dart`
- `frontend/lib/presentation/widgets/dialogs/create_role_dialog.dart` (신규)
- `frontend/lib/presentation/widgets/dialogs/edit_role_dialog.dart` (신규)

### Repository 계층
- `frontend/lib/core/repositories/member_repository.dart`
- `frontend/lib/core/repositories/role_repository.dart`
- `frontend/lib/core/repositories/join_request_repository.dart`
- `frontend/lib/core/repositories/repository_providers.dart`

### 서비스 및 상태 관리
- `frontend/lib/core/services/group_service.dart`
- `frontend/lib/presentation/providers/workspace_state_provider.dart`
- `frontend/lib/presentation/pages/member_management/providers/member_list_provider.dart`

### UI 섹션 위젯
- `frontend/lib/presentation/pages/member_management/widgets/member_list_section.dart`
- `frontend/lib/presentation/pages/member_management/widgets/role_management_section.dart`

---

## 🔗 참고 자료

- [그룹 관리 페이지 UI/UX 명세](../ui-ux/pages/group-admin-page.md)
- [권한 시스템 개념](../concepts/permission-system.md)
- [프론트엔드 가이드](../implementation/frontend-guide.md)