import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/image_gallery_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppImageGalleryLayout;

/// 이미지 갤러리 컴포넌트
///
/// **용도**: 이미지 그리드, 라이트박스, 미디어 브라우저
/// **접근성**: 키보드 네비게이션, ARIA 지원
///
/// ```dart
/// // 기본 그리드
/// AppImageGallery(
///   images: [
///     AppGalleryImage(url: 'image1.jpg'),
///     AppGalleryImage(url: 'image2.jpg'),
///   ],
/// )
///
/// // 라이트박스 활성화
/// AppImageGallery(
///   images: images,
///   enableLightbox: true,
/// )
/// ```
class AppImageGallery extends StatefulWidget {
  /// 이미지 목록
  final List<AppGalleryImage> images;

  /// 레이아웃
  final AppImageGalleryLayout layout;

  /// 그리드 열 수
  final int crossAxisCount;

  /// 간격
  final double spacing;

  /// 라이트박스 활성화
  final bool enableLightbox;

  /// 이미지 비율
  final double aspectRatio;

  /// 이미지 클릭 콜백
  final ValueChanged<int>? onImageTap;

  /// 에러 위젯 빌더
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  /// 로딩 위젯 빌더
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const AppImageGallery({
    super.key,
    required this.images,
    this.layout = AppImageGalleryLayout.grid,
    this.crossAxisCount = 3,
    this.spacing = 8.0,
    this.enableLightbox = true,
    this.aspectRatio = 1.0,
    this.onImageTap,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  State<AppImageGallery> createState() => _AppImageGalleryState();
}

class _AppImageGalleryState extends State<AppImageGallery> {
  void _openLightbox(int index) {
    if (widget.enableLightbox) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return _Lightbox(
              images: widget.images,
              initialIndex: index,
              animation: animation,
            );
          },
        ),
      );
    }
    widget.onImageTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = ImageGalleryColors.from(colorExt);

    if (widget.layout == AppImageGalleryLayout.carousel) {
      return _CarouselLayout(
        images: widget.images,
        colors: colors,
        aspectRatio: widget.aspectRatio,
        enableLightbox: widget.enableLightbox,
        onImageTap: _openLightbox,
        errorBuilder: widget.errorBuilder,
        loadingBuilder: widget.loadingBuilder,
      );
    }

    // LayoutBuilder를 사용하여 부모 크기 기반으로 높이 계산
    return LayoutBuilder(
      builder: (context, constraints) {
        // 부모 너비 기반으로 각 아이템 크기 계산
        final availableWidth = constraints.maxWidth;
        final totalSpacing = widget.spacing * (widget.crossAxisCount - 1);
        final itemWidth =
            (availableWidth - totalSpacing) / widget.crossAxisCount;
        final itemHeight = itemWidth / widget.aspectRatio;

        // 그리드의 행 수 계산
        final rowCount = (widget.images.length / widget.crossAxisCount).ceil();
        final totalHeight =
            rowCount * itemHeight + (rowCount - 1) * widget.spacing;

        return SizedBox(
          height: totalHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              crossAxisSpacing: widget.spacing,
              mainAxisSpacing: widget.spacing,
              childAspectRatio: widget.aspectRatio,
            ),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return _GalleryItem(
                image: widget.images[index],
                colors: colors,
                onTap: () => _openLightbox(index),
                errorBuilder: widget.errorBuilder,
                loadingBuilder: widget.loadingBuilder,
              );
            },
          ),
        );
      },
    );
  }
}

