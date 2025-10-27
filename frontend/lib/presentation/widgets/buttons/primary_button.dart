import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_button_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../icons/google_logo.dart';
import 'button_loading_child.dart';

enum PrimaryButtonVariant { action, brand }

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
    final isBrandVariant = variant == PrimaryButtonVariant.brand;
    final buttonStyle = isBrandVariant
        ? AppButtonStyles.brandPrimary(colorScheme)
        : AppButtonStyles.primary(colorScheme);
    final onPrimaryColor = isBrandVariant
        ? AppColors.onPrimary
        : colorScheme.onPrimary;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticsLabel ?? text,
      child: SizedBox(
        width: width,
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
      ),
    );
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

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticsLabel ?? 'Google로 계속하기',
      child: SizedBox(
        width: width,
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
      ),
    );
  }
}
