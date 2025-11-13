import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_button_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../icons/google_logo.dart';
import 'button_loading_child.dart';

enum PrimaryButtonVariant { action, brand, error, success }

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final String? semanticsLabel;
  final double? width;
  final PrimaryButtonVariant variant;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.semanticsLabel,
    this.width,
    this.variant = PrimaryButtonVariant.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null && !isLoading;

    // Select button style based on variant
    final ButtonStyle buttonStyle;
    final Color onPrimaryColor;

    switch (variant) {
      case PrimaryButtonVariant.brand:
        buttonStyle = AppButtonStyles.brandPrimary(colorScheme);
        onPrimaryColor = AppColors.onPrimary;
        break;
      case PrimaryButtonVariant.error:
        buttonStyle = AppButtonStyles.error(colorScheme);
        onPrimaryColor = Colors.white;
        break;
      case PrimaryButtonVariant.success:
        buttonStyle = FilledButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppComponents.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        );
        onPrimaryColor = Colors.white;
        break;
      case PrimaryButtonVariant.action:
        buttonStyle = AppButtonStyles.primary(colorScheme);
        onPrimaryColor = colorScheme.onPrimary;
    }

    final button = Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticsLabel ?? text,
      child: FilledButton(
        style: buttonStyle,
        onPressed: isEnabled ? onPressed : null,
        child: ButtonLoadingChild(
          text: text,
          icon: icon,
          isLoading: isLoading,
          textStyle: AppTheme.bodyLargeTheme(
            context,
          ).copyWith(color: onPrimaryColor, fontWeight: FontWeight.w600),
          indicatorColor: onPrimaryColor,
        ),
      ),
    );

    // width가 지정된 경우만 SizedBox로 감싸기
    // Row 내에서 너비 제약 없이 사용 가능하도록 조건부 처리
    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? semanticsLabel;
  final double? width;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.semanticsLabel,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null && !isLoading;

    final button = Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticsLabel ?? 'Google로 계속하기',
      child: OutlinedButton(
        style: AppButtonStyles.google(colorScheme),
        onPressed: isEnabled ? onPressed : null,
        child: ButtonLoadingChild(
          text: 'Google로 계속하기',
          icon: const GoogleLogo(size: AppComponents.googleIconSize),
          isLoading: isLoading,
          textStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: colorScheme.brightness == Brightness.dark
                ? const Color(0xFFE3E3E3)
                : const Color(0xFF1F1F1F),
            fontWeight: FontWeight.w500,
          ),
          indicatorColor: AppColors.brand,
        ),
      ),
    );

    // width가 지정된 경우만 SizedBox로 감싸기
    // Row 내에서 너비 제약 없이 사용 가능하도록 조건부 처리
    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }
}
