/// 디자인 시스템 중앙 Enum 정의
///
/// 모든 색상 토큰, 컴포넌트 스타일, 상태에 관련된 Enum을 한곳에 정의합니다.
/// 각 Enum은 해당 색상 팩토리 메서드와 일대일 대응됩니다.
library;

// ========================================================
// 반응형 & 레이아웃 (5-step responsive system)
// ========================================================

/// 화면 크기 분류 (Material Design 3 기반)
///
/// XS (Extra Small): < 450px - 작은 폰 (iPhone SE)
/// SM (Small): 450-768px - 큰 폰 (iPhone 14 Pro Max)
/// MD (Medium): 768-1024px - 태블릿 세로 (iPad)
/// LG (Large): 1024-1440px - 태블릿 가로 / 노트북
/// XL (Extra Large): >= 1440px - 데스크톱 모니터
enum ScreenSize { xs, sm, md, lg, xl }

// Legacy enum values (deprecated - for backward compatibility)
extension ScreenSizeExtension on ScreenSize {
  @Deprecated('Check against ScreenSize.xs instead of using isMobile')
  bool get isMobile => this == ScreenSize.xs;

  @Deprecated('Check against ScreenSize.sm/md instead of using isTablet')
  bool get isTablet => this == ScreenSize.sm || this == ScreenSize.md;

  @Deprecated('Check against ScreenSize.lg/xl instead of using isDesktop')
  bool get isDesktop => this == ScreenSize.lg || this == ScreenSize.xl;

  /// Breakpoint에 해당하는 Display 문자열
  String get displayName => switch (this) {
    ScreenSize.xs => 'XS (< 450px)',
    ScreenSize.sm => 'SM (450-768px)',
    ScreenSize.md => 'MD (768-1024px)',
    ScreenSize.lg => 'LG (1024-1440px)',
    ScreenSize.xl => 'XL (≥ 1440px)',
  };
}

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

/// 카드 타입 (레이아웃 방향별)
///
/// 각 타입은 이미지 위치와 전체 레이아웃 방향을 결정합니다.
/// [GridLayoutTokens] 및 [CardDesignTokens]와 연동됩니다.
enum CardVariant {
  /// 세로 카드: 이미지(상단) → 텍스트(하단)
  /// 용도: 상품, 가격표, 팀 멤버
  vertical,

  /// 가로 카드: 이미지(좌측) → 텍스트(우측)
  /// 용도: 추천사, 고객 사례, 블로그 미리보기
  horizontal,

  /// 콤팩트 카드: 아이콘/이미지(중앙) + 제목
  /// 용도: 기능 선택, 태그, 카테고리, 필터
  compact,

  /// 선택 가능 카드: 체크박스 + 콘텐츠
  /// 용도: 옵션 선택, 설정 항목
  selectable,

  /// 와이드 카드: Full-width 배너
  /// 용도: 프로모션, 광고, 중요 공지
  wide,
}

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

/// Badge 스타일 (배경 유무)
///
/// subtle: 배경색 없이 텍스트만 표시 (메타 정보용)
/// prominent: 배경색 있는 강조 배지 (상태 표시용)
enum AppBadgeVariant { subtle, prominent }

/// Badge 색상 (상태 기반)
///
/// 각 색상은 AppColorExtension의 state 토큰과 매핑됩니다.
enum AppBadgeColor {
  /// 성공/완료 상태 (초록)
  success,

  /// 경고/주의 상태 (주황)
  warning,

  /// 에러/위험 상태 (빨강)
  error,

  /// 정보/알림 상태 (파랑)
  info,

  /// 일반 상태 (회색)
  neutral,

  /// 브랜드 강조 (보라)
  brand,
}

/// Badge 크기
///
/// small: 작은 배지 (폰트 10px, 패딩 2px 6px)
/// medium: 기본 배지 (폰트 12px, 패딩 4px 8px)
enum AppBadgeSize { small, medium }

// Legacy alias for backward compatibility
@Deprecated('Use AppBadgeVariant instead')
typedef AppBadgeStyle = AppBadgeVariant;

/// Toast 타입 (피드백 종류)
///
/// 각 타입은 AppColorExtension의 state 토큰과 매핑됩니다.
enum AppToastType {
  /// 성공 메시지 (초록)
  success,

  /// 경고 메시지 (주황)
  warning,

  /// 에러 메시지 (빨강)
  error,

  /// 정보 메시지 (파랑)
  info,
}

