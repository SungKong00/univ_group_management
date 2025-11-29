import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/chart_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppChartType;

/// 차트 컴포넌트
///
/// **용도**: 데이터 시각화, 통계 표시
/// **접근성**: Semantics 지원
///
/// ```dart
/// // 라인 차트
/// AppChart(
///   type: AppChartType.line,
///   data: [
///     ChartSeries(
///       name: '매출',
///       values: [100, 150, 200, 180, 220],
///     ),
///   ],
///   labels: ['1월', '2월', '3월', '4월', '5월'],
/// )
///
/// // 바 차트
/// AppChart(
///   type: AppChartType.bar,
///   data: [
///     ChartSeries(name: '2023', values: [30, 50, 40]),
///     ChartSeries(name: '2024', values: [45, 60, 55]),
///   ],
///   labels: ['Q1', 'Q2', 'Q3'],
///   showLegend: true,
/// )
///
/// // 파이 차트
/// AppChart(
///   type: AppChartType.pie,
///   data: [
///     ChartSeries(name: '카테고리', values: [40, 30, 20, 10]),
///   ],
///   labels: ['A', 'B', 'C', 'D'],
/// )
/// ```
class AppChart extends StatefulWidget {
  /// 차트 타입
  final AppChartType type;

  /// 데이터 시리즈
  final List<ChartSeries> data;

  /// X축 레이블
  final List<String> labels;

  /// 차트 높이
  final double height;

  /// 범례 표시 여부
  final bool showLegend;

  /// 그리드 표시 여부
  final bool showGrid;

  /// 값 레이블 표시 여부
  final bool showValues;

  /// 툴팁 표시 여부
  final bool showTooltip;

  /// Y축 최소값 (null이면 자동)
  final double? minY;

  /// Y축 최대값 (null이면 자동)
  final double? maxY;

  /// 애니메이션 사용 여부
  final bool animate;

  /// 애니메이션 시간
  final Duration animationDuration;

  const AppChart({
    super.key,
    required this.type,
    required this.data,
    required this.labels,
    this.height = 300,
    this.showLegend = false,
    this.showGrid = true,
    this.showValues = false,
    this.showTooltip = true,
    this.minY,
    this.maxY,
    this.animate = true,
    this.animationDuration = AnimationTokens.durationSmooth,
  });

  @override
  State<AppChart> createState() => _AppChartState();
}

