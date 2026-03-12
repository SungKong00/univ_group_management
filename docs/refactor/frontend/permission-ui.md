# 권한을 UI 조건으로 (Permission as Condition, not State)

## 목적
프론트엔드에서 권한을 계산하지 않고, 백엔드가 제공한 권한 정보를 신뢰하여 사용. 프론트엔드는 단순히 UI 표시 여부만 결정.

## 현재 문제
- 프론트엔드에서 권한을 계산함 (post.authorId == userId)
- 백엔드에서도 권한을 검증함
- 둘이 다르면 버그 (프론트: 삭제 버튼 표시, 백: 403 거부)
- 권한 로직이 프론트/백에 중복
- 권한 변경 시 두 곳을 모두 수정해야 함

## 원칙
### 1. 백엔드가 제공한 권한 플래그를 신뢰
```dart
// 📌 API 응답에 항상 권한 정보 포함

// ✅ API 응답 (백엔드가 제공)
class PostDto {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final DateTime createdAt;

  // ✅ 백엔드가 계산한 권한 (프론트엔드는 신뢰하기만 함)
  final bool canDelete;      // 삭제 가능?
  final bool canEdit;        // 수정 가능?
  final bool canReply;       // 댓글 가능?
  final bool canViewAuthor;  // 작성자 정보 볼 수 있음?

  PostDto({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createdAt,
    required this.canDelete,
    required this.canEdit,
    required this.canReply,
    required this.canViewAuthor,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) {
    return PostDto(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      authorId: json['authorId'],
      createdAt: DateTime.parse(json['createdAt']),
      // 백엔드가 이미 계산한 권한
      canDelete: json['canDelete'] ?? false,
      canEdit: json['canEdit'] ?? false,
      canReply: json['canReply'] ?? false,
      canViewAuthor: json['canViewAuthor'] ?? true,
    );
  }
}

// ❌ 프론트엔드에서 권한 계산 (절대 금지!)
//
// final canDelete = post.authorId == currentUserId;  // ❌ 금지!
// final canEdit = post.authorId == currentUserId;     // ❌ 금지!
//
// 왜? 백엔드와 로직이 다를 수 있음
// (예: 그룹 관리자는 남의 글도 삭제 가능)
```

### 2. UI는 백엔드 플래그로만 표시
```dart
// ✅ UI는 단순히 표시하기만 함

class PostCardWidget extends ConsumerWidget {
  final PostDto post;

  const PostCardWidget({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 게시글 내용
        Text(post.title),
        Text(post.content),

        // ✅ 삭제 버튼: 백엔드 플래그 신뢰
        if (post.canDelete)
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deletePost(context, post.id),
          ),

        // ✅ 수정 버튼: 백엔드 플래그 신뢰
        if (post.canEdit)
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editPost(context, post),
          ),

        // ✅ 댓글 버튼: 백엔드 플래그 신뢰
        if (post.canReply)
          TextButton(
            onPressed: () => _showReplyDialog(context),
            child: Text('댓글 달기'),
          ),

        // ❌ 절대 금지: 프론트엔드에서 권한 계산
        // if (post.authorId == currentUserId)
        //   DeleteButton()
      ],
    );
  }

  void _deletePost(BuildContext context, String postId) {
    // 백엔드가 다시 권한 검증 (이중 검증)
    // 프론트가 잘못된 버튼을 표시했다면 백엔드에서 403 반환
  }
}
```

### 3. 권한 변경 시 API 응답 포함
```dart
// 📌 권한 변경 후에도 API 응답에 새로운 권한 포함

final deletePostProvider = FutureProvider.family<void, String>((ref, postId) async {
  final dataSource = ref.watch(apiDataSourceProvider);

  // 삭제 API 호출
  await dataSource.fetch(
    () => api.deletePost(postId),
  );

  // 삭제 후 목록 새로고침 (새로운 권한 정보 포함)
  ref.refresh(postListProvider(channelId));
});

// UI에서는 새로고침 후 자동으로 권한이 반영됨
void _deletePost(BuildContext context, String postId) {
  ref.read(deletePostProvider(postId)).then((_) {
    // 목록이 새로고침되고, canDelete 플래그도 새로 받음
  });
}
```

## 구현 패턴

