import 'package:flutter/material.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/theme/responsive_tokens.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/widgets/app_back_button.dart';

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
                _buildScreenSizeInfo(context, screenSize, width),
                const SizedBox(height: 32.0), // sectionSpacingMedium
                // 반응형 레이아웃 예시
                _buildResponsiveLayoutExample(context, screenSize, width),
                const SizedBox(height: 32.0), // sectionSpacingMedium
                // 그리드 시스템 예시
                _buildGridExample(context, screenSize, width),
                const SizedBox(height: 32.0), // sectionSpacingMedium
                // 버튼 크기 예시
                _buildButtonExample(context, screenSize, width),
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
      style: screenSize == ScreenSize.mobile
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
    final String sizeLabel = screenSize == ScreenSize.mobile
        ? 'Mobile (< 600px)'
        : screenSize == ScreenSize.tablet
        ? 'Tablet (600-1024px)'
        : 'Desktop (>= 1024px)';

    return AppCard(
      padding: EdgeInsets.all(ResponsiveTokens.cardPadding(width)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 화면 크기',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
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
        Text(
          '반응형 레이아웃',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        // ✅ 조건부 레이아웃 (기존 프로젝트 패턴)
        screenSize == ScreenSize.mobile
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
        const SizedBox(height: 8),
        Text(
          screenSize == ScreenSize.mobile
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
    final columnCount = ResponsiveTokens.columnCount(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '그리드 시스템',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 8),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '버튼 크기',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
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
        const SizedBox(height: 8),
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
