import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/pricing_card_colors.dart';
import '../theme/responsive_tokens.dart';
import 'app_button.dart';

/// Pricing Plan Card - JSON 기반 가격 책정 카드
class PricingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isHighlighted;
  final VoidCallback? onCtaPressed;

  const PricingCard({
    super.key,
    required this.data,
    this.isHighlighted = false,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final tier = data['tier'] as String? ?? 'unknown';
    final price = data['price'] as String? ?? 'N/A';
    final priceFormat = data['priceFormat'] as String? ?? '';
    final features =
        (data['features'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final ctas = _parseCtas();

    // Styling 정보
    final styling = data['styling'] as Map<String, dynamic>? ?? {};
    final borderRadius =
        double.tryParse(
          styling['borderRadius']?.toString().replaceAll('px', '') ?? '16',
        ) ??
        16.0;

    // Tier에 따른 색상 팔레트 선택
    final pricingColors = switch (tier) {
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
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier Badge (Enterprise만 표시)
          if (tier == 'enterprise') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pricingColors.tagBg,
                borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 16),
          ],

          // Price
          Text(
            price,
            style: textTheme.headlineLarge!.copyWith(
              color: pricingColors.price,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (priceFormat.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              priceFormat,
              style: textTheme.bodySmall!.copyWith(
                color: pricingColors.priceUnit,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Features
          ...features.map(
            (feature) => _buildFeatureItem(pricingColors, textTheme, feature),
          ),

          const SizedBox(height: 24),

          // CTA Button(s)
          ...ctas.asMap().entries.map((entry) {
            final index = entry.key;
            final cta = entry.value;
            final variant = (cta['variant'] as String?) == 'secondary'
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary;

            return Padding(
              padding: EdgeInsets.only(top: index > 0 ? 12 : 0),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: cta['text'] as String? ?? 'Get started',
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
    Map<String, dynamic> feature,
  ) {
    final text = feature['text'] as String? ?? '';
    final enabled = feature['enabled'] as bool? ?? true;
    final hasLink = feature['link'] != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkmark Icon
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: enabled
                  ? pricingColors.featureIconEnabled.withValues(alpha: 0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: enabled
                  ? pricingColors.featureIconEnabled
                  : pricingColors.featureIconDisabled,
            ),
          ),

          // Text
          Expanded(
            child: Text(
              text,
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

  /// CTA 파싱
  List<Map<String, dynamic>> _parseCtas() {
    final cta = data['cta'];
    final ctas = data['ctas'];

    if (ctas is List) {
      return ctas.cast<Map<String, dynamic>>();
    } else if (cta is Map) {
      return [cta.cast<String, dynamic>()];
    }
    return [];
  }
}
