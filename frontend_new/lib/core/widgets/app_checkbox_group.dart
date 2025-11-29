import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/checkbox_group_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';
import '../theme/component_size_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppCheckboxOrientation, AppCheckboxSize;

/// 체크박스 그룹 아이템
class AppCheckboxItem<T> {
  /// 항목의 값
  final T value;

  /// 라벨 텍스트
  final String label;

  /// 설명 텍스트 (선택)
  final String? description;

  /// 비활성화 상태
  final bool isDisabled;

  const AppCheckboxItem({
    required this.value,
    required this.label,
    this.description,
    this.isDisabled = false,
  });
}

/// 다중 선택 체크박스 그룹
///
/// **용도**: 여러 옵션 중 다수를 선택하는 경우
/// **접근성**: 최소 터치 영역 44px 보장, 키보드 네비게이션, Semantics 지원
/// **반응형**: 크기 옵션 및 방향(세로/가로) 선택 가능
///
/// ```dart
/// // 기본 사용 (세로 배치)
/// AppCheckboxGroup<String>(
///   items: [
///     AppCheckboxItem(value: 'email', label: '이메일'),
///     AppCheckboxItem(value: 'sms', label: 'SMS'),
///     AppCheckboxItem(value: 'push', label: '푸시 알림'),
///   ],
///   values: _selectedNotifications,
///   onChanged: (values) => setState(() => _selectedNotifications = values),
/// )
///
/// // 가로 배치 + 그룹 라벨
/// AppCheckboxGroup<String>(
///   label: '관심 분야',
///   orientation: AppCheckboxOrientation.horizontal,
///   items: [
///     AppCheckboxItem(value: 'tech', label: '기술'),
///     AppCheckboxItem(value: 'design', label: '디자인'),
///     AppCheckboxItem(value: 'business', label: '비즈니스'),
///   ],
///   values: _interests,
///   onChanged: (values) => setState(() => _interests = values),
/// )
///
/// // 최대 선택 개수 제한
/// AppCheckboxGroup<String>(
///   label: '좋아하는 색상 (최대 2개)',
///   maxSelections: 2,
///   items: [
///     AppCheckboxItem(value: 'red', label: '빨강'),
///     AppCheckboxItem(value: 'blue', label: '파랑'),
///     AppCheckboxItem(value: 'green', label: '초록'),
///     AppCheckboxItem(value: 'yellow', label: '노랑'),
///   ],
///   values: _favoriteColors,
///   onChanged: (values) => setState(() => _favoriteColors = values),
/// )
/// ```
class AppCheckboxGroup<T> extends StatelessWidget {
  /// 체크박스 아이템 목록
  final List<AppCheckboxItem<T>> items;

  /// 현재 선택된 값들
  final List<T> values;

  /// 값 변경 콜백
  final ValueChanged<List<T>>? onChanged;

  /// 그룹 방향
  final AppCheckboxOrientation orientation;

  /// 체크박스 크기
  final AppCheckboxSize size;

  /// 그룹 라벨
  final String? label;

  /// 에러 텍스트
  final String? errorText;

  /// 전체 비활성화
  final bool isDisabled;

  /// 최대 선택 개수 (null이면 제한 없음)
  final int? maxSelections;

  /// 커스텀 선택 색상
  final Color? checkedColor;

  /// 아이템 간 간격
  final double? spacing;

  const AppCheckboxGroup({
    super.key,
    required this.items,
    required this.values,
    this.onChanged,
    this.orientation = AppCheckboxOrientation.vertical,
    this.size = AppCheckboxSize.medium,
    this.label,
    this.errorText,
    this.isDisabled = false,
    this.maxSelections,
    this.checkedColor,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    final colors = checkedColor != null
        ? CheckboxGroupColors.withCheckedColor(colorExt, checkedColor!)
        : CheckboxGroupColors.from(colorExt);

    final itemSpacing =
        spacing ??
        (orientation == AppCheckboxOrientation.vertical
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

        // 체크박스 아이템들
        if (orientation == AppCheckboxOrientation.vertical)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _buildCheckboxItem(context, colors, items[i], i),
                if (i < items.length - 1) SizedBox(height: itemSpacing),
              ],
            ],
          )
        else
          Wrap(
            spacing: itemSpacing,
            runSpacing: itemSpacing,
            children: [
              for (final item in items)
                _buildCheckboxItem(context, colors, item, 0),
            ],
          ),

