import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/slider_colors.dart';
import '../theme/enums.dart';
import '../theme/component_size_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppSliderSize, AppSliderStyle;

/// 범위 선택 슬라이더
///
/// **용도**: 숫자 범위 선택, 볼륨/밝기 조절, 가격/날짜 필터
/// **접근성**: 최소 터치 영역 44px 보장, 키보드 네비게이션, Semantics 지원
/// **반응형**: 크기 옵션으로 다양한 상황에 대응
///
/// ```dart
/// // 기본 사용
/// AppSlider(
///   value: _volume,
///   onChanged: (value) => setState(() => _volume = value),
///   min: 0,
///   max: 100,
/// )
///
/// // 라벨 및 값 표시
/// AppSlider(
///   value: _brightness,
///   onChanged: (value) => setState(() => _brightness = value),
///   min: 0,
///   max: 100,
///   label: '밝기',
///   showValue: true,
///   valueFormatter: (value) => '${value.toInt()}%',
/// )
///
/// // 단계별 슬라이더
/// AppSlider(
///   value: _rating,
///   onChanged: (value) => setState(() => _rating = value),
///   min: 1,
///   max: 5,
///   divisions: 4,
///   style: AppSliderStyle.stepped,
/// )
///
/// // 마크 표시 슬라이더
/// AppSlider(
///   value: _price,
///   onChanged: (value) => setState(() => _price = value),
///   min: 0,
///   max: 1000,
///   style: AppSliderStyle.marked,
///   marks: [0, 250, 500, 750, 1000],
///   markLabels: ['0', '250', '500', '750', '1000'],
/// )
///
/// // 범위 슬라이더
/// AppRangeSlider(
///   values: RangeValues(_minPrice, _maxPrice),
///   onChanged: (values) => setState(() {
///     _minPrice = values.start;
///     _maxPrice = values.end;
///   }),
///   min: 0,
///   max: 1000,
///   label: '가격 범위',
/// )
/// ```
class AppSlider extends StatefulWidget {
  /// 현재 값
  final double value;

  /// 값 변경 콜백
  final ValueChanged<double>? onChanged;

  /// 드래그 완료 콜백
  final ValueChanged<double>? onChangeEnd;

  /// 최소값
  final double min;

  /// 최대값
  final double max;

  /// 분할 수 (null이면 연속)
  final int? divisions;

  /// 슬라이더 크기
  final AppSliderSize size;

  /// 슬라이더 스타일
  final AppSliderStyle style;

  /// 라벨 텍스트
  final String? label;

  /// 값 표시 여부
  final bool showValue;

  /// 값 포맷터
  final String Function(double)? valueFormatter;

  /// 툴팁 표시 여부
  final bool showTooltip;

  /// 마크 위치 (marked 스타일용)
  final List<double>? marks;

  /// 마크 라벨 (marked 스타일용)
  final List<String>? markLabels;

  /// 비활성화 상태
  final bool isDisabled;

  /// 커스텀 활성 색상
  final Color? activeColor;

  const AppSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.size = AppSliderSize.medium,
    this.style = AppSliderStyle.standard,
    this.label,
    this.showValue = false,
    this.valueFormatter,
    this.showTooltip = true,
    this.marks,
    this.markLabels,
    this.isDisabled = false,
    this.activeColor,
  });

  @override
  State<AppSlider> createState() => _AppSliderState();
}

class _AppSliderState extends State<AppSlider> {
  bool _isDragging = false;

