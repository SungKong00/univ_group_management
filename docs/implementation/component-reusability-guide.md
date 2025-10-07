# 컴포넌트 재사용성 가이드 (Component Reusability Guide)

## 개요 (Overview)
재사용 가능한 코드 작성 원칙과 실전 패턴. DRY(Don't Repeat Yourself) 원칙을 기반으로 유지보수성과 일관성을 극대화하는 Flutter 기반 컴포넌트 설계 가이드.

## 관련 문서
- [프론트엔드 가이드](frontend-guide.md) - 아키텍처 패턴
- [디자인 시스템](../ui-ux/design-system.md) - 토큰 시스템
- [프론트엔드 개발 에이전트](../agents/frontend-development-agent.md) - 개발 워크플로우

## 🎯 핵심 원칙

### 1. DRY (Don't Repeat Yourself)
**동일한 코드를 두 번 작성하지 말 것**

```dart
// ❌ 나쁜 예: 반복되는 버튼 스타일
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFEF4444),
    foregroundColor: Colors.white,
    minimumSize: Size(88, 44),
    // ... 20줄
  ),
  child: Text('삭제'),
)

// ✅ 좋은 예: 재사용 가능한 컴포넌트
ErrorButton(text: '삭제')
```

### 2. Single Responsibility
**하나의 컴포넌트는 하나의 책임만**

```dart
// ❌ 나쁜 예: 너무 많은 책임
class UserCard extends StatelessWidget {
  // UI 렌더링 + API 호출 + 상태 관리 + 비즈니스 로직
}

// ✅ 좋은 예: 책임 분리
class UserCard extends StatelessWidget {
  // UI 렌더링만
}
class UserService {
  // API 호출
}
class UserProvider extends StateNotifier {
  // 상태 관리
}
```

### 3. Composition Over Inheritance
**상속보다 조합을 선호**

```dart
// ❌ 나쁜 예: 상속 체인
class BaseButton extends StatelessWidget {}
class PrimaryButton extends BaseButton {}
class LargeButton extends PrimaryButton {}

// ✅ 좋은 예: 조합
class CustomButton extends StatelessWidget {
  final ButtonStyle style;
  final Widget? icon;
  const CustomButton({required this.style, this.icon});
}
```

## 📦 컴포넌트 분리 전략

### Level 1: 하드코딩 (85줄)
모든 UI 코드를 한 곳에 작성

```dart
// user_info_card.dart
Future<bool> _showLogoutConfirmDialog() async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('로그아웃', style: TextStyle(fontSize: 18, ...)),
        content: Text('정말 로그아웃하시겠습니까?', style: TextStyle(...)),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: EdgeInsets.symmetric(...),
              // ... 15줄
            ),
            child: Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              // ... 15줄
            ),
            child: Text('로그아웃'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
```

**문제점:**
- 다른 곳에서 재사용 불가능
- 스타일 변경 시 모든 곳 수정 필요
- 일관성 유지 어려움

### Level 2: 디자인 토큰화 (60줄)
스타일을 theme.dart로 분리

```dart
// theme.dart
class AppButtonStyles {
  static ButtonStyle error(ColorScheme colorScheme) {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.error,
      foregroundColor: AppColors.onPrimary,
      // ... 스타일 정의
    );
  }
}

// user_info_card.dart (60줄)
ElevatedButton(
  style: AppButtonStyles.error(colorScheme),  // 토큰 사용
  child: Text('로그아웃'),
)
```

**개선점:**
- 스타일 중앙 관리
- 일관성 자동 보장

**한계:**
- 여전히 버튼 구조 반복

### Level 3: 컴포넌트화 (35줄)
버튼을 독립 위젯으로 분리

```dart
// error_button.dart
class ErrorButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: AppButtonStyles.error(Theme.of(context).colorScheme),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

// user_info_card.dart (35줄)
ErrorButton(
  text: '로그아웃',
  onPressed: () => Navigator.pop(context, true),
)
```

**개선점:**
- 버튼 재사용 가능
- 코드 간결화

**한계:**
- 다이얼로그 전체는 여전히 반복

### Level 4: 완전한 재사용 (3줄)
다이얼로그 전체를 위젯으로 분리

```dart
// logout_dialog.dart
class LogoutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          Text('로그아웃'),
          Text('정말 로그아웃하시겠습니까?'),
          Row(
            children: [
              NeutralOutlinedButton(text: '취소', ...),
              ErrorButton(text: '로그아웃', ...),
            ],
          ),
        ],
      ),
    );
  }
}

Future<bool> showLogoutDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => const LogoutDialog(),
  );
  return result ?? false;
}

// user_info_card.dart (3줄!)
Future<bool> _showLogoutConfirmDialog() async {
  return await showLogoutDialog(context);
}
```

**최종 결과:**
- ✅ 85줄 → 3줄 (96% 감소)
- ✅ 어디서든 재사용 가능
- ✅ 스타일 자동 일관성
- ✅ 유지보수 단순화

## 🏗️ 재사용 패턴 카탈로그

### 패턴 1: 버튼 컴포넌트
**적용 시점:** 동일한 스타일의 버튼이 3곳 이상에서 사용될 때

```dart
// presentation/widgets/buttons/error_button.dart
class ErrorButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? text,
      child: FilledButton(
        style: AppButtonStyles.error(Theme.of(context).colorScheme),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text(text),
      ),
    );
  }
}
```

### 패턴 2: 다이얼로그 컴포넌트
**적용 시점:** 동일한 구조의 확인 다이얼로그가 필요할 때

```dart
// presentation/widgets/dialogs/confirm_dialog.dart
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: AppComponents.dialogMaxWidth),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(title, style: AppTheme.headlineSmall),
              SizedBox(height: AppSpacing.sm),
              Text(message, style: AppTheme.bodyMedium),
              SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  NeutralOutlinedButton(text: cancelText, ...),
                  ErrorButton(text: confirmText, ...),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 패턴 3: 헬퍼 함수
**적용 시점:** 복잡한 위젯 호출 로직을 단순화할 때

```dart
// core/utils/dialog_utils.dart
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = '확인',
  String cancelText = '취소',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
    ),
  );
  return result ?? false;
}

