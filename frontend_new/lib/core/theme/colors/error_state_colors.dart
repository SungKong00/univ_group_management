import 'package:flutter/material.dart';
import '../extensions/app_color_extension.dart';
import '../enums.dart';

/// ErrorState 컴포넌트 전용 색상 구조
///
/// AppColorExtension의 semantic 토큰을 조합하여 생성합니다.
class ErrorStateColors {
  /// 아이콘 색상
  final Color icon;

  /// 제목 색상
  final Color title;

  /// 설명 색상
  final Color description;

  /// 에러 코드 색상
  final Color errorCode;

  /// 배경 색상 (선택적)
  final Color? background;

  const ErrorStateColors({
    required this.icon,
    required this.title,
    required this.description,
    required this.errorCode,
    this.background,
  });

  /// 타입별 팩토리 메서드
  factory ErrorStateColors.from(AppColorExtension c, AppErrorStateType type) {
    return switch (type) {
      AppErrorStateType.general => ErrorStateColors(
        icon: c.stateErrorText,
        title: c.textPrimary,
        description: c.textSecondary,
        errorCode: c.textTertiary,
      ),
      AppErrorStateType.network => ErrorStateColors(
        icon: c.stateWarningText,
        title: c.textPrimary,
        description: c.textSecondary,
        errorCode: c.textTertiary,
      ),
      AppErrorStateType.server => ErrorStateColors(
        icon: c.stateErrorText,
        title: c.textPrimary,
        description: c.textSecondary,
        errorCode: c.textTertiary,
      ),
      AppErrorStateType.unauthorized => ErrorStateColors(
        icon: c.stateErrorText,
        title: c.textPrimary,
        description: c.textSecondary,
        errorCode: c.textTertiary,
      ),
      AppErrorStateType.notFound => ErrorStateColors(
        icon: c.stateInfoText,
        title: c.textPrimary,
        description: c.textSecondary,
        errorCode: c.textTertiary,
      ),
      AppErrorStateType.timeout => ErrorStateColors(
        icon: c.stateWarningText,
        title: c.textPrimary,
        description: c.textSecondary,
        errorCode: c.textTertiary,
      ),
    };
  }
}
