import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/responsive_tokens.dart';

/// Customer Logo Grid - 필터링 가능한 로고 그리드
class CustomerLogoGrid extends StatelessWidget {
  final List<Map<String, dynamic>> companies;
  final String? selectedFilter;
  final Function(Map<String, dynamic>)? onCompanyTap;

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
            childAspectRatio: 1.2,
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
  List<Map<String, dynamic>> _filterCompanies() {
    if (selectedFilter == null || selectedFilter == 'featured') {
      return companies;
    }

    return companies.where((company) {
      final categories = (company['categories'] as List?)?.cast<String>() ?? [];
      return categories.any(
        (cat) => cat.toLowerCase() == selectedFilter!.toLowerCase(),
      );
    }).toList();
  }

  /// Responsive column count
  int _getCrossAxisCount(double width) {
    if (ResponsiveTokens.isDesktop(width)) return 4;
    if (ResponsiveTokens.isTablet(width)) return 3;
    return 2; // Mobile
  }

  /// Company Card
  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final name = company['name'] as String? ?? '';
    final categories = (company['categories'] as List?)?.cast<String>() ?? [];
    final cta = company['cta'] as Map<String, dynamic>?;
    final ctaText = cta?['text'] as String? ?? 'Visit site';
    final isExternal = cta?['external'] as bool? ?? false;

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
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo Placeholder
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: colorExt.surfaceTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty
                          ? name.substring(0, 1).toUpperCase()
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
                  name,
                  style: textTheme.bodyMedium!.copyWith(
                    color: colorExt.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Categories
                if (categories.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: categories.take(2).map((cat) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorExt.surfaceTertiary,
                          borderRadius: BorderRadius.circular(4),
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
                      ctaText,
                      style: textTheme.bodySmall!.copyWith(
                        color: colorExt.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Icon(
                      isExternal ? Icons.open_in_new : Icons.arrow_forward,
                      size: 14,
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