class _AppChartState extends State<AppChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _hoveredIndex;
  int? _hoveredSeriesIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: AnimationTokens.curveDefault,
    );

    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = ChartColors.from(colorExt);

    return Semantics(
      label: '${widget.type.name} 차트',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: widget.height,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return switch (widget.type) {
                  AppChartType.line => _LineChart(
                      data: widget.data,
                      labels: widget.labels,
                      colors: colors,
                      showGrid: widget.showGrid,
                      showValues: widget.showValues,
                      animationValue: _animation.value,
                      minY: widget.minY,
                      maxY: widget.maxY,
                      hoveredIndex: _hoveredIndex,
                      hoveredSeriesIndex: _hoveredSeriesIndex,
                      onHover: widget.showTooltip
                          ? (index, seriesIndex) {
                              setState(() {
                                _hoveredIndex = index;
                                _hoveredSeriesIndex = seriesIndex;
                              });
                            }
                          : null,
                      onHoverExit: widget.showTooltip
                          ? () {
                              setState(() {
                                _hoveredIndex = null;
                                _hoveredSeriesIndex = null;
                              });
                            }
                          : null,
                    ),
                  AppChartType.bar => _BarChart(
                      data: widget.data,
                      labels: widget.labels,
                      colors: colors,
                      showGrid: widget.showGrid,
                      showValues: widget.showValues,
                      animationValue: _animation.value,
                      minY: widget.minY,
                      maxY: widget.maxY,
                      hoveredIndex: _hoveredIndex,
                      hoveredSeriesIndex: _hoveredSeriesIndex,
                      onHover: widget.showTooltip
                          ? (index, seriesIndex) {
                              setState(() {
                                _hoveredIndex = index;
                                _hoveredSeriesIndex = seriesIndex;
                              });
                            }
                          : null,
                      onHoverExit: widget.showTooltip
                          ? () {
                              setState(() {
                                _hoveredIndex = null;
                                _hoveredSeriesIndex = null;
                              });
                            }
                          : null,
                    ),
                  AppChartType.pie ||
                  AppChartType.doughnut =>
                    _PieChart(
                      data: widget.data,
                      labels: widget.labels,
                      colors: colors,
                      isDoughnut: widget.type == AppChartType.doughnut,
                      showValues: widget.showValues,
                      animationValue: _animation.value,
                      hoveredIndex: _hoveredIndex,
                      onHover: widget.showTooltip
                          ? (index) {
                              setState(() {
                                _hoveredIndex = index;
                                _hoveredSeriesIndex = 0;
                              });
                            }
                          : null,
                      onHoverExit: widget.showTooltip
                          ? () {
                              setState(() {
                                _hoveredIndex = null;
                                _hoveredSeriesIndex = null;
                              });
                            }
                          : null,
                    ),
                  AppChartType.area => _AreaChart(
                      data: widget.data,
                      labels: widget.labels,
                      colors: colors,
                      showGrid: widget.showGrid,
                      showValues: widget.showValues,
                      animationValue: _animation.value,
                      minY: widget.minY,
                      maxY: widget.maxY,
                      hoveredIndex: _hoveredIndex,
                      hoveredSeriesIndex: _hoveredSeriesIndex,
                      onHover: widget.showTooltip
                          ? (index, seriesIndex) {
                              setState(() {
                                _hoveredIndex = index;
                                _hoveredSeriesIndex = seriesIndex;
                              });
                            }
                          : null,
                      onHoverExit: widget.showTooltip
                          ? () {
                              setState(() {
                                _hoveredIndex = null;
                                _hoveredSeriesIndex = null;
                              });
                            }
                          : null,
                    ),
                };
              },
            ),
          ),
          if (widget.showLegend) ...[
            SizedBox(height: spacingExt.medium),
            _ChartLegend(
              data: widget.data,
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }
}

/// 차트 데이터 시리즈
class ChartSeries {
  /// 시리즈 이름
  final String name;

  /// 데이터 값들
  final List<double> values;

  /// 커스텀 색상 (null이면 자동)
  final Color? color;

  const ChartSeries({
    required this.name,
    required this.values,
    this.color,
  });
}

/// 라인 차트
class _LineChart extends StatelessWidget {
  final List<ChartSeries> data;
  final List<String> labels;
  final ChartColors colors;
  final bool showGrid;
  final bool showValues;
  final double animationValue;
  final double? minY;
  final double? maxY;
  final int? hoveredIndex;
  final int? hoveredSeriesIndex;
  final void Function(int index, int seriesIndex)? onHover;
  final VoidCallback? onHoverExit;

  const _LineChart({
    required this.data,
    required this.labels,
    required this.colors,
    required this.showGrid,
    required this.showValues,
    required this.animationValue,
    this.minY,
    this.maxY,
    this.hoveredIndex,
    this.hoveredSeriesIndex,
    this.onHover,
    this.onHoverExit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _LineChartPainter(
            data: data,
            labels: labels,
            colors: colors,
            showGrid: showGrid,
            showValues: showValues,
            animationValue: animationValue,
            minY: minY,
            maxY: maxY,
            hoveredIndex: hoveredIndex,
            hoveredSeriesIndex: hoveredSeriesIndex,
          ),
          child: MouseRegion(
            onHover: (event) => _handleHover(event, constraints),
            onExit: (_) => onHoverExit?.call(),
          ),
        );
      },
    );
  }

  void _handleHover(PointerHoverEvent event, BoxConstraints constraints) {
    if (onHover == null || data.isEmpty) return;

    const leftPadding = 50.0;
    const rightPadding = 20.0;
    final chartWidth = constraints.maxWidth - leftPadding - rightPadding;
    final stepX = chartWidth / (labels.length - 1).clamp(1, double.infinity);

    final relativeX = event.localPosition.dx - leftPadding;
    final index = (relativeX / stepX).round().clamp(0, labels.length - 1);

    onHover!(index, 0);
  }
}

