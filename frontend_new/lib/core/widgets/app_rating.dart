import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/rating_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppRatingStyle, AppRatingSize;

/// 별점 컴포넌트
///
/// **용도**: 평가, 리뷰, 피드백
/// **접근성**: Semantics 지원, 키보드 조작
///
/// ```dart
/// // 기본 별점
/// AppRating(
///   value: 3.5,
///   onChanged: (rating) => print(rating),
/// )
///
/// // 읽기 전용
/// AppRating(
///   value: 4.0,
///   readOnly: true,
/// )
///
/// // 하트 스타일
/// AppRating(
///   value: 5,
///   style: AppRatingStyle.heart,
///   maxRating: 5,
/// )
/// ```
class AppRating extends StatefulWidget {
  /// 현재 값
  final double value;

  /// 값 변경 콜백
  final ValueChanged<double>? onChanged;

  /// 최대 값
  final int maxRating;

  /// 스타일
  final AppRatingStyle style;

  /// 크기
  final AppRatingSize size;

  /// 읽기 전용
  final bool readOnly;

  /// 0.5 단위 허용
  final bool allowHalf;

  /// 보조 텍스트 (리뷰 수 등)
  final String? auxiliaryText;

  /// 숫자 표시 (numeric 스타일)
  final bool showValue;

  /// 커스텀 빈 아이콘
  final IconData? emptyIcon;

  /// 커스텀 채운 아이콘
  final IconData? filledIcon;

  /// 커스텀 반 채운 아이콘
  final IconData? halfIcon;

  const AppRating({
    super.key,
    required this.value,
    this.onChanged,
    this.maxRating = 5,
    this.style = AppRatingStyle.star,
    this.size = AppRatingSize.medium,
    this.readOnly = false,
    this.allowHalf = true,
    this.auxiliaryText,
    this.showValue = false,
    this.emptyIcon,
    this.filledIcon,
    this.halfIcon,
  });

  @override
  State<AppRating> createState() => _AppRatingState();
}

class _AppRatingState extends State<AppRating> {
  double? _hoverValue;

  double get _displayValue => _hoverValue ?? widget.value;

  double _getIconSize() {
    return switch (widget.size) {
      AppRatingSize.small => 16.0,
      AppRatingSize.medium => 24.0,
      AppRatingSize.large => 32.0,
    };
  }

  IconData _getEmptyIcon() {
    if (widget.emptyIcon != null) return widget.emptyIcon!;
    return switch (widget.style) {
      AppRatingStyle.star => Icons.star_outline,
      AppRatingStyle.heart => Icons.favorite_outline,
      AppRatingStyle.numeric => Icons.circle_outlined,
    };
  }

  IconData _getFilledIcon() {
    if (widget.filledIcon != null) return widget.filledIcon!;
    return switch (widget.style) {
      AppRatingStyle.star => Icons.star,
      AppRatingStyle.heart => Icons.favorite,
      AppRatingStyle.numeric => Icons.circle,
    };
  }

  IconData _getHalfIcon() {
    if (widget.halfIcon != null) return widget.halfIcon!;
    return switch (widget.style) {
      AppRatingStyle.star => Icons.star_half,
      AppRatingStyle.heart => Icons.favorite,
      AppRatingStyle.numeric => Icons.circle,
    };
  }

  void _handleTap(int index, Offset localPosition, double itemWidth) {
    if (widget.readOnly || widget.onChanged == null) return;

    double newValue;
    if (widget.allowHalf) {
      // 아이콘 왼쪽 절반이면 0.5, 오른쪽 절반이면 1.0
      final isLeftHalf = localPosition.dx < itemWidth / 2;
      newValue = index + (isLeftHalf ? 0.5 : 1.0);
    } else {
      newValue = index + 1.0;
    }

    widget.onChanged?.call(newValue.clamp(0.0, widget.maxRating.toDouble()));
  }

  void _handleHover(int index, Offset localPosition, double itemWidth) {
    if (widget.readOnly) return;

    double hoverValue;
    if (widget.allowHalf) {
      final isLeftHalf = localPosition.dx < itemWidth / 2;
      hoverValue = index + (isLeftHalf ? 0.5 : 1.0);
    } else {
      hoverValue = index + 1.0;
    }

    setState(() {
      _hoverValue = hoverValue.clamp(0.0, widget.maxRating.toDouble());
    });
  }