// 사용 예시 (어디서든 1줄로 호출)
final confirmed = await showConfirmDialog(
  context,
  title: '삭제',
  message: '정말 삭제하시겠습니까?',
);
```

### 패턴 4: 상태 표시 컴포넌트 (State Display Component)
**적용 시점:** "내용 없음", "준비 중", "로딩 중" 등 다양한 상태를 표시하는 UI가 여러 곳에서 반복될 때

여러 페이지에 걸쳐 유사하지만 조금씩 다른 '상태 표시' UI(예: 아이콘과 텍스트 메시지)를 만들어야 할 때가 많습니다. 이를 각각 별도의 위젯으로 만들면 코드 중복이 발생하고 일관성을 유지하기 어렵습니다. `enum`과 단일 위젯을 결합하여 이 문제를 해결할 수 있습니다.

**구현 단계:**

1.  **상태 타입 정의 (`enum`)**: 표시할 모든 상태를 `enum`으로 정의합니다.

    ```dart
    // presentation/pages/workspace/widgets/workspace_empty_state.dart
    enum WorkspaceEmptyType {
      groupHome,
      calendar,
      groupAdmin,
      noChannelSelected,
    }
    ```

2.  **재사용 가능한 상태 표시 위젯 생성**: `enum` 값을 받아 그에 맞는 아이콘과 텍스트를 내부적으로 결정하여 표시하는 단일 위젯을 만듭니다.

    ```dart
    // presentation/pages/workspace/widgets/workspace_empty_state.dart
    class WorkspaceEmptyState extends StatelessWidget {
      final WorkspaceEmptyType type;
      const WorkspaceEmptyState({super.key, required this.type});

      @override
      Widget build(BuildContext context) {
        // type에 따라 아이콘, 제목, 설명을 선택
        final IconData icon = _getIcon();
        final String title = _getTitle();
        final String description = _getDescription();

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppColors.brand),
              const SizedBox(height: 16),
              Text(title, style: AppTheme.displaySmall),
              const SizedBox(height: 8),
              Text(description, style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600)),
            ],
          ),
        );
      }

      // 타입별 데이터를 반환하는 내부 헬퍼 메소드들
      String _getTitle() {
        switch (type) {
          case WorkspaceEmptyType.groupHome: return '그룹 홈';
          case WorkspaceEmptyType.calendar: return '캘린더';
          // ... 나머지 케이스
        }
      }
      // _getIcon(), _getDescription() 등도 유사하게 구현
    }
    ```

3.  **UI에서 호출**: 각기 다른 위젯을 호출하는 대신, 새로운 `WorkspaceEmptyState` 위젯을 `type`만 바꿔서 재사용합니다.

    ```dart
    // ❌ 나쁜 예: 각 상태마다 별도의 위젯을 만들어 호출
    // case WorkspaceView.groupHome:
    //   return _buildGroupHomeView(); // 내부에 Icon, Text 등 중복 코드
    // case WorkspaceView.calendar:
    //   return _buildCalendarView(); // 여기도 중복 코드

    // ✅ 좋은 예: 하나의 위젯을 재사용
    // presentation/pages/workspace/workspace_page.dart
    switch (workspaceState.currentView) {
      case WorkspaceView.groupHome:
        return const WorkspaceEmptyState(type: WorkspaceEmptyType.groupHome);
      case WorkspaceView.calendar:
        return const WorkspaceEmptyState(type: WorkspaceEmptyType.calendar);
      case WorkspaceView.groupAdmin:
        return const WorkspaceEmptyState(type: WorkspaceEmptyType.groupAdmin);
      case WorkspaceView.channel:
        if (!workspaceState.hasSelectedChannel) {
          return const WorkspaceEmptyState(type: WorkspaceEmptyType.noChannelSelected);
        }
        // ...
    }
    ```

**기대 효과:**
-   **코드 중복 제거**: 수백 줄의 중복 코드를 단일 위젯으로 통합할 수 있습니다.
-   **일관성 향상**: 모든 상태 표시 UI의 디자인(폰트, 색상, 간격 등)이 자동으로 통일됩니다.
-   **유지보수 용이성**: 디자인 변경 시 `WorkspaceEmptyState` 위젯 하나만 수정하면 모든 곳에 반영됩니다.
-   **확장성**: 새로운 상태가 필요할 경우 `enum`에 한 줄, 위젯 내 `switch`문에 한 `case`만 추가하면 됩니다.

### 패턴 5: 슬라이드 패널 컴포넌트 (SlidePanel Component)
**적용 시점:** 화면 가장자리에서 부드럽게 나타나고 사라지는 사이드 패널(예: 댓글창, 상세 정보 뷰)이 필요할 때

**구현:**
```dart
// presentation/widgets/common/slide_panel.dart
class SlidePanel extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onDismiss;
  final Widget child;
  final double? width;
  final bool showBackdrop;

  @override
  Widget build(BuildContext context) {
    // Stack과 Positioned를 사용하여 화면에 오버레이
    // isVisible 값에 따라 AnimationController로 슬라이드 및 페이드 애니메이션 제어
    // 백드롭(어두운 배경) 표시 및 클릭 시 onDismiss 호출 기능
    return Visibility(
        visible: isVisible,
        child: Stack(
            children: [
                // ... Backdrop ...
                // ... SlideTransition ...
            ]
        )
    );
  }
}
```
**기대 효과:**
- **애니메이션 로직 캡슐화**: 복잡한 `AnimationController` 관리를 위젯 내부로 숨겨 사용 편의성 증대.
- **일관된 UX 제공**: 프로젝트 전체에 걸쳐 동일한 사이드 패널 애니메이션과 동작을 보장.
- **코드 단순화**: `workspace_page.dart`에서처럼 패널을 사용하는 부모 위젯의 코드가 대폭 감소.

### 패턴 6: 게시글 미리보기 위젯 (PostPreviewWidget)
**적용 시점:** 댓글창과 같이 다른 컨텍스트 내에서 원본 게시글의 요약 정보를 보여줘야 할 때

**구현:**
```dart
// presentation/widgets/workspace/post_preview_widget.dart
class PostPreviewWidget extends ConsumerWidget {
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // postPreviewProvider를 사용하여 현재 선택된 게시글의 상태(로딩, 데이터, 에러)를 구독
    final state = ref.watch(postPreviewProvider);

