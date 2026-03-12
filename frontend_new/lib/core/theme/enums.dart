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

// ========================================================
// Phase 3: 고급 UI 컴포넌트
// ========================================================

/// Menu 아이템 타입
///
/// 메뉴 아이템의 종류를 정의합니다.
enum AppMenuItemType {
  /// 일반 항목 (클릭 가능)
  item,

  /// 구분선
  divider,

  /// 그룹 헤더
  header,

  /// 서브메뉴 (하위 메뉴 포함)
  submenu,
}

/// Pagination 스타일
///
/// 페이지네이션의 표시 스타일을 정의합니다.
enum AppPaginationStyle {
  /// 기본 번호 스타일 (1, 2, 3, ... 10)
  numbered,

  /// 간단 스타일 (< 1/10 >)
  simple,

  /// 컴팩트 스타일 (< >)
  compact,
}

/// Accordion 스타일
///
/// 아코디언의 스타일을 정의합니다.
enum AppAccordionStyle {
  /// 기본 스타일 (테두리 있음)
  bordered,

  /// 구분선 스타일 (항목 사이 구분선)
  separated,

  /// 플레인 스타일 (테두리 없음)
  plain,
}

/// Stepper 방향
///
/// 스테퍼의 레이아웃 방향을 정의합니다.
enum AppStepperOrientation {
  /// 가로 방향
  horizontal,

  /// 세로 방향
  vertical,
}

/// Stepper 단계 상태
///
/// 각 단계의 상태를 정의합니다.
enum AppStepStatus {
  /// 완료됨
  completed,

  /// 현재 활성
  active,

  /// 대기 중
  pending,

  /// 에러
  error,
}

/// ProgressBar 스타일
///
/// 진행률 표시의 스타일을 정의합니다.
enum AppProgressBarStyle {
  /// 기본 스타일 (막대형)
  linear,

  /// 원형 스타일
  circular,

  /// 반원형 스타일
  semicircular,
}

/// ProgressBar 색상
///
/// 진행률 표시의 색상을 정의합니다.
enum AppProgressBarColor {
  /// 브랜드 색상
  brand,

  /// 성공 색상
  success,

  /// 경고 색상
  warning,

  /// 에러 색상
  error,

  /// 정보 색상
  info,
}

/// Divider 스타일
///
/// 구분선의 스타일을 정의합니다.
enum AppDividerStyle {
  /// 실선
  solid,

  /// 점선
  dashed,

  /// 도트
  dotted,
}

/// Divider 두께
///
/// 구분선의 두께를 정의합니다.
enum AppDividerThickness {
  /// 얇음 (1px)
  thin,

  /// 보통 (2px)
  medium,

  /// 두꺼움 (4px)
  thick,
}

/// Divider 색상 스타일
///
/// 구분선의 색상 변형을 정의합니다.
enum AppDividerColorStyle {
  /// 표준 색상
  standard,

  /// 강조 색상
  prominent,

  /// 미묘한 색상
  subtle,
}

// ========================================================
// Phase 4: 네비게이션 & 레이아웃 컴포넌트
// ========================================================

/// BottomSheet 타입
///
/// 바텀시트의 동작 방식을 정의합니다.
enum AppBottomSheetType {
  /// 모달 (배경 어둡게, 외부 탭으로 닫힘)
  modal,

  /// 지속 (배경과 상호작용 가능)
  persistent,
}

/// Drawer 위치
///
/// 드로어가 나타나는 위치를 정의합니다.
enum AppDrawerPosition {
  /// 좌측
  left,

  /// 우측
  right,
}

/// Navigation Sidebar 스타일
///
/// 사이드바 네비게이션의 스타일을 정의합니다.
/// - standard: 일반 스타일 (라벨 표시, 너비 240px)
/// - compact: 컴팩트 스타일 (아이콘만, 너비 72px)
/// - expandable: 확장 가능 스타일 (토글 버튼으로 standard ↔ compact 전환)
///
/// **용도**: 대시보드 네비게이션, 관리자 메뉴, 앱 주요 메뉴
/// **색상 정의**: NavSidebarColors (모든 스타일이 동일한 색상 사용, AppSidebar가 너비/레이아웃으로 구분)
enum AppSidebarStyle {
  /// 일반 스타일 (라벨 표시, 너비 240px)
  standard,

