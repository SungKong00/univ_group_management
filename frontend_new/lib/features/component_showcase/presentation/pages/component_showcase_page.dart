import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/extensions/app_typography_extension.dart';
import '../../../../core/theme/extensions/app_spacing_extension.dart';
import '../../../../core/theme/responsive_tokens.dart';
import '../../../../core/theme/enums.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/app_section.dart';
import '../../../../core/widgets/app_top_bar.dart';
import 'advanced_components_page.dart';
import 'responsive_test_page.dart';
import 'v3_components_page.dart';
import 'feedback_components_page.dart';
import 'advanced_ui_components_page.dart';
import 'navigation_components_page.dart';
import 'data_form_components_page.dart';
import 'feedback_overlay_components_page.dart';
import 'special_components_page.dart';

/// 모든 디자인 컴포넌트 샘플을 보여주는 페이지
class ComponentShowcasePage extends StatefulWidget {
  const ComponentShowcasePage({super.key});

  @override
  State<ComponentShowcasePage> createState() => _ComponentShowcasePageState();
}

class _ComponentShowcasePageState extends State<ComponentShowcasePage> {
  bool _isLoading = false;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    // ================================================================
    // 📐 Spacing 사용 패턴:
    //
    // - ResponsiveTokens: 화면 크기별로 다른 값
    //   예: sectionVerticalGap(width), sectionContentGap, pagePadding(width)
    //
    // - context.appSpacing: 고정된 4dp 그리드 기반 (모든 화면에서 동일)
    //   예: xs(4px), small(8px), medium(12px), large(16px)
    //
    // ⚠️ 주의: ResponsiveTokens.sectionContentGap는 고정값이지만,
    //         ResponsiveTokens.sectionVerticalGap는 반응형이므로 주의!
    // ================================================================

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppTopBar(
          title: Text(
            '컴포넌트 쇼케이스',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorExt.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: _PageNavigationMenu(),
        ),
      ),
      body: ResponsiveBuilder(
        builder: (context, screenSize, width) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColorPaletteSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildTypographySection(),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildButtonsSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildInputFieldsSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildCardElevationSection(),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildCardDisabledOpacitySection(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========================================================
  // Section 1: 색상 팔레트
  // ========================================================
  Widget _buildColorPaletteSection(double width) {
    return AppSection(
      title: '색상 팔레트',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColorRow('브랜드 색상', [
            ('브랜드', context.appColors.brandPrimary),
            ('강조', context.appColors.brandSecondary),
            ('강조 호버', context.appColors.accentHover),
          ]),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          _buildColorRow('상태 색상', [
            ('초록', context.appColors.stateSuccessBg),
            ('빨강', context.appColors.stateErrorBg),
            ('노랑', context.appColors.stateWarningBg),
            ('주황', context.appColors.stateBuildBg),
            ('파랑', context.appColors.stateInfoBg),
          ]),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          _buildColorRow('텍스트 색상', [
            ('기본', context.appColors.textPrimary),
            ('보조', context.appColors.textSecondary),
            ('3순위', context.appColors.textTertiary),
            ('4순위', context.appColors.textQuaternary),
          ]),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          _buildColorRow('배경 색상', [
            ('레벨 0', context.appColors.surfacePrimary),
            ('레벨 1', context.appColors.surfaceSecondary),
            ('레벨 2', context.appColors.surfaceTertiary),
            ('레벨 3', context.appColors.surfaceQuaternary),
          ]),
        ],
      ),
    );
  }

