import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';

/// Billing Toggle - 월간/연간 청구 토글
class BillingToggle extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isYearly;
  final ValueChanged<bool> onChanged;

  const BillingToggle({
    super.key,
    required this.data,
    required this.isYearly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final options =
        (data['options'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final monthlyLabel =
        options.firstWhere(
              (opt) => opt['value'] == 'monthly',
              orElse: () => {'label': 'Billed monthly'},
            )['label']
            as String;
    final yearlyLabel =
        options.firstWhere(
              (opt) => opt['value'] == 'yearly',
              orElse: () => {'label': 'Billed yearly'},
            )['label']
            as String;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Monthly Label
        GestureDetector(
          onTap: () => onChanged(false),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: textTheme.bodyMedium!.copyWith(
              color: isYearly ? colorExt.textTertiary : colorExt.textPrimary,
              fontWeight: isYearly ? FontWeight.normal : FontWeight.w600,
            ),
            child: Text(monthlyLabel),
          ),
        ),

        const SizedBox(width: 12.0),

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
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: isYearly
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12.0),

        // Yearly Label
        GestureDetector(
          onTap: () => onChanged(true),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: textTheme.bodyMedium!.copyWith(
              color: isYearly ? colorExt.textPrimary : colorExt.textTertiary,
              fontWeight: isYearly ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(yearlyLabel),
          ),
        ),
      ],
    );
  }
}
