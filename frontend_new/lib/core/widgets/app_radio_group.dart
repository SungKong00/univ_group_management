import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/radio_group_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';
import '../theme/component_size_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppRadioOrientation, AppRadioSize;

/// 라디오 버튼 그룹 아이템
class AppRadioItem<T> {
  /// 항목의 값
  final T value;

  /// 라벨 텍스트
  final String label;

  /// 설명 텍스트 (선택)
  final String? description;

  /// 비활성화 상태
  final bool isDisabled;

  const AppRadioItem({
    required this.value,
    required this.label,
    this.description,
    this.isDisabled = false,
  });
}

/// 단일 선택 라디오 버튼 그룹
///
/// **용도**: 여러 옵션 중 하나만 선택하는 경우
/// **접근성**: 최소 터치 영역 44px 보장, 키보드 네비게이션, Semantics 지원
/// **반응형**: 크기 옵션 및 방향(세로/가로) 선택 가능
///
/// ```dart
/// // 기본 사용 (세로 배치)
/// AppRadioGroup<String>(
///   items: [
///     AppRadioItem(value: 'option1', label: '옵션 1'),
///     AppRadioItem(value: 'option2', label: '옵션 2'),
///     AppRadioItem(value: 'option3', label: '옵션 3'),
///   ],
///   value: _selectedOption,
///   onChanged: (value) => setState(() => _selectedOption = value),
/// )
///
/// // 가로 배치 + 그룹 라벨
/// AppRadioGroup<String>(
///   label: '결제 방법',
///   orientation: AppRadioOrientation.horizontal,
///   items: [
///     AppRadioItem(value: 'card', label: '신용카드'),
///     AppRadioItem(value: 'bank', label: '계좌이체'),
///   ],
///   value: _paymentMethod,
///   onChanged: (value) => setState(() => _paymentMethod = value),
/// )
///
/// // 설명 포함 옵션
/// AppRadioGroup<String>(
///   label: '알림 설정',
///   items: [
///     AppRadioItem(
///       value: 'all',
///       label: '모든 알림',
///       description: '모든 활동에 대해 알림을 받습니다',
///     ),
///     AppRadioItem(
///       value: 'mentions',
///       label: '멘션만',
///       description: '나를 언급한 경우에만 알림을 받습니다',
///     ),
///     AppRadioItem(
///       value: 'none',
///       label: '알림 끄기',
///       description: '알림을 받지 않습니다',
///     ),
///   ],
///   value: _notificationSetting,
///   onChanged: (value) => setState(() => _notificationSetting = value),
/// )
/// ```
class AppRadioGroup<T> extends StatelessWidget {
  /// 라디오 아이템 목록
  final List<AppRadioItem<T>> items;

  /// 현재 선택된 값
  final T? value;

  /// 값 변경 콜백
  final ValueChanged<T?>? onChanged;

  /// 그룹 방향
  final AppRadioOrientation orientation;

  /// 라디오 크기
  final AppRadioSize size;

  /// 그룹 라벨
  final String? label;

  /// 에러 텍스트
  final String? errorText;

  /// 전체 비활성화
  final bool isDisabled;

  /// 커스텀 선택 색상
  final Color? selectedColor;

  /// 아이템 간 간격
  final double? spacing;

  const AppRadioGroup({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.orientation = AppRadioOrientation.vertical,
    this.size = AppRadioSize.medium,
    this.label,
    this.errorText,
    this.isDisabled = false,
    this.selectedColor,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    final colors = selectedColor != null
        ? RadioGroupColors.withSelectedColor(colorExt, selectedColor!)
        : RadioGroupColors.from(colorExt);

    final itemSpacing =
        spacing ??
        (orientation == AppRadioOrientation.vertical
            ? spacingExt.medium
            : spacingExt.large);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 그룹 라벨
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isDisabled ? colors.disabledText : colors.groupLabelText,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacingExt.small),
        ],

        // 라디오 아이템들
        if (orientation == AppRadioOrientation.vertical)
          _buildVerticalLayout(colors, itemSpacing)
        else
          _buildHorizontalLayout(colors, itemSpacing),

