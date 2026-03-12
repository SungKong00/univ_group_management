import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/switch_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppSwitchSize;

/// On/Off 토글 스위치 컴포넌트
///
/// **용도**: 설정 토글, 기능 활성화/비활성화
/// **접근성**: 최소 터치 영역 44px 보장, 포커스 상태 표시, Semantics 지원
/// **반응형**: 크기 옵션으로 다양한 상황에 대응
///
/// ```dart
/// // 기본 사용
/// AppSwitch(
///   value: _isEnabled,
///   onChanged: (value) => setState(() => _isEnabled = value),
/// )
///
/// // 라벨과 설명 포함
/// AppSwitch(
///   value: _notifications,
///   onChanged: (value) => setState(() => _notifications = value),
///   label: '알림 받기',
///   description: '새로운 메시지가 오면 알림을 받습니다',
/// )
///
/// // 커스텀 활성 색상
/// AppSwitch(
///   value: _darkMode,
///   onChanged: (value) => setState(() => _darkMode = value),
///   label: '다크 모드',
///   activeColor: Colors.blue,
/// )
/// ```
class AppSwitch extends StatefulWidget {
  /// 현재 값
  final bool value;

  /// 값 변경 콜백
  final ValueChanged<bool>? onChanged;

  /// 스위치 크기
  final AppSwitchSize size;

  /// 라벨 텍스트
  final String? label;

  /// 설명 텍스트
  final String? description;

  /// 비활성화 상태
  final bool isDisabled;

  /// 로딩 상태
  final bool isLoading;

  /// 커스텀 활성 색상
  final Color? activeColor;

  const AppSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.size = AppSwitchSize.medium,
    this.label,
    this.description,
    this.isDisabled = false,
    this.isLoading = false,
    this.activeColor,
  });

  @override
  State<AppSwitch> createState() => _AppSwitchState();
}

