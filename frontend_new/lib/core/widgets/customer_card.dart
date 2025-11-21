import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/customer_card_colors.dart';
import '../theme/responsive_tokens.dart';

/// Customer Card - 고객 사례 카드
class CustomerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const CustomerCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final customerCardColors = CustomerCardColors.standard(colorExt);
    final width = MediaQuery.sizeOf(context).width;
    final company = data['company'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final hasImage = data['hasImage'] as bool? ?? false;
    final cta = data['cta'] as Map<String, dynamic>?;
    final ctaText = cta?['text'] as String? ?? 'Read story';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: customerCardColors.background,
          border: Border.all(color: customerCardColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            if (hasImage)
              Container(
                height: 180,
                color: customerCardColors.logoBg,
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: colorExt.textQuaternary,
                  ),
                ),
              ),

            // Content
            Padding(
              padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Name
                  Text(
                    company,
                    style: textTheme.bodySmall!.copyWith(
                      color: customerCardColors.meta,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    title,
                    style: textTheme.headlineSmall!.copyWith(
                      color: customerCardColors.companyName,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // CTA
                  Row(
                    children: [
                      Text(
                        ctaText,
                        style: textTheme.bodyMedium!.copyWith(
                          color: colorExt.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: colorExt.brandPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