        // 에러 텍스트
        if (errorText != null) ...[
          SizedBox(height: context.appSpacing.xs),
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

  Widget _buildCheckboxItem(
    BuildContext context,
    CheckboxGroupColors colors,
    AppCheckboxItem<T> item,
    int index,
  ) {
    final isItemDisabled =
        isDisabled ||
        item.isDisabled ||
        (maxSelections != null &&
            values.length >= maxSelections! &&
            !values.contains(item.value));

    return _AppCheckbox<T>(
      item: item,
      isChecked: values.contains(item.value),
      onChanged: isItemDisabled || onChanged == null
          ? null
          : (checked) {
              final newValues = List<T>.from(values);
              if (checked) {
                if (maxSelections != null &&
                    newValues.length >= maxSelections!) {
                  return;
                }
                newValues.add(item.value);
              } else {
                newValues.remove(item.value);
              }
              onChanged!(newValues);
            },
      colors: colors,
      size: size,
      isDisabled: isItemDisabled,
    );
  }
}

/// 개별 체크박스 위젯
class _AppCheckbox<T> extends StatefulWidget {
  final AppCheckboxItem<T> item;
  final bool isChecked;
  final ValueChanged<bool>? onChanged;
  final CheckboxGroupColors colors;
  final AppCheckboxSize size;
  final bool isDisabled;

  const _AppCheckbox({
    required this.item,
    required this.isChecked,
    required this.onChanged,
    required this.colors,
    required this.size,
    required this.isDisabled,
  });

  @override
  State<_AppCheckbox<T>> createState() => _AppCheckboxState<T>();
}

class _AppCheckboxState<T> extends State<_AppCheckbox<T>>
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

    if (widget.isChecked) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AppCheckbox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked) {
      if (widget.isChecked) {
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
    if (widget.isDisabled || widget.onChanged == null) return;
    widget.onChanged!(!widget.isChecked);
  }

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    // 사이즈별 토큰
    final (checkboxSize, iconSize) = switch (widget.size) {
      AppCheckboxSize.small => (
        ComponentSizeTokens.checkboxSmallSize,
        ComponentSizeTokens.checkboxSmallIconSize,
      ),
      AppCheckboxSize.medium => (
        ComponentSizeTokens.checkboxMediumSize,
        ComponentSizeTokens.checkboxMediumIconSize,
      ),
      AppCheckboxSize.large => (
        ComponentSizeTokens.checkboxLargeSize,
        ComponentSizeTokens.checkboxLargeIconSize,
      ),
    };

    return Semantics(
      checked: widget.isChecked,
      enabled: !widget.isDisabled,
      label: widget.item.label,
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: GestureDetector(
          onTap: _handleTap,
          child: MouseRegion(
            cursor: widget.isDisabled
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
                  // 체크박스
                  _buildCheckbox(checkboxSize, iconSize),
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
                                color: widget.isDisabled
                                    ? widget.colors.disabledText
                                    : widget.colors.labelText,
                                fontWeight: widget.isChecked
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
                                  color: widget.isDisabled
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

  Widget _buildCheckbox(double checkboxSize, double iconSize) {
    // 상태별 색상
    final borderColor = widget.isDisabled
        ? widget.colors.borderDisabled
        : _isFocused
        ? widget.colors.borderFocus
        : widget.isChecked
        ? widget.colors.borderChecked
        : _isHovered
        ? widget.colors.borderHover
        : widget.colors.border;

    final backgroundColor = widget.isDisabled
        ? widget.colors.backgroundDisabled
        : widget.isChecked
        ? widget.colors.backgroundChecked
        : _isHovered
        ? widget.colors.backgroundHover
        : widget.colors.background;

    final iconColor = widget.isDisabled
        ? widget.colors.checkIconDisabled
        : widget.colors.checkIcon;

    final borderWidth = _isFocused
        ? ComponentSizeTokens.checkboxFocusBorderWidth
        : ComponentSizeTokens.checkboxBorderWidth;

    return AnimatedContainer(
      duration: AnimationTokens.durationQuick,
      width: checkboxSize,
      height: checkboxSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          ComponentSizeTokens.checkboxBorderRadius,
        ),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(Icons.check, size: iconSize, color: iconColor),
            );
          },
        ),
      ),
    );
  }
}

