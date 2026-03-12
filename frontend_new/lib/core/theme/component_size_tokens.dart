/// Component Size Design Tokens
///
/// 아이콘, 아바타, 버튼, 박스 등 공통 컴포넌트의 크기를 표준화합니다.
/// 모든 컴포넌트에서 하드코딩된 크기 값을 제거하고 이 토큰을 사용하도록 통일합니다.
class ComponentSizeTokens {
  ComponentSizeTokens._();

  // ============================================================
  // Icon Sizes
  // ============================================================

  /// 초소형 아이콘 (16px)
  /// 사용: 인라인 텍스트 아이콘, 배지
  static const double iconXSmall = 16.0;

  /// 소형 아이콘 (20px)
  /// 사용: 기본 아이콘 (버튼 내부, 리스트 아이템)
  static const double iconSmall = 20.0;

  /// 중형 아이콘 (24px)
  /// 사용: 주요 아이콘 (네비게이션, 상단바)
  static const double iconMedium = 24.0;

  /// 대형 아이콘 (32px)
  /// 사용: 강조 아이콘, 독립 실행형 아이콘
  static const double iconLarge = 32.0;

  // ============================================================
  // Avatar Sizes
  // ============================================================

  /// 초소형 아바타 (24px)
  /// 사용: 인라인 프로필 사진, 댓글 작가
  static const double avatarXSmall = 24.0;

  /// 소형 아바타 (32px)
  /// 사용: 리스트 아이템, 메시지 프리뷰
  static const double avatarSmall = 32.0;

  /// 중형 아바타 (40px)
  /// 사용: 사용자 프로필, 팀 멤버
  static const double avatarMedium = 40.0;

  /// 대형 아바타 (48px)
  /// 사용: 프로필 페이지, 주요 사용자 정보
  static const double avatarLarge = 48.0;

  /// 초대형 아바타 (64px)
  /// 사용: 프로필 상단 사진
  static const double avatarXLarge = 64.0;

  // ============================================================
  // Button / Box Sizes
  // ============================================================

  /// 초소형 박스 (32px)
  /// 사용: 아주 작은 입력 필드, 미니 버튼
  static const double boxXSmall = 32.0;

  /// 소형 박스 (40px)
  /// 사용: 아이콘 버튼, 작은 입력 필드
  static const double boxSmall = 40.0;

  /// 중형 박스 (48px)
  /// 사용: 기본 버튼, 입력 필드, 아바타 옆 공간
  static const double boxMedium = 48.0;

  /// 대형 박스 (56px)
  /// 사용: 큰 버튼, 확장된 입력 필드
  static const double boxLarge = 56.0;

  /// 초대형 박스 (64px)
  /// 사용: 매우 큰 버튼, 헤더 높이
  static const double boxXLarge = 64.0;

  // ============================================================
  // Badge & Indicator Sizes
  // ============================================================

  /// 배지 크기 (8px)
  /// 사용: 온라인 상태 표시, 알림 배지
  static const double badgeSmall = 8.0;

  /// 배지 중형 (12px)
  /// 사용: 숫자 배지, 상태 표시
  static const double badgeMedium = 12.0;

  // ============================================================
  // Spacing inside Components
  // ============================================================

  /// 아이콘-텍스트 간격 (8px)
  /// 사용: 버튼 내 아이콘과 텍스트 사이
  static const double iconTextGap = 8.0;

  /// 아바타-정보 간격 (12px)
  /// 사용: 아바타와 사용자 정보 사이
  static const double avatarInfoGap = 12.0;

  /// 최소 터치 영역 (44px)
  /// 사용: 모바일 버튼, 클릭 가능한 요소
  static const double minTouchTarget = 44.0;

  // ============================================================
  // Switch Sizes (Phase 5)
  // ============================================================

  /// 스위치 트랙 너비 - 소형 (36px)
  static const double switchSmallTrackWidth = 36.0;

  /// 스위치 트랙 높이 - 소형 (20px)
  static const double switchSmallTrackHeight = 20.0;

  /// 스위치 썸 크기 - 소형 (14px)
  static const double switchSmallThumbSize = 14.0;

  /// 스위치 썸 패딩 - 소형 (3px)
  static const double switchSmallThumbPadding = 3.0;

  /// 스위치 트랙 너비 - 중형 (48px)
  static const double switchMediumTrackWidth = 48.0;