  /// 컴팩트 스타일 (아이콘만, 너비 72px)
  compact,

  /// 확장 가능 스타일 (토글 버튼으로 standard ↔ compact 전환)
  expandable,
}

/// BottomNav 스타일
///
/// 하단 네비게이션의 스타일을 정의합니다.
enum AppBottomNavStyle {
  /// 기본 스타일 (아이콘 + 라벨)
  standard,

  /// 컴팩트 스타일 (아이콘만)
  compact,

  /// 쉬프팅 스타일 (활성 아이템만 라벨 표시)
  shifting,
}

/// Breadcrumb 구분자
///
/// 브레드크럼 항목 간 구분자를 정의합니다.
enum AppBreadcrumbSeparator {
  /// 슬래시 (/)
  slash,

  /// 화살표 (>)
  arrow,

  /// 쉐브론 (›)
  chevron,

  /// 도트 (•)
  dot,
}

/// Navbar 스타일
///
/// 상단 네비게이션 바의 스타일을 정의합니다.
enum AppNavbarStyle {
  /// 기본 스타일
  standard,

  /// 투명 스타일
  transparent,

  /// 고정 스타일 (스크롤 시 고정)
  sticky,
}

/// NavigationRail 정렬
///
/// 네비게이션 레일의 아이템 정렬을 정의합니다.
enum AppNavigationRailAlignment {
  /// 상단 정렬
  start,

  /// 중앙 정렬
  center,

  /// 하단 정렬
  end,
}

// ========================================================
// Phase 5: 데이터 & 폼 확장 컴포넌트
// ========================================================

/// Switch 크기
///
/// 토글 스위치의 크기를 정의합니다.
enum AppSwitchSize {
  /// 작은 스위치 (너비 36px, 높이 20px)
  small,

  /// 기본 스위치 (너비 48px, 높이 26px)
  medium,

  /// 큰 스위치 (너비 60px, 높이 32px)
  large,
}

/// RadioGroup 방향
///
/// 라디오 버튼 그룹의 레이아웃 방향을 정의합니다.
enum AppRadioOrientation {
  /// 세로 배치
  vertical,

  /// 가로 배치
  horizontal,
}

/// RadioGroup 크기
///
/// 라디오 버튼의 크기를 정의합니다.
enum AppRadioSize {
  /// 작은 라디오 (16px)
  small,

  /// 기본 라디오 (20px)
  medium,

  /// 큰 라디오 (24px)
  large,
}

/// CheckboxGroup 방향
///
/// 체크박스 그룹의 레이아웃 방향을 정의합니다.
enum AppCheckboxOrientation {
  /// 세로 배치
  vertical,

  /// 가로 배치
  horizontal,
}

/// CheckboxGroup 크기
///
/// 체크박스의 크기를 정의합니다.
enum AppCheckboxSize {
  /// 작은 체크박스 (16px)
  small,

  /// 기본 체크박스 (20px)
  medium,

  /// 큰 체크박스 (24px)
  large,
}

/// Slider 크기
///
/// 슬라이더의 크기를 정의합니다.
enum AppSliderSize {
  /// 작은 슬라이더
  small,

  /// 기본 슬라이더
  medium,

  /// 큰 슬라이더
  large,
}

/// Slider 스타일
///
/// 슬라이더의 표시 스타일을 정의합니다.
enum AppSliderStyle {
  /// 기본 스타일
  standard,

  /// 범위 마크 표시
  marked,

  /// 단계별 스타일
  stepped,
}

// ========================================================
// Phase 5 추가: 색상 선택 & OTP 입력
// ========================================================

/// ColorPicker 모드
///
/// 색상 선택기의 동작 모드를 정의합니다.
enum AppColorPickerMode {
  /// 프리셋 팔레트만 표시
  palette,

  /// HEX 입력 가능
  hex,

  /// HSV 슬라이더 (향후 확장)
  // hsv,
}

/// FileUpload 타입
///
/// 파일 업로드의 선택 모드를 정의합니다.
enum AppFileUploadType {
  /// 단일 파일
  single,

  /// 다중 파일
  multiple,

  /// 드래그 앤 드롭 영역
  dropzone,
}