### Before (현재 - 프론트에서 권한 계산)
```dart
// ❌ 문제: 프론트/백 권한 로직 중복

// 백엔드
@GetMapping("/posts/{id}")
fun getPost(@PathVariable id: Long): ApiResponse<PostDto> {
  val post = postRepository.findById(id)
  val currentUser = getCurrentUser()

  return ApiResponse.success(PostDto(
    id = post.id,
    title = post.title,
    // 권한 계산 (백엔드)
    canDelete = post.authorId == currentUser.id,
    canEdit = post.authorId == currentUser.id,
  ))
}

// 프론트엔드
final PostDto post = fetchPost(postId);

// 권한을 다시 계산 (프론트)
final canDelete = post.authorId == currentUserId;  // ❌ 중복!
final canEdit = post.authorId == currentUserId;    // ❌ 중복!

if (canDelete) {  // 잘못된 계산!
  // 삭제 버튼 표시
  DeleteButton()
}

// 결과:
// 그룹 관리자가 일반 멤버의 글을 삭제하려고 해도
// 프론트에서 버튼을 표시하지 않음 (계산이 다름)
```

### After (개선 - 백엔드 권한 신뢰)
```dart
// ✅ 해결: 백엔드 권한만 사용

// 백엔드
@GetMapping("/posts/{id}")
fun getPost(@PathVariable id: Long): ApiResponse<PostDto> {
  val post = postRepository.findById(id)
  val currentUser = getCurrentUser()

  // 권한 도메인이 계산
  val permissions = permissionEvaluator.evaluatePostPermissions(
    user = currentUser,
    post = post,
    group = post.group,
  )

  return ApiResponse.success(PostDto(
    id = post.id,
    title = post.title,
    // ✅ 복잡한 권한 로직 (그룹 관리자, 채널 관리자 등 고려)
    canDelete = permissions.contains(Permission.POST_DELETE),
    canEdit = permissions.contains(Permission.POST_EDIT),
    canReply = permissions.contains(Permission.COMMENT_CREATE),
  ))
}

// 프론트엔드
final PostDto post = fetchPost(postId);

// ✅ 프론트는 단순히 신뢰하기만 함 (계산 X)
if (post.canDelete) {
  DeleteButton(
    onPressed: () => deletePost(post.id),
  )
}

if (post.canEdit) {
  EditButton(
    onPressed: () => editPost(post),
  )
}

// 결과:
// - 백엔드에서 권한을 정확히 계산
// - 프론트는 표시만 함
// - 권한 변경은 백엔드만 수정
```

### DTO에 권한 플래그 추가 규칙
```dart
// 📋 모든 사용자 대면 DTO에 권한 포함

// ✅ 필수: 권한 정보 포함
class PostDto {
  final String id;
  final String title;
  // ...
  final bool canDelete;
  final bool canEdit;
  final bool canReply;
}

class GroupDto {
  final String id;
  final String name;
  // ...
  final bool canEdit;
  final bool canDelete;
  final bool canInviteMembers;
  final bool canManageRoles;
}

class CommentDto {
  final String id;
  final String content;
  // ...
  final bool canDelete;
  final bool canEdit;
}

// ❌ 금지: 권한 정보 없음
class GroupDto {
  final String id;
  final String name;
  // → canEdit, canDelete 없음 = 프론트에서 권한 계산할 수밖에 없음
}
```

## 검증 방법

### 체크리스트
- [ ] 모든 사용자 대면 DTO에 권한 플래그가 있는가?
- [ ] 프론트엔드에서 권한을 계산하는 코드가 없는가?
- [ ] UI는 API 응답의 권한 플래그만 사용하는가?
- [ ] 권한 변경 후 목록을 새로고침하는가?
- [ ] 백엔드 삭제 실패 시 UI를 수정하는가?

### 구체적 검증
```bash
# 1. 프론트 권한 계산 검사 (금지)
grep -r "authorId.*==\|userId.*==\|currentUser.*==" lib/features/*/presentation/
# → 0개 (권한 계산 금지)

# 2. DTO에 권한 플래그 확인
grep -r "canDelete\|canEdit\|can" lib/core/models/
# → 모든 DTO에서 발견되어야 함

# 3. UI에서 권한 확인
grep -r "if.*can" lib/features/*/presentation/
# → 모두 "response.can*" 형식이어야 함 (로컬 계산 금지)
```

## 관련 문서
- [API 응답 매핑](api-response-mapping.md) - DTO 파싱 규칙
- [권한 검증 (역함수 패턴)](../backend/permission-guard.md) - 백엔드 권한 설계
- [헌법 - RBAC + Override](../../.specify/memory/constitution.md#iii-rbac--override-권한-시스템-비협상)
