import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/responsive_tokens.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/pricing_card.dart';
import '../../../../core/widgets/billing_toggle.dart';
import '../../../../core/widgets/pricing_comparison_table.dart';
import '../../../../core/widgets/customer_card.dart';
import '../../../../core/widgets/customer_filter_tabs.dart';
import '../../../../core/widgets/customer_logo_grid.dart';
import '../../../../core/widgets/adaptive_card_grid.dart';
import '../../../../core/widgets/vertical_card.dart';
import '../../../../core/widgets/horizontal_card.dart';
import '../../../../core/widgets/compact_card.dart';
import '../../../../core/widgets/selectable_card.dart';
import '../../../../core/widgets/wide_card.dart';
import '../../data/models/pricing_plan_model.dart';
import '../../data/models/billing_cycle_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/customer_company_model.dart';
import '../../data/models/filter_tab_model.dart';
import '../../data/models/feature_model.dart';
import '../../data/models/cta_model.dart';

/// V2 Components Showcase Page - Pricing & Customers
///
/// Displays migrated components from JSON-based to type-safe model system.
class V2ComponentsPage extends StatefulWidget {
  const V2ComponentsPage({super.key});

  @override
  State<V2ComponentsPage> createState() => _V2ComponentsPageState();
}

class _V2ComponentsPageState extends State<V2ComponentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isYearly = false;
  String _selectedCustomerFilter = 'all';
  List<bool> _selectedCards = List.filled(3, false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
              children: [
                _buildPricingTab(),
                _buildCustomersTab(),
                _buildCardsTab(),
              ],
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
          Tab(text: 'Design Cards'),
        ],
      ),
    );
  }

  /// Pricing Tab
  Widget _buildPricingTab() {
    return ResponsiveBuilder(
      builder: (context, screenSize, width) {
        // Sample pricing plans data
        final pricingPlans = [
          PricingPlan(
            tier: 'Starter',
            price: '29',
            priceFormat: '/month',
            features: [
              const Feature(text: 'Up to 10 projects', enabled: true),
              const Feature(text: '5GB storage', enabled: true),
              const Feature(text: 'Basic support', enabled: true),
              const Feature(text: 'API access', enabled: false),
            ],
            ctas: [CTA(text: 'Get Started', variant: 'primary')],
          ),
          PricingPlan(
            tier: 'Professional',
            price: '99',
            priceFormat: '/month',
            features: [
              const Feature(text: 'Unlimited projects', enabled: true),
              const Feature(text: '100GB storage', enabled: true),
              const Feature(text: 'Priority support', enabled: true),
              const Feature(text: 'API access', enabled: true),
            ],
            ctas: [CTA(text: 'Try Free', variant: 'secondary')],
          ),
          PricingPlan(
            tier: 'Enterprise',
            price: '299',
            priceFormat: '/month',
            features: [
              const Feature(text: 'Unlimited everything', enabled: true),
              const Feature(text: '1TB storage', enabled: true),
              const Feature(text: '24/7 support', enabled: true),
              const Feature(text: 'Advanced API', enabled: true),
            ],
            ctas: [CTA(text: 'Contact Sales', variant: 'primary')],
          ),
        ];

        final billingCycle = const BillingCycle(
          monthlyLabel: 'Monthly',
          yearlyLabel: 'Yearly',
        );

        return SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pricing Plans',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose a plan that fits your needs',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveTokens.cardGap(width) * 1.5),

              // Billing Toggle
              Center(
                child: BillingToggle(
                  cycle: billingCycle,
                  isYearly: _isYearly,
                  onChanged: (isYearly) {
                    setState(() => _isYearly = isYearly);
                  },
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width)),

              // Pricing Cards - Responsive Grid
              // Material Design 3: maxItemWidth 기준으로 자동 열 계산
              AdaptiveCardGrid(
                itemCount: pricingPlans.length,
                itemBuilder: (context, index) =>
                    PricingCard(plan: pricingPlans[index]),
                minItemWidth: 280,
                maxItemWidth: 420,
                maxColumns: 3,
                preferredItemWidth: 320,
                aspectRatio: const ResponsiveValue<double>(
                  mobile: 3 / 4,
                  tablet: 4 / 5,
                  desktop: 4 / 5,
                ),
                maxContentWidth: ResponsiveTokens.maxContentWidth,
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 2),

              // Comparison Table Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feature Comparison',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Compare features across all plans',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveTokens.cardGap(width)),
              PricingComparisonTable(
                data: {
                  'columns': 3,
                  'columnHeaders': [
                    {'text': 'Starter'},
                    {'text': 'Professional'},
                    {'text': 'Enterprise'},
                  ],
                  'sections': [
                    {
                      'name': 'Resources',
                      'rows': [
                        {
                          'feature': 'Projects',
                          'cells': ['✓', '✓', '✓'],
                        },
                        {
                          'feature': 'Storage',
                          'cells': ['5GB', '100GB', '1TB'],
                        },
                      ],
                    },
                    {
                      'name': 'Support',
                      'rows': [
                        {
                          'feature': 'Support',
                          'cells': ['Basic', 'Priority', '24/7'],
                        },
                      ],
                    },
                  ],
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Design Cards Tab
  Widget _buildCardsTab() {
    return ResponsiveBuilder(
      builder: (context, screenSize, width) {
        final colorExt = context.appColors;

        return SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Design System Cards',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: colorExt.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '5가지 카드 유형 및 변형 스타일 (standard, featured, highlighted)',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: colorExt.textSecondary,
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width)),

              // 1. Vertical Card Section
              _buildSectionHeader('1. Vertical Card', 'Image(top) → Title → Description'),
              SizedBox(height: ResponsiveTokens.cardGap(width)),
              AdaptiveCardGrid(
                itemCount: 3,
                itemBuilder: (context, index) {
                  final variants = ['standard', 'featured', 'highlighted'];
                  return VerticalCard(
                    title: 'Vertical Card ${variants[index]}',
                    subtitle: 'Subtitle text here',
                    description: 'This is a vertical card with image on top and text below.',
                    meta: 'Meta info',
                    image: Container(
                      color: colorExt.surfaceTertiary,
                      child: Center(
                        child: Icon(Icons.image, color: colorExt.textTertiary, size: 48),
                      ),
                    ),
                    variant: variants[index],
                  );
                },
                minItemWidth: 240,
                maxItemWidth: 320,
                maxColumns: 3,
                preferredItemWidth: 280,
                aspectRatio: const ResponsiveValue<double>(
                  mobile: 3 / 4,
                  tablet: 3 / 4,
                  desktop: 3 / 4,
                ),
                maxContentWidth: ResponsiveTokens.maxContentWidth,
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 1.5),

              // 2. Horizontal Card Section
              _buildSectionHeader('2. Horizontal Card', 'Image(left) → Text(right)'),
              SizedBox(height: ResponsiveTokens.cardGap(width)),
              AdaptiveCardGrid(
                itemCount: 3,
                itemBuilder: (context, index) {
                  final variants = ['standard', 'featured', 'highlighted'];
                  return HorizontalCard(
                    title: 'Horizontal ${variants[index]}',
                    subtitle: 'Subtitle',
                    description: 'A horizontal layout with image on the left.',
                    meta: 'Info',
                    image: Container(
                      color: colorExt.surfaceTertiary,
                      child: Center(
                        child: Icon(Icons.image, color: colorExt.textTertiary, size: 48),
                      ),
                    ),
                    variant: variants[index],
                  );
                },
                minItemWidth: 320,
                maxItemWidth: 500,
                maxColumns: 2,
                preferredItemWidth: 400,
                aspectRatio: const ResponsiveValue<double>(
                  mobile: 4 / 3,
                  tablet: 4 / 3,
                  desktop: 4 / 3,
                ),
                maxContentWidth: ResponsiveTokens.maxContentWidth,
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 1.5),

              // 3. Compact Card Section
              _buildSectionHeader('3. Compact Card', 'Icon + Title (자동 높이)'),
              SizedBox(height: ResponsiveTokens.cardGap(width)),
              AdaptiveCardGrid(
                itemCount: 6,
                itemBuilder: (context, index) {
                  final variants = ['standard', 'featured', 'highlighted'];
                  final variant = variants[index % 3];
                  return CompactCard(
                    title: variant == 'standard'
                        ? '항목 ${index ~/ 3 + 1}'
                        : '${variant.substring(0, 1).toUpperCase()}${variant.substring(1)}',
                    meta: 'Meta',
                    icon: Icons.category,
                    variant: variant,
                    isSelected: _selectedCards[index % 3],
                    onTap: () {
                      setState(() {
                        _selectedCards[index % 3] = !_selectedCards[index % 3];
                      });
                    },
                  );
                },
                minItemWidth: 100,
                maxItemWidth: 160,
                maxColumns: 6,
                preferredItemWidth: 120,
                enforceAspectRatio: false,
                maxContentWidth: ResponsiveTokens.maxContentWidth,
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 1.5),

              // 4. Selectable Card Section
              _buildSectionHeader('4. Selectable Card', 'Checkbox + Content (다중선택)'),
              SizedBox(height: ResponsiveTokens.cardGap(width)),
              Column(
                children: List.generate(3, (index) {
                  final variants = ['standard', 'featured', 'highlighted'];
                  return Padding(
                    padding: EdgeInsets.only(bottom: ResponsiveTokens.cardGap(width)),
                    child: SelectableCard(
                      title: 'Option ${index + 1} (${variants[index]})',
                      subtitle: 'Select to enable this feature',
                      isSelected: _selectedCards[index],
                      onSelected: (value) {
                        setState(() {
                          _selectedCards[index] = value;
                        });
                      },
                      variant: variants[index],
                    ),
                  );
                }),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 1.5),

              // 5. Wide Card Section
              _buildSectionHeader('5. Wide Card', 'Full-width Banner (배너/프로모션)'),
              SizedBox(height: ResponsiveTokens.cardGap(width)),
              Column(
                children: [
                  WideCard(
                    title: 'Standard Wide Card',
                    subtitle: 'Full-width banner layout',
                    description: 'This is a promotional banner with CTA button',
                    ctaText: 'Learn More',
                    variant: 'standard',
                    onCtaPressed: () {},
                    backgroundContent: Container(
                      color: context.appColors.surfaceTertiary,
                      child: Center(
                        child: Icon(Icons.image, color: colorExt.textTertiary, size: 64),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveTokens.cardGap(width)),
                  WideCard(
                    title: 'Featured Promotion',
                    subtitle: 'Special offer',
                    description: 'Get started with our premium features today',
                    ctaText: 'Get Started',
                    variant: 'featured',
                    onCtaPressed: () {},
                    backgroundContent: Container(
                      color: context.appColors.brandSecondary.withValues(alpha: 0.2),
                      child: Center(
                        child: Icon(Icons.star, color: colorExt.brandPrimary, size: 64),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width)),
            ],
          ),
        );
      },
    );
  }

  /// Helper: Section Header
  Widget _buildSectionHeader(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Customers Tab
  Widget _buildCustomersTab() {
    return ResponsiveBuilder(
      builder: (context, screenSize, width) {
        // Sample filter tabs
        final filterTabs = [
          const FilterTab(label: 'All', filter: 'all'),
          const FilterTab(label: 'Enterprise', filter: 'enterprise'),
          const FilterTab(label: 'Startup', filter: 'startup'),
          const FilterTab(label: 'Tech', filter: 'tech'),
        ];

        // Sample customers data
        final customers = [
          const Customer(
            company: 'Acme Corp',
            title: 'Enterprise Customer',
            hasImage: true,
            ctaText: 'Learn More',
          ),
          const Customer(
            company: 'StartupHub',
            title: 'Early Adopter',
            hasImage: true,
            ctaText: 'Explore',
          ),
          const Customer(
            company: 'CloudNext',
            title: 'Strategic Partner',
            hasImage: true,
            ctaText: 'Connect',
          ),
          const Customer(
            company: 'FastGrow Inc',
            title: 'Growth Customer',
            hasImage: false,
            ctaText: 'Inquire',
          ),
        ];

        final logoCompanies = [
          const CustomerCompany(
            name: 'Company A',
            categories: ['Enterprise'],
            ctaText: '',
            isExternal: false,
          ),
          const CustomerCompany(
            name: 'Company B',
            categories: ['Tech'],
            ctaText: '',
            isExternal: false,
          ),
          const CustomerCompany(
            name: 'Company C',
            categories: ['Startup'],
            ctaText: '',
            isExternal: false,
          ),
          const CustomerCompany(
            name: 'Company D',
            categories: ['Enterprise'],
            ctaText: '',
            isExternal: false,
          ),
          const CustomerCompany(
            name: 'Company E',
            categories: ['Tech'],
            ctaText: '',
            isExternal: false,
          ),
          const CustomerCompany(
            name: 'Company F',
            categories: ['Startup'],
            ctaText: '',
            isExternal: false,
          ),
        ];

        return SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Tabs
              CustomerFilterTabs(
                tabs: filterTabs,
                selectedTab: _selectedCustomerFilter,
                onTabSelected: (filter) {
                  setState(() => _selectedCustomerFilter = filter);
                },
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 2),

              // Customer Cards - Horizontal Scroll (Carousel Pattern)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Featured Customers',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Trusted by companies worldwide',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveTokens.cardGap(width)),
              // Featured Customers - Responsive Grid
              // Material Design 3: maxItemWidth 기준으로 자동 열 계산
              AdaptiveCardGrid(
                itemCount: customers.length,
                itemBuilder: (context, index) =>
                    CustomerCard(customer: customers[index]),
                minItemWidth: 240,
                maxItemWidth: 380,
                maxColumns: 4,
                preferredItemWidth: 225,
                aspectRatio: const ResponsiveValue<double>(
                  mobile: 3 / 4,
                  tablet: 4 / 5,
                  desktop: 4 / 5,
                ),
                maxContentWidth: ResponsiveTokens.maxContentWidth,
                scrollOnOverflow: true,
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 2),

              // Logo Grid Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partner Companies',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Our trusted technology partners',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveTokens.cardGap(width)),
              CustomerLogoGrid(companies: logoCompanies),
            ],
          ),
        );
      },
    );
  }
}
