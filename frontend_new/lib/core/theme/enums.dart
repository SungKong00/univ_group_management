/// 디자인 시스템 중앙 Enum 정의
///
/// 모든 색상 토큰, 컴포넌트 스타일, 상태에 관련된 Enum을 한곳에 정의합니다.
/// 각 Enum은 해당 색상 팩토리 메서드와 일대일 대응됩니다.
library core.theme.enums;

// ========================================================
// 반응형 & 레이아웃
// ========================================================
enum ScreenSize { mobile, tablet, desktop }

// ========================================================
// 버튼 컴포넌트
// ========================================================
enum AppButtonVariant { primary, secondary, ghost }

enum AppButtonSize { small, medium, large }

enum AppInputCursorColor { primary }

// ========================================================
// 카드 & 컨테이너
// ========================================================
enum AppCardElevation { none, low }

enum BreadcrumbStyle { default_, dark, compact }

// ========================================================
// 사이드바 & 섹션
// ========================================================
enum SidebarStyle { default_, dark, compact }

enum LabelsSectionStyle { default_, dark, colorful }

// ========================================================
// 상태 & 액션
// ========================================================
enum IssuePriority { high, medium, low, none }

enum IssueStatus { done, inProgress, pending, cancelled }

enum AssigneeState { assigned, unassigned, multiple }

enum ReactionState { inactive, active, add }

enum AttachmentState { default_, uploading, error, add, delete }

// ========================================================
// 콘텐츠 표현
// ========================================================
enum ActivityType {
  comment,
  created,
  updated,
  deleted,
  assigned,
  statusChanged,
  priorityChanged,
  labelAdded,
  labelRemoved,
}

enum EditorType { default_, title, comment }

enum GradientType { topToBottom, leftToRight, diagonalTL, diagonalTR, radial }

// ========================================================
// UI 패턴
// ========================================================
enum AppBadgeStyle { subtle, prominent }