/// FileUpload 상태
///
/// 업로드 상태를 정의합니다.
enum AppFileUploadStatus {
  /// 기본 상태
  idle,

  /// 업로드 중
  uploading,

  /// 업로드 완료
  completed,

  /// 에러 발생
  error,
}

/// FileUpload 크기
///
/// 컴포넌트의 크기를 정의합니다.
enum AppFileUploadSize {
  /// 작은 크기
  small,

  /// 기본 크기
  medium,

  /// 큰 크기
  large,
}

// ========================================================
// Phase 5 추가: 데이터 테이블
// ========================================================

/// DataTable 정렬 방향
///
/// 컬럼 정렬 방향을 정의합니다.
enum AppDataTableSortDirection {
  /// 오름차순
  ascending,

  /// 내림차순
  descending,
}

/// DataTable 크기
///
/// 테이블의 밀도를 정의합니다.
enum AppDataTableDensity {
  /// 컴팩트 (작은 패딩)
  compact,

  /// 기본
  standard,

  /// 여유로움 (큰 패딩)
  comfortable,
}

/// DataTable 선택 모드
///
/// 행 선택 모드를 정의합니다.
enum AppDataTableSelectionMode {
  /// 선택 없음
  none,

  /// 단일 선택
  single,

  /// 다중 선택
  multiple,
}

// ========================================================
// Phase 6: 고급 피드백 & 오버레이 컴포넌트
// ========================================================

/// Spinner 크기
///
/// 스피너의 크기를 정의합니다.
enum AppSpinnerSize {
  /// 초소형 (12px)
  xs,

  /// 소형 (16px)
  small,

  /// 중형 (24px)
  medium,

  /// 대형 (32px)
  large,

  /// 초대형 (48px)
  xl,
}

/// Spinner 스타일
///
/// 스피너의 스타일을 정의합니다.
enum AppSpinnerStyle {
  /// 기본 원형
  circular,

  /// 점 스타일
  dots,

  /// 펄스 스타일
  pulse,
}

/// Alert 타입
///
/// 알림 배너의 타입을 정의합니다.
enum AppAlertType {
  /// 정보 (파랑)
  info,

  /// 성공 (초록)
  success,

  /// 경고 (주황)
  warning,

  /// 에러 (빨강)
  error,
}

/// Alert 스타일
///
/// 알림 배너의 스타일을 정의합니다.
enum AppAlertStyle {
  /// 채워진 스타일
  filled,

  /// 아웃라인 스타일
  outlined,

  /// 미묘한 스타일
  subtle,
}

/// Sheet 위치
///
/// 시트가 나타나는 위치를 정의합니다.
enum AppSheetPosition {
  /// 우측
  right,

  /// 좌측
  left,

  /// 상단
  top,

  /// 하단
  bottom,
}

/// Sheet 크기
///
/// 시트의 크기를 정의합니다.
enum AppSheetSize {
  /// 작은 크기 (320px)
  small,

  /// 중간 크기 (480px)
  medium,

  /// 큰 크기 (640px)
  large,

  /// 전체 크기
  full,
}

/// Popover 위치
///
/// 팝오버가 나타나는 위치를 정의합니다.
enum AppPopoverPosition {
  /// 상단
  top,

  /// 하단
  bottom,

  /// 좌측
  left,

  /// 우측
  right,

  /// 상단 시작
  topStart,

  /// 상단 끝
  topEnd,

  /// 하단 시작
  bottomStart,

  /// 하단 끝
  bottomEnd,
}

/// HoverCard 크기
///
/// 호버 카드의 크기를 정의합니다.
enum AppHoverCardSize {
  /// 작은 크기
  small,

  /// 중간 크기
  medium,

  /// 큰 크기
  large,
}

// ========================================================
// Phase 7: 특수 컴포넌트
// ========================================================

/// Collapsible 스타일
///
/// 접기/펼치기 컴포넌트의 스타일을 정의합니다.
enum AppCollapsibleStyle {
  /// 기본 스타일 (테두리 없음)
  plain,

  /// 테두리 스타일
  bordered,

  /// 카드 스타일
  card,
}

/// Timeline 방향
///
/// 타임라인의 레이아웃 방향을 정의합니다.
enum AppTimelineOrientation {
  /// 세로 방향
  vertical,

