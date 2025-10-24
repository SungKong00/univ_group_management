# 컴포넌트 구현 (Components)

## StateView - 범용 상태 관리 위젯

**파일**: presentation/widgets/common/state_view.dart

**목적**: AsyncValue의 loading/error/empty/data 상태를 통합 처리

**주요 기능**:
- AsyncValue<T> 자동 상태 처리
- 빈 상태 자동 감지 (emptyChecker)
- 커스터마이징 가능한 UI (아이콘, 제목, 액션 버튼)
- Extension 메서드로 간편한 사용

**사용 예시**:

```dart
final usersAsync = ref.watch(usersProvider);

return StateView<List<User>>(
  value: usersAsync,
  emptyChecker: (users) => users.isEmpty,
  emptyIcon: Icons.person_off,
  emptyTitle: '사용자가 없습니다',
  builder: (context, users) => UserList(users: users),
);
```

**효과**: 3개 페이지 적용으로 147줄 감소
- channel_list_section.dart (-55줄)
- role_management_section.dart (-9줄)
- recruitment_management_page.dart (-83줄)

## 게시글/댓글 시스템

**핵심 패턴**: 채팅형 역방향 스크롤 (reverse: true), 스크롤 위치 유지

**구조**:
- `presentation/widgets/post/`: post_card, post_list, post_composer
- `presentation/widgets/comment/`: comment_item, comment_composer
- `core/services/`: post_service, comment_service

## CollapsibleContent 위젯

**파일**: presentation/widgets/common/collapsible_content.dart

**기능**: `maxLines` 초과 시 "더보기" 버튼 자동 표시

```dart
CollapsibleContent(text: postContent, maxLines: 5)
```

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

## 네비게이션 컴포넌트

- **BreadcrumbWidget**: 단순 제목 표시
- **WorkspaceHeader**: 그룹/채널 + 드롭다운 (Provider 기반 경로 계산)

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
