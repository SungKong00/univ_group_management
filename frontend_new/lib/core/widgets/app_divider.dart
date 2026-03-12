import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/divider_colors.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppDividerStyle, AppDividerThickness;

/// 구분선 컴포넌트
///
/// **용도**: 콘텐츠 구분, 섹션 분리, 시각적 계층 표현
/// **접근성**: 시각적 분리를 위한 장식 요소
///
/// ```dart
/// // 기본 구분선
/// AppDivider()
///
/// // 라벨 포함 구분선
/// AppDivider.withLabel(label: '또는')
///
/// // 세로 구분선
/// AppDivider.vertical(height: 24)
///
/// // 점선 구분선
/// AppDivider(style: AppDividerStyle.dashed)
/// ```
class AppDivider extends StatelessWidget {
  /// 구분선 스타일
  final AppDividerStyle style;

  /// 구분선 두께
  final AppDividerThickness thickness;

  /// 색상 (null이면 기본 색상)
  final Color? color;

  /// 들여쓰기 (시작)
  final double? indent;

  /// 들여쓰기 (끝)
  final double? endIndent;

  /// 세로 마진
  final double? verticalMargin;

  /// 라벨 텍스트
  final String? label;

  /// 가로/세로 방향
  final bool isVertical;

  /// 세로 구분선 높이
  final double? height;

  const AppDivider({
    super.key,
    this.style = AppDividerStyle.solid,
    this.thickness = AppDividerThickness.thin,
    this.color,
    this.indent,
    this.endIndent,
    this.verticalMargin,
    this.label,
    this.isVertical = false,
    this.height,
  });

  /// 라벨 포함 구분선 팩토리
  factory AppDivider.withLabel({
    Key? key,
    required String label,
    AppDividerStyle style = AppDividerStyle.solid,
    AppDividerThickness thickness = AppDividerThickness.thin,
    Color? color,
    double? verticalMargin,
  }) {
    return AppDivider(
      key: key,
      style: style,
      thickness: thickness,
      color: color,
      verticalMargin: verticalMargin,
      label: label,
    );
  }

  /// 세로 구분선 팩토리
  factory AppDivider.vertical({
    Key? key,
    double? height,
    AppDividerStyle style = AppDividerStyle.solid,
    AppDividerThickness thickness = AppDividerThickness.thin,
    Color? color,
  }) {
    return AppDivider(
      key: key,
      style: style,
      thickness: thickness,
      color: color,
      isVertical: true,
      height: height,
    );
  }

  double get _thicknessValue => switch (thickness) {
    AppDividerThickness.thin => 1.0,
    AppDividerThickness.medium => 2.0,
    AppDividerThickness.thick => 4.0,
  };

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = DividerColors.from(colorExt, AppDividerColorStyle.standard);

    final effectiveColor = color ?? colors.line;
    final effectiveMargin = verticalMargin ?? spacingExt.medium;

    if (isVertical) {
      return _buildVertical(effectiveColor, height ?? 24);
    }

    if (label != null) {
      return _buildWithLabel(colors, spacingExt, effectiveMargin);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: effectiveMargin),
      child: switch (style) {
        AppDividerStyle.solid => _buildSolidLine(effectiveColor),
        AppDividerStyle.dashed => _buildDashedLine(effectiveColor),
        AppDividerStyle.dotted => _buildDottedLine(effectiveColor),
      },
    );
  }

  Widget _buildSolidLine(Color color) {
    return Container(
      height: _thicknessValue,
      margin: EdgeInsets.only(left: indent ?? 0, right: endIndent ?? 0),
      color: color,
    );
  }

  Widget _buildDashedLine(Color color) {
    return CustomPaint(
      size: Size(double.infinity, _thicknessValue),
      painter: _DashedLinePainter(
        color: color,
        strokeWidth: _thicknessValue,
        dashWidth: 6,
        dashSpace: 4,
        indent: indent ?? 0,
        endIndent: endIndent ?? 0,
      ),
    );
  }

  Widget _buildDottedLine(Color color) {
    return CustomPaint(
      size: Size(double.infinity, _thicknessValue),
      painter: _DashedLinePainter(
        color: color,
        strokeWidth: _thicknessValue,
        dashWidth: 2,
        dashSpace: 4,
        indent: indent ?? 0,
        endIndent: endIndent ?? 0,
      ),
    );
  }

  Widget _buildVertical(Color color, double height) {
    return switch (style) {
      AppDividerStyle.solid => Container(
        width: _thicknessValue,
        height: height,
        color: color,
      ),
      AppDividerStyle.dashed || AppDividerStyle.dotted => CustomPaint(
        size: Size(_thicknessValue, height),
        painter: _VerticalDashedLinePainter(
          color: color,
          strokeWidth: _thicknessValue,
          dashWidth: style == AppDividerStyle.dotted ? 2 : 6,
          dashSpace: 4,
        ),
      ),
    };
  }

  Widget _buildWithLabel(
    DividerColors colors,
    AppSpacingExtension spacing,
    double margin,
  ) {
    final effectiveColor = color ?? colors.line;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: margin),
      child: Row(
        children: [
          Expanded(
            child: switch (style) {
              AppDividerStyle.solid => _buildSolidLine(effectiveColor),
              AppDividerStyle.dashed => _buildDashedLine(effectiveColor),
              AppDividerStyle.dotted => _buildDottedLine(effectiveColor),
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.medium),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.small,
                vertical: spacing.xs,
              ),
              decoration: BoxDecoration(color: colors.labelBackground),
              child: Text(
                label!,
                style: TextStyle(
                  color: colors.labelText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: switch (style) {
              AppDividerStyle.solid => _buildSolidLine(effectiveColor),
              AppDividerStyle.dashed => _buildDashedLine(effectiveColor),
              AppDividerStyle.dotted => _buildDottedLine(effectiveColor),
            },
          ),
        ],
      ),
    );
  }
}

/// 가로 점선 페인터
class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double indent;
  final double endIndent;

  _DashedLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.indent,
    required this.endIndent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startX = indent;
    final endX = size.width - endIndent;
    final y = size.height / 2;

    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth > endX ? endX : startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 세로 점선 페인터
class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _VerticalDashedLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startY = 0;
    final x = size.width / 2;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(
          x,
          startY + dashWidth > size.height ? size.height : startY + dashWidth,
        ),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 간격이 있는 구분선 (섹션 구분용)
///
/// ```dart
/// AppSectionDivider()
/// AppSectionDivider.small()
/// AppSectionDivider.large()
/// ```
class AppSectionDivider extends StatelessWidget {
  /// 위/아래 마진
  final double margin;

  /// 구분선 색상
  final Color? color;

  const AppSectionDivider({super.key, this.margin = 24, this.color});

  /// 작은 섹션 구분선
  factory AppSectionDivider.small({Key? key, Color? color}) {
    return AppSectionDivider(key: key, margin: 16, color: color);
  }

  /// 큰 섹션 구분선
  factory AppSectionDivider.large({Key? key, Color? color}) {
    return AppSectionDivider(key: key, margin: 32, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return AppDivider(verticalMargin: margin, color: color);
  }
}
