# 워크스페이스: 관리 페이지 (Workspace Admin Pages)

본 문서는 워크스페이스 내 그룹 관리, 멤버 관리, 지원자 관리 페이지의 UI/UX를 정의합니다.

## 개요

관리 페이지는 그룹 관리 권한을 가진 사용자가 그룹의 채널, 멤버, 지원자를 관리하는 공간입니다. 이 페이지들은 워크스페이스의 채널 네비게이션에서 '관리자' 버튼을 통해 접근할 수 있습니다.

## 구현 현황 (2025-10-17)

### 완료된 페이지
- 그룹 관리 페이지 (GroupAdminPage)
- 멤버 관리 페이지 (MemberManagementPage)
- 지원자 관리 페이지 (ApplicationManagementPage)

### 준비 중인 기능
- 그룹 홈 (WorkspaceEmptyState 표시)
- 그룹 캘린더 (WorkspaceEmptyState 표시)

## 1. 그룹 관리 페이지

### 1.1. 접근 경로

워크스페이스 > 채널 네비게이션 > '관리자' 버튼 클릭

### 1.2. 구성 요소

**컴포넌트**: `GroupAdminPage`
**위치**: `frontend/lib/presentation/pages/group/group_admin_page.dart`

### 1.3. 동작

사용자가 채널 네비게이션의 '관리자' 버튼을 클릭하면, `workspace_page.dart`는 `GroupAdminPage` 위젯을 렌더링합니다. `workspace_state_provider`는 `previousView`를 기록하여 '뒤로가기' 시 이전 채널 뷰로 복귀할 수 있도록 지원합니다.

### 1.4. 권한 제어

현재 사용자가 그룹 관리 권한(`hasAnyGroupPermission`)을 가진 경우에만 '관리자' 버튼이 표시됩니다.

## 2. 멤버 관리 페이지

### 2.1. 접근 경로

워크스페이스 > 그룹 관리 페이지 > '멤버 목록' 클릭

### 2.2. 구성 요소

**컴포넌트**: `MemberManagementPage`
**위치**: `frontend/lib/presentation/pages/member_management/member_management_page.dart`

### 2.3. 동작

그룹 관리 페이지에서 '멤버 목록'을 클릭하면 `WorkspaceView`가 `memberManagement`로 변경되어 이 페이지로 이동합니다.

### 2.4. 반응형 레이아웃

#### 데스크톱 (768px 이상)
**테이블 레이아웃**:
```
[멤버 | 역할 | 가입일 | 상태 | 액션]
─────────────────────────────────────
[Row 1] 데이터...
[Row 2] 데이터...
```
- `Expanded(flex)` 비율 기반 열 너비
- 흰색 배경, 둥근 모서리 (`AppRadius.card`), 회색 테두리 (`AppColors.neutral300`)
- 구분선 (`Divider`)으로 행 분리

#### 모바일 (768px 미만)
**카드 레이아웃**:
```
┌─────────────────────────────────┐
│ [아바타] 멤버명                 │
│ 역할: [그룹장] Chip            │
│ 가입일: 2025.10.10             │
│ [관리] 버튼                    │
└─────────────────────────────────┘
```
- 각 멤버를 독립된 카드로 표시
- 패딩 16px, 카드 간격 12px
- 아이콘 + 텍스트 조합

## 3. 지원자 관리 페이지

### 3.1. 접근 경로

워크스페이스 > 그룹 관리 페이지 > '지원자 관리' 클릭

### 3.2. 구성 요소

**컴포넌트**: `ApplicationManagementPage`
**위치**: `frontend/lib/presentation/pages/recruitment_management/application_management_page.dart`

### 3.3. 동작

그룹 관리 페이지에서 '지원자 관리'를 클릭하면 `WorkspaceView`가 `applicationManagement`로 변경되어 이 페이지로 이동합니다.

### 3.4. 구성 요소

#### 탭 구조 (TabController 사용)
```
[모집 공고 관리] [지원자 관리]
─────────────────────────────────
(현재 탭 콘텐츠)
```

#### 상태 필터
"전체", "신청 완료", "승인", "반려", "철회" 상태를 선택할 수 있는 필터를 제공하여 지원자 목록을 필터링합니다.

#### 지원자 리스트
각 지원자는 리스트의 한 항목으로 표시됩니다:
- **항목 내용**: 지원자 프로필 이미지, 닉네임, 지원 날짜, 현재 상태(Chip 활용)
- **항목 클릭**: 지원서 상세 내용을 볼 수 있는 Dialog 또는 별도 페이지로 이동
- **정렬**: 철회된 지원서는 리스트 하단에 옅은 색상으로 표시

#### 심사 액션
"신청 완료" 상태의 지원자 항목 우측에 "승인" 버튼과 "반려" 버튼을 배치합니다:
- "반려" 클릭 시: 간단한 사유를 입력할 수 있는 Dialog 표시
- 심사 완료 시: 해당 지원자의 상태 변경 및 리스트 업데이트

### 3.5. 반응형 레이아웃

#### 데스크톱 (768px 이상)
**테이블 레이아웃**:
```
[지원자 | 지원 날짜 | 상태 | 심사자 | 액션]
─────────────────────────────────────────
[Row 1] 데이터...
[Row 2] 데이터...
```
- `Expanded(flex)` 비율 기반 열 너비
- 우측에 승인/반려 버튼 배치

#### 모바일 (768px 미만)
**카드 레이아웃**:
```
┌─────────────────────────────────┐
│ [아바타] 지원자명               │
│ 지원일: 2025.10.10             │
│ 상태: [신청 완료] Chip         │
│ [승인] [반려] 버튼             │
└─────────────────────────────────┘
```
- 각 지원자를 독립된 카드로 표시
- 패딩 16px, 카드 간격 12px

## 4. 준비 중인 페이지

### 4.1. WorkspaceEmptyState 컴포넌트

**위치**: `frontend/lib/presentation/pages/workspace/widgets/workspace_empty_state.dart`

이 위젯은 `WorkspaceEmptyType` 값을 받아, 기능에 맞는 아이콘과 텍스트를 표시합니다.

| 기능 | `WorkspaceEmptyType` | 표시 아이콘 | 표시 제목 |
| :--- | :--- | :--- | :--- |
| 그룹 홈 | `groupHome` | `Icons.home_outlined` | 그룹 홈 |
| 그룹 캘린더 | `calendar` | `Icons.calendar_today_outlined` | 캘린더 |
| 채널 미선택 | `noChannelSelected` | `Icons.tag` | "채널을 선택하세요" |

### 4.2. 향후 계획

그룹 홈 및 캘린더의 실제 기능은 각 개별 명세에 따라 순차적으로 구현될 예정입니다. 현재의 `WorkspaceEmptyState`는 해당 기능들이 구현되기 전까지의 Placeholder 역할을 수행합니다.

## 관련 문서

- [워크스페이스 페이지](workspace-pages.md) - 워크스페이스 전체 구조
- [워크스페이스 채널 뷰](workspace-channel-view.md) - 채널 및 게시글 시스템
- [모집 페이지](recruitment-pages.md) - 모집 공고 관련 페이지
- [네비게이션 및 페이지 플로우](navigation-and-page-flow.md) - 전체 네비게이션 구조
- [권한 시스템](../../concepts/permission-system.md) - 권한 개념