        // 에러 텍스트
        if (errorText != null) ...[
          SizedBox(height: spacingExt.xs),
          Text(
            errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.errorText),
          ),
        ],
      ],
    );
  }

  Widget _buildVerticalLayout(RadioGroupColors colors, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _AppRadioButton<T>(
            item: items[i],
            isSelected: value == items[i].value,
            onChanged: isDisabled || items[i].isDisabled || onChanged == null
                ? null
                : () => onChanged!(items[i].value),
            colors: colors,
            size: size,
            isGroupDisabled: isDisabled,
          ),
          if (i < items.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }

  Widget _buildHorizontalLayout(RadioGroupColors colors, double spacing) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: items.map((item) {
        return _AppRadioButton<T>(
          item: item,
          isSelected: value == item.value,
          onChanged: isDisabled || item.isDisabled || onChanged == null
              ? null
              : () => onChanged!(item.value),
          colors: colors,
          size: size,
          isGroupDisabled: isDisabled,
        );
      }).toList(),
    );
  }
}

/// 개별 라디오 버튼 위젯
class _AppRadioButton<T> extends StatefulWidget {
  final AppRadioItem<T> item;
  final bool isSelected;
  final VoidCallback? onChanged;
  final RadioGroupColors colors;
  final AppRadioSize size;
  final bool isGroupDisabled;

  const _AppRadioButton({
    required this.item,
    required this.isSelected,
    required this.onChanged,
    required this.colors,
    required this.size,
    required this.isGroupDisabled,
  });

  @override
  State<_AppRadioButton<T>> createState() => _AppRadioButtonState<T>();
}

class _AppRadioButtonState<T> extends State<_AppRadioButton<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationTokens.durationQuick,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationTokens.curveSmooth),
    );

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AppRadioButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
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

  bool get _isDisabled =>
      widget.isGroupDisabled ||
      widget.item.isDisabled ||
      widget.onChanged == null;

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    // 사이즈별 토큰
    final (radioSize, indicatorSize) = switch (widget.size) {
      AppRadioSize.small => (
        ComponentSizeTokens.radioSmallSize,
        ComponentSizeTokens.radioSmallIndicatorSize,
      ),
      AppRadioSize.medium => (
        ComponentSizeTokens.radioMediumSize,
        ComponentSizeTokens.radioMediumIndicatorSize,
      ),
      AppRadioSize.large => (
        ComponentSizeTokens.radioLargeSize,
        ComponentSizeTokens.radioLargeIndicatorSize,
      ),
    };

    return Semantics(
      selected: widget.isSelected,
      enabled: !_isDisabled,
      label: widget.item.label,
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: GestureDetector(
          onTap: _isDisabled ? null : widget.onChanged,
          child: MouseRegion(
            cursor: _isDisabled
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: ComponentSizeTokens.minTouchTarget,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: widget.item.description != null
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  // 라디오 버튼
                  _buildRadioCircle(radioSize, indicatorSize),
                  SizedBox(width: spacingExt.small),
                  // 라벨 및 설명
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.item.label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _isDisabled
                                    ? widget.colors.disabledText
                                    : widget.colors.labelText,
                                fontWeight: widget.isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                        ),
                        if (widget.item.description != null) ...[
                          SizedBox(height: spacingExt.xs),
                          Text(
                            widget.item.description!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: _isDisabled
                                      ? widget.colors.disabledText
                                      : widget.colors.descriptionText,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioCircle(double radioSize, double indicatorSize) {
    // 상태별 색상
    final borderColor = _isDisabled
        ? widget.colors.borderDisabled
        : _isFocused
        ? widget.colors.borderFocus
        : widget.isSelected
        ? widget.colors.borderSelected
        : _isHovered
        ? widget.colors.borderHover
        : widget.colors.border;

    final backgroundColor = _isDisabled
        ? widget.colors.backgroundDisabled
        : _isHovered && !widget.isSelected
        ? widget.colors.backgroundHover
        : widget.colors.background;

    final indicatorColor = _isDisabled
        ? widget.colors.indicatorDisabled
        : widget.colors.indicator;

    final borderWidth = _isFocused
        ? ComponentSizeTokens.radioFocusBorderWidth
        : ComponentSizeTokens.radioBorderWidth;

    return AnimatedContainer(
      duration: AnimationTokens.durationQuick,
      width: radioSize,
      height: radioSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: indicatorSize,
                height: indicatorSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: indicatorColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
