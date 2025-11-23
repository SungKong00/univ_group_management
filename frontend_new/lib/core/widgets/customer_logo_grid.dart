import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';
import '../../features/component_showcase/data/models/customer_company_model.dart';

/// Customer Logo Grid - 필터링 가능한 로고 그리드
class CustomerLogoGrid extends StatelessWidget {
  final List<CustomerCompany> companies;
  final String? selectedFilter;
  final Function(CustomerCompany)? onCompanyTap;

  const CustomerLogoGrid({
    super.key,
    required this.companies,
    this.selectedFilter,
    this.onCompanyTap,
  });

  @override
  Widget build(BuildContext context) {
    // Filter companies
    final filteredCompanies = _filterCompanies();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive columns
        final width = constraints.maxWidth;
        final crossAxisCount = _getCrossAxisCount(width);
        final gap = ResponsiveTokens.cardGap(width);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: 1.1,
          ),
          itemCount: filteredCompanies.length,
          itemBuilder: (context, index) {
            return _buildCompanyCard(filteredCompanies[index]);
          },
        );
      },
    );
  }

  /// Filter companies by selected category
  List<CustomerCompany> _filterCompanies() {
    if (selectedFilter == null || selectedFilter == 'featured') {
      return companies;
    }

    return companies.where((company) {
      return company.categories.any(
        (cat) => cat.toLowerCase() == selectedFilter!.toLowerCase(),
      );
    }).toList();
  }

  /// Responsive column count
  int _getCrossAxisCount(double width) {
    if (width >= 1024) return 4; // lg, xl
    if (width >= 768) return 3; // md
    return 2; // xs, sm (Mobile)
  }

  /// Company Card
  Widget _buildCompanyCard(CustomerCompany company) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colorExt = context.appColors;
        final textTheme = Theme.of(context).textTheme;
        final width = MediaQuery.sizeOf(context).width;

        return GestureDetector(
          onTap: () => onCompanyTap?.call(company),
          child: Container(
            decoration: BoxDecoration(
              color: colorExt.surfaceSecondary,
              border: Border.all(color: colorExt.borderPrimary),
              borderRadius: BorderTokens.xlRadius(),
            ),
            padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo Placeholder
                Container(
                  width: ComponentSizeTokens.avatarLarge,
                  height: ComponentSizeTokens.avatarLarge,
                  decoration: BoxDecoration(
                    color: colorExt.surfaceTertiary,
                    borderRadius: BorderTokens.largeRadius(),
                  ),
                  child: Center(
                    child: Text(
                      company.name.isNotEmpty
                          ? company.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: textTheme.headlineMedium!.copyWith(
                        color: colorExt.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Company Name
                Text(
                  company.name,
                  style: textTheme.bodyMedium!.copyWith(
                    color: colorExt.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Categories
                if (company.categories.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: company.categories.take(2).map((cat) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorExt.surfaceTertiary,
                          borderRadius: BorderTokens.smallRadius(),
                        ),
                        child: Text(
                          cat,
                          style: textTheme.labelSmall!.copyWith(
                            color: colorExt.textTertiary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                // CTA
                Row(
                  children: [
                    Text(
                      company.ctaText,
                      style: textTheme.bodySmall!.copyWith(
                        color: colorExt.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Icon(
                      company.isExternal
                          ? Icons.open_in_new
                          : Icons.arrow_forward,
                      size: ComponentSizeTokens.badgeMedium,
                      color: colorExt.brandPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
