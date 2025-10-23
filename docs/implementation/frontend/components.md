# 컴포넌트 구현 (Components)

## 게시글/댓글 시스템

### 핵심 동작 패턴

**채팅형 역방향 스크롤**: 최신 글이 화면 하단에 표시 (reverse: true)

**스크롤 위치 유지**: 이전 글 로드 시 자연스러운 위치 유지

**구조**:
- `presentation/widgets/post/`: post_card, post_list, post_composer, date_divider, post_skeleton
- `presentation/widgets/comment/`: comment_item, comment_composer
- `core/models/`: post_models, comment_models
- `core/services/`: post_service, comment_service

## CollapsibleContent 위젯

**용도**: 긴 텍스트 자동 접기/펼치기

**파일**: presentation/widgets/common/collapsible_content.dart

**기능**:
- `maxLines` 초과 시 자동으로 "더보기" 버튼 표시
- 사용자가 펼침/접힘 가능
- 부드러운 UI 전환

**사용 예시**:

```dart
// post_item.dart - 게시글 본문
CollapsibleContent(
  text: postContent,
  maxLines: 5,
)

// workspace_page.dart - 댓글 사이드바
CollapsibleContent(
  text: postPreview,
  maxLines: 3,
)
```

## 권한 기반 UI 제어

### 프론트엔드 권한 유틸리티

**파일**: lib/core/utils/permission_utils.dart

```dart
class PermissionUtils {
  static const List<String> groupManagementPermissions = [
    'GROUP_MANAGE', 'MEMBER_MANAGE', 'ROLE_MANAGE',
  ];

  static bool hasAnyGroupManagementPermission(List<String> permissions) {
    return permissions.any((p) => groupManagementPermissions.contains(p));
  }
}
```

**위젯에서 사용**:

```dart
final hasAdminAccess = PermissionUtils.hasAnyGroupManagementPermission(
  user.permissions
);

if (hasAdminAccess) {
  AdminButton()
} else {
  Text('관리 권한이 없습니다')
}
```

### API를 통한 동적 권한 확인

```dart
// 채널 권한 조회
final permissions = await ref.read(channelServiceProvider)
    .getMyPermissions(channelId);

// 조건부 렌더링
if (permissions.contains('POST_WRITE')) {
  PostComposer(channelId: channelId)
} else {
  Text('이 채널에 글을 작성할 권한이 없습니다')
}
```

## 키보드 입력 핸들링

Enter: 전송, Shift+Enter: 줄바꿈 처리로 다중 라인 입력 지원

## 네비게이션 컴포넌트

- **BreadcrumbWidget**: 단순 제목 표시
- **WorkspaceHeader**: 그룹/채널 + 드롭다운

Provider 기반 경로 계산으로 각 페이지가 자동으로 브레드크럼 표시

## 재사용 패턴

### WorkspaceEmptyState (상태 표시)

**파일**: presentation/pages/workspace/widgets/workspace_empty_state.dart

Enum으로 여러 빈 상태를 단일 위젯으로 처리:
- `WorkspaceEmptyType.groupHome` / `calendar` / `groupAdmin` 등
- 아이콘, 제목, 설명을 타입별로 자동 선택
- 수백 줄 중복 → 단일 위젯 재사용

### SlidePanel (사이드 패널)

**파일**: presentation/widgets/common/slide_panel.dart

화면 가장자리에서 부드럽게 나타나는 패널:
- 애니메이션 로직 캡슐화
- `isVisible`, `onDismiss`, `child` Props
- 백드롭(어두운 배경) 클릭으로 닫기
