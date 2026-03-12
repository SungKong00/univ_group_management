import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';

/// FileUpload 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class FileUploadColors {
  /// 배경 색상
  final Color background;

  /// 호버 시 배경 색상
  final Color backgroundHover;

  /// 드래그 오버 시 배경 색상
  final Color backgroundDragOver;

  /// 테두리 색상
  final Color border;

  /// 호버 시 테두리 색상
  final Color borderHover;

  /// 드래그 오버 시 테두리 색상
  final Color borderDragOver;

  /// 비활성화 테두리 색상
  final Color borderDisabled;

  /// 에러 테두리 색상
  final Color borderError;

  /// 아이콘 색상
  final Color icon;

  /// 드래그 오버 시 아이콘 색상
  final Color iconDragOver;

  /// 비활성화 아이콘 색상
  final Color iconDisabled;

  /// 텍스트 색상
  final Color text;

  /// 보조 텍스트 색상
  final Color textSecondary;

  /// 비활성화 텍스트 색상
  final Color textDisabled;

  /// 에러 텍스트 색상
  final Color textError;

  /// 파일 아이템 배경 색상
  final Color itemBackground;

  /// 파일 아이템 호버 배경 색상
  final Color itemBackgroundHover;

  /// 파일 아이템 테두리 색상
  final Color itemBorder;

  /// 프로그레스 바 색상
  final Color progressBar;

  /// 프로그레스 바 배경 색상
  final Color progressBarBackground;

  /// 삭제 버튼 색상
  final Color deleteButton;

  /// 삭제 버튼 호버 색상
  final Color deleteButtonHover;

  /// 성공 아이콘 색상
  final Color successIcon;

  const FileUploadColors({
    required this.background,
    required this.backgroundHover,
    required this.backgroundDragOver,
    required this.border,
    required this.borderHover,
    required this.borderDragOver,
    required this.borderDisabled,
    required this.borderError,
    required this.icon,
    required this.iconDragOver,
    required this.iconDisabled,
    required this.text,
    required this.textSecondary,
    required this.textDisabled,
    required this.textError,
    required this.itemBackground,
    required this.itemBackgroundHover,
    required this.itemBorder,
    required this.progressBar,
    required this.progressBarBackground,
    required this.deleteButton,
    required this.deleteButtonHover,
    required this.successIcon,
  });

  /// 기본 팩토리 메서드
  factory FileUploadColors.from(AppColorExtension c) {
    return FileUploadColors(
      background: c.surfaceSecondary,
      backgroundHover: c.surfaceTertiary,
      backgroundDragOver: c.brandPrimary.withValues(alpha: 0.1),
      border: c.borderSecondary,
      borderHover: c.borderPrimary,
      borderDragOver: c.brandPrimary,
      borderDisabled: c.borderTertiary,
      borderError: c.stateErrorBg,
      icon: c.textTertiary,
      iconDragOver: c.brandPrimary,
      iconDisabled: c.textQuaternary,
      text: c.textPrimary,
      textSecondary: c.textSecondary,
      textDisabled: c.textQuaternary,
      textError: c.stateErrorText,
      itemBackground: c.surfaceTertiary,
      itemBackgroundHover: c.surfaceQuaternary,
      itemBorder: c.borderTertiary,
      progressBar: c.brandPrimary,
      progressBarBackground: c.surfaceQuaternary,
      deleteButton: c.textTertiary,
      deleteButtonHover: c.stateErrorBg,
      successIcon: c.stateSuccessText,
    );
  }
}
