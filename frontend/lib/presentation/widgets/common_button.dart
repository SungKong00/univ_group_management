import 'package:flutter/material.dart';

enum ButtonType { primary, text }

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    Widget child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    final Widget button = switch (type) {
      ButtonType.primary => ElevatedButton(onPressed: isDisabled ? null : onPressed, child: child),
      ButtonType.text => TextButton(onPressed: isDisabled ? null : onPressed, child: child),
    };

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: button);
    }
    return button;
  }
}

