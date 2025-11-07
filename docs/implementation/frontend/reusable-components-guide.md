# 재사용 가능한 공통 컴포넌트 가이드

이 문서는 프로젝트에서 제공하는 재사용 가능한 공통 컴포넌트의 사용법을 설명합니다.

## 목차
1. [버튼 컴포넌트](#버튼-컴포넌트)
2. [SnackBar (알림 메시지)](#snackbar-알림-메시지)
3. [EmptyState (빈 상태)](#emptystate-빈-상태)
4. [StateView (상태 관리 위젯)](#stateview-상태-관리-위젯)
5. [다이얼로그 컴포넌트](#다이얼로그-컴포넌트)

---

## 버튼 컴포넌트

### ButtonLoadingChild (로딩 버튼)

**위치**: `lib/presentation/widgets/buttons/button_loading_child.dart`

**설명**: 모든 버튼 컴포넌트에 통합된 로딩 상태 처리 위젯입니다. 직접 사용하지 말고, PrimaryButton, ErrorButton 등 표준 버튼 컴포넌트를 사용하세요.

#### ❌ 잘못된 예시
```dart
FilledButton(
  onPressed: _isLoading ? null : _handleSave,
  child: _isLoading
    ? const CircularProgressIndicator(color: Colors.white)
    : const Text('저장'),
)
```

#### ✅ 올바른 예시
```dart
PrimaryButton(
  text: '저장',
  isLoading: _isLoading,
  onPressed: _handleSave,
)
```

### 표준 버튼 컴포넌트

#### PrimaryButton
- **variant**: `action` (기본), `brand`, `error`, `success`
- **isLoading**: 로딩 상태 자동 처리
- **onPressed**: null일 때 자동 비활성화

```dart
PrimaryButton(
  text: '확인',
  variant: PrimaryButtonVariant.action,
  isLoading: _isSaving,
  onPressed: _handleConfirm,
)
```

#### ErrorButton
```dart
ErrorButton(
  text: '삭제',
  isLoading: _isDeleting,
  onPressed: _handleDelete,
)
```

#### NeutralOutlinedButton
```dart
NeutralOutlinedButton(
  text: '취소',
  onPressed: () => Navigator.pop(context),
)
```

---

## SnackBar (알림 메시지)

### AppSnackBar

**위치**: `lib/core/utils/snack_bar_helper.dart`

**설명**: 일관된 스타일의 알림 메시지를 표시하는 유틸리티입니다.

#### 메서드
- `success(context, message)` - 성공 메시지 (녹색)
- `error(context, message)` - 에러 메시지 (빨간색)
- `warning(context, message)` - 경고 메시지 (노란색)
- `info(context, message)` - 정보 메시지 (회색)
- `custom(context, message, backgroundColor, textColor, duration)` - 커스텀

#### ❌ 잘못된 예시
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('저장되었습니다'),
    duration: Duration(seconds: 2),
  ),
);
```

#### ✅ 올바른 예시
```dart
AppSnackBar.success(context, '저장되었습니다');
AppSnackBar.error(context, '저장에 실패했습니다');
AppSnackBar.warning(context, '이름이 너무 깁니다');
AppSnackBar.info(context, '신고 기능은 추후 구현 예정입니다');
```

#### 커스텀 duration
```dart
AppSnackBar.custom(
  context,
  '5초 동안 표시되는 메시지',
  backgroundColor: Colors.purple,
  duration: const Duration(seconds: 5),
);
```

---

## EmptyState (빈 상태)

### AppEmptyState

**위치**: `lib/presentation/widgets/common/app_empty_state.dart`

**설명**: 데이터가 없거나 검색 결과가 없을 때 표시하는 표준 위젯입니다.

#### Factory Constructors
- `noData()` - 일반 데이터 없음
- `noResults()` - 검색 결과 없음
- `noComments()` - 댓글 없음
- `noPosts()` - 게시글 없음
- `noGroups()` - 그룹 없음
- `noPlaces()` - 장소 없음
- `noMembers()` - 멤버 없음
- `noRecruitments()` - 모집공고 없음

#### ❌ 잘못된 예시
```dart
Widget _buildEmptyState() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.comment_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('아직 댓글이 없습니다', style: TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}
```

#### ✅ 올바른 예시
```dart
Widget _buildEmptyState() {
  return AppEmptyState.noComments();
}

// 또는 커스텀 메시지
AppEmptyState.noGroups(
  message: '선택된 그룹이 없습니다',
  subtitle: '그룹을 선택해주세요',
)

// 액션 버튼 추가
AppEmptyState.noPosts(
  action: PrimaryButton(
    text: '게시글 작성',
    onPressed: _showCreatePostDialog,
  ),
)
```

---

## StateView (상태 관리 위젯)

### StateView

**위치**: `lib/presentation/widgets/common/state_view.dart`

**설명**: 로딩, 에러, 빈 상태를 통합 관리하는 위젯입니다.

#### 사용 예시
```dart
StateView<List<Post>>(
  state: _postState, // AsyncValue<List<Post>>
  onRetry: _loadPosts,
  builder: (context, posts) {
    if (posts.isEmpty) {
      return AppEmptyState.noPosts();
    }
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) => PostItem(post: posts[index]),
    );
  },
)
```

---

## 다이얼로그 컴포넌트

### ConfirmDialog

**위치**: `lib/presentation/widgets/dialogs/confirm_dialog.dart`

**설명**: 표준 확인 다이얼로그입니다.

#### 사용 예시
```dart
final confirmed = await showConfirmDialog(
  context,
  title: '삭제 확인',
  message: '정말로 삭제하시겠습니까?',
  confirmLabel: '삭제',
  isDestructive: true,
);

if (confirmed) {
  // 삭제 로직
}
```

---

## 다이얼로그 헬퍼

### DialogHelpers

**위치**: `lib/presentation/widgets/dialogs/dialog_helpers.dart`

**설명**: 표준화된 다이얼로그 표시 유틸리티입니다.

#### 메서드
- `showAppDialog()` - 표준 다이얼로그 표시 (중앙 애니메이션, 반응형 크기)
- `showAppBottomSheet()` - 바텀시트 표시 (모바일 최적화)

#### 사용 예시
```dart
await DialogHelpers.showAppDialog(
  context: context,
  builder: (context) => CreateGroupDialog(),
);

// 바텀시트 (모바일)
await DialogHelpers.showAppBottomSheet(
  context: context,
  builder: (context) => PlaceSelectorBottomSheet(),
);
```

---

## 다이얼로그 타이틀

### AppDialogTitle

**위치**: `lib/presentation/widgets/dialogs/app_dialog_title.dart`

**설명**: 모든 다이얼로그에서 사용하는 표준 타이틀 바입니다.

#### ❌ 잘못된 예시
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      '그룹 생성',
      style: AppTheme.titleLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.neutral900,
      ),
    ),
    IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.pop(context),
    ),
  ],
)
```

#### ✅ 올바른 예시
```dart
AppDialogTitle(
  title: '그룹 생성',
  onClose: () => Navigator.pop(context),
)
```

---

## 다이얼로그 액션 버튼

### ConfirmCancelActions

**위치**: `lib/presentation/widgets/dialogs/confirm_cancel_actions.dart`

**설명**: 다이얼로그 하단의 표준 확인/취소 버튼 쌍입니다.

#### 사용 예시
```dart
ConfirmCancelActions(
  confirmText: '저장',
  onConfirm: _isLoading ? null : _handleSave,
  isConfirmLoading: _isLoading,
  confirmVariant: PrimaryButtonVariant.action,
  onCancel: () => Navigator.pop(context),
)

// 삭제 다이얼로그
ConfirmCancelActions(
  confirmText: '삭제',
  onConfirm: _handleDelete,
  isConfirmLoading: _isDeleting,
  confirmVariant: PrimaryButtonVariant.error,
  onCancel: () => Navigator.pop(context),
)
```

---

## 폼 입력 컴포넌트

### AppFormField

**위치**: `lib/presentation/widgets/form/app_form_field.dart`

**설명**: 표준 입력 필드 컴포넌트입니다.

#### 사용 예시
```dart
AppFormField(
  label: '그룹 이름',
  controller: _nameController,
  hintText: '그룹 이름을 입력하세요',
  required: true,
  maxLength: 50,
)

// 멀티라인
AppFormField(
  label: '설명',
  controller: _descController,
  hintText: '그룹 설명을 입력하세요',
  maxLines: 5,
  maxLength: 500,
)
```

---

## 정보 배너

### AppInfoBanner

**위치**: `lib/presentation/widgets/common/app_info_banner.dart`

**설명**: 정보/경고/에러 메시지를 표시하는 배너입니다.

#### 사용 예시
```dart
AppInfoBanner.info(
  message: '최대 5개의 그룹을 선택할 수 있습니다.',
)

AppInfoBanner.warning(
  message: '삭제된 데이터는 복구할 수 없습니다.',
)

AppInfoBanner.error(
  message: '권한이 부족합니다.',
)
```

---

## 추가 컴포넌트

### CollapsibleContent (접을 수 있는 콘텐츠)

**위치**: `lib/presentation/widgets/common/collapsible_content.dart`

**설명**: 긴 텍스트를 자동으로 접고 "더 보기" 버튼을 표시합니다.

#### 사용 예시
```dart
CollapsibleContent(
  content: post.content,
  maxLines: 10,
  style: AppTheme.bodyMedium,
)
```

### OptionMenu (옵션 메뉴)

**위치**: `lib/presentation/widgets/common/option_menu.dart`

**설명**: 세 점 메뉴 버튼과 옵션 리스트를 표시합니다.

#### 사용 예시
```dart
OptionMenu(
  items: [
    OptionMenuItem(
      label: '수정',
      icon: Icons.edit_outlined,
      onTap: _showEditDialog,
    ),
    OptionMenuItem(
      label: '삭제',
      icon: Icons.delete_outline,
      onTap: _showDeleteDialog,
      isDestructive: true,
    ),
  ],
)
```

---

## 기여 가이드

새로운 공통 컴포넌트를 추가할 때:
1. `/lib/presentation/widgets/common/` 또는 `/lib/core/utils/`에 배치
2. 이 문서에 사용법 추가
3. 기존 코드에서 중복 패턴 제거
4. PR 리뷰 시 재사용성 확인

---

**마지막 업데이트**: 2025-11-02
**관리자**: Frontend Team