    return state.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
      data: (post) {
        // 게시글 헤더, 접고 펼 수 있는 본문 등 UI 표시
        // onClose 콜백을 사용하는 닫기 버튼 포함
      },
    );
  }
}
```
**기대 효과:**
- **관심사 분리**: 게시글 데이터를 가져오고 표시하는 로직을 부모 위젯(`workspace_page`)으로부터 완전히 분리.
- **상태 관리 위임**: Riverpod Provider를 통해 비동기 데이터 로딩, 상태 업데이트, 에러 처리를 위임하여 위젯을 단순하게 유지.
- **재사용성**: 게시글 미리보기가 필요한 어느 곳에서든 쉽게 재사용 가능.

## 🎨 디자인 토큰 활용

### 컬러 토큰화
```dart
// ❌ 나쁜 예: 하드코딩
Container(
  color: Color(0xFFEF4444),
  child: Text('Error', style: TextStyle(color: Color(0xFFFFFFFF))),
)

// ✅ 좋은 예: 토큰 사용
Container(
  color: AppColors.error,
  child: Text('Error', style: TextStyle(color: AppColors.onPrimary)),
)
```

### 간격 토큰화
```dart
// ❌ 나쁜 예: 매직 넘버
Padding(padding: EdgeInsets.all(24))