class _AppSwitchState extends State<AppSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbAnimation;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationTokens.durationQuick,
      vsync: this,
    );
    _thumbAnimation = CurvedAnimation(
      parent: _controller,
      curve: AnimationTokens.curveSmooth,
    );

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AppSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isDisabled || widget.isLoading || widget.onChanged == null) {
      return;
    }
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    final colors = widget.activeColor != null
        ? SwitchColors.withActiveColor(colorExt, widget.activeColor!)
        : SwitchColors.from(colorExt);

    // 사이즈별 토큰
    final (
      trackWidth,
      trackHeight,
      thumbSize,
      thumbPadding,
    ) = switch (widget.size) {
      AppSwitchSize.small => (
        ComponentSizeTokens.switchSmallTrackWidth,
        ComponentSizeTokens.switchSmallTrackHeight,
        ComponentSizeTokens.switchSmallThumbSize,
        ComponentSizeTokens.switchSmallThumbPadding,
      ),
      AppSwitchSize.medium => (
        ComponentSizeTokens.switchMediumTrackWidth,
        ComponentSizeTokens.switchMediumTrackHeight,
        ComponentSizeTokens.switchMediumThumbSize,
        ComponentSizeTokens.switchMediumThumbPadding,
      ),
      AppSwitchSize.large => (
        ComponentSizeTokens.switchLargeTrackWidth,
        ComponentSizeTokens.switchLargeTrackHeight,
        ComponentSizeTokens.switchLargeThumbSize,
        ComponentSizeTokens.switchLargeThumbPadding,
      ),
    };

    final isDisabled = widget.isDisabled || widget.onChanged == null;
    final thumbTravel = trackWidth - thumbSize - (thumbPadding * 2);

    return Semantics(
      toggled: widget.value,
      enabled: !isDisabled,
      label: widget.label ?? '스위치',
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: GestureDetector(
          onTap: _handleTap,
          child: MouseRegion(
            cursor: isDisabled
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Switch 트랙
                _buildSwitch(
                  colors: colors,
                  trackWidth: trackWidth,
                  trackHeight: trackHeight,
                  thumbSize: thumbSize,
                  thumbPadding: thumbPadding,
                  thumbTravel: thumbTravel,
                  isDisabled: isDisabled,
                  colorExt: colorExt,
                ),

                // 라벨 및 설명
                if (widget.label != null || widget.description != null) ...[
                  SizedBox(width: spacingExt.medium),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.label != null)
                          Text(
                            widget.label!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isDisabled
                                      ? colors.disabledText
                                      : colors.labelText,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        if (widget.description != null) ...[
                          SizedBox(height: spacingExt.xs),
                          Text(
                            widget.description!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDisabled
                                      ? colors.disabledText
                                      : colors.descriptionText,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required SwitchColors colors,
    required double trackWidth,
    required double trackHeight,
    required double thumbSize,
    required double thumbPadding,
    required double thumbTravel,
    required bool isDisabled,
    required AppColorExtension colorExt,
  }) {
    // 상태별 색상 계산
    final trackColor = isDisabled
        ? colors.trackBackgroundDisabled
        : widget.value
        ? colors.trackBackgroundActive
        : _isHovered
        ? colors.trackBackgroundHover
        : colors.trackBackground;

    final thumbColor = isDisabled ? colors.thumbDisabled : colors.thumb;

    final borderColor = _isFocused
        ? colors.borderFocus
        : isDisabled
        ? colors.trackBackgroundDisabled
        : widget.value
        ? colors.borderActive
        : colors.border;

    // 최소 터치 영역 보장 (44x44)
    return Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _thumbAnimation,
        builder: (context, child) {
          return Container(
            width: trackWidth,
            height: trackHeight,
            decoration: BoxDecoration(
              color: ColorTween(
                begin: colors.trackBackground,
                end: trackColor,
              ).evaluate(_thumbAnimation),
              borderRadius: BorderRadius.circular(trackHeight / 2),
              border: Border.all(
                color: borderColor,
                width: _isFocused
                    ? BorderTokens.switchBorderFocus
                    : BorderTokens.switchBorderThin,
              ),
            ),
            child: Stack(
              children: [
                // Thumb
                Positioned(
                  left: thumbPadding + (thumbTravel * _thumbAnimation.value),
                  top: thumbPadding,
                  child: widget.isLoading
                      ? SizedBox(
                          width: thumbSize,
                          height: thumbSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: thumbColor,
                          ),
                        )
                      : Container(
                          width: thumbSize,
                          height: thumbSize,
                          decoration: BoxDecoration(
                            color: thumbColor,
                            shape: BoxShape.circle,
                            boxShadow: isDisabled
                                ? null
                                : [
                                    BoxShadow(
                                      color: colorExt.shadow,
                                      blurRadius:
                                          ComponentSizeTokens.switchShadowBlur,
                                      offset: Offset(
                                        ComponentSizeTokens.switchShadowOffsetX,
                                        ComponentSizeTokens.switchShadowOffsetY,
                                      ),
                                    ),
                                  ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Switch 그룹 (여러 스위치를 세로로 나열)
///
/// ```dart
/// AppSwitchGroup(
///   items: [
///     AppSwitchItem(
///       value: _notifications,
///       label: '알림',
///       description: '푸시 알림 받기',
///       onChanged: (v) => setState(() => _notifications = v),
///     ),
///     AppSwitchItem(
///       value: _sound,
///       label: '소리',
///       description: '알림 소리 재생',
///       onChanged: (v) => setState(() => _sound = v),
///     ),
///   ],
/// )
/// ```
class AppSwitchGroup extends StatelessWidget {
  /// 스위치 아이템 목록
  final List<AppSwitchItem> items;

  /// 스위치 크기
  final AppSwitchSize size;

  /// 아이템 사이 간격
  final double? spacing;

  const AppSwitchGroup({
    super.key,
    required this.items,
    this.size = AppSwitchSize.medium,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;
    final itemSpacing = spacing ?? spacingExt.large;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          AppSwitch(
            value: items[i].value,
            onChanged: items[i].onChanged,
            size: size,
            label: items[i].label,
            description: items[i].description,
            isDisabled: items[i].isDisabled,
            activeColor: items[i].activeColor,
          ),
          if (i < items.length - 1) SizedBox(height: itemSpacing),
        ],
      ],
    );
  }
}

/// Switch 그룹 아이템
class AppSwitchItem {
  /// 현재 값
  final bool value;

  /// 라벨 텍스트
  final String? label;

  /// 설명 텍스트
  final String? description;

  /// 값 변경 콜백
  final ValueChanged<bool>? onChanged;

  /// 비활성화 상태
  final bool isDisabled;

  /// 커스텀 활성 색상
  final Color? activeColor;

  const AppSwitchItem({
    required this.value,
    this.label,
    this.description,
    this.onChanged,
    this.isDisabled = false,
    this.activeColor,
  });
}
