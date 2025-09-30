import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_button_styles.dart';
import '../../../core/theme/app_colors.dart';

class OutlinedLinkButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final String? semanticsLabel;
  final double? width;
  final ButtonVariant variant;

  const OutlinedLinkButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.semanticsLabel,
    this.width,
    this.variant = ButtonVariant.outlined,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null && !isLoading;

    final button = switch (variant) {
      ButtonVariant.outlined => OutlinedButton(
          style: AppButtonStyles.outlined(colorScheme),
          onPressed: isEnabled ? onPressed : null,
          child: _OutlinedChild(
            text: text,
            icon: icon,
            isLoading: isLoading,
            textStyle: AppTheme.bodyMediumTheme(context).copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ButtonVariant.tonal => FilledButton(
          style: AppButtonStyles.tonal(colorScheme),
          onPressed: isEnabled ? onPressed : null,
          child: _OutlinedChild(
            text: text,
            icon: icon,
            isLoading: isLoading,
            textStyle: AppTheme.bodyMediumTheme(context).copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    };

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticsLabel ?? text,
      child: SizedBox(width: width, child: button),
    );
  }
}

class _OutlinedChild extends StatelessWidget {
  final String text;
  final Widget? icon;
  final bool isLoading;
  final TextStyle textStyle;

  const _OutlinedChild({
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: AppComponents.progressIndicatorSize,
        height: AppComponents.progressIndicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
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
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class AdminLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? semanticsLabel;
  final double? width;
  final ButtonVariant variant;

  const AdminLoginButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.semanticsLabel,
    this.width,
    this.variant = ButtonVariant.outlined,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedLinkButton(
      text: '관리자 계정으로 로그인',
      onPressed: onPressed,
      isLoading: isLoading,
      semanticsLabel: semanticsLabel ?? '관리자 계정으로 로그인',
      width: width,
      variant: variant,
      icon: isLoading
          ? null
          : const Icon(
              Icons.admin_panel_settings_outlined,
              size: AppComponents.googleIconSize,
              color: AppColors.brand,
            ),
    );
  }
}

enum ButtonVariant { outlined, tonal }
