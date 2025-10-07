# 그룹 관리 권한 유지보수 가이드

> **목적**: 새로운 그룹 관리 권한 추가 시 시스템 전반 업데이트 체크리스트

## 📋 현재 그룹 관리 권한 (4개)

| 권한 이름 | 설명 | 주요 기능 |
|---------|------|----------|
| `GROUP_MANAGE` | 그룹 정보 관리 | 그룹 정보 수정, 삭제, 소유권 이전 |
| `ADMIN_MANAGE` | 멤버 및 역할 관리 | 멤버 역할 변경, 강제 탈퇴, 역할 생성, 가입 승인 |
| `CHANNEL_MANAGE` | 채널 관리 | 채널 생성, 삭제, 설정 수정, 역할 바인딩 |
| `RECRUITMENT_MANAGE` | 모집 관리 | 모집 공고 작성, 지원서 심사 |

## 🔄 권한 추가 워크플로우

### Phase 1: 백엔드 정의
1. **`backend/.../entity/GroupPermission.kt`**
   - enum에 새 권한 추가
   ```kotlin
   enum class GroupPermission {
       GROUP_MANAGE,
       ADMIN_MANAGE,
       CHANNEL_MANAGE,
       RECRUITMENT_MANAGE,
       NEW_PERMISSION, // 👈 추가
   }
   ```
2. 권한 설명 주석 작성
3. 백엔드 테스트 작성

### Phase 2: 프론트엔드 동기화
1. **`frontend/.../utils/permission_utils.dart`** (필수)
   - `groupManagementPermissions` 리스트에 추가
   ```dart
   static const List<String> groupManagementPermissions = [
     'GROUP_MANAGE',
     'ADMIN_MANAGE',
     'CHANNEL_MANAGE',
     'RECRUITMENT_MANAGE',
     'NEW_PERMISSION', // 👈 추가
   ];
   ```
2. **`MembershipInfo.hasAnyGroupPermission`** (자동 반영)
   - PermissionUtils를 재사용하므로 별도 수정 불필요

### Phase 3: UI 업데이트 (선택)
1. **`frontend/.../pages/group/group_admin_page.dart`**
   - 새 권한에 대한 관리 섹션 추가 (필요 시)
   - `_AdminContentView`에 권한 기반 조건부 렌더링 추가

### Phase 4: 문서 업데이트
1. **본 문서** 권한 목록 테이블에 추가 (필수)
2. **`docs/concepts/permission-system.md`** 상세 설명 추가 (필수)
3. **`docs/implementation/api-reference.md`** 영향받는 API 문서화 (권장)

### Phase 5: 검증
1. 새 권한 보유자로 그룹 관리 페이지 접근 테스트
2. 해당 권한 필요 기능 동작 확인
3. 권한 없는 사용자 접근 거부 확인

## 📝 체크리스트

- [ ] 백엔드: `GroupPermission.kt` enum에 추가
- [ ] 프론트엔드: `permission_utils.dart`의 `groupManagementPermissions`에 추가
- [ ] UI: `group_admin_page.dart`에 관리 섹션 추가 (필요 시)
- [ ] 문서: 본 문서 권한 테이블 업데이트
- [ ] 문서: `permission-system.md` 상세 설명 추가
- [ ] 테스트: 새 권한 보유자 접근 확인
- [ ] 테스트: 권한 없는 사용자 거부 확인

## 🔗 관련 문서

- [권한 시스템 개념](../concepts/permission-system.md)
- [프론트엔드 가이드](../implementation/frontend-guide.md)
- [백엔드 가이드](../implementation/backend-guide.md)

## 📌 중요 노트

- 그룹 관리 페이지는 4개 권한 중 **하나라도** 있으면 접근 가능
- `permission_utils.dart` 수정하지 않으면 새 권한 보유자가 접근 불가
- `MembershipInfo.hasAnyGroupPermission`은 PermissionUtils를 재사용하므로 자동 반영

## 🆕 최근 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2025-10-08 | 권한 정보 중앙화: WorkspaceState에 currentGroupPermissions 추가, MembershipInfo 리팩토링 |
| 2025-10-07 | 최초 작성 |
