import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/horizontal_card_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/card_design_tokens.dart';

/// Horizontal Card - 이미지 좌측 + 텍스트 우측
///
/// 레이아웃: Image (left) → Title/Subtitle/Description (right)
/// 비율: 4:3 ~ 16:9 (가로 스크롤 최적화)
///
/// ## 반응형 동작
/// - 카드 너비 < 240px: 이미지 비율 30%로 축소
/// - 카드 너비 < 200px: 이미지 숨김 (세로 레이아웃 폴백)
/// - 모든 텍스트는 ellipsis로 처리
class HorizontalCard extends StatefulWidget {
  /// 카드 제목
  final String title;

  /// 카드 부제목 (선택)
  final String? subtitle;

  /// 카드 설명
  final String? description;

  /// 메타 정보 (선택)
  final String? meta;

  /// 이미지 위젯 (좌측)
  final Widget? image;

  /// 이미지 너비 비율 (0.3 ~ 0.5, 좁은 카드에서는 자동 조정)
  final double imageWidthRatio;

  /// 액션 버튼들
  final List<Widget>? actions;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// 카드 스타일 variant (standard, featured, highlighted)
  final String variant;

  /// 최소 콘텐츠 영역 너비 (이미지 비율 조정 기준)
  /// 8px 그리드: 15×8 = 120px
  final double minContentWidth;

  const HorizontalCard({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.meta,
    this.image,
    this.imageWidthRatio = 0.4,
    this.actions,
    this.onTap,
    this.variant = 'standard',
    this.minContentWidth = 120, // 15×8px
  });

  @override
  State<HorizontalCard> createState() => _HorizontalCardState();
}

class _HorizontalCardState extends State<HorizontalCard> {
  bool _isHovered = false;

  /// 기준 카드 너비 (이 너비에서 100% 폰트 크기)
  static const double _referenceCardWidth = 400.0;

  /// 최소 폰트 스케일 (너무 작아지지 않도록)
  static const double _minFontScale = 0.7;

  /// 최대 폰트 스케일 (너무 커지지 않도록)
  static const double _maxFontScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    // 색상 선택
    final colors = switch (widget.variant) {
      'featured' => HorizontalCardColors.featured(colorExt),
      'highlighted' => HorizontalCardColors.highlighted(colorExt),
      _ => HorizontalCardColors.standard(colorExt),
    };

