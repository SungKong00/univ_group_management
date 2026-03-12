import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/responsive_tokens.dart';
import '../../../../core/theme/enums.dart';
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
import '../../../../core/widgets/app_tabs.dart';
import '../../../../core/widgets/controlled_app_tabs.dart';
import '../../../../core/widgets/app_section.dart';
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
///
/// ## AdaptiveCardGrid 사용법 (권장)
///
/// ```dart
/// // ✅ fromCardType (권장 - 반응형 자동)
/// AdaptiveCardGrid.fromCardType(
///   cardType: CardVariant.vertical,  // vertical, horizontal, compact
///   columns: GridPresetColumns.three, // one, two, three, four, five, six
///   itemCount: items.length,
///   itemBuilder: (context, index) => VerticalCard(...),
/// )
///
/// // Breakpoint별 열 수 자동 조정:
/// // XS: 1열, SM: 2열, MD/LG/XL: 3열
/// ```
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
  final List<bool> _selectedCards = List.filled(3, false);
  GridPresetColumns _selectedPreset = GridPresetColumns.three;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
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
            child: IndexedStack(
              index: _tabController.index,
              children: [
                _buildPricingTab(),
                _buildCustomersTab(),
                _buildCardsTab(),
                _buildGridPresetsTab(),
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
          SizedBox(height: ResponsiveTokens.space8),
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
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveTokens.pagePadding(
          MediaQuery.sizeOf(context).width,
        ),
      ),
      child: ControlledAppTabs(
        controller: _tabController,
        tabs: const [
          AppTabItem(label: 'Pricing'),
          AppTabItem(label: 'Customers'),
          AppTabItem(label: 'Design Cards'),
          AppTabItem(label: 'Grid Presets'),
        ],
        indicatorHeight: 2.0,
        animationCurve: Curves.easeInOutQuart,
        animationDuration: const Duration(milliseconds: 350),
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
              AppSection(
                title: 'Pricing Plans',
                variant: SectionVariant.standard,
                child: Column(
                  children: [
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

                    // Pricing Cards - 3열 그리드 (권장 방식)
                    AdaptiveCardGrid.fromCardType(
                      cardType: CardVariant.vertical,
                      columns: GridPresetColumns.three,
                      itemCount: pricingPlans.length,
                      itemBuilder: (context, index) =>
                          PricingCard(plan: pricingPlans[index]),
                      maxContentWidth: ResponsiveTokens.maxContentWidth,
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 2),

              // Comparison Table Section
              AppSection(
                title: 'Feature Comparison',
                variant: SectionVariant.standard,
                child: PricingComparisonTable(
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
              AppSection(
                title: 'Design System Cards',
                variant: SectionVariant.standard,
                child: const SizedBox.shrink(),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width)),

              // 1. Vertical Card Section
              AppSection(
                title: '1. Vertical Card',
                variant: SectionVariant.standard,
                child: AdaptiveCardGrid.fromCardType(
                  cardType: CardVariant.vertical,
                  columns: GridPresetColumns.three,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final variants = ['standard', 'featured', 'highlighted'];
                    return VerticalCard(
                      title: 'Vertical Card ${variants[index]}',
                      subtitle: 'Subtitle text here',
                      description:
                          'This is a vertical card with image on top and text below.',
                      meta: 'Meta info',
                      image: Container(
                        color: colorExt.surfaceTertiary,
                        child: Center(
                          child: Icon(
                            Icons.image,
                            color: colorExt.textTertiary,
                            size: 48,
                          ),
                        ),
                      ),
                      variant: variants[index],
                    );
                  },
                  maxContentWidth: ResponsiveTokens.maxContentWidth,
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 1.5),

              // 2. Horizontal Card Section
              AppSection(
                title: '2. Horizontal Card',
                variant: SectionVariant.standard,
                child: AdaptiveCardGrid.fromCardType(
                  cardType: CardVariant.horizontal,
                  columns: GridPresetColumns.two,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final variants = ['standard', 'featured', 'highlighted'];
                    return HorizontalCard(
                      title: 'Horizontal ${variants[index]}',
                      subtitle: 'Subtitle',
                      description:
                          'A horizontal layout with image on the left.',
                      meta: 'Info',
                      image: Container(
                        color: colorExt.surfaceTertiary,
                        child: Center(
                          child: Icon(
                            Icons.image,
                            color: colorExt.textTertiary,
                            size: 48,
                          ),
                        ),
                      ),
                      variant: variants[index],
                    );
                  },
                  maxContentWidth: ResponsiveTokens.maxContentWidth,
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 1.5),

              // 3. Compact Card Section
              AppSection(
                title: '3. Compact Card',
                variant: SectionVariant.standard,
                child: AdaptiveCardGrid.fromCardType(
                  cardType: CardVariant.compact,
                  columns: GridPresetColumns.six,
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
                          _selectedCards[index % 3] =
                              !_selectedCards[index % 3];
                        });
                      },
                    );
                  },
                  maxContentWidth: ResponsiveTokens.maxContentWidth,
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 1.5),

              // 4. Selectable Card Section
              AppSection(
                title: '4. Selectable Card',
                variant: SectionVariant.standard,
                child: Column(
                  children: List.generate(3, (index) {
                    final variants = ['standard', 'featured', 'highlighted'];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: ResponsiveTokens.cardGap(width),
                      ),
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
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 1.5),

              // 5. Wide Card Section
              AppSection(
                title: '5. Wide Card',
                variant: SectionVariant.standard,
                child: Column(
                  children: [
                    WideCard(
                      title: 'Standard Wide Card',
                      subtitle: 'Full-width banner layout',
                      description:
                          'This is a promotional banner with CTA button',
                      ctaText: 'Learn More',
                      variant: 'standard',
                      onCtaPressed: () {},
                      backgroundContent: Container(
                        color: context.appColors.surfaceTertiary,
                        child: Center(
                          child: Icon(
                            Icons.image,
                            color: colorExt.textTertiary,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveTokens.cardGap(width)),
                    WideCard(
                      title: 'Featured Promotion',
                      subtitle: 'Special offer',
                      description:
                          'Get started with our premium features today',
                      ctaText: 'Get Started',
                      variant: 'featured',
                      onCtaPressed: () {},
                      backgroundContent: Container(
                        color: context.appColors.brandSecondary.withValues(
                          alpha: 0.2,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.star,
                            color: colorExt.brandPrimary,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width)),
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

              // Customer Cards - 4열 그리드
              AppSection(
                title: 'Featured Customers',
                variant: SectionVariant.standard,
                child: AdaptiveCardGrid.fromCardType(
                  cardType: CardVariant.vertical,
                  columns: GridPresetColumns.four,
                  itemCount: customers.length,
                  itemBuilder: (context, index) =>
                      CustomerCard(customer: customers[index]),
                  maxContentWidth: ResponsiveTokens.maxContentWidth,
                  scrollOnOverflow: true,
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 2),

              // Logo Grid Section
              AppSection(
                title: 'Partner Companies',
                variant: SectionVariant.standard,
                child: CustomerLogoGrid(companies: logoCompanies),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Grid Presets Showcase Tab
  Widget _buildGridPresetsTab() {
    return ResponsiveBuilder(
      builder: (context, screenSize, width) {
        final colorExt = context.appColors;
        final pagePadding = ResponsiveTokens.pagePadding(width);

        return SingleChildScrollView(
          padding: EdgeInsets.all(pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Grid Layout Presets',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: colorExt.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: ResponsiveTokens.space12),
              Text(
                '프리셋 선택으로 2~6열 레이아웃을 간편하게 테스트하세요',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: colorExt.textSecondary),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width)),

              // Preset Selector
              Container(
                decoration: BoxDecoration(
                  color: colorExt.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorExt.borderPrimary),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveTokens.space16,
                  vertical: ResponsiveTokens.space12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '프리셋 선택',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: colorExt.textSecondary,
                      ),
                    ),
                    SizedBox(height: ResponsiveTokens.space12),
                    Wrap(
                      spacing: ResponsiveTokens.space8,
                      children: GridPresetColumns.values.map((preset) {
                        final isSelected = _selectedPreset == preset;
                        return FilterChip(
                          label: Text(
                            preset.name.toUpperCase(),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedPreset = preset);
                          },
                          backgroundColor: colorExt.surfacePrimary,
                          selectedColor: colorExt.brandPrimary.withValues(
                            alpha: 0.2,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? colorExt.brandPrimary
                                : colorExt.borderPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width)),

              // Preset Info
              Container(
                decoration: BoxDecoration(
                  color: colorExt.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(ResponsiveTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '선택된 프리셋: ${_selectedPreset.name}',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: colorExt.brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveTokens.space12),
                    _buildPresetInfo(context, colorExt),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width)),

              // Demo Grid - Vertical Cards
              AppSection(
                title: '1. Vertical Cards',
                variant: SectionVariant.standard,
                child: AdaptiveCardGrid.fromCardType(
                  cardType: CardVariant.vertical,
                  columns: _selectedPreset,
                  itemCount: (_selectedPreset.index + 1) * 2,
                  itemBuilder: (context, index) {
                    return VerticalCard(
                      title: '카드 ${index + 1}',
                      subtitle: 'Demo Card',
                      description: '프리셋으로 생성된 그리드 예제입니다',
                      meta: '#${_selectedPreset.name}',
                      image: Container(
                        color: colorExt.surfaceTertiary,
                        child: Center(
                          child: Icon(
                            Icons.image,
                            color: colorExt.textTertiary,
                            size: 48,
                          ),
                        ),
                      ),
                      variant: 'standard',
                    );
                  },
                  maxContentWidth: ResponsiveTokens.maxContentWidth,
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 1.5),

              // Demo Grid - Horizontal Cards
              AppSection(
                title: '2. Horizontal Cards',
                variant: SectionVariant.standard,
                child: AdaptiveCardGrid.fromCardType(
                  cardType: CardVariant.horizontal,
                  columns: _selectedPreset,
                  itemCount: (_selectedPreset.index + 1) * 2,
                  itemBuilder: (context, index) {
                    return HorizontalCard(
                      title: '카드 ${index + 1}',
                      subtitle: 'Demo Card',
                      description: '프리셋으로 생성된 가로 카드 예제입니다',
                      meta: '#${_selectedPreset.name}',
                      image: Container(
                        color: colorExt.surfaceTertiary,
                        child: Center(
                          child: Icon(
                            Icons.image,
                            color: colorExt.textTertiary,
                            size: 48,
                          ),
                        ),
                      ),
                      variant: 'standard',
                    );
                  },
                  maxContentWidth: ResponsiveTokens.maxContentWidth,
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width) * 1.5),

              // Demo Grid - Compact Cards
              AppSection(
                title: '3. Compact Cards',
                variant: SectionVariant.standard,
                child: AdaptiveCardGrid.fromCardType(
                  cardType: CardVariant.compact,
                  columns: _selectedPreset,
                  itemCount: (_selectedPreset.index + 1) * 2,
                  itemBuilder: (context, index) {
                    return CompactCard(
                      title: '항목 ${index + 1}',
                      meta: 'Meta',
                      icon: Icons.category,
                      variant: 'standard',
                      isSelected: false,
                      onTap: () {},
                    );
                  },
                  maxContentWidth: ResponsiveTokens.maxContentWidth,
                ),
              ),
              SizedBox(height: ResponsiveTokens.pagePadding(width)),
            ],
          ),
        );
      },
    );
  }

  /// Helper: Display preset info
  Widget _buildPresetInfo(BuildContext context, dynamic colorExt) {
    final presetName = _selectedPreset.name;
    final columnCount = _selectedPreset.index + 1;

    final descriptions = {
      'one': '1열 레이아웃 (모바일, 리스트 전용)',
      'two': '2열 레이아웃 (추천사, 2단 카드)',
      'three': '3열 레이아웃 (가격, 기능, 세로 카드)',
      'four': '4열 레이아웃 (고객 로고, 소형 항목)',
      'five': '5열 레이아웃 (아이콘 그리드, 콤팩트 항목)',
      'six': '6열 레이아웃 (태그, 배지, 미니 카드)',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          descriptions[presetName] ?? '',
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: colorExt.textPrimary),
        ),
        SizedBox(height: ResponsiveTokens.space12),
        Container(
          decoration: BoxDecoration(
            color: colorExt.surfacePrimary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colorExt.borderPrimary),
          ),
          padding: EdgeInsets.all(ResponsiveTokens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(context, colorExt, '최대 열 수:', '$columnCount'),
              _buildInfoRow(
                context,
                colorExt,
                '아이템 카운트:',
                '${_selectedPreset.index + 3}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Helper: Info row
  Widget _buildInfoRow(
    BuildContext context,
    dynamic colorExt,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall!.copyWith(color: colorExt.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: colorExt.brandPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
