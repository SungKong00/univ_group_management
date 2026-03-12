import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/spinner_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppSpinnerSize, AppSpinnerStyle;

/// 스피너 로딩 인디케이터
///
/// **용도**: 인라인 로딩, 버튼 로딩, 페이지 로딩
/// **접근성**: Semantics 지원
///
/// ```dart
/// // 기본 스피너
/// AppSpinner()
///
/// // 크기별
/// AppSpinner(size: AppSpinnerSize.small)
/// AppSpinner(size: AppSpinnerSize.large)
///
/// // 색상별
/// AppSpinner(color: Colors.blue)
///
/// // 스타일별
/// AppSpinner(style: AppSpinnerStyle.dots)
/// AppSpinner(style: AppSpinnerStyle.pulse)
/// ```
class AppSpinner extends StatefulWidget {
  /// 스피너 크기
  final AppSpinnerSize size;

  /// 스피너 스타일
  final AppSpinnerStyle style;

  /// 커스텀 색상
  final Color? color;

  /// 트랙 색상
  final Color? trackColor;

  /// 스트로크 너비
  final double? strokeWidth;

  /// 시맨틱 라벨
  final String? semanticLabel;

  const AppSpinner({
    super.key,
    this.size = AppSpinnerSize.medium,
    this.style = AppSpinnerStyle.circular,
    this.color,
    this.trackColor,
    this.strokeWidth,
    this.semanticLabel,
  });

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getSize() {
    return switch (widget.size) {
      AppSpinnerSize.xs => 12.0,
      AppSpinnerSize.small => 16.0,
      AppSpinnerSize.medium => 24.0,
      AppSpinnerSize.large => 32.0,
      AppSpinnerSize.xl => 48.0,
    };
  }

  double _getStrokeWidth() {
    if (widget.strokeWidth != null) return widget.strokeWidth!;
    return switch (widget.size) {
      AppSpinnerSize.xs => 1.5,
      AppSpinnerSize.small => 2.0,
      AppSpinnerSize.medium => 2.5,
      AppSpinnerSize.large => 3.0,
      AppSpinnerSize.xl => 4.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = SpinnerColors.from(colorExt);
    final size = _getSize();
    final spinnerColor = widget.color ?? colors.brand;
    final trackColor = widget.trackColor ?? colors.track;

    Widget spinner = switch (widget.style) {
      AppSpinnerStyle.circular => _buildCircularSpinner(
        size,
        spinnerColor,
        trackColor,
      ),
      AppSpinnerStyle.dots => _buildDotsSpinner(size, spinnerColor),
      AppSpinnerStyle.pulse => _buildPulseSpinner(size, spinnerColor),
    };

    return Semantics(label: widget.semanticLabel ?? '로딩 중', child: spinner);
  }

  Widget _buildCircularSpinner(double size, Color color, Color trackColor) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: _getStrokeWidth(),
        valueColor: AlwaysStoppedAnimation<Color>(color),
        backgroundColor: trackColor,
      ),
    );
  }

  Widget _buildDotsSpinner(double size, Color color) {
    final dotSize = size / 4;
    return SizedBox(
      width: size,
      height: dotSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.15;
              final value = ((_controller.value + delay) % 1.0);
              final scale = 0.5 + (math.sin(value * math.pi) * 0.5);
              final opacity = 0.3 + (math.sin(value * math.pi) * 0.7);

              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPulseSpinner(double size, Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.8 + (_controller.value * 0.4);
        final opacity = 1.0 - (_controller.value * 0.6);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 펄스 링
              Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: _getStrokeWidth(),
                      ),
                    ),
                  ),
                ),
              ),
              // 중심 원
              Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 로딩 오버레이
///
/// 전체 화면 또는 특정 영역을 덮는 로딩 상태
class AppSpinnerOverlay extends StatelessWidget {
  /// 오버레이할 자식 위젯
  final Widget child;

  /// 로딩 표시 여부
  final bool isLoading;

  /// 스피너 크기
  final AppSpinnerSize spinnerSize;

  /// 스피너 색상
  final Color? spinnerColor;

  /// 오버레이 색상
  final Color? overlayColor;

  /// 로딩 메시지
  final String? message;

  const AppSpinnerOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.spinnerSize = AppSpinnerSize.large,
    this.spinnerColor,
    this.overlayColor,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: isLoading ? 1.0 : 0.0,
              duration: AnimationTokens.durationQuick,
              child: Container(
                color: overlayColor ?? colorExt.overlayMedium,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSpinner(size: spinnerSize, color: spinnerColor),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorExt.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
