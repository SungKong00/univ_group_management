# 그룹 관리자 페이지 구현 상태

> **현재 상태**: Phase 1 완료 (UI 스캐폴딩) → 디버깅 필요 → Phase 2 대기 (기능 구현)

## 📊 진행률

- [x] Phase 1: UI 스캐폴딩 (100%)
- [ ] 디버깅: 버튼 표시 이슈 해결 (진행 중)
- [ ] Phase 2: 각 기능 실제 구현 (0%)

---

## ✅ 완료된 작업 (Phase 1)

### 1. GroupAdminPage UI 구현
- **파일**: `frontend/lib/presentation/pages/group/group_admin_page.dart` (452줄)
- **구조**: 4개 관리 섹션 + 권한 기반 조건부 렌더링
- **디자인**: ActionCard 패턴, Title + Description, 토스 디자인 철학

### 2. 4개 관리 섹션 구성
| 섹션 | 필요 권한 | ActionCard 수 |
|------|----------|--------------|
| 그룹 설정 | GROUP_MANAGE | 3개 |
| 멤버 및 역할 관리 | MEMBER_MANAGE | 3개 |
| 채널 관리 | CHANNEL_MANAGE | 3개 |
| 모집 관리 | RECRUITMENT_MANAGE | 3개 |

### 3. 권한 시스템 통합
- WorkspaceState에 `currentGroupRole`, `currentGroupPermissions` 추가
- PermissionUtils를 단일 진실 공급원으로 사용
- MembershipInfo 리팩토링 (PermissionUtils 재사용)
- 권한명 통일: `MEMBER_MANAGE` (백엔드와 일치)

### 4. 네비게이션 연결
- workspace_page.dart에서 GroupAdminPage 렌더링
- 상단바 중복 제거 (글로벌 상단바 사용)

---

## ⚠️ 현재 문제 (디버깅 필요)

### 증상
- 채널 네비게이션의 채널 버튼 미표시
- 관리자 페이지 버튼 미표시

### 디버깅 체크리스트
- [ ] WorkspaceState의 `currentGroupPermissions`가 정상 로드되는지 확인
- [ ] `currentGroupProvider`가 null 반환하는지 확인
- [ ] `myGroupsProvider` 로딩 상태 확인
- [ ] 브라우저 콘솔 로그 확인
- [ ] API 응답에서 권한 목록 확인 (`/api/me/groups`)

---

## 🚀 다음 작업 (Phase 2: 기능 구현)

### 우선순위 1: 그룹 설정
1. **그룹 정보 수정** (난이도: 중)
   - 그룹명, 설명, 이미지 수정 폼
   - PUT `/api/groups/{id}` 연동
2. **그룹 공개 설정** (난이도: 하)
   - 공개 범위 선택 UI
3. **그룹 삭제** (난이도: 상)
   - 확인 다이얼로그 + 30일 유예 기간 안내

### 우선순위 2: 멤버 관리
4. **멤버 목록 및 관리** (난이도: 상)
   - 멤버 목록 테이블, 역할 변경 드롭다운, 강제 탈퇴
5. **역할 관리 및 권한** (난이도: 상)
   - 커스텀 역할 생성, Permission-Centric 매트릭스
6. **가입 신청 승인/거절** (난이도: 중)
   - 대기 중인 신청 목록, 승인/거절 버튼

### 우선순위 3: 채널 관리
7. **채널 생성** (난이도: 중)
   - 채널명, 타입, 설명 입력 폼
8. **채널 목록 및 설정** (난이도: 중)
   - 채널 리스트, 수정/삭제
9. **채널 권한 설정** (난이도: 상)
   - 역할별 채널 접근 권한 매트릭스

### 우선순위 4: 모집 관리
10. **모집 공고 작성/수정** (난이도: 중)
11. **지원서 확인/관리** (난이도: 중)
12. **모집 통계 확인** (난이도: 하)

---

## 📂 코드 위치

- **메인 페이지**: `frontend/lib/presentation/pages/group/group_admin_page.dart`
- **권한 유틸**: `frontend/lib/core/utils/permission_utils.dart`
- **상태 관리**: `frontend/lib/presentation/providers/workspace_state_provider.dart`
- **백엔드 권한**: `backend/src/main/kotlin/org/castlekong/backend/entity/GroupPermission.kt`

---

## 🔗 참고 자료

- [권한 시스템 개념](../concepts/permission-system.md)
- [권한 추가 가이드](../maintenance/group-management-permissions.md)
- [프론트엔드 가이드](../implementation/frontend-guide.md)
- [디자인 시스템](../ui-ux/concepts/design-system.md)
