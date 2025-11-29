import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/resizable_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppResizeDirection;

/// 리사이즈 가능한 컨테이너
///
/// **용도**: 패널 크기 조절, 분할 뷰
/// **접근성**: 키보드 조작 지원
///
/// ```dart
/// // 가로 방향 리사이즈
/// AppResizable(
///   direction: AppResizeDirection.horizontal,
///   initialSize: 300,
///   child: SidePanel(),
/// )
///
/// // 최소/최대 크기 제한
/// AppResizable(
///   direction: AppResizeDirection.vertical,
///   initialSize: 200,
///   minSize: 100,
///   maxSize: 400,
///   child: BottomPanel(),
/// )
/// ```
class AppResizable extends StatefulWidget {
  /// 자식 위젯
  final Widget child;

  /// 리사이즈 방향
  final AppResizeDirection direction;

  /// 초기 크기
  final double initialSize;

  /// 최소 크기
  final double minSize;

  /// 최대 크기
  final double maxSize;

  /// 핸들 크기
  final double handleSize;

  /// 크기 변경 콜백
  final ValueChanged<double>? onResize;

  /// 리사이즈 시작 콜백
  final VoidCallback? onResizeStart;

  /// 리사이즈 종료 콜백
  final VoidCallback? onResizeEnd;

  /// 핸들 위치 (시작 또는 끝)
  final bool handleAtEnd;

  /// 커스텀 핸들 위젯
  final Widget? customHandle;

  const AppResizable({
    super.key,
    required this.child,
    this.direction = AppResizeDirection.horizontal,
    this.initialSize = 200,
    this.minSize = 100,
    this.maxSize = double.infinity,
    this.handleSize = 8,
    this.onResize,
    this.onResizeStart,
    this.onResizeEnd,
    this.handleAtEnd = true,
    this.customHandle,
  });

  @override
  State<AppResizable> createState() => _AppResizableState();
}

class _AppResizableState extends State<AppResizable> {
  late double _size;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _size = widget.initialSize.clamp(widget.minSize, widget.maxSize);
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
    widget.onResizeStart?.call();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      double delta;
      if (widget.direction == AppResizeDirection.horizontal ||
          widget.direction == AppResizeDirection.both) {
        delta = widget.handleAtEnd ? details.delta.dx : -details.delta.dx;
      } else {
        delta = widget.handleAtEnd ? details.delta.dy : -details.delta.dy;
      }

      _size = (_size + delta).clamp(widget.minSize, widget.maxSize);
    });
    widget.onResize?.call(_size);
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    widget.onResizeEnd?.call();
  }

  MouseCursor get _cursor {
    return switch (widget.direction) {
      AppResizeDirection.horizontal => SystemMouseCursors.resizeColumn,
      AppResizeDirection.vertical => SystemMouseCursors.resizeRow,
      AppResizeDirection.both => SystemMouseCursors.move,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = ResizableColors.from(colorExt);

    final handle = widget.customHandle ??
        _ResizeHandle(
          direction: widget.direction,
          size: widget.handleSize,
          colors: colors,
          isDragging: _isDragging,
        );

    final handleWidget = GestureDetector(
      onHorizontalDragStart:
          widget.direction != AppResizeDirection.vertical
              ? _handleDragStart
              : null,
      onHorizontalDragUpdate:
          widget.direction != AppResizeDirection.vertical
              ? _handleDragUpdate
              : null,
      onHorizontalDragEnd:
          widget.direction != AppResizeDirection.vertical
              ? _handleDragEnd
              : null,
      onVerticalDragStart:
          widget.direction != AppResizeDirection.horizontal
              ? _handleDragStart
              : null,
      onVerticalDragUpdate:
          widget.direction != AppResizeDirection.horizontal
              ? _handleDragUpdate
              : null,
      onVerticalDragEnd:
          widget.direction != AppResizeDirection.horizontal
              ? _handleDragEnd
              : null,
      child: MouseRegion(
        cursor: _cursor,
        child: handle,
      ),
    );

    if (widget.direction == AppResizeDirection.horizontal ||
        widget.direction == AppResizeDirection.both) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.handleAtEnd
            ? [
                SizedBox(width: _size, child: widget.child),
                handleWidget,
              ]
            : [
                handleWidget,
                SizedBox(width: _size, child: widget.child),
              ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.handleAtEnd
            ? [
                SizedBox(height: _size, child: widget.child),
                handleWidget,
              ]
            : [
                handleWidget,
                SizedBox(height: _size, child: widget.child),
              ],
      );
    }
  }
}

/// 리사이즈 핸들
class _ResizeHandle extends StatefulWidget {
  final AppResizeDirection direction;
  final double size;
  final ResizableColors colors;
  final bool isDragging;

  const _ResizeHandle({
    required this.direction,
    required this.size,
    required this.colors,
    required this.isDragging,
  });

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _isHovered = false;

  Color get _backgroundColor {
    if (widget.isDragging) return widget.colors.handleBackgroundDrag;
    if (_isHovered) return widget.colors.handleBackgroundHover;
    return widget.colors.handleBackground;
  }

