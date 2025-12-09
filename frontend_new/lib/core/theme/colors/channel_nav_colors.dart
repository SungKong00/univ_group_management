import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// 채널 네비게이션 컴포넌트 전용 색상 구조
///
/// 워크스페이스 내 채널 목록 사이드바의 색상을 정의합니다.
/// 그룹 헤더, 채널 목록, 섹션 구분자 등의 색상을 포함합니다.
class ChannelNavColors {
  /// 배경 색상
  final Color background;

  /// 테두리 색상
  final Color border;

  /// 헤더 배경 색상
  final Color headerBackground;

  /// 헤더 텍스트 색상
  final Color headerText;

  /// 헤더 보조 텍스트 색상 (역할 표시 등)
  final Color headerTextSecondary;

  /// 섹션 제목 색상
  final Color sectionTitle;

  /// 채널 아이템 배경 (기본)
  final Color itemBackground;

  /// 채널 아이템 배경 (호버)
  final Color itemHover;

  /// 채널 아이템 배경 (활성)
  final Color itemActive;

  /// 채널 아이콘 색상
  final Color itemIcon;

  /// 채널 아이콘 색상 (활성)
  final Color itemIconActive;

  /// 채널 텍스트 색상
  final Color itemText;

  /// 채널 텍스트 색상 (활성)
  final Color itemTextActive;

  /// 미읽음 배지 배경
  final Color badgeBackground;

  /// 미읽음 배지 텍스트
  final Color badgeText;

  /// 드롭다운 화살표 색상
  final Color dropdownIcon;

  /// 구분선 색상
  final Color divider;

  const ChannelNavColors({
    required this.background,
    required this.border,
    required this.headerBackground,
    required this.headerText,
    required this.headerTextSecondary,
    required this.sectionTitle,
    required this.itemBackground,
    required this.itemHover,
    required this.itemActive,
    required this.itemIcon,
    required this.itemIconActive,
    required this.itemText,
    required this.itemTextActive,
    required this.badgeBackground,
    required this.badgeText,
    required this.dropdownIcon,
    required this.divider,
  });

  /// 기본 팩토리
  factory ChannelNavColors.from(AppColorExtension c) {
    return ChannelNavColors(
      background: c.surfaceSecondary,
      border: c.borderSecondary,
      headerBackground: c.surfaceTertiary,
      headerText: c.textPrimary,
      headerTextSecondary: c.textTertiary,
      sectionTitle: c.textTertiary,
      itemBackground: Colors.transparent,
      itemHover: c.surfaceTertiary,
      itemActive: c.brandPrimary.withValues(alpha: 0.15),
      itemIcon: c.textTertiary,
      itemIconActive: c.brandPrimary,
      itemText: c.textSecondary,
      itemTextActive: c.textPrimary,
      badgeBackground: c.brandPrimary,
      badgeText: c.brandText,
      dropdownIcon: c.textTertiary,
      divider: c.borderSecondary,
    );
  }
}
