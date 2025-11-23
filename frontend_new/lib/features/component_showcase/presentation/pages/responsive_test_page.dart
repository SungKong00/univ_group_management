import 'package:flutter/material.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/theme/responsive_tokens.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/extensions/app_spacing_extension.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_section.dart';
import '../../../../core/theme/enums.dart';

/// 반응형 디자인 테스트 페이지
///
/// 화면 크기에 따른 레이아웃 변경, 패딩 조정, 컬럼 배치 등을 테스트합니다.
class ResponsiveTestPage extends StatelessWidget {
  const ResponsiveTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    return Scaffold(
      backgroundColor: colorExt.surfacePrimary,
      appBar: AppBar(
        backgroundColor: colorExt.surfaceSecondary,
        elevation: 0,
        leading: AppBackButton(),
        title: const Text('반응형 디자인 테스트'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveTokens.space24),
        child: ResponsiveBuilder(
          builder: (context, screenSize, width) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                _buildHeader(context, screenSize, width),
                const SizedBox(height: 32.0), // sectionSpacingMedium
                // 화면 크기 정보
                AppSection(
                  title: '현재 화면 크기',
                  variant: SectionVariant.standard,
                  child: _buildScreenSizeInfo(context, screenSize, width),
                ),
                const SizedBox(height: 32.0), // sectionSpacingMedium
                // 반응형 레이아웃 예시
                AppSection(
                  title: '반응형 레이아웃',
                  variant: SectionVariant.standard,
                  child: _buildResponsiveLayoutExample(
                    context,
                    screenSize,
                    width,
                  ),
                ),
                const SizedBox(height: 32.0), // sectionSpacingMedium
                // 그리드 시스템 예시
                AppSection(
                  title: '그리드 시스템',
                  variant: SectionVariant.standard,
                  child: _buildGridExample(context, screenSize, width),
                ),
                const SizedBox(height: 32.0), // sectionSpacingMedium
                // 버튼 크기 예시
                AppSection(
                  title: '버튼 크기',
                  variant: SectionVariant.standard,
                  child: _buildButtonExample(context, screenSize, width),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ScreenSize screenSize,
    double width,
  ) {
    return Text(
      '반응형 디자인 테스트',
      style: screenSize == ScreenSize.xs || screenSize == ScreenSize.sm
          ? Theme.of(context).textTheme.headlineMedium
          : Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget _buildScreenSizeInfo(
    BuildContext context,
    ScreenSize screenSize,
    double width,
  ) {
    final colorExt = context.appColors;
    final String sizeLabel =
        screenSize == ScreenSize.xs || screenSize == ScreenSize.sm
        ? 'Mobile (< 768px)'
        : screenSize == ScreenSize.md
        ? 'Tablet (768-1024px)'
        : 'Desktop (>= 1024px)';

    return AppCard(
      padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sizeLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: colorExt.brandSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '너비: ${width.toStringAsFixed(0)}px',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: colorExt.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '그리드 컬럼: ${ResponsiveTokens.columnCount(width)}개',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: colorExt.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '페이지 패딩: ${ResponsiveTokens.pagePadding(width)}px',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: colorExt.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveLayoutExample(
    BuildContext context,
    ScreenSize screenSize,
    double width,
  ) {
    final colorExt = context.appColors;
    final spacing = context.appSpacing;
    // 카드들을 미리 정의
    final cards = [
      AppCard(
        padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
        child: SizedBox(
          height: 80, // 명시적 높이 제공
          child: Center(
            child: Text('카드 1', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ),
      AppCard(
        padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
        child: SizedBox(
          height: 80,
          child: Center(
            child: Text('카드 2', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ),
      AppCard(
        padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
        child: SizedBox(
          height: 80,
          child: Center(
            child: Text('카드 3', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ 조건부 레이아웃 (기존 프로젝트 패턴)
        screenSize == ScreenSize.xs || screenSize == ScreenSize.sm
            ? Column(
                // Mobile: 세로 배치
                children: cards
                    .map(
                      (card) => Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveTokens.cardGap(width),
                        ),
                        child: card,
                      ),
                    )
                    .toList(),
              )
            : Row(
                // Desktop: 가로 배치
                children: cards
                    .map(
                      (card) => Flexible(
                        // ✅ Flexible with loose fit
                        fit: FlexFit.loose,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: ResponsiveTokens.cardGap(width),
                          ),
                          child: card,
                        ),
                      ),
                    )
                    .toList(),
              ),
        SizedBox(height: spacing.small),
        Text(
          screenSize == ScreenSize.xs || screenSize == ScreenSize.sm
              ? 'Mobile: 세로 배치 (Column)'
              : 'Desktop: 가로 배치 (Row with Flexible)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: colorExt.textTertiary),
        ),
      ],
    );
  }

  Widget _buildGridExample(
    BuildContext context,
    ScreenSize screenSize,
    double width,
  ) {
    final colorExt = context.appColors;
    final spacing = context.appSpacing;
    final columnCount = ResponsiveTokens.columnCount(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ LayoutBuilder로 실제 사용 가능한 너비 계산
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final gutter = 16.0; // gridGutter
            final totalGutterWidth = (columnCount - 1) * gutter;
            final cellWidth = (availableWidth - totalGutterWidth) / columnCount;

            return Wrap(
              spacing: gutter,
              runSpacing: 16.0, // gridRowGap
              children: List.generate(
                columnCount,
                (index) => Container(
                  width: cellWidth,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorExt.brandSecondary.withValues(alpha: 0.2),
                    border: Border.all(color: colorExt.brandSecondary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: colorExt.brandSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: spacing.small),
        Text(
          '$columnCount 컬럼 그리드',
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: colorExt.textTertiary),
        ),
      ],
    );
  }

  Widget _buildButtonExample(
    BuildContext context,
    ScreenSize screenSize,
    double width,
  ) {
    final colorExt = context.appColors;
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: spacing.medium,
          runSpacing: spacing.medium,
          children: [
            AppButton(
              text: '작은 버튼',
              size: AppButtonSize.small,
              onPressed: () {},
            ),
            AppButton(
              text: '중간 버튼',
              size: AppButtonSize.medium,
              onPressed: () {},
            ),
            AppButton(
              text: '큰 버튼',
              size: AppButtonSize.large,
              onPressed: () {},
            ),
          ],
        ),
        SizedBox(height: spacing.small),
        Text(
          '최소 터치 영역: ${ResponsiveTokens.minTapSize}px',
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: colorExt.textTertiary),
        ),
      ],
    );
  }
}