/// 갤러리 아이템
class _GalleryItem extends StatefulWidget {
  final AppGalleryImage image;
  final ImageGalleryColors colors;
  final VoidCallback onTap;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const _GalleryItem({
    required this.image,
    required this.colors,
    required this.onTap,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  State<_GalleryItem> createState() => _GalleryItemState();
}

class _GalleryItemState extends State<_GalleryItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
            border: Border.all(
              color: widget.colors.border,
              width: BorderTokens.widthThin,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(),
              if (_isHovered)
                Container(
                  color: widget.colors.overlay,
                  child: Center(
                    child: Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: ComponentSizeTokens.iconLarge,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.image.url.startsWith('http')) {
      return Image.network(
        widget.image.url,
        fit: BoxFit.cover,
        errorBuilder: widget.errorBuilder ?? _defaultErrorBuilder,
        loadingBuilder: widget.loadingBuilder ?? _defaultLoadingBuilder,
      );
    }
    return Image.asset(
      widget.image.url,
      fit: BoxFit.cover,
      errorBuilder: widget.errorBuilder ?? _defaultErrorBuilder,
    );
  }

  Widget _defaultErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stack,
  ) {
    return Container(
      color: widget.colors.imageBackground,
      child: Icon(
        Icons.broken_image_outlined,
        color: widget.colors.captionText.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _defaultLoadingBuilder(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    if (loadingProgress == null) return child;
    return Container(
      color: widget.colors.imageBackground,
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }
}

/// 캐러셀 레이아웃
class _CarouselLayout extends StatefulWidget {
  final List<AppGalleryImage> images;
  final ImageGalleryColors colors;
  final double aspectRatio;
  final bool enableLightbox;
  final ValueChanged<int> onImageTap;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const _CarouselLayout({
    required this.images,
    required this.colors,
    required this.aspectRatio,
    required this.enableLightbox,
    required this.onImageTap,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  State<_CarouselLayout> createState() => _CarouselLayoutState();
}

class _CarouselLayoutState extends State<_CarouselLayout> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: spacingExt.small),
                child: _GalleryItem(
                  image: widget.images[index],
                  colors: widget.colors,
                  onTap: () => widget.onImageTap(index),
                  errorBuilder: widget.errorBuilder,
                  loadingBuilder: widget.loadingBuilder,
                ),
              );
            },
          ),
        ),
        SizedBox(height: spacingExt.medium),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (index) {
            return AnimatedContainer(
              duration: AnimationTokens.durationQuick,
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: index == _currentPage ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == _currentPage
                    ? widget.colors.indicatorActive
                    : widget.colors.indicatorInactive,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// 라이트박스
class _Lightbox extends StatefulWidget {
  final List<AppGalleryImage> images;
  final int initialIndex;
  final Animation<double> animation;

  const _Lightbox({
    required this.images,
    required this.initialIndex,
    required this.animation,
  });

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: AnimationTokens.durationSmooth,
        curve: AnimationTokens.curveSmooth,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: AnimationTokens.durationSmooth,
        curve: AnimationTokens.curveSmooth,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = ImageGalleryColors.from(colorExt);
    final spacingExt = context.appSpacing;

    return FadeTransition(
      opacity: widget.animation,
      child: Material(
        color: colors.lightboxBackground,
        child: Stack(
          children: [
            // 이미지 뷰어
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final image = widget.images[index];
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: image.url.startsWith('http')
                        ? Image.network(image.url, fit: BoxFit.contain)
                        : Image.asset(image.url, fit: BoxFit.contain),
                  ),
                );
              },
            ),

            // 닫기 버튼
            Positioned(
              top: spacingExt.large,
              right: spacingExt.large,
              child: _LightboxButton(
                icon: Icons.close,
                colors: colors,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // 이전 버튼
            if (_currentIndex > 0)
              Positioned(
                left: spacingExt.large,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _LightboxButton(
                    icon: Icons.chevron_left,
                    colors: colors,
                    onPressed: _goToPrevious,
                  ),
                ),
              ),

            // 다음 버튼
            if (_currentIndex < widget.images.length - 1)
              Positioned(
                right: spacingExt.large,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _LightboxButton(
                    icon: Icons.chevron_right,
                    colors: colors,
                    onPressed: _goToNext,
                  ),
                ),
              ),

            // 인디케이터
            Positioned(
              bottom: spacingExt.large,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacingExt.medium,
                    vertical: spacingExt.small,
                  ),
                  decoration: BoxDecoration(
                    color: colors.captionBackground,
                    borderRadius: BorderRadius.circular(
                      BorderTokens.radiusMedium,
                    ),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colors.captionText),
                  ),
                ),
              ),
            ),

            // 캡션
            if (widget.images[_currentIndex].caption != null)
              Positioned(
                bottom: spacingExt.large + 48,
                left: spacingExt.large,
                right: spacingExt.large,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacingExt.medium,
                      vertical: spacingExt.small,
                    ),
                    decoration: BoxDecoration(
                      color: colors.captionBackground,
                      borderRadius: BorderRadius.circular(
                        BorderTokens.radiusMedium,
                      ),
                    ),
                    child: Text(
                      widget.images[_currentIndex].caption!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.captionText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 라이트박스 버튼
class _LightboxButton extends StatefulWidget {
  final IconData icon;
  final ImageGalleryColors colors;
  final VoidCallback onPressed;

  const _LightboxButton({
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  @override
  State<_LightboxButton> createState() => _LightboxButtonState();
}

class _LightboxButtonState extends State<_LightboxButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.colors.captionBackground
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: _isHovered
                ? widget.colors.lightboxControlHover
                : widget.colors.lightboxControl,
            size: ComponentSizeTokens.iconLarge,
          ),
        ),
      ),
    );
  }
}

/// 갤러리 이미지 데이터
class AppGalleryImage {
  /// 이미지 URL
  final String url;

  /// 썸네일 URL (옵션)
  final String? thumbnailUrl;

  /// 캡션
  final String? caption;

  /// 메타데이터
  final Map<String, dynamic>? metadata;

  const AppGalleryImage({
    required this.url,
    this.thumbnailUrl,
    this.caption,
    this.metadata,
  });
}
