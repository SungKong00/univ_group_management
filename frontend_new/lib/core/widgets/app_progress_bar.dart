import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/progress_bar_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppProgressBarStyle, AppProgressBarColor;

/// 진행률 표시 컴포넌트
///
/// **용도**: 파일 업로드, 다운로드 진행률, 프로세스 진행 표시
/// **접근성**: 스크린 리더에 진행률 안내
///
/// ```dart
/// // 기본 선형 프로그레스바
/// AppProgressBar(
///   value: 0.65,
///   label: '업로드 중...',
/// )
///
/// // 원형 프로그레스바
/// AppProgressBar.circular(
///   value: 0.75,
///   showPercentage: true,
/// )
///
/// // 불확정 프로그레스바
/// AppProgressBar(
///   isIndeterminate: true,
/// )
/// ```
class AppProgressBar extends StatefulWidget {
  /// 진행률 (0.0 ~ 1.0)
  final double value;

  /// 프로그레스바 스타일
  final AppProgressBarStyle style;

  /// 프로그레스바 색상
  final AppProgressBarColor color;

  /// 라벨 텍스트
  final String? label;

  /// 퍼센트 표시 여부
  final bool showPercentage;

  /// 불확정 상태 (무한 로딩)
  final bool isIndeterminate;

  /// 높이 (linear 스타일용)
  final double height;

  /// 크기 (circular 스타일용)
  final double size;

  /// 스트로크 두께 (circular 스타일용)
  final double strokeWidth;

  const AppProgressBar({
    super.key,
    this.value = 0,
    this.style = AppProgressBarStyle.linear,
    this.color = AppProgressBarColor.brand,
    this.label,
    this.showPercentage = false,
    this.isIndeterminate = false,
    this.height = 8,
    this.size = 48,
    this.strokeWidth = 4,
  });

  /// 원형 프로그레스바 팩토리
  factory AppProgressBar.circular({
    Key? key,
    double value = 0,
    AppProgressBarColor color = AppProgressBarColor.brand,
    String? label,
    bool showPercentage = false,
    bool isIndeterminate = false,
    double size = 48,
    double strokeWidth = 4,
  }) {
    return AppProgressBar(
      key: key,
      value: value,
      style: AppProgressBarStyle.circular,
      color: color,
      label: label,
      showPercentage: showPercentage,
      isIndeterminate: isIndeterminate,
      size: size,
      strokeWidth: strokeWidth,
    );
  }

  /// 반원형 프로그레스바 팩토리
  factory AppProgressBar.semicircular({
    Key? key,
    double value = 0,
    AppProgressBarColor color = AppProgressBarColor.brand,
    String? label,
    bool showPercentage = false,
    double size = 120,
    double strokeWidth = 8,
  }) {
    return AppProgressBar(
      key: key,
      value: value,
      style: AppProgressBarStyle.semicircular,
      color: color,
      label: label,
      showPercentage: showPercentage,
      size: size,
      strokeWidth: strokeWidth,
    );
  }

  @override
  State<AppProgressBar> createState() => _AppProgressBarState();
}

class _AppProgressBarState extends State<AppProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.isIndeterminate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AppProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isIndeterminate != oldWidget.isIndeterminate) {
      if (widget.isIndeterminate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = ProgressBarColors.from(colorExt, widget.color);

    final percentage = (widget.value * 100).round();

    return Semantics(
      label: '진행률 $percentage%',
      value: '$percentage%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null &&
              widget.style == AppProgressBarStyle.linear) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label!,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.showPercentage)
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            SizedBox(height: spacingExt.xs),
          ],
          switch (widget.style) {
            AppProgressBarStyle.linear => _buildLinear(colors),
            AppProgressBarStyle.circular => _buildCircular(colors),
            AppProgressBarStyle.semicircular => _buildSemicircular(
              colors,
              spacingExt,
            ),
          },
        ],
      ),
    );
  }

  Widget _buildLinear(ProgressBarColors colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height / 2),
      child: SizedBox(
        height: widget.height,
        child: widget.isIndeterminate
            ? AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Container(color: colors.trackBackground),
                      Positioned(
                        left: -0.5 + _controller.value * 1.5,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors.progressFill.withValues(alpha: 0),
                                  colors.progressFill,
                                  colors.progressFill.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            : Stack(
                children: [
                  Container(color: colors.trackBackground),
                  AnimatedFractionallySizedBox(
                    duration: AnimationTokens.durationSmooth,
                    widthFactor: widget.value.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.progressFill,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCircular(ProgressBarColors colors) {
    final percentage = (widget.value * 100).round();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.isIndeterminate
              ? AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _controller.value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _CircularProgressPainter(
                          progress: 0.25,
                          trackColor: colors.trackBackground,
                          progressColor: colors.progressFill,
                          strokeWidth: widget.strokeWidth,
                        ),
                      ),
                    );
                  },
                )
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.value),
                  duration: AnimationTokens.durationSmooth,
                  builder: (context, value, child) {
                    return CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _CircularProgressPainter(
                        progress: value.clamp(0.0, 1.0),
                        trackColor: colors.trackBackground,
                        progressColor: colors.progressFill,
                        strokeWidth: widget.strokeWidth,
                      ),
                    );
                  },
                ),
          if (widget.showPercentage && !widget.isIndeterminate)
            Text(
              '$percentage%',
              style: TextStyle(
                color: colors.text,
                fontSize: widget.size * 0.25,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSemicircular(
    ProgressBarColors colors,
    AppSpacingExtension spacing,
  ) {
    final percentage = (widget.value * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size / 2 + widget.strokeWidth,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: widget.value),
            duration: AnimationTokens.durationSmooth,
            builder: (context, value, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size / 2 + widget.strokeWidth),
                painter: _SemicircularProgressPainter(
                  progress: value.clamp(0.0, 1.0),
                  trackColor: colors.trackBackground,
                  progressColor: colors.progressFill,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
        ),
        if (widget.showPercentage || widget.label != null) ...[
          SizedBox(height: spacing.xs),
          if (widget.showPercentage)
            Text(
              '$percentage%',
              style: TextStyle(
                color: colors.text,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (widget.label != null)
            Text(
              widget.label!,
              style: TextStyle(color: colors.text, fontSize: 12),
            ),
        ],
      ],
    );
  }
}

/// 원형 프로그레스 페인터
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 트랙
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 진행
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 반원형 프로그레스 페인터
class _SemicircularProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _SemicircularProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = (size.width - strokeWidth) / 2;

    // 트랙
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    // 진행
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SemicircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
