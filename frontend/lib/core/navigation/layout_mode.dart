import 'package:flutter/widgets.dart';

/// 화면 크기에 따른 레이아웃 모드
///
/// 3단계 반응형 디자인:
/// - COMPACT (0-600px): 모바일 - 하단 네비게이션
/// - MEDIUM (601-1024px): 태블릿 - 축소 사이드바 (아이콘만)
/// - WIDE (1025px+): 데스크톱 - 전체 사이드바 (아이콘 + 텍스트)
enum LayoutMode {
  /// 모바일 레이아웃 (0-600px)
  /// - 하단 네비게이션 바
  /// - 전체 화면 콘텐츠
  compact,

  /// 태블릿 레이아웃 (601-1024px)
  /// - 축소된 좌측 사이드바 (아이콘만)
  /// - 콘텐츠 영역 축소
  medium,

  /// 데스크톱 레이아웃 (1025px+)
  /// - 전체 좌측 사이드바 (아이콘 + 텍스트 + 설명)
  /// - 워크스페이스 진입 시 축소 가능
  wide,
}

/// LayoutMode 확장 메서드
extension LayoutModeExtension on LayoutMode {
  /// 현재 모드가 모바일인지 확인
  bool get isCompact => this == LayoutMode.compact;

  /// 현재 모드가 태블릿인지 확인
  bool get isMedium => this == LayoutMode.medium;

  /// 현재 모드가 데스크톱인지 확인
  bool get isWide => this == LayoutMode.wide;

  /// 사이드바를 사용하는 모드인지 확인 (MEDIUM, WIDE)
  bool get usesSidebar => this == LayoutMode.medium || this == LayoutMode.wide;

  /// 하단 네비게이션을 사용하는 모드인지 확인 (COMPACT)
  bool get usesBottomNavigation => this == LayoutMode.compact;

  /// 사이드바를 항상 축소해야 하는지 확인 (MEDIUM)
  bool get forceSidebarCollapsed => this == LayoutMode.medium;

  /// 화면 너비로부터 LayoutMode 계산
  static LayoutMode fromWidth(double width) {
    if (width <= 600) {
      return LayoutMode.compact;
    } else if (width <= 1024) {
      return LayoutMode.medium;
    } else {
      return LayoutMode.wide;
    }
  }

  /// BuildContext로부터 현재 LayoutMode 계산
  static LayoutMode fromContext(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return fromWidth(width);
  }

  /// 디버그용 문자열 표현
  String get displayName {
    switch (this) {
      case LayoutMode.compact:
        return 'Compact (Mobile)';
      case LayoutMode.medium:
        return 'Medium (Tablet)';
      case LayoutMode.wide:
        return 'Wide (Desktop)';
    }
  }
}
