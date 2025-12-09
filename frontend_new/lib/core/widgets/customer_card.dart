import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/customer_card_colors.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // 카드 너비 기준 반응형 계산
        final cardWidth = constraints.maxWidth;
        final isTiny = cardWidth < 120;
        final isCompact = cardWidth < 180;
        final isSmall = cardWidth < 250;

        // 카드 너비 기반 패딩/간격
        final cardPadding = isTiny ? 8.0 : (isCompact ? 10.0 : (isSmall ? 12.0 : 16.0));
        final cardGap = isTiny ? 4.0 : (isCompact ? 6.0 : (isSmall ? 8.0 : 12.0));

        // 카드 너비 기반 아이콘 크기
        final iconSize = isTiny ? 20.0 : (isCompact ? 28.0 : (isSmall ? 36.0 : 48.0));
        final ctaIconSize = isTiny ? 10.0 : (isCompact ? 12.0 : 14.0);

        // 카드 너비 기반 폰트 크기
        final companyFontSize = isTiny ? 8.0 : (isCompact ? 9.0 : (isSmall ? 10.0 : 12.0));
        final titleFontSize = isTiny ? 11.0 : (isCompact ? 13.0 : (isSmall ? 15.0 : 18.0));
        final ctaFontSize = isTiny ? 9.0 : (isCompact ? 10.0 : (isSmall ? 11.0 : 13.0));

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
              mainAxisSize: MainAxisSize.min,
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
                          size: iconSize,
                          color: colorExt.textQuaternary,
                        ),
                      ),
                    ),
                  ),

                // Content
                Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Company Name
                      Text(
                        customer.company,
                        style: textTheme.bodySmall!.copyWith(
                          fontSize: companyFontSize,
                          color: customerCardColors.meta,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: cardGap * 0.5),

                      // Title
                      Text(
                        customer.title,
                        style: textTheme.titleMedium!.copyWith(
                          fontSize: titleFontSize,
                          color: customerCardColors.companyName,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: isTiny ? 1 : (isCompact ? 2 : 3),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: cardGap),

                      // CTA
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              customer.ctaText,
                              style: textTheme.bodyMedium!.copyWith(
                                fontSize: ctaFontSize,
                                color: colorExt.brandPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: cardGap * 0.5),
                          Icon(
                            Icons.arrow_forward,
                            size: ctaIconSize,
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
      },
    );
  }
}
