import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/animation_tokens.dart';
import '../theme/responsive_tokens.dart';
import '../../features/component_showcase/data/models/billing_cycle_model.dart';

/// Billing Toggle - 월간/연간 청구 토글
class BillingToggle extends StatelessWidget {
  final BillingCycle cycle;
  final bool isYearly;
  final ValueChanged<bool> onChanged;

  const BillingToggle({
    super.key,
    required this.cycle,
    required this.isYearly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Monthly Label
        GestureDetector(
          onTap: () => onChanged(false),
          child: AnimatedDefaultTextStyle(
            duration: AnimationTokens.durationStandard,
            style: textTheme.bodyMedium!.copyWith(
              color: isYearly ? colorExt.textTertiary : colorExt.textPrimary,
              fontWeight: isYearly ? FontWeight.normal : FontWeight.w600,
            ),
            child: Text(cycle.monthlyLabel),
          ),
        ),

        const SizedBox(width: ResponsiveTokens.space12),

        // Toggle Switch
        GestureDetector(
          onTap: () => onChanged(!isYearly),
          child: Container(
            width: 48,
            height: 28,
            decoration: BoxDecoration(
              color: isYearly
                  ? colorExt.brandPrimary
                  : colorExt.borderSecondary,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(3),
            child: AnimatedAlign(
              duration: AnimationTokens.durationStandard,
              curve: AnimationTokens.curveSmooth,
              alignment: isYearly
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colorExt.textOnBrand,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorExt.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: ResponsiveTokens.space12),

        // Yearly Label
        GestureDetector(
          onTap: () => onChanged(true),
          child: AnimatedDefaultTextStyle(
            duration: AnimationTokens.durationStandard,
            style: textTheme.bodyMedium!.copyWith(
              color: isYearly ? colorExt.textPrimary : colorExt.textTertiary,
              fontWeight: isYearly ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(cycle.yearlyLabel),
          ),
        ),
      ],
    );
  }
}