    // LayoutBuilder: 실제 할당된 카드 너비 기준으로 레이아웃 결정
    return LayoutBuilder(
      builder: (context, constraints) {
        // 실제 카드 너비 (AdaptiveCardGrid가 할당한 너비)
        final actualCardWidth = constraints.maxWidth;

        // 화면 너비는 반응형 토큰(padding, gap)에만 사용
        final screenWidth = MediaQuery.sizeOf(context).width;
        final padding = _scaledPadding(actualCardWidth, screenWidth);
        final gap = _scaledGap(actualCardWidth, screenWidth);
        final lineNumbers =
            CardDesignTokens.textLineNumbersByCard['horizontal']!;

        // 카드 너비 기반 폰트 스케일 계산
        final fontScale = _calculateFontScale(actualCardWidth);

        // 오버플로우 방지: 카드 너비에 따라 이미지 비율 동적 조정
        // 콘텐츠 영역 = 카드너비 - 이미지너비 - 패딩×2
        // 콘텐츠 영역이 minContentWidth보다 작으면 이미지 비율 축소
        final effectiveImageRatio = _calculateImageRatio(
          actualCardWidth,
          padding,
          widget.imageWidthRatio,
          widget.minContentWidth * fontScale, // 최소 콘텐츠 너비도 스케일링
        );

        // 이미지 숨김 여부 (너무 좁은 카드)
        final hideImage = effectiveImageRatio <= 0 || widget.image == null;

        // 이미지 너비: 실제 카드 너비 기준으로 계산
        final imageWidth = hideImage
            ? 0.0
            : actualCardWidth * effectiveImageRatio;

        // 이미지 비율 기반 최소 높이 자동 계산
        final imageAspectRatio =
            CardDesignTokens.imageAspectRatios['horizontal']!;
        final minHeight = hideImage
            ? ResponsiveTokens.space64 * fontScale // 이미지 없을 때도 스케일링
            : imageWidth / imageAspectRatio;

        return GestureDetector(
          onTap: widget.onTap,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: CardDesignTokens.hoverAnimationDuration,
              decoration: BoxDecoration(
                color: _isHovered ? colors.backgroundHover : colors.background,
                border: Border.all(color: colors.border),
                borderRadius: BorderTokens.largeRadius(),
              ),
              clipBehavior: Clip.antiAlias,
              // ConstrainedBox: 이미지 비율 기반 최소 높이 자동 계산
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Section (Left) - 조건부 표시
                    if (!hideImage)
                      SizedBox(
                        width: imageWidth,
                        child: AspectRatio(
                          aspectRatio:
                              CardDesignTokens.imageAspectRatios['horizontal']!,
                          child: widget.image!,
                        ),
                      ),

                    // Content Section (Right)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Meta
                            if (widget.meta != null)
                              Text(
                                widget.meta!,
                                style: _scaledTextStyle(
                                  CardDesignTokens.getMetaStyle(context),
                                  fontScale,
                                ).copyWith(color: colors.meta),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (widget.meta != null)
                              SizedBox(height: gap * 0.5),

                            // Title (필수, Flexible로 감싸서 오버플로우 방지)
                            Flexible(
                              child: Text(
                                widget.title,
                                style: _scaledTextStyle(
                                  CardDesignTokens.getTitleStyle(context),
                                  fontScale,
                                ).copyWith(color: colors.title),
                                maxLines: lineNumbers['title'],
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: gap * 0.5),

                            // Subtitle
                            if (widget.subtitle != null)
                              Flexible(
                                child: Text(
                                  widget.subtitle!,
                                  style: _scaledTextStyle(
                                    CardDesignTokens.getSubtitleStyle(context),
                                    fontScale,
                                  ).copyWith(color: colors.subtitle),
                                  maxLines: lineNumbers['subtitle'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (widget.subtitle != null)
                              SizedBox(height: gap * 0.5),

                            // Description
                            if (widget.description != null)
                              Flexible(
                                child: Text(
                                  widget.description!,
                                  style: _scaledTextStyle(
                                    CardDesignTokens.getDescriptionStyle(
                                      context,
                                    ),
                                    fontScale,
                                  ).copyWith(color: colors.description),
                                  maxLines: lineNumbers['description'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (widget.description != null)
                              SizedBox(height: gap),

                            // Actions
                            if (widget.actions != null &&
                                widget.actions!.isNotEmpty)
                              Wrap(
                                spacing: gap * 0.5,
                                runSpacing: gap * 0.5,
                                children: widget.actions!,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 카드 너비에 따른 이미지 비율 동적 계산
  ///
  /// - 콘텐츠 영역이 minContentWidth 이상이면 원래 비율 사용
  /// - 콘텐츠 영역이 부족하면 이미지 비율 축소
  /// - 이미지 비율이 0.2 미만이면 이미지 숨김 (0 반환)
  double _calculateImageRatio(
    double cardWidth,
    double padding,
    double requestedRatio,
    double minContentWidth,
  ) {
    // 콘텐츠 영역 = 카드너비 × (1 - 이미지비율) - 패딩×2
    final contentWidth = cardWidth * (1 - requestedRatio) - (padding * 2);

    if (contentWidth >= minContentWidth) {
      // 충분한 공간 있음 → 원래 비율 사용
      return requestedRatio;
    }

    // 최소 콘텐츠 너비 확보를 위해 이미지 비율 역계산
    // minContentWidth = cardWidth × (1 - ratio) - padding×2
    // ratio = 1 - (minContentWidth + padding×2) / cardWidth
    final adjustedRatio = 1 - (minContentWidth + padding * 2) / cardWidth;

    // 이미지 비율이 너무 작으면 숨김
    if (adjustedRatio < 0.2) {
      return 0;
    }

    return adjustedRatio.clamp(0.2, requestedRatio);
  }

  /// 카드 너비 기반 폰트 스케일 계산
  ///
  /// 기준 너비(400px)에서 1.0, 그보다 작으면 비례 축소
  /// 최소 0.7, 최대 1.0으로 제한
  double _calculateFontScale(double cardWidth) {
    final scale = cardWidth / _referenceCardWidth;
    return scale.clamp(_minFontScale, _maxFontScale);
  }

  /// 스케일이 적용된 패딩 계산
  double _scaledPadding(double cardWidth, double screenWidth) {
    final basePadding = ResponsiveTokens.cardPadding(screenWidth);
    final scale = _calculateFontScale(cardWidth);
    return basePadding * scale;
  }

  /// 스케일이 적용된 간격 계산
  double _scaledGap(double cardWidth, double screenWidth) {
    final baseGap = ResponsiveTokens.cardGap(screenWidth);
    final scale = _calculateFontScale(cardWidth);
    return baseGap * scale;
  }

  /// 스케일이 적용된 텍스트 스타일 반환
  TextStyle _scaledTextStyle(TextStyle baseStyle, double scale) {
    final fontSize = baseStyle.fontSize ?? 14.0;
    return baseStyle.copyWith(
      fontSize: fontSize * scale,
    );
  }
}
