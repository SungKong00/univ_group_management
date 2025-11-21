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
}
