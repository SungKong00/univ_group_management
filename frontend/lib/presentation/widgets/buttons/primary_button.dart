import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_button_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../icons/google_logo.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final String? semanticsLabel;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
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
      label: semanticsLabel ?? text,
      child: SizedBox(
        width: width,
        child: FilledButton(
          style: AppButtonStyles.primary(colorScheme),
          onPressed: isEnabled ? onPressed : null,
          child: _PrimaryButtonChild(
            text: text,
            icon: icon,
            isLoading: isLoading,
            textStyle: AppTheme.bodyLargeTheme(context).copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            indicatorColor: colorScheme.onPrimary,
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
          child: _PrimaryButtonChild(
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

class _PrimaryButtonChild extends StatelessWidget {
  final String text;
  final Widget? icon;
  final bool isLoading;
  final TextStyle textStyle;
  final Color indicatorColor;

  const _PrimaryButtonChild({
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.textStyle,
    required this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: AppComponents.progressIndicatorSize,
        height: AppComponents.progressIndicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      );
    }

    if (icon == null) {
      return Text(text, style: textStyle, textAlign: TextAlign.center);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTheme(
          data: IconThemeData(
            size: AppComponents.googleIconSize,
            color: textStyle.color,
          ),
          child: icon!,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: textStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