  Color get _gripColor {
    if (widget.isDragging || _isHovered) return widget.colors.handleGripHover;
    return widget.colors.handleGrip;
  }

  @override
  Widget build(BuildContext context) {
    final isHorizontal = widget.direction == AppResizeDirection.horizontal ||
        widget.direction == AppResizeDirection.both;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AnimationTokens.durationQuick,
        width: isHorizontal ? widget.size : double.infinity,
        height: isHorizontal ? double.infinity : widget.size,
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border(
            left: isHorizontal
                ? BorderSide(
                    color: widget.colors.border,
                    width: BorderTokens.widthThin,
                  )
                : BorderSide.none,
            top: !isHorizontal
                ? BorderSide(
                    color: widget.colors.border,
                    width: BorderTokens.widthThin,
                  )
                : BorderSide.none,
          ),
        ),
        child: Center(
          child: _GripIndicator(
            direction: widget.direction,
            color: _gripColor,
          ),
        ),
      ),
    );
  }
}

/// 그립 인디케이터
class _GripIndicator extends StatelessWidget {
  final AppResizeDirection direction;
  final Color color;

  const _GripIndicator({
    required this.direction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isHorizontal = direction == AppResizeDirection.horizontal ||
        direction == AppResizeDirection.both;

    return isHorizontal
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (index) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (index) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
  }
}

/// 분할 패널 (2개의 리사이즈 가능한 패널)
class AppSplitPanel extends StatefulWidget {
  /// 첫 번째 패널
  final Widget firstChild;

  /// 두 번째 패널
  final Widget secondChild;

  /// 분할 방향
  final AppResizeDirection direction;

  /// 초기 분할 비율 (0.0 ~ 1.0)
  final double initialRatio;

  /// 최소 비율
  final double minRatio;

  /// 최대 비율
  final double maxRatio;

  /// 핸들 크기
  final double handleSize;

  /// 비율 변경 콜백
  final ValueChanged<double>? onRatioChanged;

  const AppSplitPanel({
    super.key,
    required this.firstChild,
    required this.secondChild,
    this.direction = AppResizeDirection.horizontal,
    this.initialRatio = 0.5,
    this.minRatio = 0.2,
    this.maxRatio = 0.8,
    this.handleSize = 8,
    this.onRatioChanged,
  });

  @override
  State<AppSplitPanel> createState() => _AppSplitPanelState();
}

class _AppSplitPanelState extends State<AppSplitPanel> {
  late double _ratio;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio.clamp(widget.minRatio, widget.maxRatio);
  }

  void _handleDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      final totalSize = widget.direction == AppResizeDirection.horizontal
          ? constraints.maxWidth
          : constraints.maxHeight;

      final delta = widget.direction == AppResizeDirection.horizontal
          ? details.delta.dx
          : details.delta.dy;

      _ratio = (_ratio + delta / totalSize).clamp(widget.minRatio, widget.maxRatio);
    });
    widget.onRatioChanged?.call(_ratio);
  }

  MouseCursor get _cursor {
    return widget.direction == AppResizeDirection.horizontal
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = ResizableColors.from(colorExt);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = widget.direction == AppResizeDirection.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;

        final firstSize = totalSize * _ratio - widget.handleSize / 2;
        final secondSize = totalSize * (1 - _ratio) - widget.handleSize / 2;

        final handle = GestureDetector(
          onHorizontalDragStart:
              widget.direction == AppResizeDirection.horizontal
                  ? (_) => setState(() => _isDragging = true)
                  : null,
          onHorizontalDragUpdate:
              widget.direction == AppResizeDirection.horizontal
                  ? (d) => _handleDragUpdate(d, constraints)
                  : null,
          onHorizontalDragEnd:
              widget.direction == AppResizeDirection.horizontal
                  ? (_) => setState(() => _isDragging = false)
                  : null,
          onVerticalDragStart:
              widget.direction == AppResizeDirection.vertical
                  ? (_) => setState(() => _isDragging = true)
                  : null,
          onVerticalDragUpdate:
              widget.direction == AppResizeDirection.vertical
                  ? (d) => _handleDragUpdate(d, constraints)
                  : null,
          onVerticalDragEnd: widget.direction == AppResizeDirection.vertical
              ? (_) => setState(() => _isDragging = false)
              : null,
          child: MouseRegion(
            cursor: _cursor,
            child: _ResizeHandle(
              direction: widget.direction,
              size: widget.handleSize,
              colors: colors,
              isDragging: _isDragging,
            ),
          ),
        );

        if (widget.direction == AppResizeDirection.horizontal) {
          return Row(
            children: [
              SizedBox(width: firstSize, child: widget.firstChild),
              handle,
              SizedBox(width: secondSize, child: widget.secondChild),
            ],
          );
        } else {
          return Column(
            children: [
              SizedBox(height: firstSize, child: widget.firstChild),
              handle,
              SizedBox(height: secondSize, child: widget.secondChild),
            ],
          );
        }
      },
    );
  }
}