// ✅ 좋은 예: 토큰 사용
Padding(padding: EdgeInsets.all(AppSpacing.md))
```

### 타이포그래피 토큰화
```dart
// ❌ 나쁜 예: 스타일 하드코딩
Text('Title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))

// ✅ 좋은 예: 토큰 사용
Text('Title', style: AppTheme.headlineSmall)
```

## ✅ 재사용성 체크리스트

### 개발 전
- [ ] 동일한 UI가 3곳 이상에서 사용되는가?
- [ ] 스타일이 반복되고 있는가?
- [ ] 비즈니스 로직이 UI와 섞여 있는가?

### 개발 중
- [ ] 디자인 토큰을 사용하고 있는가?
- [ ] 컴포넌트가 단일 책임을 가지는가?
- [ ] Props로 커스터마이징 가능한가?

### 개발 후
- [ ] 다른 곳에서 재사용 가능한가?
- [ ] 문서화되어 있는가?
- [ ] 접근성(semantics)이 구현되어 있는가?

## 📝 문서화 규칙

### 컴포넌트 주석
```dart
/// 위험한 액션을 위한 에러 톤 버튼 (주로 삭제, 로그아웃 등)
///
/// 토스 디자인 철학 적용:
/// - 명확성: #EF4444 빨간색으로 위험한 액션임을 명확히 표현
/// - 피드백: hover → 진한 빨강(#DC2626)
/// - 접근성: 포커스 링, semanticsLabel
///
/// Usage:
/// ```dart
/// ErrorButton(
///   text: '삭제',
///   onPressed: () => deleteItem(),
///   semanticsLabel: '항목 삭제',
/// )
/// ```
class ErrorButton extends StatelessWidget {
  // ...
}
```

### 헬퍼 함수 주석
```dart
/// 로그아웃 확인 다이얼로그를 표시하는 헬퍼 함수
///
/// 토스 4대 디자인 원칙 적용된 다이얼로그를 표시합니다.
///
/// Returns: 사용자가 "로그아웃"을 선택하면 true, "취소"를 선택하면 false
///
/// Usage:
/// ```dart
/// final confirmed = await showLogoutDialog(context);
/// if (confirmed) {
///   await authService.logout();
/// }
/// ```
Future<bool> showLogoutDialog(BuildContext context) async {
  // ...
}
```

## 🔄 개발 완료 시 문서 업데이트

### 새 컴포넌트 추가 시
1. **이 문서 업데이트**: 재사용 패턴 카탈로그에 추가
2. **design-system.md 업데이트**: 디자인 토큰 추가된 경우
3. **frontend-guide.md 업데이트**: 새로운 아키텍처 패턴인 경우

### 예시: ErrorButton 추가 후
```markdown
## 패턴 카탈로그에 추가

### 패턴 N: ErrorButton
**적용 시점:** 위험한 액션(삭제, 로그아웃 등)이 필요할 때
**위치:** presentation/widgets/buttons/error_button.dart
**토큰:** AppButtonStyles.error(), AppColors.error
**사용 예시:** [코드]
```

## 📊 성과 측정

### 재사용성 지표
- **코드 중복률**: 동일 패턴 반복 횟수
- **컴포넌트 재사용 횟수**: 한 컴포넌트가 사용된 곳의 수
- **유지보수 시간**: 스타일 변경 시 수정 파일 수

### 목표
- 85줄 → 3줄: **96% 코드 감소**
- 5개 화면에서 재사용: **5배 생산성**
- 스타일 변경 1곳만 수정: **유지보수 시간 80% 감소**