/// 단일 체크박스 위젯 (그룹 없이 독립적으로 사용)
///
/// ```dart
/// AppCheckbox(
///   value: _agreeToTerms,
///   onChanged: (value) => setState(() => _agreeToTerms = value),
///   label: '이용약관에 동의합니다',
/// )
/// ```
class AppCheckbox extends StatefulWidget {
  /// 현재 값
  final bool value;

  /// 값 변경 콜백
  final ValueChanged<bool>? onChanged;

  /// 체크박스 크기
  final AppCheckboxSize size;

  /// 라벨 텍스트
  final String? label;

  /// 설명 텍스트
  final String? description;

  /// 비활성화 상태
  final bool isDisabled;

  /// 커스텀 선택 색상
  final Color? checkedColor;

  const AppCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = AppCheckboxSize.medium,
    this.label,
    this.description,
    this.isDisabled = false,
    this.checkedColor,
  });

  @override
  State<AppCheckbox> createState() => _AppCheckboxState2();
}

class _AppCheckboxState2 extends State<AppCheckbox>
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

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AppCheckbox oldWidget) {
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
    if (widget.isDisabled || widget.onChanged == null) return;
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    final colors = widget.checkedColor != null
        ? CheckboxGroupColors.withCheckedColor(colorExt, widget.checkedColor!)
        : CheckboxGroupColors.from(colorExt);

    final isDisabled = widget.isDisabled || widget.onChanged == null;

    // 사이즈별 토큰
    final (checkboxSize, iconSize) = switch (widget.size) {
      AppCheckboxSize.small => (
        ComponentSizeTokens.checkboxSmallSize,
        ComponentSizeTokens.checkboxSmallIconSize,
      ),
      AppCheckboxSize.medium => (
        ComponentSizeTokens.checkboxMediumSize,
        ComponentSizeTokens.checkboxMediumIconSize,
      ),
      AppCheckboxSize.large => (
        ComponentSizeTokens.checkboxLargeSize,
        ComponentSizeTokens.checkboxLargeIconSize,
      ),
    };

    // 상태별 색상
    final borderColor = isDisabled
        ? colors.borderDisabled
        : _isFocused
        ? colors.borderFocus
        : widget.value
        ? colors.borderChecked
        : _isHovered
        ? colors.borderHover
        : colors.border;

    final backgroundColor = isDisabled
        ? colors.backgroundDisabled
        : widget.value
        ? colors.backgroundChecked
        : _isHovered
        ? colors.backgroundHover
        : colors.background;

    final iconColor = isDisabled ? colors.checkIconDisabled : colors.checkIcon;

    final borderWidth = _isFocused
        ? ComponentSizeTokens.checkboxFocusBorderWidth
        : ComponentSizeTokens.checkboxBorderWidth;

    return Semantics(
      checked: widget.value,
      enabled: !isDisabled,
      label: widget.label ?? '체크박스',
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
            child: Container(
              constraints: const BoxConstraints(
                minHeight: ComponentSizeTokens.minTouchTarget,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: widget.description != null
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  // 체크박스
                  AnimatedContainer(
                    duration: AnimationTokens.durationQuick,
                    width: checkboxSize,
                    height: checkboxSize,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(
                        ComponentSizeTokens.checkboxBorderRadius,
                      ),
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Icon(
                              Icons.check,
                              size: iconSize,
                              color: iconColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 라벨 및 설명
                  if (widget.label != null || widget.description != null) ...[
                    SizedBox(width: spacingExt.small),
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
                                    fontWeight: widget.value
                                        ? FontWeight.w500
                                        : FontWeight.normal,
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
      ),
    );
  }
}