/// Toast 위치
///
/// 토스트가 표시될 화면 위치를 결정합니다.
enum AppToastPosition {
  /// 상단 중앙
  topCenter,

  /// 상단 우측
  topRight,

  /// 하단 중앙
  bottomCenter,

  /// 하단 우측
  bottomRight,
}

/// Tooltip 위치
///
/// 툴팁이 표시될 선호 위치를 결정합니다.
/// 화면 가장자리에 가까울 경우 자동으로 반대 방향으로 조정됩니다.
enum AppTooltipPosition {
  /// 상단
  top,

  /// 하단
  bottom,

  /// 좌측
  left,

  /// 우측
  right,
}

/// Dialog 타입
///
/// 다이얼로그의 용도에 따른 타입을 정의합니다.
enum AppDialogType {
  /// 확인만 있는 알림
  alert,

  /// 확인/취소 선택
  confirm,

  /// 입력 포함 다이얼로그
  prompt,

  /// 커스텀 콘텐츠
  custom,
}

/// Chip 타입
///
/// 칩의 용도에 따른 타입을 정의합니다.
enum AppChipType {
  /// 필터 선택용 (선택/해제)
  filter,

  /// 입력된 값 표시 (삭제 가능)
  input,

  /// 추천 항목 (탭으로 선택)
  suggestion,
}

/// Chip 크기
enum AppChipSize {
  /// 작은 칩
  small,

  /// 기본 칩
  medium,
}

/// Dropdown 크기
enum AppDropdownSize {
  /// 작은 드롭다운
  small,

  /// 기본 드롭다운
  medium,

  /// 큰 드롭다운
  large,
}

// ========================================================
// Phase 2: 폼/입력 강화 컴포넌트
// ========================================================

/// Skeleton 타입
///
/// 스켈레톤 로딩 플레이스홀더의 모양을 정의합니다.
enum AppSkeletonType {
  /// 텍스트 라인 (기본 사각형)
  text,

  /// 원형 (아바타, 프로필)
  circle,

  /// 사각형 (이미지, 카드)
  rectangle,
}

/// EmptyState 타입
///
/// 빈 상태 표시의 용도별 타입을 정의합니다.
enum AppEmptyStateType {
  /// 일반 빈 상태
  general,

  /// 검색 결과 없음
  search,

  /// 필터 결과 없음
  filter,

  /// 데이터 없음
  noData,

  /// 즐겨찾기 없음
  noFavorites,

  /// 알림 없음
  noNotifications,
}

/// ErrorState 타입
///
/// 에러 상태 표시의 종류별 타입을 정의합니다.
enum AppErrorStateType {
  /// 일반 에러
  general,

  /// 네트워크 에러
  network,

  /// 서버 에러
  server,

  /// 권한 없음
  unauthorized,

  /// 찾을 수 없음
  notFound,

  /// 시간 초과
  timeout,
}

/// Avatar 크기
///
/// 아바타의 크기를 정의합니다.
enum AppAvatarSize {
  /// 24px (매우 작음)
  xs,

  /// 32px (작음)
  sm,

  /// 40px (기본)
  md,

  /// 48px (큼)
  lg,

  /// 64px (매우 큼)
  xl,

  /// 96px (초대형)
  xxl,
}

/// Avatar 상태
///
/// 온라인 상태 표시를 위한 enum입니다.
enum AppAvatarStatus {
  /// 온라인
  online,

  /// 오프라인
  offline,

  /// 자리 비움
  away,

  /// 방해 금지
  busy,
}

/// DatePicker 모드
///
/// 날짜 선택기의 선택 모드를 정의합니다.
enum AppDatePickerMode {
  /// 단일 날짜 선택
  single,

  /// 범위 선택 (시작~끝)
  range,

  /// 다중 선택
  multiple,
}

/// DatePicker 뷰 타입
///
/// 달력 뷰의 표시 단위를 정의합니다.
enum AppDatePickerView {
  /// 일 단위 (기본)
  day,

  /// 월 단위
  month,

  /// 년 단위
  year,
}

/// TimePicker 포맷
///
/// 시간 표시 형식을 정의합니다.
enum AppTimePickerFormat {
  /// 12시간제 (AM/PM)
  hour12,

  /// 24시간제
  hour24,
}

/// TimePicker 정밀도
///
/// 시간 선택의 정밀도를 정의합니다.
enum AppTimePickerPrecision {
  /// 시간만
  hour,

  /// 시간 + 분
  minute,

  /// 시간 + 분 + 초
  second,
}