  /// 가로 방향
  horizontal,
}

/// Timeline 아이템 상태
///
/// 타임라인 아이템의 상태를 정의합니다.
enum AppTimelineItemStatus {
  /// 완료됨
  completed,

  /// 현재 활성
  active,

  /// 대기 중
  pending,

  /// 에러
  error,
}

/// Timeline 위치
///
/// 세로 타임라인에서 콘텐츠 위치를 정의합니다.
enum AppTimelinePosition {
  /// 좌측
  left,

  /// 우측
  right,

  /// 번갈아 배치
  alternate,
}

/// Calendar 뷰 타입
///
/// 캘린더의 표시 모드를 정의합니다.
enum AppCalendarView {
  /// 월간 뷰
  month,

  /// 주간 뷰
  week,

  /// 년간 뷰
  year,
}

/// Calendar 스타일
///
/// 캘린더의 스타일을 정의합니다.
enum AppCalendarStyle {
  /// 기본 스타일
  standard,

  /// 컴팩트 스타일
  compact,

  /// 미니 스타일
  mini,
}

/// ImageGallery 레이아웃
///
/// 이미지 갤러리의 레이아웃을 정의합니다.
enum AppImageGalleryLayout {
  /// 그리드 레이아웃
  grid,

  /// 메이슨리 레이아웃
  masonry,

  /// 캐러셀 레이아웃
  carousel,
}

/// Rating 스타일
///
/// 별점 표시 스타일을 정의합니다.
enum AppRatingStyle {
  /// 별 스타일
  star,

  /// 하트 스타일
  heart,

  /// 숫자 스타일
  numeric,
}

/// Rating 크기
///
/// 별점의 크기를 정의합니다.
enum AppRatingSize {
  /// 작은 크기 (16px)
  small,

  /// 중간 크기 (24px)
  medium,

  /// 큰 크기 (32px)
  large,
}

/// Chart 타입
///
/// 차트의 종류를 정의합니다.
enum AppChartType {
  /// 라인 차트
  line,

  /// 바 차트
  bar,

  /// 파이 차트
  pie,

  /// 도넛 차트
  doughnut,

  /// 영역 차트
  area,
}

/// CodeBlock 언어
///
/// 코드 블록의 프로그래밍 언어를 정의합니다.
enum AppCodeBlockLanguage {
  /// Dart
  dart,

  /// JavaScript
  javascript,

  /// TypeScript
  typescript,

  /// Python
  python,

  /// Java
  java,

  /// Kotlin
  kotlin,

  /// JSON
  json,

  /// YAML
  yaml,

  /// Markdown
  markdown,

  /// Bash
  bash,

  /// 일반 텍스트
  plaintext,
}

/// CodeBlock 테마
///
/// 코드 블록의 테마를 정의합니다.
enum AppCodeBlockTheme {
  /// 라이트 테마
  light,

  /// 다크 테마
  dark,

  /// 시스템 테마 따라감
  auto,
}

/// Resizable 방향
///
/// 리사이즈 가능 방향을 정의합니다.
enum AppResizeDirection {
  /// 가로 방향만
  horizontal,

  /// 세로 방향만
  vertical,

  /// 모든 방향
  both,
}

/// KanbanBoard 카드 크기
///
/// 칸반 카드의 크기를 정의합니다.
enum AppKanbanCardSize {
  /// 컴팩트
  compact,

  /// 기본
  standard,

  /// 상세
  detailed,
}

// ========================================================
// RichTextEditor
// ========================================================

/// 리치 텍스트 에디터 서식 타입
enum RichTextFormat {
  /// 굵게
  bold,

  /// 기울임
  italic,

  /// 밑줄
  underline,

  /// 취소선
  strikethrough,

  /// 제목 1
  heading1,

  /// 제목 2
  heading2,

  /// 제목 3
  heading3,

  /// 불릿 리스트
  bulletList,

  /// 번호 리스트
  numberedList,

  /// 인용
  blockquote,

  /// 코드
  code,

  /// 링크
  link,
}

/// 리치 텍스트 에디터 크기
enum AppRichTextEditorSize {
  /// 작은 크기
  small,

  /// 중간 크기
  medium,

  /// 큰 크기
  large,
}