/// 라인 차트 페인터
class _LineChartPainter extends CustomPainter {
  final List<ChartSeries> data;
  final List<String> labels;
  final ChartColors colors;
  final bool showGrid;
  final bool showValues;
  final double animationValue;
  final double? minY;
  final double? maxY;
  final int? hoveredIndex;
  final int? hoveredSeriesIndex;

  _LineChartPainter({
    required this.data,
    required this.labels,
    required this.colors,
    required this.showGrid,
    required this.showValues,
    required this.animationValue,
    this.minY,
    this.maxY,
    this.hoveredIndex,
    this.hoveredSeriesIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const leftPadding = 50.0;
    const rightPadding = 20.0;
    const topPadding = 20.0;
    const bottomPadding = 40.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Calculate min/max values
    final allValues = data.expand((s) => s.values).toList();
    final dataMinY = allValues.isEmpty
        ? 0.0
        : allValues.reduce((a, b) => a < b ? a : b);
    final dataMaxY = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final effectiveMinY = minY ?? (dataMinY * 0.9);
    final effectiveMaxY = maxY ?? (dataMaxY * 1.1);
    final valueRange = effectiveMaxY - effectiveMinY;

    // Draw grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = colors.gridLine
        ..strokeWidth = BorderTokens.widthThin;

      for (int i = 0; i <= 5; i++) {
        final y = topPadding + chartHeight * (1 - i / 5);
        canvas.drawLine(
          Offset(leftPadding, y),
          Offset(size.width - rightPadding, y),
          gridPaint,
        );

        // Y axis labels
        final value = effectiveMinY + valueRange * i / 5;
        final textPainter = TextPainter(
          text: TextSpan(
            text: value.toStringAsFixed(0),
            style: TextStyle(
              color: colors.axisLabel,
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
        );
      }
    }

    // Draw X axis labels
    final stepX = chartWidth / (labels.length - 1).clamp(1, double.infinity);
    for (int i = 0; i < labels.length; i++) {
      final x = leftPadding + stepX * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: colors.axisLabel,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPadding + 8),
      );
    }

    // Draw lines
    for (int seriesIndex = 0; seriesIndex < data.length; seriesIndex++) {
      final series = data[seriesIndex];
      final seriesColor =
          series.color ?? colors.seriesColors[seriesIndex % colors.seriesColors.length];

      final linePaint = Paint()
        ..color = seriesColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      for (int i = 0; i < series.values.length && i < labels.length; i++) {
        final x = leftPadding + stepX * i;
        final normalizedValue =
            (series.values[i] - effectiveMinY) / valueRange;
        final y = topPadding +
            chartHeight * (1 - normalizedValue * animationValue);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }

        // Draw points
        final pointPaint = Paint()
          ..color = seriesColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 4, pointPaint);

        // Hovered point
        if (hoveredIndex == i && hoveredSeriesIndex == seriesIndex) {
          final hoverPaint = Paint()
            ..color = seriesColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(x, y), 8, hoverPaint);
        }
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.hoveredSeriesIndex != hoveredSeriesIndex;
  }
}

/// 바 차트
class _BarChart extends StatelessWidget {
  final List<ChartSeries> data;
  final List<String> labels;
  final ChartColors colors;
  final bool showGrid;
  final bool showValues;
  final double animationValue;
  final double? minY;
  final double? maxY;
  final int? hoveredIndex;
  final int? hoveredSeriesIndex;
  final void Function(int index, int seriesIndex)? onHover;
  final VoidCallback? onHoverExit;