  String _formatValue(double value) {
    if (widget.valueFormatter != null) {
      return widget.valueFormatter!(value);
    }
    if (widget.divisions != null) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    final colors = widget.activeColor != null
        ? SliderColors.withActiveColor(colorExt, widget.activeColor!)
        : SliderColors.from(colorExt);

    final isDisabled = widget.isDisabled || widget.onChanged == null;

    // 사이즈별 토큰
    final (trackHeight, thumbSize) = switch (widget.size) {
      AppSliderSize.small => (
        ComponentSizeTokens.sliderSmallTrackHeight,
        ComponentSizeTokens.sliderSmallThumbSize,
      ),
      AppSliderSize.medium => (
        ComponentSizeTokens.sliderMediumTrackHeight,
        ComponentSizeTokens.sliderMediumThumbSize,
      ),
      AppSliderSize.large => (
        ComponentSizeTokens.sliderLargeTrackHeight,
        ComponentSizeTokens.sliderLargeThumbSize,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨 및 값 표시
        if (widget.label != null || widget.showValue) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDisabled ? colors.disabledText : colors.labelText,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (widget.showValue)
                Text(
                  _formatValue(widget.value),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDisabled ? colors.disabledText : colors.valueText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: spacingExt.small),
        ],

        // 슬라이더
        Semantics(
          slider: true,
          value: _formatValue(widget.value),
          enabled: !isDisabled,
          label: widget.label,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: trackHeight,
              thumbShape: _AppSliderThumbShape(
                thumbRadius: thumbSize / 2,
                thumbColor: isDisabled ? colors.thumbDisabled : colors.thumb,
                borderColor: isDisabled
                    ? colors.trackDisabled
                    : colors.thumbBorder,
                focusRingColor: colors.focusRing,
                showFocusRing: _isDragging,
              ),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: isDisabled
                  ? colors.trackDisabled
                  : colors.trackActive,
              inactiveTrackColor: colors.trackBackground,
              disabledActiveTrackColor: colors.trackDisabled,
              disabledInactiveTrackColor: colors.trackBackground,
              tickMarkShape: widget.style == AppSliderStyle.stepped
                  ? const RoundSliderTickMarkShape(tickMarkRadius: 3)
                  : SliderTickMarkShape.noTickMark,
              activeTickMarkColor: colors.markActive,
              inactiveTickMarkColor: colors.mark,
              valueIndicatorShape: widget.showTooltip
                  ? const PaddleSliderValueIndicatorShape()
                  : SliderComponentShape.noOverlay,
              valueIndicatorColor: colors.tooltipBackground,
              valueIndicatorTextStyle: TextStyle(
                color: colors.tooltipText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              showValueIndicator: widget.showTooltip
                  ? ShowValueIndicator.onlyForContinuous
                  : ShowValueIndicator.never,
            ),
            child: Slider(
              value: widget.value.clamp(widget.min, widget.max),
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              label: widget.showTooltip ? _formatValue(widget.value) : null,
              onChanged: isDisabled
                  ? null
                  : (value) {
                      setState(() => _isDragging = true);
                      widget.onChanged?.call(value);
                    },
              onChangeEnd: (value) {
                setState(() => _isDragging = false);
                widget.onChangeEnd?.call(value);
              },
            ),
          ),
        ),

        // 마크 라벨 (marked 스타일)
        if (widget.style == AppSliderStyle.marked &&
            widget.marks != null &&
            widget.markLabels != null) ...[
          SizedBox(height: spacingExt.xs),
          _buildMarkLabels(colors, isDisabled),
        ],
      ],
    );
  }

  Widget _buildMarkLabels(SliderColors colors, bool isDisabled) {
    final marks = widget.marks!;
    final labels = widget.markLabels!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < marks.length && i < labels.length; i++)
          Text(
            labels[i],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDisabled ? colors.disabledText : colors.valueText,
            ),
          ),
      ],
    );
  }
}

/// 커스텀 슬라이더 썸 모양
class _AppSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final Color thumbColor;
  final Color borderColor;
  final Color focusRingColor;
  final bool showFocusRing;

  const _AppSliderThumbShape({
    required this.thumbRadius,
    required this.thumbColor,
    required this.borderColor,
    required this.focusRingColor,
    this.showFocusRing = false,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // 포커스 링
    if (showFocusRing) {
      final focusRingPaint = Paint()
        ..color = focusRingColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        center,
        thumbRadius + ComponentSizeTokens.sliderFocusRingWidth,
        focusRingPaint,
      );
    }

    // 테두리
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, borderPaint);

    // 썸 (내부)
    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius - 2, thumbPaint);
  }
}

/// 범위 선택 슬라이더
///
/// 시작값과 끝값을 선택할 수 있는 슬라이더입니다.
class AppRangeSlider extends StatefulWidget {
  /// 현재 값 범위
  final RangeValues values;

  /// 값 변경 콜백
  final ValueChanged<RangeValues>? onChanged;

  /// 드래그 완료 콜백
  final ValueChanged<RangeValues>? onChangeEnd;

  /// 최소값
  final double min;

  /// 최대값
  final double max;

  /// 분할 수 (null이면 연속)
  final int? divisions;

  /// 슬라이더 크기
  final AppSliderSize size;

