import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/sheet_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppSheetPosition, AppSheetSize;

/// 시트 (사이드 패널) 컴포넌트
///
/// **용도**: 상세 정보, 편집 패널, 필터 패널
/// **접근성**: 포커스 트랩, ESC 키로 닫기
///
/// ```dart
/// // 우측 시트
/// showAppSheet(
///   context: context,
///   title: '상세 정보',
///   child: DetailContent(),
/// )
///
/// // 좌측 시트 (큰 크기)
/// showAppSheet(
///   context: context,
///   position: AppSheetPosition.left,
///   size: AppSheetSize.large,
///   title: '편집',
///   child: EditForm(),
/// )
/// ```
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  AppSheetPosition position = AppSheetPosition.right,
  AppSheetSize size = AppSheetSize.medium,
  bool showCloseButton = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: '시트 닫기',
    barrierColor: Colors.transparent,
    transitionDuration: AnimationTokens.durationSmooth,
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AppSheetDialog(
        title: title,
        position: position,
        size: size,
        showCloseButton: showCloseButton,
        isDismissible: isDismissible,
        animation: animation,
        child: child,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

class _AppSheetDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final AppSheetPosition position;
  final AppSheetSize size;
  final bool showCloseButton;
  final bool isDismissible;
  final Animation<double> animation;

  const _AppSheetDialog({
    required this.child,
    required this.animation,
    this.title,
    this.position = AppSheetPosition.right,
    this.size = AppSheetSize.medium,
    this.showCloseButton = true,
    this.isDismissible = true,
  });

  double _getWidth(double screenWidth) {
    final maxWidth = switch (size) {
      AppSheetSize.small => 320.0,
      AppSheetSize.medium => 480.0,
      AppSheetSize.large => 640.0,
      AppSheetSize.full => screenWidth,
    };
    return maxWidth.clamp(0, screenWidth);
  }

  double _getHeight(double screenHeight) {
    final maxHeight = switch (size) {
      AppSheetSize.small => 320.0,
      AppSheetSize.medium => 480.0,
      AppSheetSize.large => 640.0,
      AppSheetSize.full => screenHeight,
    };
    return maxHeight.clamp(0, screenHeight);
  }

  Offset _getSlideOffset() {
    return switch (position) {
      AppSheetPosition.right => const Offset(1, 0),
      AppSheetPosition.left => const Offset(-1, 0),
      AppSheetPosition.top => const Offset(0, -1),
      AppSheetPosition.bottom => const Offset(0, 1),
    };
  }

  Alignment _getAlignment() {
    return switch (position) {
      AppSheetPosition.right => Alignment.centerRight,
      AppSheetPosition.left => Alignment.centerLeft,
      AppSheetPosition.top => Alignment.topCenter,
      AppSheetPosition.bottom => Alignment.bottomCenter,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = SheetColors.from(colorExt);
    final screenSize = MediaQuery.sizeOf(context);
    final isHorizontal =
        position == AppSheetPosition.left || position == AppSheetPosition.right;

    final slideAnimation =
        Tween<Offset>(begin: _getSlideOffset(), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: AnimationTokens.curveSmooth,
          ),
        );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: AnimationTokens.curveDefault),
    );

    return Stack(
      children: [
        // 오버레이
        GestureDetector(
          onTap: isDismissible ? () => Navigator.of(context).pop() : null,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Container(color: colors.overlay),
          ),
        ),

        // 시트
        Align(
          alignment: _getAlignment(),
          child: SlideTransition(
            position: slideAnimation,
            child: Container(
              width: isHorizontal
                  ? _getWidth(screenSize.width)
                  : screenSize.width,
              height: isHorizontal
                  ? screenSize.height
                  : _getHeight(screenSize.height),
              decoration: BoxDecoration(
                color: colors.background,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 24,
                    offset: _getShadowOffset(),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null || showCloseButton)
                    _SheetHeader(
                      title: title,
                      showCloseButton: showCloseButton,
                      colors: colors,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Offset _getShadowOffset() {
    return switch (position) {
      AppSheetPosition.right => const Offset(-8, 0),
      AppSheetPosition.left => const Offset(8, 0),
      AppSheetPosition.top => const Offset(0, 8),
      AppSheetPosition.bottom => const Offset(0, -8),
    };
  }
}

/// 시트 헤더
class _SheetHeader extends StatelessWidget {
  final String? title;
  final bool showCloseButton;
  final SheetColors colors;
  final VoidCallback onClose;

  const _SheetHeader({
    this.title,
    required this.showCloseButton,
    required this.colors,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Container(
      padding: EdgeInsets.all(spacingExt.medium),
      decoration: BoxDecoration(
        color: colors.headerBackground,
        border: Border(
          bottom: BorderSide(
            color: colors.headerBorder,
            width: BorderTokens.widthThin,
          ),
        ),
      ),
      child: Row(
        children: [
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.titleText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (showCloseButton) _CloseButton(colors: colors, onTap: onClose),
        ],
      ),
    );
  }
}

/// 닫기 버튼
class _CloseButton extends StatefulWidget {
  final SheetColors colors;
  final VoidCallback onTap;

  const _CloseButton({required this.colors, required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.colors.closeButtonBgHover
                : Colors.transparent,
            borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
          ),
          child: Icon(
            Icons.close,
            size: ComponentSizeTokens.iconSmall,
            color: _isHovered
                ? widget.colors.closeButtonHover
                : widget.colors.closeButton,
          ),
        ),
      ),
    );
  }
}
