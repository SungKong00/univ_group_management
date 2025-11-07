import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// App SnackBar Helper
///
/// Provides convenient factory methods for showing SnackBars with consistent styling.
///
/// ## Usage
///
/// ```dart
/// // Success message
/// AppSnackBar.success(context, '저장되었습니다');
///
/// // Error message
/// AppSnackBar.error(context, '저장에 실패했습니다');
///
/// // Warning message
/// AppSnackBar.warning(context, '권한이 부족합니다');
///
/// // Info message
/// AppSnackBar.info(context, '처리 중입니다...');
///
/// // Custom duration
/// AppSnackBar.success(
///   context,
///   '작업이 완료되었습니다',
///   duration: const Duration(seconds: 3),
/// );
/// ```
///
/// ## Design
///
/// - **Success**: Green background (AppColors.success)
/// - **Error**: Red background (AppColors.error)
/// - **Warning**: Orange background
/// - **Info**: Default grey background
/// - **Text Color**: White for all variants
/// - **Default Duration**: 2 seconds
class AppSnackBar {
  AppSnackBar._();

  /// Shows a success message with green background
  ///
  /// Use for successful operations like save, delete, update.
  ///
  /// Example:
  /// ```dart
  /// AppSnackBar.success(context, '저장되었습니다');
  /// ```
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.success,
      duration: duration,
    );
  }

  /// Shows an error message with red background
  ///
  /// Use for failed operations or error states.
  ///
  /// Example:
  /// ```dart
  /// AppSnackBar.error(context, '저장에 실패했습니다');
  /// ```
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.error,
      duration: duration,
    );
  }

  /// Shows a warning message with orange background
  ///
  /// Use for warnings or cautionary messages.
  ///
  /// Example:
  /// ```dart
  /// AppSnackBar.warning(context, '권한이 부족합니다');
  /// ```
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      message,
      backgroundColor: Colors.orange,
      duration: duration,
    );
  }

  /// Shows an info message with default grey background
  ///
  /// Use for informational messages or neutral notifications.
  ///
  /// Example:
  /// ```dart
  /// AppSnackBar.info(context, '처리 중입니다...');
  /// ```
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      message,
      backgroundColor: Colors.grey,
      duration: duration,
    );
  }

  /// Shows a custom SnackBar with specified background color
  ///
  /// Use when you need a custom color not covered by success/error/warning/info.
  ///
  /// Example:
  /// ```dart
  /// AppSnackBar.custom(
  ///   context,
  ///   '커스텀 메시지',
  ///   backgroundColor: Colors.purple,
  ///   duration: const Duration(seconds: 3),
  /// );
  /// ```
  static void custom(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.grey,
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      message,
      backgroundColor: backgroundColor,
      duration: duration,
    );
  }

  /// Internal method to show SnackBar
  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }
}
