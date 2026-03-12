import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/carousel_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/component_size_tokens.dart';

/// Linear 스타일 수평 스크롤 Carousel
///
/// 특징:
/// - 수평 스크롤 + 스크롤 네비게이션 버튼
/// - smooth scroll behavior
/// - 시작/끝 지점에서 버튼 비활성화
class AppCarousel extends StatefulWidget {
  final List<Widget> items;
  final double itemWidth;
  final double gap;
  final bool showNavigation;
  final EdgeInsets? padding;

  const AppCarousel({
    super.key,
    required this.items,
    this.itemWidth = 300,
    this.gap = 16,
    this.showNavigation = true,
    this.padding,
  });

  @override
  State<AppCarousel> createState() => _AppCarouselState();
}

class _AppCarouselState extends State<AppCarousel> {
  late ScrollController _scrollController;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollButtons);

    // 초기 상태 설정 (다음 프레임에서)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollButtons();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!mounted) return;

    final position = _scrollController.position;
    setState(() {
      _canScrollLeft = position.pixels > 0;
      _canScrollRight = position.pixels < position.maxScrollExtent;
    });
  }

  void _scrollLeft() {
    final targetPosition =
        (_scrollController.offset - widget.itemWidth - widget.gap).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );

    _scrollController.animateTo(
      targetPosition,
      duration: AnimationTokens.durationSmooth,
      curve: AnimationTokens.curveDefault,
    );
  }

  void _scrollRight() {
    final targetPosition =
        (_scrollController.offset + widget.itemWidth + widget.gap).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );

    _scrollController.animateTo(
      targetPosition,
      duration: AnimationTokens.durationSmooth,
      curve: AnimationTokens.curveDefault,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Stack(
      children: [
        // 스크롤 가능한 아이템 리스트
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding:
              widget.padding ??
              EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
          child: Row(
            children: [
              for (int i = 0; i < widget.items.length; i++) ...[
                SizedBox(width: widget.itemWidth, child: widget.items[i]),
                if (i < widget.items.length - 1) SizedBox(width: widget.gap),
              ],
            ],
          ),
        ),

        // 네비게이션 버튼들
        if (widget.showNavigation) ...[
          // 왼쪽 버튼
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavButton(
                icon: Icons.arrow_back,
                onPressed: _canScrollLeft ? _scrollLeft : null,
              ),
            ),
          ),

          // 오른쪽 버튼
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavButton(
                icon: Icons.arrow_forward,
                onPressed: _canScrollRight ? _scrollRight : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavButton({required this.icon, this.onPressed});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final carouselColors = CarouselColors.standard(colorExt);
    final isEnabled = widget.onPressed != null;
    final opacity = isEnabled ? (_isHovered ? 1.0 : 0.7) : 0.3;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedOpacity(
        duration: AnimationTokens.durationQuick,
        opacity: opacity,
        child: Material(
          color: carouselColors.navButtonBackground,
          borderRadius: BorderTokens.roundRadius(),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderTokens.roundRadius(),
            child: Container(
              width: ComponentSizeTokens.boxSmall,
              height: ComponentSizeTokens.boxSmall,
              decoration: BoxDecoration(
                borderRadius: BorderTokens.roundRadius(),
                border: Border.all(color: colorExt.borderPrimary, width: 1),
              ),
              child: Icon(
                widget.icon,
                size: ComponentSizeTokens.iconSmall,
                color: carouselColors.navButtonIcon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
