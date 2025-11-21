/// 디자인 시스템 중앙 Enum 정의
///
/// 모든 색상 토큰, 컴포넌트 스타일, 상태에 관련된 Enum을 한곳에 정의합니다.
/// 각 Enum은 해당 색상 팩토리 메서드와 일대일 대응됩니다.
library;

// ========================================================
// 반응형 & 레이아웃
// ========================================================
enum ScreenSize { mobile, tablet, desktop }

/// 그리드 레이아웃 열 수 프리셋
///
/// 반응형 그리드의 표준 열 구성을 정의합니다.
/// 실제 렌더링되는 열 수는 화면이 좁을 때 자동으로 줄어들 수 있습니다.
/// (minItemWidth 제약에 의해)
///
/// 사용 예시:
/// ```dart
/// // 가격 카드를 3열로 배치
/// final config = GridLayoutTokens.forCardType(
///   CardVariant.vertical,
///   columns: GridPresetColumns.three,
/// );
///
/// AdaptiveCardGrid.fromPreset(
///   config: config,
///   itemCount: pricingPlans.length,
///   itemBuilder: (context, index) => PricingCard(pricingPlans[index]),
/// );
/// ```
enum GridPresetColumns {
  /// 1열 레이아웃 (모바일, 리스트 전용)
  one,

  /// 2열 레이아웃 (추천사, 2단 카드)
  two,

  /// 3열 레이아웃 (가격, 기능, 세로 카드)
  three,

  /// 4열 레이아웃 (고객 로고, 소형 항목)
  four,

  /// 5열 레이아웃 (아이콘 그리드, 콤팩트 항목)
  five,

  /// 6열 레이아웃 (태그, 배지, 미니 카드)
  six,
}

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

enum SectionVariant { standard, compact }

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

enum GradientType {
  subtleTopFade,
  lightTopFade,
  extraLightTopFade,
  subtleBottomFade,
  subtleLeftFade,
  subtleRightFade,
  radialFade,
}

// ========================================================
// UI 패턴
// ========================================================
enum AppBadgeStyle { subtle, prominent }
