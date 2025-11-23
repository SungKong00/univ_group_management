import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/pricing_card_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';
import 'app_button.dart';
import '../../features/component_showcase/data/models/pricing_plan_model.dart';
import '../../features/component_showcase/data/models/feature_model.dart';

/// Pricing Plan Card - 가격 책정 카드
class PricingCard extends StatelessWidget {
  final PricingPlan plan;
  final bool isHighlighted;
  final VoidCallback? onCtaPressed;

  const PricingCard({
    super.key,
    required this.plan,
    this.isHighlighted = false,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacing = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;

    // Tier에 따른 색상 팔레트 선택
    final pricingColors = switch (plan.tier) {
      'enterprise' => PricingCardColors.enterprise(colorExt),
      'premium' => PricingCardColors.premium(colorExt),
      _ => PricingCardColors.standard(colorExt),
    };

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: pricingColors.background,
        border: Border.all(
          color: isHighlighted
              ? pricingColors.borderHighlight
              : pricingColors.border,
          width: isHighlighted ? 2 : 1,
        ),
        borderRadius: BorderTokens.xxlRadius(),
      ),
      padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier Badge (Enterprise만 표시)
          if (plan.tier == 'enterprise') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pricingColors.tagBg,
                borderRadius: BorderTokens.xlRadius(),
              ),
              child: Text(
                'PREMIUM',
                style: textTheme.labelSmall!.copyWith(
                  color: pricingColors.tagText,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: spacing.large),
          ],

          // Price
          Text(
            plan.price,
            style: textTheme.headlineLarge!.copyWith(
              color: pricingColors.price,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (plan.priceFormat.isNotEmpty) ...[
            SizedBox(height: spacing.xs),
            Text(
              plan.priceFormat,
              style: textTheme.bodySmall!.copyWith(
                color: pricingColors.priceUnit,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Features
          ...plan.features.map(
            (feature) => _buildFeatureItem(pricingColors, textTheme, feature),
          ),

          const SizedBox(height: 24),

          // CTA Button(s)
          ...plan.ctas.asMap().entries.map((entry) {
            final index = entry.key;
            final cta = entry.value;
            final variant = cta.variant == 'secondary'
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary;

            return Padding(
              padding: EdgeInsets.only(top: index > 0 ? 12 : 0),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: cta.text,
                  variant: variant,
                  onPressed: onCtaPressed,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Feature 아이템 빌드
  Widget _buildFeatureItem(
    PricingCardColors pricingColors,
    TextTheme textTheme,
    Feature feature,
  ) {
    final hasLink = feature.link != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkmark Icon
          Container(
            width: ComponentSizeTokens.iconSmall,
            height: ComponentSizeTokens.iconSmall,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: feature.enabled
                  ? pricingColors.featureIconEnabled.withValues(alpha: 0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: ComponentSizeTokens.badgeMedium,
              color: feature.enabled
                  ? pricingColors.featureIconEnabled
                  : pricingColors.featureIconDisabled,
            ),
          ),

          // Text
          Expanded(
            child: Text(
              feature.text,
              style: textTheme.bodyMedium!.copyWith(
                color: pricingColors.featureText,
                decoration: hasLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
