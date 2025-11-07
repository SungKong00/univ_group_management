# 워크스페이스: 관리 페이지 (Workspace Admin Pages)

본 문서는 워크스페이스 내 그룹 관리, 멤버 관리, 지원자 관리 페이지의 UI/UX를 정의합니다.

## 개요

관리 페이지는 그룹 관리 권한을 가진 사용자가 그룹의 채널, 멤버, 지원자를 관리하는 공간입니다. 워크스페이스의 채널 네비게이션에서 '관리자' 버튼으로 접근하며, GroupAdminPage, MemberManagementPage, ApplicationManagementPage가 구현되어 있습니다.

## 1. 그룹 관리 페이지

**접근**: 워크스페이스 > 채널 네비게이션 > '관리자' 버튼
**컴포넌트**: `GroupAdminPage` (frontend/lib/presentation/pages/group/)
**동작**: 관리자 버튼 클릭 시 GroupAdminPage 렌더링, workspace_state_provider가 previousView 기록하여 뒤로가기 지원
**권한**: `hasAnyGroupPermission` 보유 시에만 버튼 표시

## 2. 멤버 관리 페이지

**접근**: 그룹 관리 페이지 > '멤버 목록' 클릭
**컴포넌트**: `MemberManagementPage` (frontend/lib/presentation/pages/member_management/)
**동작**: WorkspaceView가 memberManagement로 변경

### 반응형 레이아웃

**데스크톱 (≥768px)**: 테이블 형식 (멤버|역할|가입일|상태|액션), Expanded(flex) 비율 기반 열 너비, 흰색 배경, AppRadius.card, Divider로 행 분리
**모바일 (<768px)**: 카드 형식 (아바타, 멤버명, 역할 Chip, 가입일, 관리 버튼), 패딩 16px, 카드 간격 12px

## 3. 지원자 관리 페이지

**접근**: 그룹 관리 페이지 > '지원자 관리' 클릭
**컴포넌트**: `ApplicationManagementPage` (frontend/lib/presentation/pages/recruitment_management/)
**동작**: WorkspaceView가 applicationManagement로 변경

### 주요 기능

**탭**: [모집 공고 관리] [지원자 관리] (TabController 사용)
**상태 필터**: 전체, 신청 완료, 승인, 반려, 철회
**지원자 리스트**: 프로필, 닉네임, 지원 날짜, 상태 Chip 표시. 클릭 시 Dialog/페이지 전환. 철회 지원서는 하단에 옅은 색상으로 표시
**심사 액션**: "신청 완료" 상태 우측에 승인/반려 버튼. 반려 시 사유 입력 Dialog

### 반응형 레이아웃

**데스크톱 (≥768px)**: 테이블 형식 (지원자|지원 날짜|상태|심사자|액션), 우측에 승인/반려 버튼
**모바일 (<768px)**: 카드 형식 (아바타, 지원자명, 지원일, 상태 Chip, 승인/반려 버튼), 패딩 16px, 카드 간격 12px

## 4. WorkspaceEmptyState 컴포넌트

**컴포넌트**: `WorkspaceEmptyState` (frontend/lib/presentation/pages/workspace/widgets/)
**역할**: 기능 구현 전 Placeholder. WorkspaceEmptyType 값에 따라 아이콘과 텍스트 표시
**지원 타입**: groupHome (Icons.home_outlined, "그룹 홈"), calendar (Icons.calendar_today_outlined, "캘린더"), noChannelSelected (Icons.tag, "채널을 선택하세요")

## 관련 문서

- [워크스페이스 페이지](workspace-pages.md) - 워크스페이스 전체 구조
- [워크스페이스 채널 뷰](workspace-channel-view.md) - 채널 및 게시글 시스템
- [모집 페이지](recruitment-pages.md) - 모집 공고 관련 페이지
- [네비게이션 및 페이지 플로우](navigation-and-page-flow.md) - 전체 네비게이션 구조
- [권한 시스템](../../concepts/permission-system.md) - 권한 개념
