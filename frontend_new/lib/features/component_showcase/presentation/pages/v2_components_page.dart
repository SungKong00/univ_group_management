import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/responsive_tokens.dart';
// import '../../../../core/theme/pricing_tokens.dart'; // DEPRECATED: JSON-based tokens removed
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/app_back_button.dart';

/// V2 Components Showcase Page - Pricing & Customers
///
/// ⚠️ DEPRECATED: This page depends on JSON-based PricingTokens which has been removed.
/// This page is kept for reference but will not compile without PricingTokens.
class V2ComponentsPage extends StatefulWidget {
  const V2ComponentsPage({super.key});

  @override
  State<V2ComponentsPage> createState() => _V2ComponentsPageState();
}

class _V2ComponentsPageState extends State<V2ComponentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    return Scaffold(
      backgroundColor: colorExt.surfacePrimary,
      appBar: AppBar(
        backgroundColor: colorExt.surfaceSecondary,
        elevation: 0,
        leading: AppBackButton(onPressed: () => context.go('/component')),
        title: const Text('V2 Components'),
      ),
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Tab Bar
          _buildTabBar(),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPricingTab(), _buildCustomersTab()],
            ),
          ),
        ],
      ),
    );
  }

  /// Header
  Widget _buildHeader() {
    final colorExt = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
      decoration: BoxDecoration(
        color: colorExt.surfaceSecondary,
        border: Border(bottom: BorderSide(color: colorExt.borderPrimary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'V2 Components',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: colorExt.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pricing & Customers 페이지 컴포넌트 (JSON 기반)',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: colorExt.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Tab Bar
  Widget _buildTabBar() {
    final colorExt = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colorExt.surfaceSecondary,
        border: Border(bottom: BorderSide(color: colorExt.borderPrimary)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colorExt.textPrimary,
        unselectedLabelColor: colorExt.textTertiary,
        indicatorColor: colorExt.brandSecondary,
        labelStyle: Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Pricing'),
          Tab(text: 'Customers'),
        ],
      ),
    );
  }

  /// Pricing Tab
  Widget _buildPricingTab() {
    return ResponsiveBuilder(
      builder: (context, screenSize, width) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Deprecation Notice
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceSecondary,
                  border: Border.all(color: context.appColors.borderPrimary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ This page is deprecated',
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: context.appColors.stateErrorBg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PricingTokens and JSON-based token system has been removed from the codebase.\n\n'
                      'This page depends on:\n'
                      '• PricingTokens (pricing_tokens.dart)\n'
                      '• CustomersTokens (pricing_tokens.dart)\n'
                      '• PricingCard, BillingToggle, PricingComparisonTable widgets\n'
                      '• CustomerCard, CustomerFilterTabs, CustomerLogoGrid widgets\n\n'
                      'These components relied on JSON data loading which has been deprecated\n'
                      'in favor of hardcoded design tokens.',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: context.appColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Customers Tab
  Widget _buildCustomersTab() {
    return ResponsiveBuilder(
      builder: (context, screenSize, width) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.appColors.surfaceSecondary,
                border: Border.all(color: context.appColors.borderPrimary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ This tab is deprecated',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: context.appColors.stateErrorBg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CustomersTokens has been removed along with the JSON-based token system.',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: context.appColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