  const _BarChart({
    required this.data,
    required this.labels,
    required this.colors,
    required this.showGrid,
    required this.showValues,
    required this.animationValue,
    this.minY,
    this.maxY,
    this.hoveredIndex,
    this.hoveredSeriesIndex,
    this.onHover,
    this.onHoverExit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BarChartPainter(
            data: data,
            labels: labels,
            colors: colors,
            showGrid: showGrid,
            showValues: showValues,
            animationValue: animationValue,
            minY: minY,
            maxY: maxY,
            hoveredIndex: hoveredIndex,
            hoveredSeriesIndex: hoveredSeriesIndex,
          ),
          child: MouseRegion(
            onHover: (event) => _handleHover(event, constraints),
            onExit: (_) => onHoverExit?.call(),
          ),
        );
      },
    );
  }

  void _handleHover(PointerHoverEvent event, BoxConstraints constraints) {
    if (onHover == null || data.isEmpty) return;

    const leftPadding = 50.0;
    const rightPadding = 20.0;
    final chartWidth = constraints.maxWidth - leftPadding - rightPadding;
    final groupWidth = chartWidth / labels.length;
    final barWidth = groupWidth / (data.length + 1);

    final relativeX = event.localPosition.dx - leftPadding;
    final groupIndex = (relativeX / groupWidth).floor().clamp(0, labels.length - 1);
    final withinGroup = relativeX - groupIndex * groupWidth;
    final seriesIndex = ((withinGroup - barWidth / 2) / barWidth).floor().clamp(0, data.length - 1);

    onHover!(groupIndex, seriesIndex);
  }
}

/// 바 차트 페인터
class _BarChartPainter extends CustomPainter {
  final List<ChartSeries> data;
  final List<String> labels;
  final ChartColors colors;
  final bool showGrid;
  final bool showValues;
  final double animationValue;
  final double? minY;
  final double? maxY;
  final int? hoveredIndex;
  final int? hoveredSeriesIndex;