  void _handleHoverExit() {
    if (widget.readOnly) return;
    setState(() {
      _hoverValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = widget.style == AppRatingStyle.heart
        ? RatingColors.heart(colorExt)
        : RatingColors.from(colorExt);

    if (widget.style == AppRatingStyle.numeric) {
      return _NumericRating(
        value: widget.value,
        maxRating: widget.maxRating,
        size: widget.size,
        colors: colors,
        auxiliaryText: widget.auxiliaryText,
      );
    }

    final iconSize = _getIconSize();

    return Semantics(
      label: '평점 ${widget.value}점 (${widget.maxRating}점 만점)',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(widget.maxRating, (index) {
            return _RatingIcon(
              index: index,
              value: _displayValue,
              iconSize: iconSize,
              colors: colors,
              emptyIcon: _getEmptyIcon(),
              filledIcon: _getFilledIcon(),
              halfIcon: _getHalfIcon(),
              isHovered: _hoverValue != null,
              readOnly: widget.readOnly,
              onTap: (localPos) => _handleTap(index, localPos, iconSize),
              onHover: (localPos) => _handleHover(index, localPos, iconSize),
              onHoverExit: _handleHoverExit,
            );
          }),
          if (widget.showValue || widget.auxiliaryText != null) ...[
            SizedBox(width: 8),
            Text(
              widget.showValue
                  ? '${widget.value}'
                  : '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (widget.auxiliaryText != null) ...[
              SizedBox(width: 4),
              Text(
                widget.auxiliaryText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.secondaryText,
                    ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// 개별 별점 아이콘
class _RatingIcon extends StatelessWidget {
  final int index;
  final double value;
  final double iconSize;
  final RatingColors colors;
  final IconData emptyIcon;
  final IconData filledIcon;
  final IconData halfIcon;
  final bool isHovered;
  final bool readOnly;
  final void Function(Offset) onTap;
  final void Function(Offset) onHover;
  final VoidCallback onHoverExit;

  const _RatingIcon({
    required this.index,
    required this.value,
    required this.iconSize,
    required this.colors,
    required this.emptyIcon,
    required this.filledIcon,
    required this.halfIcon,
    required this.isHovered,
    required this.readOnly,
    required this.onTap,
    required this.onHover,
    required this.onHoverExit,
  });

  IconData get _icon {
    final fillAmount = value - index;
    if (fillAmount >= 1) return filledIcon;
    if (fillAmount >= 0.5) return halfIcon;
    return emptyIcon;
  }

  Color get _color {
    final fillAmount = value - index;
    if (fillAmount > 0) {
      return isHovered ? colors.hover : colors.active;
    }
    return colors.inactive;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: readOnly ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onHover: (event) => onHover(event.localPosition),
      onExit: (_) => onHoverExit(),
      child: GestureDetector(
        onTapDown: readOnly
            ? null
            : (details) => onTap(details.localPosition),
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            _icon,
            size: iconSize,
            color: _color,
          ),
        ),
      ),
    );
  }
}

/// 숫자 스타일 레이팅
class _NumericRating extends StatelessWidget {
  final double value;
  final int maxRating;
  final AppRatingSize size;
  final RatingColors colors;
  final String? auxiliaryText;

  const _NumericRating({
    required this.value,
    required this.maxRating,
    required this.size,
    required this.colors,
    this.auxiliaryText,
  });

  double get _fontSize {
    return switch (size) {
      AppRatingSize.small => 14.0,
      AppRatingSize.medium => 18.0,
      AppRatingSize.large => 24.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        Text(
          ' / $maxRating',
          style: TextStyle(
            fontSize: _fontSize * 0.7,
            color: colors.secondaryText,
          ),
        ),
        if (auxiliaryText != null) ...[
          SizedBox(width: 8),
          Text(
            auxiliaryText!,
            style: TextStyle(
              fontSize: _fontSize * 0.7,
              color: colors.secondaryText,
            ),
          ),
        ],
      ],
    );
  }
}

/// 읽기 전용 컴팩트 별점 표시
class AppRatingDisplay extends StatelessWidget {
  /// 현재 값
  final double value;

  /// 최대 값
  final int maxRating;

  /// 크기
  final AppRatingSize size;

  /// 보조 텍스트
  final String? auxiliaryText;

  const AppRatingDisplay({
    super.key,
    required this.value,
    this.maxRating = 5,
    this.size = AppRatingSize.small,
    this.auxiliaryText,
  });

  @override
  Widget build(BuildContext context) {
    return AppRating(
      value: value,
      maxRating: maxRating,
      size: size,
      readOnly: true,
      showValue: true,
      auxiliaryText: auxiliaryText,
    );
  }
}
