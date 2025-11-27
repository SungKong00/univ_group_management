import 'package:flutter/material.dart';
import '../../../../core/theme/responsive_tokens.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/extensions/app_spacing_extension.dart';
import '../../../../core/theme/enums.dart';
import '../../../../core/widgets/app_carousel.dart';
import '../../../../core/widgets/app_tabs.dart';
import '../../../../core/widgets/app_definition_list.dart';
import '../../../../core/widgets/app_agent_selector.dart';
import '../../../../core/widgets/app_gradient_overlay.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feature_card.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_section.dart';

/// 고급 컴포넌트 쇼케이스 (Carousel, Tabs, Lists 등)
class AdvancedComponentsPage extends StatefulWidget {
  const AdvancedComponentsPage({super.key});

  @override
  State<AdvancedComponentsPage> createState() => _AdvancedComponentsPageState();
}

class _AdvancedComponentsPageState extends State<AdvancedComponentsPage> {
  int _selectedTabIndex = 0;
  int? _selectedAgentIndex;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacing = context.appSpacing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('고급 컴포넌트 쇼케이스'),
        backgroundColor: colorExt.surfaceSecondary,
        elevation: 0,
        leading: AppBackButton(),
      ),
      body: ResponsiveBuilder(
        builder: (context, screenSize, width) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carousel 섹션
                AppSection(
                  title: 'Carousel (수평 스크롤)',
                  variant: SectionVariant.standard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '아이템 개수별 샘플',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: spacing.large),
                      _buildSubtitle('3개 아이템 (네비게이션 없음)'),
                      SizedBox(height: spacing.medium),
                      AppCarousel(
                        items: _buildCarouselItems(3),
                        itemWidth: 280,
                        showNavigation: false,
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('7개 아이템 (네비게이션 있음)'),
                      SizedBox(height: spacing.medium),
                      AppCarousel(
                        items: _buildCarouselItems(7),
                        itemWidth: 280,
                        showNavigation: true,
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('12개 아이템 (gap 조절)'),
                      SizedBox(height: spacing.medium),
                      AppCarousel(
                        items: _buildCarouselItems(12),
                        itemWidth: 250,
                        gap: 24,
                        showNavigation: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.xxxl),

                // Tabs 섹션
                AppSection(
                  title: 'Content Tabs',
                  variant: SectionVariant.standard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '애니메이션 커브별 비교 - 여러 탭을 건너뛰어서 확인해보세요',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: spacing.large),
                      _buildSubtitle('2개 탭 (기본 - easeInOut)'),
                      SizedBox(height: spacing.medium),
                      AppTabs(
                        tabs: const [
                          AppTabItem(label: '개요'),
                          AppTabItem(label: '상세'),
                        ],
                        animationCurve: Curves.easeInOut,
                        onTabChanged: (index) {
                          debugPrint('Tab changed: $index');
                        },
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('3개 탭 - easeOutCubic (더 자연스러운 감속)'),
                      SizedBox(height: spacing.medium),
                      AppTabs(
                        tabs: const [
                          AppTabItem(label: 'Collaborative documents'),
                          AppTabItem(label: 'Inline comments'),
                          AppTabItem(label: 'Text-to-issue commands'),
                        ],
                        initialIndex: _selectedTabIndex,
                        indicatorHeight: 2.0,
                        animationCurve: Curves.easeOutCubic,
                        animationDuration: const Duration(milliseconds: 300),
                        onTabChanged: (index) {
                          setState(() => _selectedTabIndex = index);
                        },
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('3개 탭 - easeInOutQuart (부드럽고 우아한)'),
                      SizedBox(height: spacing.medium),
                      AppTabs(
                        tabs: const [
                          AppTabItem(label: 'Collaborative documents'),
                          AppTabItem(label: 'Inline comments'),
                          AppTabItem(label: 'Text-to-issue commands'),
                        ],
                        indicatorHeight: 2.5,
                        animationCurve: Curves.easeInOutQuart,
                        animationDuration: const Duration(milliseconds: 350),
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle(
                        '3개 탭 - fastOutSlowIn (Material Design 스타일)',
                      ),
                      SizedBox(height: spacing.medium),
                      AppTabs(
                        tabs: const [
                          AppTabItem(label: 'Collaborative documents'),
                          AppTabItem(label: 'Inline comments'),
                          AppTabItem(label: 'Text-to-issue commands'),
                        ],
                        indicatorHeight: 2.0,
                        animationCurve: Curves.fastOutSlowIn,
                        animationDuration: const Duration(milliseconds: 300),
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('5개 탭 - easeOutExpo (급격한 감속)'),
                      SizedBox(height: spacing.medium),
                      AppTabs(
                        tabs: const [
                          AppTabItem(label: '전체'),
                          AppTabItem(label: '진행중'),
                          AppTabItem(label: '완료'),
                          AppTabItem(label: '보류'),
                          AppTabItem(label: '취소'),
                        ],
                        animationCurve: Curves.easeOutExpo,
                        animationDuration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('5개 탭 - elasticOut (탄성 효과 - 약간 튕김)'),
                      SizedBox(height: spacing.medium),
                      AppTabs(
                        tabs: const [
                          AppTabItem(label: '전체'),
                          AppTabItem(label: '진행중'),
                          AppTabItem(label: '완료'),
                          AppTabItem(label: '보류'),
                          AppTabItem(label: '취소'),
                        ],
                        animationCurve: Curves.elasticOut,
                        animationDuration: const Duration(milliseconds: 500),
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('5개 탭 - easeOutBack (살짝 오버슈트)'),
                      SizedBox(height: spacing.medium),
                      AppTabs(
                        tabs: const [
                          AppTabItem(label: '전체'),
                          AppTabItem(label: '진행중'),
                          AppTabItem(label: '완료'),
                          AppTabItem(label: '보류'),
                          AppTabItem(label: '취소'),
                        ],
                        animationCurve: Curves.easeOutBack,
                        animationDuration: const Duration(milliseconds: 350),
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('5개 탭 - linear (선형 - 비교용)'),
                      SizedBox(height: spacing.medium),
                      AppTabs(
                        tabs: const [
                          AppTabItem(label: '전체'),
                          AppTabItem(label: '진행중'),
                          AppTabItem(label: '완료'),
                          AppTabItem(label: '보류'),
                          AppTabItem(label: '취소'),
                        ],
                        animationCurve: Curves.linear,
                        animationDuration: const Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.xxxl),

                // Definition List 섹션
                AppSection(
                  title: 'Definition List (용어 정의)',
                  variant: SectionVariant.standard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'gap 크기별 샘플',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: spacing.large),
                      _buildSubtitle('gap: 16px (촘촘)'),
                      SizedBox(height: spacing.medium),
                      AppDefinitionList(
                        items: const [
                          AppDefinitionItem(
                            icon: Icons.sync,
                            term: 'Linear Sync Engine',
                            definition:
                                'Built with a high-performance architecture and an obsessive focus on speed.',
                          ),
                          AppDefinitionItem(
                            icon: Icons.security,
                            term: 'Enterprise-ready security',
                            definition:
                                'Best-in-class security practices keep your work safe and secure at every layer.',
                          ),
                        ],
                        itemGap: 16,
                        padding: EdgeInsets.all(spacing.xl),
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('gap: 24px (기본)'),
                      SizedBox(height: spacing.medium),
                      AppDefinitionList(
                        items: const [
                          AppDefinitionItem(
                            icon: Icons.sync,
                            term: 'Linear Sync Engine',
                            definition:
                                'Built with a high-performance architecture and an obsessive focus on speed.',
                          ),
                          AppDefinitionItem(
                            icon: Icons.security,
                            term: 'Enterprise-ready security',
                            definition:
                                'Best-in-class security practices keep your work safe and secure at every layer.',
                          ),
                          AppDefinitionItem(
                            icon: Icons.scale,
                            term: 'Engineered for scale',
                            definition:
                                'Built for teams of all sizes. From early-stage startups to global enterprises.',
                          ),
                        ],
                        itemGap: 24,
                        padding: EdgeInsets.all(spacing.xl),
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('gap: 32px (여유)'),
                      SizedBox(height: spacing.medium),
                      AppDefinitionList(
                        items: [
                          AppDefinitionItem(
                            icon: Icons.sync,
                            term: 'Linear Sync Engine (링크 있음)',
                            definition:
                                'Built with a high-performance architecture and an obsessive focus on speed.',
                            onTermTap: () {
                              debugPrint('Term clicked: Sync Engine');
                            },
                          ),
                          const AppDefinitionItem(
                            icon: Icons.security,
                            term: 'Enterprise-ready security',
                            definition:
                                'Best-in-class security practices keep your work safe and secure at every layer.',
                          ),
                        ],
                        itemGap: 32,
                        padding: EdgeInsets.all(spacing.xl),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.xxxl),

                // Agent Selector 섹션
                AppSection(
                  title: 'AI Agent Selector',
                  variant: SectionVariant.standard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '아바타 크기 + 배지 스타일',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: spacing.large),
                      _buildSubtitle('아바타 16px + subtle 배지'),
                      SizedBox(height: spacing.medium),
                      AppAgentSelector(
                        agents: const [
                          AppAgent(
                            name: 'Cursor',
                            badge: 'Agent',
                            icon: Icons.edit,
                          ),
                          AppAgent(
                            name: 'GitHub Copilot',
                            badge: 'Agent',
                            icon: Icons.code,
                          ),
                          AppAgent(
                            name: 'Sentry',
                            badge: 'Agent',
                            icon: Icons.bug_report,
                          ),
                          AppAgent(name: 'Leela', icon: Icons.person),
                          AppAgent(
                            name: 'Devin',
                            badge: 'Agent',
                            icon: Icons.construction,
                          ),
                        ],
                        avatarSize: 16,
                        badgeStyle: AppBadgeStyle.subtle,
                        selectedIndex: _selectedAgentIndex,
                        onAgentSelected: (index) {
                          setState(() => _selectedAgentIndex = index);
                        },
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('아바타 18px + prominent 배지'),
                      SizedBox(height: spacing.medium),
                      AppAgentSelector(
                        agents: const [
                          AppAgent(
                            name: 'Cursor',
                            badge: 'Agent',
                            icon: Icons.edit,
                          ),
                          AppAgent(
                            name: 'GitHub Copilot',
                            badge: 'Agent',
                            icon: Icons.code,
                          ),
                          AppAgent(
                            name: 'Sentry',
                            badge: 'Agent',
                            icon: Icons.bug_report,
                          ),
                        ],
                        avatarSize: 18,
                        badgeStyle: AppBadgeStyle.prominent,
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('아바타 24px (큰 사이즈)'),
                      SizedBox(height: spacing.medium),
                      AppAgentSelector(
                        agents: const [
                          AppAgent(
                            name: 'Cursor',
                            badge: 'Agent',
                            icon: Icons.edit,
                          ),
                          AppAgent(
                            name: 'GitHub Copilot',
                            badge: 'Agent',
                            icon: Icons.code,
                          ),
                        ],
                        avatarSize: 24,
                        badgeStyle: AppBadgeStyle.prominent,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.xxxl),

                // Gradient Overlay 섹션
                AppSection(
                  title: 'Gradient Overlay',
                  variant: SectionVariant.standard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'opacity 강도별 비교',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: spacing.large),
                      _buildSubtitle('Extra Light (0.03 opacity)'),
                      SizedBox(height: spacing.medium),
                      AppGradientOverlay(
                        type: GradientType.extraLightTopFade,
                        child: Container(
                          height: 200,
                          color: colorExt.surfaceTertiary,
                          child: Center(
                            child: Text(
                              'Extra Light Gradient',
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(color: colorExt.textPrimary),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.xl),
                      _buildSubtitle('Subtle (0.05 opacity) - 기본값'),
                      SizedBox(height: spacing.medium),
                      AppGradientOverlay(
                        type: GradientType.subtleTopFade,
                        child: Container(
                          height: 200,
                          color: colorExt.surfaceTertiary,
                          child: Center(
                            child: Text(
                              'Subtle Gradient',
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(color: colorExt.textPrimary),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.xl),
                      _buildSubtitle('Light (0.08 opacity) - hover 효과'),
                      SizedBox(height: spacing.medium),
                      AppGradientOverlay(
                        type: GradientType.lightTopFade,
                        child: Container(
                          height: 200,
                          color: colorExt.surfaceTertiary,
                          child: Center(
                            child: Text(
                              'Light Gradient',
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(color: colorExt.textPrimary),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.xl),
                      _buildSubtitle('방향별 그래디언트'),
                      SizedBox(height: spacing.medium),
                      Row(
                        children: [
                          Expanded(
                            child: AppGradientOverlay(
                              type: GradientType.subtleBottomFade,
                              child: Container(
                                height: 150,
                                color: colorExt.surfaceTertiary,
                                child: const Center(child: Text('Bottom Fade')),
                              ),
                            ),
                          ),
                          SizedBox(width: spacing.large),
                          Expanded(
                            child: AppGradientOverlay(
                              type: GradientType.subtleLeftFade,
                              child: Container(
                                height: 150,
                                color: colorExt.surfaceTertiary,
                                child: const Center(child: Text('Left Fade')),
                              ),
                            ),
                          ),
                          SizedBox(width: spacing.large),
                          Expanded(
                            child: AppGradientOverlay(
                              type: GradientType.radialFade,
                              child: Container(
                                height: 150,
                                color: colorExt.surfaceTertiary,
                                child: const Center(child: Text('Radial')),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.xxxl),

                // Feature Card 섹션
                AppSection(
                  title: 'Feature Cards (대형 클릭 가능 카드)',
                  variant: SectionVariant.standard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '크기별 샘플 + hover 효과',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: spacing.large),
                      _buildSubtitle('기본 크기 (아이콘 사용)'),
                      SizedBox(height: spacing.medium),
                      Wrap(
                        spacing: spacing.large,
                        runSpacing: spacing.large,
                        children: [
                          AppFeatureCard(
                            title: 'Customer Requests',
                            subtitle: 'Build what customers actually want',
                            icon: Icons.people,
                            width: 280,
                            onTap: () {
                              debugPrint('Customer Requests tapped');
                            },
                          ),
                          AppFeatureCard(
                            title: 'Powerful git workflows',
                            subtitle:
                                'Automate pull requests and commit workflows',
                            icon: Icons.code,
                            width: 280,
                            onTap: () {
                              debugPrint('Git workflows tapped');
                            },
                          ),
                          AppFeatureCard(
                            title: 'Linear Mobile',
                            subtitle: 'Move product work forward from anywhere',
                            icon: Icons.phone_android,
                            width: 280,
                            onTap: () {
                              debugPrint('Linear Mobile tapped');
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('큰 크기 (이미지 영역 포함)'),
                      SizedBox(height: spacing.medium),
                      Wrap(
                        spacing: spacing.large,
                        runSpacing: spacing.large,
                        children: [
                          AppFeatureCard(
                            title: 'Linear Asks',
                            subtitle:
                                'Turn workplace requests into actionable issues',
                            width: 336,
                            image: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: colorExt.surfaceQuaternary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.help_outline,
                                  size: 64,
                                  color: colorExt.textTertiary,
                                ),
                              ),
                            ),
                            onTap: () {
                              debugPrint('Linear Asks tapped');
                            },
                          ),
                          AppFeatureCard(
                            title: 'Linear integrations',
                            subtitle:
                                '100+ ways to enhance your Linear experience',
                            width: 336,
                            image: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: colorExt.surfaceQuaternary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.extension,
                                  size: 64,
                                  color: colorExt.textTertiary,
                                ),
                              ),
                            ),
                            onTap: () {
                              debugPrint('Integrations tapped');
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.xxl),
                      _buildSubtitle('작은 크기 (컴팩트)'),
                      SizedBox(height: spacing.medium),
                      Wrap(
                        spacing: spacing.large,
                        runSpacing: spacing.large,
                        children: [
                          AppFeatureCard(
                            title: 'Figma integration',
                            subtitle:
                                'Bridge the gap between engineering and design',
                            icon: Icons.design_services,
                            width: 220,
                            onTap: () {
                              debugPrint('Figma integration tapped');
                            },
                          ),
                          AppFeatureCard(
                            title: 'Built for developers',
                            subtitle:
                                'Build your own add-ons with the Linear API',
                            icon: Icons.code_outlined,
                            width: 220,
                            onTap: () {
                              debugPrint('Developer API tapped');
                            },
                          ),
                          AppFeatureCard(
                            title: 'Security first',
                            subtitle:
                                'Enterprise-ready security at every layer',
                            icon: Icons.security,
                            width: 220,
                            onTap: () {
                              debugPrint('Security tapped');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    final colorExt = context.appColors;
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall!.copyWith(
        color: colorExt.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  List<Widget> _buildCarouselItems(int count) {
    final colorExt = context.appColors;
    final spacing = context.appSpacing;
    return List.generate(
      count,
      (index) => AppCard(
        elevation: AppCardElevation.low,
        onTap: () {
          debugPrint('Card ${index + 1} tapped');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 샘플 이미지 영역
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colorExt.surfaceQuaternary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: colorExt.textTertiary,
                ),
              ),
            ),
            SizedBox(height: spacing.large),
            Text(
              'Feature ${index + 1}',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: colorExt.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Sample description for item ${index + 1}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: colorExt.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
