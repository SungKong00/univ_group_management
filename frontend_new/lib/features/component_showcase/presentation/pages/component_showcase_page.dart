import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/extensions/app_typography_extension.dart';
import '../../../../core/theme/responsive_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_builder.dart';
import 'advanced_components_page.dart';
import 'responsive_test_page.dart';
import 'v3_components_page.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('컴포넌트 쇼케이스'),
        backgroundColor: colorExt.surfaceSecondary,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AppButton(
              text: 'V3 컴포넌트 →',
              size: AppButtonSize.small,
              variant: AppButtonVariant.primary,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const V3ComponentsPage()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: AppButton(
              text: '반응형 테스트 →',
              size: AppButtonSize.small,
              variant: AppButtonVariant.ghost,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResponsiveTestPage()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: AppButton(
              text: 'V2 컴포넌트 →',
              size: AppButtonSize.small,
              variant: AppButtonVariant.ghost,
              onPressed: () {
                context.go('/v2');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: AppButton(
              text: '고급 컴포넌트 →',
              size: AppButtonSize.small,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdvancedComponentsPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, screenSize, width) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 색상 팔레트
                _buildSection(
                  title: '색상 팔레트',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildColorRow('브랜드 색상', [
                        ('브랜드', colorExt.brandPrimary),
                        ('강조', colorExt.brandSecondary),
                        ('강조 호버', colorExt.accentHover),
                      ]),
                      const SizedBox(height: 12),
                      _buildColorRow('상태 색상', [
                        ('초록', colorExt.stateSuccessBg),
                        ('빨강', colorExt.stateErrorBg),
                        ('노랑', colorExt.stateWarningBg),
                        ('주황', colorExt.stateBuildBg),
                        ('파랑', colorExt.stateInfoBg),
                      ]),
                      const SizedBox(height: 12),
                      _buildColorRow('텍스트 색상', [
                        ('기본', colorExt.textPrimary),
                        ('보조', colorExt.textSecondary),
                        ('3순위', colorExt.textTertiary),
                        ('4순위', colorExt.textQuaternary),
                      ]),
                      const SizedBox(height: 12),
                      _buildColorRow('배경 색상', [
                        ('레벨 0', colorExt.surfacePrimary),
                        ('레벨 1', colorExt.surfaceSecondary),
                        ('레벨 2', colorExt.surfaceTertiary),
                        ('레벨 3', colorExt.surfaceQuaternary),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 타이포그래피
                _buildSection(
                  title: '타이포그래피',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '제목 1',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '제목 2',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '제목 3',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '제목 4',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '큰 텍스트',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '일반 텍스트',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '작은 텍스트',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '미니 텍스트',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('마이크로 텍스트', style: context.appTypography.textMicro),
                      const SizedBox(height: 8),
                      Text(
                        'Monospace Code',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 버튼 - 유형별 (좌→우: 큰 크기 순)
                _buildSection(
                  title: '버튼 - 유형별',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ========== Primary 버튼 ==========
                      Text(
                        'Primary (기본 버튼)',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: colorExt.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          // Row 1: 기본 (Large → Medium → Small)
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
                          // Row 2: 아이콘 포함 (Large → Medium → Small)
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
                          // Row 3: 상태 (로딩, 비활성화)
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
                      const SizedBox(height: 32),

                      // ========== Secondary 버튼 ==========
                      Text(
                        'Secondary (보조 버튼)',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: colorExt.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          // Row 1: 기본 (Large → Medium → Small)
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
                          // Row 2: 아이콘 포함 (Large → Medium → Small)
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
                          // Row 3: 상태 (로딩, 비활성화)
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
                      const SizedBox(height: 32),

                      // ========== Ghost 버튼 ==========
                      Text(
                        'Ghost (유령 버튼)',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: colorExt.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          // Row 1: 기본 (Large → Medium → Small)
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
                          // Row 2: 아이콘 포함 (Large → Medium → Small)
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
                          // Row 3: 상태 (로딩, 비활성화만 - Ghost는 특수 용도)
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
                ),
                const SizedBox(height: 32),

                // 입력 필드 - 기본
                _buildSection(
                  title: '입력 필드',
                  child: Column(
                    children: [
                      AppInput(
                        label: '이메일',
                        placeholder: 'your.email@example.com',
                        controller: _textController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      const AppInput(
                        label: '비밀번호',
                        placeholder: '비밀번호 입력',
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      const AppInput(
                        label: '도움말 텍스트 포함',
                        placeholder: '무언가 입력',
                        helperText: '이것은 도움말 텍스트입니다',
                      ),
                      const SizedBox(height: 16),
                      const AppInput(
                        label: '오류 포함',
                        placeholder: '무언가 입력',
                        errorText: '필수 입력 항목입니다',
                      ),
                      const SizedBox(height: 16),
                      const AppInput(
                        label: '비활성화됨',
                        placeholder: '편집 불가',
                        enabled: false,
                      ),
                      const SizedBox(height: 16),
                      const AppInput(
                        label: '여러 줄',
                        placeholder: '설명 입력',
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 카드 - 높이 샘플
                _buildSection(
                  title: '카드 - 높이 샘플',
                  child: Column(
                    children: [
                      AppCard(
                        elevation: AppCardElevation.none,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('none 카드 클릭')),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 60,
                              decoration: BoxDecoration(
                                color: colorExt.stateInfoBg,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'elevation: none (기본값)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '그림자 없음 → hover: low',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(color: colorExt.textTertiary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        elevation: AppCardElevation.low,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('low 카드 클릭')),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 60,
                              decoration: BoxDecoration(
                                color: colorExt.stateSuccessBg,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'elevation: low',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'rgba(255,255,255,0.05) 0px 2px 4px',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                          color: colorExt.textTertiary,
                                          fontFamily: 'monospace',
                                        ),
                                  ),
                                  Text(
                                    '미묘한 그림자 → hover: medium',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                          color: colorExt.textQuaternary,
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
                ),
                const SizedBox(height: 32),

                // 카드 - 비활성화 투명도 샘플
                _buildSection(
                  title: '카드 - 비활성화 투명도 (그림자 포함)',
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
                                color: colorExt.stateWarningBg,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'disabledOpacity: 0.65',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '가장 선명 (투명도 낮음)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(color: colorExt.textTertiary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        elevation: AppCardElevation.low,
                        disabledOpacity: 0.75,
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 50,
                              decoration: BoxDecoration(
                                color: colorExt.stateErrorBg,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'disabledOpacity: 0.75',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '표준 (권장)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(color: colorExt.textTertiary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        elevation: AppCardElevation.low,
                        disabledOpacity: 0.85,
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 50,
                              decoration: BoxDecoration(
                                color: colorExt.brandSecondary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'disabledOpacity: 0.85',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '덜 선명 (투명도 높음)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(color: colorExt.textTertiary),
                                  ),
                                ],
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
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final colorExt = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.copyWith(color: colorExt.textPrimary),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildColorRow(String label, List<(String, Color)> colors) {
    final colorExt = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: colorExt.textTertiary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
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
                const SizedBox(height: 4),
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
