# 컴포넌트 구현 (Components)

## StateView - 범용 상태 관리 위젯

**파일**: presentation/widgets/common/state_view.dart
**구현일**: 2025-10-24

**목적**: AsyncValue의 loading/error/empty/data 상태를 통합 처리

**주요 기능**:
- AsyncValue<T> 자동 상태 처리 (when 메서드 활용)
- 빈 상태 자동 감지 (emptyChecker 함수)
- 커스터마이징 가능한 UI (아이콘, 제목, 설명, 액션 버튼)
- Extension 메서드로 간편한 사용 (buildWith)
- 재시도 기능 (onRetry 콜백)

**사용 예시**:

```dart
// 기본 사용
final usersAsync = ref.watch(usersProvider);

return StateView<List<User>>(
  value: usersAsync,
  emptyChecker: (users) => users.isEmpty,
  emptyIcon: Icons.person_off,
  emptyTitle: '사용자가 없습니다',
  emptyDescription: '아직 등록된 사용자가 없습니다',
  builder: (context, users) => UserList(users: users),
  onRetry: () => ref.refresh(usersProvider),
);

// Extension 사용
return usersAsync.buildWith(
  context: context,
  builder: (users) => UserList(users: users),
  emptyChecker: (users) => users.isEmpty,
  emptyTitle: '사용자가 없습니다',
);
```

**적용 현황**: 9개 파일 (147줄 감소)
- workspace_page.dart
- recruitment_management_page.dart (-83줄)
- member_list_section.dart
- role_management_section.dart (-9줄)
- channel_list_section.dart (-55줄)
- recruitment_application_section.dart
- join_request_section.dart
- channel_management_page.dart
- application_management_page.dart

## 게시글/댓글 시스템

**핵심 패턴**: 채팅형 역방향 스크롤 (reverse: true), 스크롤 위치 유지

**구조**:
- `presentation/widgets/post/`: post_card, post_list, post_composer
- `presentation/widgets/comment/`: comment_item, comment_composer
- `core/services/`: post_service, comment_service

## CollapsibleContent - 접기/펼치기 텍스트 위젯

**파일**: presentation/widgets/common/collapsible_content.dart
**구현일**: 기존 구현

**목적**: 긴 텍스트를 자동으로 축약하고 "더 보기" 버튼으로 펼치기

**주요 기능**:
- maxLines 초과 자동 감지 및 축약
- 애니메이션 펼치기/접기 (AnimatedSize)
- 스크롤 가능한 확장 모드 (expandedScrollable)
- 커스터마이징 가능한 버튼 텍스트

**사용 예시**:

```dart
// 기본 사용 (전체 펼치기)
CollapsibleContent(
  content: post.content,
  maxLines: 5,
  style: AppTheme.bodyMedium,
)

// 스크롤 가능한 확장 모드
CollapsibleContent(
  content: longText,
  maxLines: 3,
  expandedScrollable: true,
  expandedMaxLines: 10, // 최대 10줄 높이로 제한 + 스크롤
)
```

**적용 현황**: 2개 파일
- recruitment_management_page.dart
- post_preview_widget.dart

## 권한 기반 UI 제어

**파일**: lib/core/utils/permission_utils.dart

**기능**: 그룹 관리 권한 체크 (GROUP_MANAGE, MEMBER_MANAGE, ROLE_MANAGE)

```dart
final hasAdminAccess = PermissionUtils.hasAnyGroupManagementPermission(
  user.permissions
);
if (hasAdminAccess) AdminButton()
```

**API 동적 권한**:

```dart
final permissions = await channelService.getMyPermissions(channelId);
if (permissions.contains('POST_WRITE')) PostComposer()
```

## CompactTabBar - 높이 최적화 탭 바

**파일**: presentation/widgets/common/compact_tab_bar.dart
**구현일**: 기존 구현

**목적**: 공간 효율성을 극대화한 탭 바 (표준 TabBar보다 20% 작음)

**주요 기능**:
- 최적화된 높이: 52dp (표준 대비 20% 감소)
- 아이콘 + 라벨 지원
- 커스터마이징 가능한 색상 및 스타일
- Toss 디자인 원칙 적용 (단순함, 여백)

**사용 예시**:

```dart
CompactTabBar(
  controller: _tabController,
  tabs: const [
    CompactTab(icon: Icons.people_outline, label: '멤버 목록'),
    CompactTab(icon: Icons.admin_panel_settings_outlined, label: '역할 관리'),
    CompactTab(icon: Icons.inbox_outlined, label: '가입 신청'),
  ],
  onTap: (index) {
    // 탭 변경 로직
  },
)
```

**적용 현황**:
- MemberManagementPage (멤버 목록 / 역할 관리 / 가입 신청)
- 기타 탭 기반 페이지

## 네비게이션 컴포넌트

- **BreadcrumbWidget**: 단순 제목 표시
- **WorkspaceHeader**: 그룹/채널 + 드롭다운 (Provider 기반 경로 계산)
- **BottomNavigation**: 모바일용 하단 네비게이션
- **SidebarNavigation**: 데스크톱용 사이드바 네비게이션
- **TopNavigation**: 상단 헤더 네비게이션

## 재사용 패턴

### WorkspaceEmptyState

**파일**: presentation/pages/workspace/widgets/workspace_empty_state.dart

Enum으로 여러 빈 상태 처리:
- `WorkspaceEmptyType.groupHome` / `calendar` / `groupAdmin`
- 아이콘/제목/설명 타입별 자동 선택

### SlidePanel

**파일**: presentation/widgets/common/slide_panel.dart

화면 가장자리에서 나타나는 패널 (애니메이션, 백드롭 클릭 닫기)

## 관련 문서

- [상태 관리](state-management.md) - Riverpod Provider 패턴
- [디자인 시스템](design-system.md) - 컴포넌트 스타일 가이드
- [반응형 디자인](responsive-design.md) - 레이아웃 패턴