  // ========================================================
  // Section 2: 타이포그래피
  // ========================================================
  Widget _buildTypographySection() {
    return AppSection(
      title: '타이포그래피',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('제목 1', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          Text('제목 2', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          Text('제목 3', style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          Text('제목 4', style: Theme.of(context).textTheme.headlineLarge),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Text('큰 텍스트', style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          Text('일반 텍스트', style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          Text('작은 텍스트', style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          Text('미니 텍스트', style: Theme.of(context).textTheme.labelSmall),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          Text('마이크로 텍스트', style: context.appTypography.textMicro),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          Text(
            'Monospace Code',
            style: TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 3: 버튼
  // ========================================================
  Widget _buildButtonsSection(double width) {
    return AppSection(
      title: '버튼 - 유형별',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== Primary 버튼 ==========
          Text(
            'Primary (기본 버튼)',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          Wrap(
            spacing: context.appSpacing.medium,
            runSpacing: context.appSpacing.medium,
            children: [
              AppButton(
                text: 'Primary Large',
                size: AppButtonSize.large,
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
              AppButton(
                text: 'Primary Medium',
                size: AppButtonSize.medium,
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
              AppButton(
                text: 'Primary Small',
                size: AppButtonSize.small,
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
              AppButton(
                text: 'Add Large',
                icon: Icons.add,
                size: AppButtonSize.large,
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
              AppButton(
                text: 'Add Medium',
                icon: Icons.add,
                size: AppButtonSize.medium,
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
              AppButton(
                text: 'Add Small',
                icon: Icons.add,
                size: AppButtonSize.small,
                variant: AppButtonVariant.primary,
                onPressed: () {},
              ),
              AppButton(
                text: '로딩 중',
                isLoading: _isLoading,
                variant: AppButtonVariant.primary,
                onPressed: () {
                  setState(() {
                    _isLoading = !_isLoading;
                  });
                },
              ),
              const AppButton(
                text: '비활성화',
                variant: AppButtonVariant.primary,
                onPressed: null,
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),

          // ========== Secondary 버튼 ==========
          Text(
            'Secondary (보조 버튼)',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          Wrap(
            spacing: context.appSpacing.medium,
            runSpacing: context.appSpacing.medium,
            children: [
              AppButton(
                text: 'Secondary Large',
                size: AppButtonSize.large,
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                text: 'Secondary Medium',
                size: AppButtonSize.medium,
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                text: 'Secondary Small',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                text: 'Delete Large',
                icon: Icons.delete,
                size: AppButtonSize.large,
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                text: 'Delete Medium',
                icon: Icons.delete,
                size: AppButtonSize.medium,
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                text: 'Delete Small',
                icon: Icons.delete,
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                text: '로딩 중',
                isLoading: _isLoading,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  setState(() {
                    _isLoading = !_isLoading;
                  });
                },
              ),
              const AppButton(
                text: '비활성화',
                variant: AppButtonVariant.secondary,
                onPressed: null,
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),

          // ========== Ghost 버튼 ==========
          Text(
            'Ghost (유령 버튼)',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          Wrap(
            spacing: context.appSpacing.medium,
            runSpacing: context.appSpacing.medium,
            children: [
              AppButton(
                text: 'Ghost Large',
                size: AppButtonSize.large,
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
              AppButton(
                text: 'Ghost Medium',
                size: AppButtonSize.medium,
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
              AppButton(
                text: 'Ghost Small',
                size: AppButtonSize.small,
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
              AppButton(
                text: 'Edit Large',
                icon: Icons.edit,
                size: AppButtonSize.large,
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
              AppButton(
                text: 'Edit Medium',
                icon: Icons.edit,
                size: AppButtonSize.medium,
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
              AppButton(
                text: 'Edit Small',
                icon: Icons.edit,
                size: AppButtonSize.small,
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
              AppButton(
                text: '로딩',
                isLoading: _isLoading,
                variant: AppButtonVariant.ghost,
                onPressed: () {
                  setState(() {
                    _isLoading = !_isLoading;
                  });
                },
              ),
              const AppButton(
                text: '비활성화',
                variant: AppButtonVariant.ghost,
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 4: 입력 필드
  // ========================================================
  Widget _buildInputFieldsSection(double width) {
    return AppSection(
      title: '입력 필드',
      variant: SectionVariant.compact,
      child: Column(
        children: [
          AppInput(
            label: '이메일',
            placeholder: 'your.email@example.com',
            controller: _textController,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          const AppInput(
            label: '비밀번호',
            placeholder: '비밀번호 입력',
            obscureText: true,
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          const AppInput(
            label: '도움말 텍스트 포함',
            placeholder: '무언가 입력',
            helperText: '이것은 도움말 텍스트입니다',
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          const AppInput(
            label: '오류 포함',
            placeholder: '무언가 입력',
            errorText: '필수 입력 항목입니다',
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          const AppInput(label: '비활성화됨', placeholder: '편집 불가', enabled: false),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          const AppInput(label: '여러 줄', placeholder: '설명 입력', maxLines: 4),
        ],
      ),
    );
  }

  // ========================================================
  // Section 5: 카드 - 높이 샘플
  // ========================================================
  Widget _buildCardElevationSection() {
    return AppSection(
      title: '카드 - 높이 샘플',
      variant: SectionVariant.compact,
      child: Column(
        children: [
          AppCard(
            elevation: AppCardElevation.none,
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('none 카드 클릭')));
            },
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: context.appColors.stateInfoBg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: context.appSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'elevation: none (기본값)',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveTokens.sectionContentGap * 0.25,
                      ),
                      Text(
                        '그림자 없음 → hover: low',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: context.appColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppCard(
            elevation: AppCardElevation.low,
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('low 카드 클릭')));
            },
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: context.appColors.stateSuccessBg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: context.appSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'elevation: low',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveTokens.sectionContentGap * 0.25,
                      ),
                      Text(
                        'rgba(255,255,255,0.05) 0px 2px 4px',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: context.appColors.textTertiary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '미묘한 그림자 → hover: medium',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: context.appColors.textQuaternary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 6: 카드 - 비활성화 투명도 샘플
  // ========================================================
  Widget _buildCardDisabledOpacitySection() {
    return AppSection(
      title: '카드 - 비활성화 투명도 (그림자 포함)',
      variant: SectionVariant.compact,
      child: Column(
        children: [
          AppCard(
            elevation: AppCardElevation.low,
            disabledOpacity: 0.65,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.appColors.stateWarningBg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: context.appSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'disabledOpacity: 0.65',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '가장 선명 (투명도 낮음)',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: context.appColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppCard(
            elevation: AppCardElevation.low,
            disabledOpacity: 0.75,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.appColors.stateErrorBg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: context.appSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'disabledOpacity: 0.75',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '표준 (권장)',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: context.appColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppCard(
            elevation: AppCardElevation.low,
            disabledOpacity: 0.85,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.appColors.brandSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: context.appSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'disabledOpacity: 0.85',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '덜 선명 (투명도 높음)',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: context.appColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(String label, List<(String, Color)> colors) {
    final colorExt = context.appColors;
    final spacing = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: colorExt.textTertiary),
        ),
        SizedBox(height: spacing.small),
        Wrap(
          spacing: spacing.medium,
          runSpacing: spacing.small,
          children: colors.map((colorInfo) {
            final (name, color) = colorInfo;
            return Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorExt.borderPrimary, width: 1),
                  ),
                ),
                SizedBox(height: spacing.xs),
                SizedBox(
                  width: 60,
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: context.appTypography.textMicro.copyWith(
                      color: colorExt.textTertiary,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 페이지 네비게이션 메뉴
///
/// 다른 쇼케이스 페이지로 이동하는 메뉴를 표시합니다.
/// PopupMenuButton을 사용하여 오버플로우 문제를 해결합니다.
class _PageNavigationMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    return PopupMenuButton<void>(
      icon: Icon(Icons.apps, color: colorExt.textPrimary),
      tooltip: '다른 쇼케이스 페이지',
      offset: const Offset(0, 48),
      itemBuilder: (context) => [
        _buildMenuItem(
          context,
          '데이터/폼 컴포넌트',
          Icons.input,
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DataFormComponentsPage()),
          ),
        ),
        _buildMenuItem(
          context,
          '네비게이션 컴포넌트',
          Icons.navigation,
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NavigationComponentsPage()),
          ),
        ),
        _buildMenuItem(
          context,
          '고급 UI 컴포넌트',
          Icons.dashboard_customize,
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdvancedUIComponentsPage()),
          ),
        ),
        _buildMenuItem(
          context,
          '피드백/유틸 컴포넌트',
          Icons.feedback,
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FeedbackComponentsPage()),
          ),
        ),
        _buildMenuItem(
          context,
          '오버레이 컴포넌트',
          Icons.layers,
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const FeedbackOverlayComponentsPage(),
            ),
          ),
        ),
        _buildMenuItem(
          context,
          '특수 컴포넌트',
          Icons.auto_awesome,
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SpecialComponentsPage()),
          ),
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          context,
          'V3 컴포넌트',
          Icons.new_releases,
          () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const V3ComponentsPage())),
        ),
        _buildMenuItem(
          context,
          '반응형 테스트',
          Icons.settings_overscan,
          () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ResponsiveTestPage())),
        ),
        _buildMenuItem(
          context,
          'V2 컴포넌트',
          Icons.archive,
          () => context.go('/v2'),
        ),
        _buildMenuItem(
          context,
          '고급 컴포넌트',
          Icons.extension,
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdvancedComponentsPage()),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<void> _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colorExt = context.appColors;
    final spacing = context.appSpacing;

    return PopupMenuItem(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorExt.textSecondary),
          SizedBox(width: spacing.medium),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorExt.textPrimary),
          ),
        ],
      ),
    );
  }
}