  /// 스위치 트랙 높이 - 중형 (26px)
  static const double switchMediumTrackHeight = 26.0;

  /// 스위치 썸 크기 - 중형 (20px)
  static const double switchMediumThumbSize = 20.0;

  /// 스위치 썸 패딩 - 중형 (3px)
  static const double switchMediumThumbPadding = 3.0;

  /// 스위치 트랙 너비 - 대형 (60px)
  static const double switchLargeTrackWidth = 60.0;

  /// 스위치 트랙 높이 - 대형 (32px)
  static const double switchLargeTrackHeight = 32.0;

  /// 스위치 썸 크기 - 대형 (26px)
  static const double switchLargeThumbSize = 26.0;

  /// 스위치 썸 패딩 - 대형 (3px)
  static const double switchLargeThumbPadding = 3.0;

  /// 스위치 Box Shadow Blur Radius (4px)
  static const double switchShadowBlur = 4.0;

  /// 스위치 Box Shadow Offset Y (2px)
  static const double switchShadowOffsetY = 2.0;

  /// 스위치 Box Shadow Offset X (0px)
  static const double switchShadowOffsetX = 0.0;

  /// 스위치 Box Shadow Alpha (0.2)
  static const double switchShadowAlpha = 0.2;

  // ============================================================
  // Radio Button Sizes (Phase 5)
  // ============================================================

  /// 라디오 버튼 크기 - 소형 (16px)
  static const double radioSmallSize = 16.0;

  /// 라디오 버튼 내부 원 크기 - 소형 (8px)
  static const double radioSmallIndicatorSize = 8.0;

  /// 라디오 버튼 크기 - 중형 (20px)
  static const double radioMediumSize = 20.0;

  /// 라디오 버튼 내부 원 크기 - 중형 (10px)
  static const double radioMediumIndicatorSize = 10.0;

  /// 라디오 버튼 크기 - 대형 (24px)
  static const double radioLargeSize = 24.0;

  /// 라디오 버튼 내부 원 크기 - 대형 (12px)
  static const double radioLargeIndicatorSize = 12.0;

  /// 라디오 버튼 테두리 두께 (2px)
  static const double radioBorderWidth = 2.0;

  /// 라디오 버튼 포커스 테두리 두께 (3px)
  static const double radioFocusBorderWidth = 3.0;

  // ============================================================
  // Checkbox Sizes (Phase 5)
  // ============================================================

  /// 체크박스 크기 - 소형 (16px)
  static const double checkboxSmallSize = 16.0;

  /// 체크박스 아이콘 크기 - 소형 (12px)
  static const double checkboxSmallIconSize = 12.0;

  /// 체크박스 크기 - 중형 (20px)
  static const double checkboxMediumSize = 20.0;

  /// 체크박스 아이콘 크기 - 중형 (14px)
  static const double checkboxMediumIconSize = 14.0;

  /// 체크박스 크기 - 대형 (24px)
  static const double checkboxLargeSize = 24.0;

  /// 체크박스 아이콘 크기 - 대형 (18px)
  static const double checkboxLargeIconSize = 18.0;

  /// 체크박스 테두리 두께 (2px)
  static const double checkboxBorderWidth = 2.0;

  /// 체크박스 포커스 테두리 두께 (3px)
  static const double checkboxFocusBorderWidth = 3.0;

  /// 체크박스 모서리 반경 (4px)
  static const double checkboxBorderRadius = 4.0;

  // ============================================================
  // Slider Sizes (Phase 5)
  // ============================================================

  /// 슬라이더 트랙 높이 - 소형 (4px)
  static const double sliderSmallTrackHeight = 4.0;

  /// 슬라이더 썸 크기 - 소형 (12px)
  static const double sliderSmallThumbSize = 12.0;

  /// 슬라이더 트랙 높이 - 중형 (6px)
  static const double sliderMediumTrackHeight = 6.0;

  /// 슬라이더 썸 크기 - 중형 (16px)
  static const double sliderMediumThumbSize = 16.0;

  /// 슬라이더 트랙 높이 - 대형 (8px)
  static const double sliderLargeTrackHeight = 8.0;

  /// 슬라이더 썸 크기 - 대형 (20px)
  static const double sliderLargeThumbSize = 20.0;

  /// 슬라이더 마크 크기 (8px)
  static const double sliderMarkSize = 8.0;

  /// 슬라이더 포커스 링 크기 (4px)
  static const double sliderFocusRingWidth = 4.0;
}