  /// 라벨 텍스트
  final String? label;

  /// 값 표시 여부
  final bool showValue;

  /// 값 포맷터
  final String Function(double)? valueFormatter;

  /// 비활성화 상태
  final bool isDisabled;

  /// 커스텀 활성 색상
  final Color? activeColor;

  const AppRangeSlider({
    super.key,
    required this.values,
    this.onChanged,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.size = AppSliderSize.medium,
    this.label,
    this.showValue = false,
    this.valueFormatter,
    this.isDisabled = false,
    this.activeColor,
  });

  @override
  State<AppRangeSlider> createState() => _AppRangeSliderState();
}

class _AppRangeSliderState extends State<AppRangeSlider> {
  String _formatValue(double value) {
    if (widget.valueFormatter != null) {
      return widget.valueFormatter!(value);
    }
    if (widget.divisions != null) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    final colors = widget.activeColor != null
        ? SliderColors.withActiveColor(colorExt, widget.activeColor!)
        : SliderColors.from(colorExt);

    final isDisabled = widget.isDisabled || widget.onChanged == null;

    // 사이즈별 토큰
    final (trackHeight, thumbSize) = switch (widget.size) {
      AppSliderSize.small => (
        ComponentSizeTokens.sliderSmallTrackHeight,
        ComponentSizeTokens.sliderSmallThumbSize,
      ),
      AppSliderSize.medium => (
        ComponentSizeTokens.sliderMediumTrackHeight,
        ComponentSizeTokens.sliderMediumThumbSize,
      ),
      AppSliderSize.large => (
        ComponentSizeTokens.sliderLargeTrackHeight,
        ComponentSizeTokens.sliderLargeThumbSize,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨 및 값 표시
        if (widget.label != null || widget.showValue) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDisabled ? colors.disabledText : colors.labelText,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (widget.showValue)
                Text(
                  '${_formatValue(widget.values.start)} - ${_formatValue(widget.values.end)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDisabled ? colors.disabledText : colors.valueText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: spacingExt.small),
        ],

        // 범위 슬라이더
        Semantics(
          label: widget.label,
          enabled: !isDisabled,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: trackHeight,
              rangeThumbShape: _AppRangeSliderThumbShape(
                thumbRadius: thumbSize / 2,
                thumbColor: isDisabled ? colors.thumbDisabled : colors.thumb,
                borderColor: isDisabled
                    ? colors.trackDisabled
                    : colors.thumbBorder,
              ),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: isDisabled
                  ? colors.trackDisabled
                  : colors.trackActive,
              inactiveTrackColor: colors.trackBackground,
              disabledActiveTrackColor: colors.trackDisabled,
              disabledInactiveTrackColor: colors.trackBackground,
              rangeTickMarkShape: widget.divisions != null
                  ? const RoundRangeSliderTickMarkShape(tickMarkRadius: 3)
                  : null,
              activeTickMarkColor: colors.markActive,
              inactiveTickMarkColor: colors.mark,
              rangeValueIndicatorShape:
                  const PaddleRangeSliderValueIndicatorShape(),
              valueIndicatorColor: colors.tooltipBackground,
              valueIndicatorTextStyle: TextStyle(
                color: colors.tooltipText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              showValueIndicator: ShowValueIndicator.onlyForContinuous,
            ),
            child: RangeSlider(
              values: RangeValues(
                widget.values.start.clamp(widget.min, widget.max),
                widget.values.end.clamp(widget.min, widget.max),
              ),
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              labels: RangeLabels(
                _formatValue(widget.values.start),
                _formatValue(widget.values.end),
              ),
              onChanged: isDisabled ? null : widget.onChanged,
              onChangeEnd: widget.onChangeEnd,
            ),
          ),
        ),
      ],
    );
  }
}

/// 커스텀 범위 슬라이더 썸 모양
class _AppRangeSliderThumbShape extends RangeSliderThumbShape {
  final double thumbRadius;
  final Color thumbColor;
  final Color borderColor;

  const _AppRangeSliderThumbShape({
    required this.thumbRadius,
    required this.thumbColor,
    required this.borderColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool? isDiscrete,
    bool? isEnabled,
    bool? isOnTop,
    bool? isPressed,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
  }) {
    final canvas = context.canvas;

    // 테두리
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, borderPaint);

    // 썸 (내부)
    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius - 2, thumbPaint);
  }
}
