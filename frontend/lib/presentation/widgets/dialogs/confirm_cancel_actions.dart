import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../buttons/neutral_outlined_button.dart';
import '../buttons/primary_button.dart';

export '../buttons/primary_button.dart' show PrimaryButtonVariant;

/// Dialog action row that places a primary confirm button on the left and a
/// neutral cancel button on the right for consistent layout.
class ConfirmCancelActions extends StatelessWidget {
  const ConfirmCancelActions({
    super.key,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText = '취소',
    this.onCancel,
    this.confirmSemanticsLabel,
    this.cancelSemanticsLabel,
    this.isConfirmLoading = false,
    this.isCancelLoading = false,
    this.spacing = AppSpacing.xs,
    this.cancelButtonWidth = 132,
    this.confirmVariant = PrimaryButtonVariant.action,
  });

  final String confirmText;
  final VoidCallback? onConfirm;
  final String? confirmSemanticsLabel;
  final bool isConfirmLoading;
  final PrimaryButtonVariant confirmVariant;

  final String cancelText;
  final VoidCallback? onCancel;
  final String? cancelSemanticsLabel;
  final bool isCancelLoading;

  final double spacing;
  final double cancelButtonWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: PrimaryButton(
            text: confirmText,
            onPressed: onConfirm,
            isLoading: isConfirmLoading,
            semanticsLabel: confirmSemanticsLabel,
            variant: confirmVariant,
          ),
        ),
        SizedBox(width: spacing),
        NeutralOutlinedButton(
          text: cancelText,
          onPressed: onCancel,
          isLoading: isCancelLoading,
          semanticsLabel: cancelSemanticsLabel,
          width: cancelButtonWidth,
        ),
      ],
    );
  }
}
