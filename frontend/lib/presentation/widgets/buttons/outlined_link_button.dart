import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_button_styles.dart';
import '../../../core/theme/app_colors.dart';
import 'button_loading_child.dart';

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

    final button = Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticsLabel ?? text,
      child: switch (variant) {
        ButtonVariant.outlined => OutlinedButton(
          style: AppButtonStyles.outlined(colorScheme),
          onPressed: isEnabled ? onPressed : null,
          child: ButtonLoadingChild(
            text: text,
            icon: icon,
            isLoading: isLoading,
            textStyle: AppTheme.bodyLargeTheme(
              context,
            ).copyWith(color: AppColors.brand, fontWeight: FontWeight.w600),
            indicatorColor: AppColors.brand,
          ),
        ),
        ButtonVariant.tonal => FilledButton(
          style: AppButtonStyles.tonal(colorScheme),
          onPressed: isEnabled ? onPressed : null,
          child: ButtonLoadingChild(
            text: text,
            icon: icon,
            isLoading: isLoading,
            textStyle: AppTheme.bodyMediumTheme(
              context,
            ).copyWith(color: AppColors.brand, fontWeight: FontWeight.w500),
            indicatorColor: AppColors.brand,
          ),
        ),
      },
    );

    // width가 지정된 경우만 SizedBox로 감싸기
    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
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
