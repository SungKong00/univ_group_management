import '../../../core/constants/app_constants.dart';

/// PostList 위젯 전용 상수 정의
class PostListConstants {
  /// Sticky header 높이 (날짜 구분선)
  static const double stickyHeaderHeight = 24.0;

  /// 채널 헤더 높이 (화면 전체 좌표계 기준)
  /// - Container padding top: 13px
  /// - Text(channelName) 높이: 26px (headlineMedium: fontSize 20px × height 1.3)
  /// - SizedBox: 0px
  /// - 총합: 39px
  ///
  /// 📍 용도:
  /// - _updateSticky(): localToGlobal() 좌표 보정 (화면 전체 기준 y좌표)
  /// - Positioned(top): ❌ 사용 금지! PostList Stack은 상대 좌표이므로 top: 0 사용
  ///
  /// 📍 참조: channel_content_view.dart, theme.dart headlineMedium
  static const double channelHeaderHeight = 39.0;

  /// Sticky Header 표시 임계값 (화면 전체 좌표계 기준)
  ///
  /// 📍 계산 근거:
  /// - TopNavigation: 48px (AppConstants.topNavigationHeight)
  /// - ChannelHeader: 39px (channelHeaderHeight)
  /// - 총합: 87px
  ///
  /// 📍 좌표 시스템:
  /// - localToGlobal()은 viewport 최상단(0,0)부터 측정
  /// - pos.dy = 0: TopNavigation 최상단
  /// - pos.dy = 48: ChannelHeader 시작점
  /// - pos.dy = 87: PostList 시작점 (Sticky Header 고정 위치)
  ///
  /// 📍 용도:
  /// - _updateSticky(): "TopNavigation + ChannelHeader 아래에서 조금이라도 보이는" 항목 탐지
  static const double stickyThreshold =
      AppConstants.topNavigationHeight + channelHeaderHeight; // 48 + 39 = 87
}
