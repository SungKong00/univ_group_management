import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/customer_card_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../../features/component_showcase/data/models/customer_model.dart';

/// Customer Card - 고객 사례 카드
class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;

  const CustomerCard({super.key, required this.customer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final customerCardColors = CustomerCardColors.standard(colorExt);
    final width = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: customerCardColors.background,
          border: Border.all(color: customerCardColors.border),
          borderRadius: BorderTokens.xxlRadius(),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            if (customer.hasImage)
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Container(
                  color: customerCardColors.logoBg,
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: colorExt.textQuaternary,
                    ),
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
                    customer.company,
                    style: textTheme.bodySmall!.copyWith(
                      color: customerCardColors.meta,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    customer.title,
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
                        customer.ctaText,
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
