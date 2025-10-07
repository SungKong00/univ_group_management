import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../core/constants/app_breakpoints.dart';

/// 워크스페이스 반응형 레이아웃 계산 헬퍼
///
/// 반응형 브레이크포인트, 채널바/댓글바 너비, inset 계산 등을 중앙화
class ResponsiveLayoutHelper {
  final BuildContext context;
  final BoxConstraints constraints;

  const ResponsiveLayoutHelper({
    required this.context,
    required this.constraints,
  });

  /// 현재 화면이 데스크톱인지 확인
  /// 문서 스펙: MOBILE(0-600px), TABLET(601-800px), DESKTOP(801px+)
  /// largerThan(MOBILE) = 601px 이상 = TABLET, DESKTOP, 4K
  bool get isDesktop => ResponsiveBreakpoints.of(context).largerThan(MOBILE);

  /// 현재 화면이 모바일인지 확인
  bool get isMobile => !isDesktop;

  /// Narrow Desktop 여부 확인
  /// 채널바(200px) + 여유있는 콘텐츠(350px) + 댓글바(300px) = 850px
  /// 사용자 요청: 850px 미만을 narrow desktop으로 간주
  bool get isNarrowDesktop => isDesktop && constraints.maxWidth < 850;

  /// Wide Desktop 여부 확인
  bool get isWideDesktop => isDesktop && !isNarrowDesktop;

  /// 화면 너비 (MediaQuery 캐싱)
  double get screenWidth => MediaQuery.of(context).size.width;

  /// 채널바 너비 계산
  /// 1200px 이상: 256px, 그 외: 200px
  double get channelBarWidth => screenWidth >= 1200 ? 256.0 : 200.0;

  /// 댓글바 너비 계산
  /// 1200px 이상: 390px, 그 외: 300px
  double get commentBarWidth => screenWidth >= 1200 ? 390.0 : 300.0;

  /// 왼쪽 inset 계산 (채널 네비게이션)
  double getLeftInset({required bool showChannelNavigation}) {
    return showChannelNavigation ? channelBarWidth : 0;
  }

  /// 오른쪽 inset 계산 (댓글 패널)
  double getRightInset({
    required bool showComments,
    required bool isNarrowCommentFullscreen,
  }) {
    // Narrow desktop 댓글 전체 화면: 오른쪽 inset 없음
    return (showComments && !isNarrowCommentFullscreen) ? commentBarWidth : 0;
  }

  /// 레이아웃 정보를 한 번에 계산하여 반환
  ResponsiveLayoutInfo calculateLayout({
    required bool showChannelNavigation,
    required bool showComments,
    required bool isNarrowCommentFullscreen,
  }) {
    return ResponsiveLayoutInfo(
      isDesktop: isDesktop,
      isMobile: isMobile,
      isNarrowDesktop: isNarrowDesktop,
      isWideDesktop: isWideDesktop,
      screenWidth: screenWidth,
      channelBarWidth: channelBarWidth,
      commentBarWidth: commentBarWidth,
      leftInset: getLeftInset(showChannelNavigation: showChannelNavigation),
      rightInset: getRightInset(
        showComments: showComments,
        isNarrowCommentFullscreen: isNarrowCommentFullscreen,
      ),
    );
  }
}

/// 계산된 반응형 레이아웃 정보
class ResponsiveLayoutInfo {
  final bool isDesktop;
  final bool isMobile;
  final bool isNarrowDesktop;
  final bool isWideDesktop;
  final double screenWidth;
  final double channelBarWidth;
  final double commentBarWidth;
  final double leftInset;
  final double rightInset;

  const ResponsiveLayoutInfo({
    required this.isDesktop,
    required this.isMobile,
    required this.isNarrowDesktop,
    required this.isWideDesktop,
    required this.screenWidth,
    required this.channelBarWidth,
    required this.commentBarWidth,
    required this.leftInset,
    required this.rightInset,
  });
}