  _BarChartPainter({
    required this.data,
    required this.labels,
    required this.colors,
    required this.showGrid,
    required this.showValues,
    required this.animationValue,
    this.minY,
    this.maxY,
    this.hoveredIndex,
    this.hoveredSeriesIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const leftPadding = 50.0;
    const rightPadding = 20.0;
    const topPadding = 20.0;
    const bottomPadding = 40.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Calculate min/max values
    final allValues = data.expand((s) => s.values).toList();
    final dataMaxY = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final effectiveMinY = minY ?? 0.0;
    final effectiveMaxY = maxY ?? (dataMaxY * 1.1);
    final valueRange = effectiveMaxY - effectiveMinY;

    // Draw grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = colors.gridLine
        ..strokeWidth = BorderTokens.widthThin;

      for (int i = 0; i <= 5; i++) {
        final y = topPadding + chartHeight * (1 - i / 5);
        canvas.drawLine(
          Offset(leftPadding, y),
          Offset(size.width - rightPadding, y),
          gridPaint,
        );

        final value = effectiveMinY + valueRange * i / 5;
        final textPainter = TextPainter(
          text: TextSpan(
            text: value.toStringAsFixed(0),
            style: TextStyle(
              color: colors.axisLabel,
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
        );
      }
    }

    // Draw bars
    final groupWidth = chartWidth / labels.length;
    final barWidth = groupWidth / (data.length + 1);
    final barGap = barWidth / (data.length + 1);

    for (int labelIndex = 0; labelIndex < labels.length; labelIndex++) {
      // X axis label
      final labelX = leftPadding + groupWidth * labelIndex + groupWidth / 2;
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[labelIndex],
          style: TextStyle(
            color: colors.axisLabel,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, size.height - bottomPadding + 8),
      );

      // Bars for each series
      for (int seriesIndex = 0; seriesIndex < data.length; seriesIndex++) {
        final series = data[seriesIndex];
        if (labelIndex >= series.values.length) continue;

        final value = series.values[labelIndex];
        final normalizedValue = (value - effectiveMinY) / valueRange;
        final barHeight = chartHeight * normalizedValue * animationValue;

        final barX = leftPadding +
            groupWidth * labelIndex +
            barGap +
            (barWidth + barGap) * seriesIndex;
        final barY = topPadding + chartHeight - barHeight;

        final seriesColor =
            series.color ?? colors.seriesColors[seriesIndex % colors.seriesColors.length];

        final isHovered =
            hoveredIndex == labelIndex && hoveredSeriesIndex == seriesIndex;
        final barPaint = Paint()
          ..color = isHovered ? seriesColor.withValues(alpha: 0.8) : seriesColor
          ..style = PaintingStyle.fill;

        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(barX, barY, barWidth, barHeight),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect, barPaint);

        // Value label
        if (showValues && animationValue == 1.0) {
          final valuePainter = TextPainter(
            text: TextSpan(
              text: value.toStringAsFixed(0),
              style: TextStyle(
                color: colors.axisLabel,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          valuePainter.paint(
            canvas,
            Offset(
              barX + barWidth / 2 - valuePainter.width / 2,
              barY - valuePainter.height - 4,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.hoveredSeriesIndex != hoveredSeriesIndex;
  }
}

/// 파이/도넛 차트
class _PieChart extends StatelessWidget {
  final List<ChartSeries> data;
  final List<String> labels;
  final ChartColors colors;
  final bool isDoughnut;
  final bool showValues;
  final double animationValue;
  final int? hoveredIndex;
  final void Function(int index)? onHover;
  final VoidCallback? onHoverExit;

  const _PieChart({
    required this.data,
    required this.labels,
    required this.colors,
    required this.isDoughnut,
    required this.showValues,
    required this.animationValue,
    this.hoveredIndex,
    this.onHover,
    this.onHoverExit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _PieChartPainter(
            data: data,
            labels: labels,
            colors: colors,
            isDoughnut: isDoughnut,
            showValues: showValues,
            animationValue: animationValue,
            hoveredIndex: hoveredIndex,
          ),
          child: MouseRegion(
            onHover: (event) => _handleHover(event, constraints),
            onExit: (_) => onHoverExit?.call(),
          ),
        );
      },
    );
  }

  void _handleHover(PointerHoverEvent event, BoxConstraints constraints) {
    if (onHover == null || data.isEmpty || data[0].values.isEmpty) return;

    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
    final position = event.localPosition - center;
    var angle = math.atan2(position.dy, position.dx);
    if (angle < -math.pi / 2) {
      angle += math.pi * 2;
    }
    angle += math.pi / 2;
    if (angle > math.pi * 2) {
      angle -= math.pi * 2;
    }

    final total = data[0].values.reduce((a, b) => a + b);
    var currentAngle = 0.0;

    for (int i = 0; i < data[0].values.length; i++) {
      final sweepAngle = (data[0].values[i] / total) * math.pi * 2;
      if (angle >= currentAngle && angle < currentAngle + sweepAngle) {
        onHover!(i);
        return;
      }
      currentAngle += sweepAngle;
    }
  }
}

/// 파이 차트 페인터
class _PieChartPainter extends CustomPainter {
  final List<ChartSeries> data;
  final List<String> labels;
  final ChartColors colors;
  final bool isDoughnut;
  final bool showValues;
  final double animationValue;
  final int? hoveredIndex;

  _PieChartPainter({
    required this.data,
    required this.labels,
    required this.colors,
    required this.isDoughnut,
    required this.showValues,
    required this.animationValue,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data[0].values.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    final innerRadius = isDoughnut ? radius * 0.6 : 0.0;

    final values = data[0].values;
    final total = values.reduce((a, b) => a + b);
    var startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * math.pi * 2 * animationValue;
      final color = colors.seriesColors[i % colors.seriesColors.length];

      final isHovered = hoveredIndex == i;
      final paint = Paint()
        ..color = isHovered ? color.withValues(alpha: 0.8) : color
        ..style = PaintingStyle.fill;

      final extraRadius = isHovered ? 8.0 : 0.0;
      final path = Path()
        ..moveTo(
          center.dx + (innerRadius) * math.cos(startAngle),
          center.dy + (innerRadius) * math.sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius + extraRadius),
          startAngle,
          sweepAngle,
          false,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle + sweepAngle,
          -sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      // Draw labels
      if (animationValue == 1.0) {
        final midAngle = startAngle + sweepAngle / 2;
        final labelRadius = radius + 25;
        final labelX = center.dx + labelRadius * math.cos(midAngle);
        final labelY = center.dy + labelRadius * math.sin(midAngle);

        final label = i < labels.length ? labels[i] : '';
        final percentage = (values[i] / total * 100).toStringAsFixed(1);
        final textPainter = TextPainter(
          text: TextSpan(
            text: showValues ? '$label\n$percentage%' : label,
            style: TextStyle(
              color: colors.axisLabel,
              fontSize: 11,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

/// 영역 차트
class _AreaChart extends StatelessWidget {
  final List<ChartSeries> data;
  final List<String> labels;
  final ChartColors colors;
  final bool showGrid;
  final bool showValues;
  final double animationValue;
  final double? minY;
  final double? maxY;
  final int? hoveredIndex;
  final int? hoveredSeriesIndex;
  final void Function(int index, int seriesIndex)? onHover;
  final VoidCallback? onHoverExit;

  const _AreaChart({
    required this.data,
    required this.labels,
    required this.colors,
    required this.showGrid,
    required this.showValues,
    required this.animationValue,
    this.minY,
    this.maxY,
    this.hoveredIndex,
    this.hoveredSeriesIndex,
    this.onHover,
    this.onHoverExit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _AreaChartPainter(
            data: data,
            labels: labels,
            colors: colors,
            showGrid: showGrid,
            showValues: showValues,
            animationValue: animationValue,
            minY: minY,
            maxY: maxY,
            hoveredIndex: hoveredIndex,
            hoveredSeriesIndex: hoveredSeriesIndex,
          ),
          child: MouseRegion(
            onHover: (event) => _handleHover(event, constraints),
            onExit: (_) => onHoverExit?.call(),
          ),
        );
      },
    );
  }

  void _handleHover(PointerHoverEvent event, BoxConstraints constraints) {
    if (onHover == null || data.isEmpty) return;

    const leftPadding = 50.0;
    const rightPadding = 20.0;
    final chartWidth = constraints.maxWidth - leftPadding - rightPadding;
    final stepX = chartWidth / (labels.length - 1).clamp(1, double.infinity);

    final relativeX = event.localPosition.dx - leftPadding;
    final index = (relativeX / stepX).round().clamp(0, labels.length - 1);

    onHover!(index, 0);
  }
}

/// 영역 차트 페인터
class _AreaChartPainter extends CustomPainter {
  final List<ChartSeries> data;
  final List<String> labels;
  final ChartColors colors;
  final bool showGrid;
  final bool showValues;
  final double animationValue;
  final double? minY;
  final double? maxY;
  final int? hoveredIndex;
  final int? hoveredSeriesIndex;

  _AreaChartPainter({
    required this.data,
    required this.labels,
    required this.colors,
    required this.showGrid,
    required this.showValues,
    required this.animationValue,
    this.minY,
    this.maxY,
    this.hoveredIndex,
    this.hoveredSeriesIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const leftPadding = 50.0;
    const rightPadding = 20.0;
    const topPadding = 20.0;
    const bottomPadding = 40.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartBottom = topPadding + chartHeight;

    // Calculate min/max values
    final allValues = data.expand((s) => s.values).toList();
    final dataMinY = allValues.isEmpty
        ? 0.0
        : allValues.reduce((a, b) => a < b ? a : b);
    final dataMaxY = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final effectiveMinY = minY ?? (dataMinY * 0.9);
    final effectiveMaxY = maxY ?? (dataMaxY * 1.1);
    final valueRange = effectiveMaxY - effectiveMinY;

    // Draw grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = colors.gridLine
        ..strokeWidth = BorderTokens.widthThin;

      for (int i = 0; i <= 5; i++) {
        final y = topPadding + chartHeight * (1 - i / 5);
        canvas.drawLine(
          Offset(leftPadding, y),
          Offset(size.width - rightPadding, y),
          gridPaint,
        );

        final value = effectiveMinY + valueRange * i / 5;
        final textPainter = TextPainter(
          text: TextSpan(
            text: value.toStringAsFixed(0),
            style: TextStyle(
              color: colors.axisLabel,
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
        );
      }
    }

    // Draw X axis labels
    final stepX = chartWidth / (labels.length - 1).clamp(1, double.infinity);
    for (int i = 0; i < labels.length; i++) {
      final x = leftPadding + stepX * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: colors.axisLabel,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPadding + 8),
      );
    }

    // Draw areas
    for (int seriesIndex = 0; seriesIndex < data.length; seriesIndex++) {
      final series = data[seriesIndex];
      final seriesColor =
          series.color ?? colors.seriesColors[seriesIndex % colors.seriesColors.length];

      // Area fill
      final areaPath = Path();
      for (int i = 0; i < series.values.length && i < labels.length; i++) {
        final x = leftPadding + stepX * i;
        final normalizedValue =
            (series.values[i] - effectiveMinY) / valueRange;
        final y = topPadding +
            chartHeight * (1 - normalizedValue * animationValue);

        if (i == 0) {
          areaPath.moveTo(x, chartBottom);
          areaPath.lineTo(x, y);
        } else {
          areaPath.lineTo(x, y);
        }
      }
      areaPath.lineTo(
        leftPadding + stepX * (series.values.length - 1).clamp(0, labels.length - 1),
        chartBottom,
      );
      areaPath.close();

      final areaPaint = Paint()
        ..color = seriesColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, areaPaint);

      // Line
      final linePaint = Paint()
        ..color = seriesColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final linePath = Path();
      for (int i = 0; i < series.values.length && i < labels.length; i++) {
        final x = leftPadding + stepX * i;
        final normalizedValue =
            (series.values[i] - effectiveMinY) / valueRange;
        final y = topPadding +
            chartHeight * (1 - normalizedValue * animationValue);

        if (i == 0) {
          linePath.moveTo(x, y);
        } else {
          linePath.lineTo(x, y);
        }

        // Points
        final pointPaint = Paint()
          ..color = seriesColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 4, pointPaint);

        if (hoveredIndex == i && hoveredSeriesIndex == seriesIndex) {
          final hoverPaint = Paint()
            ..color = seriesColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(x, y), 8, hoverPaint);
        }
      }
      canvas.drawPath(linePath, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.hoveredSeriesIndex != hoveredSeriesIndex;
  }
}

/// 차트 범례
class _ChartLegend extends StatelessWidget {
  final List<ChartSeries> data;
  final ChartColors colors;

  const _ChartLegend({
    required this.data,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Wrap(
      spacing: spacingExt.medium,
      runSpacing: spacingExt.small,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final series = entry.value;
        final color =
            series.color ?? colors.seriesColors[index % colors.seriesColors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: spacingExt.xs),
            Text(
              series.name,
              style: TextStyle(
                color: colors.legendText,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
