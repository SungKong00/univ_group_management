import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// AppChip 색상 변형
enum AppChipVariant {
  /// 기본 (neutral) - 일반적인 태그, 라벨
  defaultVariant,

  /// Primary (brand) - 브랜드 강조 칩
  primary,

  /// Success (green) - 성공, 활성화 상태
  success,

  /// Warning (yellow) - 경고, 주의
  warning,

  /// Error (red) - 오류, 위험
  error,
}

/// AppChip 크기 변형
enum AppChipSize {
  /// Small - 12px 폰트, 작은 패딩
  small,

  /// Medium - 14px 폰트, 중간 패딩 (기본값)
  medium,

  /// Large - 16px 폰트, 큰 패딩
  large,
}

/// 재사용 가능한 범용 Chip 컴포넌트
///
/// **용도**: 태그, 필터, 상태 표시, 선택 가능한 옵션
///
/// **특징**:
/// - 텍스트 + 선택적 아이콘 (선행/후행)
/// - 삭제 버튼(× icon) 지원
/// - 선택 가능/불가능 상태
/// - 비활성화 상태
/// - 다양한 색상 변형 (default, primary, success, warning, error)
/// - 크기 변형 (small, medium, large)
///
/// **사용 예시**:
/// ```dart
/// // 기본 칩
/// AppChip(label: '태그')
///
/// // 삭제 가능 칩
/// AppChip(
///   label: '검색어',
///   onDeleted: () => print('삭제'),
/// )
///
/// // 선택 가능 칩
/// AppChip(
///   label: '필터',
///   selected: isSelected,
///   onSelected: (selected) => setState(() => isSelected = selected),
/// )
///
/// // 아이콘 포함 칩
/// AppChip(
///   label: '그룹',
///   leadingIcon: Icons.group,
///   variant: AppChipVariant.primary,
/// )
/// ```
class AppChip extends StatelessWidget {
  /// 칩에 표시될 텍스트 (필수)
  final String label;

  /// 선택 여부
  final bool selected;

  /// 선택 콜백 (null이면 선택 불가능)
  final ValueChanged<bool>? onSelected;

  /// 삭제 콜백 (null이면 삭제 버튼 미표시)
  final VoidCallback? onDeleted;

  /// 선행 아이콘 (텍스트 앞)
  final IconData? leadingIcon;

  /// 후행 아이콘 (텍스트 뒤, 삭제 버튼과 함께 표시 안됨)
  final IconData? trailingIcon;

  /// 색상 변형
  final AppChipVariant variant;

  /// 크기 변형
  final AppChipSize size;

  /// 비활성화 여부
  final bool enabled;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.onDeleted,
    this.leadingIcon,
    this.trailingIcon,
    this.variant = AppChipVariant.defaultVariant,
    this.size = AppChipSize.medium,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final specs = _getSizeSpecs();

    // 선택 가능한 칩
    if (onSelected != null) {
      return FilterChip(
        label: _buildLabel(specs),
        selected: selected,
        onSelected: enabled ? onSelected : null,
        avatar: leadingIcon != null ? Icon(leadingIcon, size: specs.iconSize) : null,
        deleteIcon: onDeleted != null ? Icon(Icons.close, size: specs.iconSize) : null,
        onDeleted: enabled && onDeleted != null ? onDeleted : null,
        backgroundColor: enabled ? colors.backgroundColor : AppColors.disabledBgLight,
        selectedColor: enabled ? colors.selectedBackgroundColor : AppColors.disabledBgLight,
        checkmarkColor: enabled ? colors.selectedForegroundColor : AppColors.disabledTextLight,
        labelStyle: TextStyle(
          fontSize: specs.fontSize,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: enabled
              ? (selected ? colors.selectedForegroundColor : colors.foregroundColor)
              : AppColors.disabledTextLight,
        ),
        padding: specs.padding,
        labelPadding: specs.labelPadding,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(specs.borderRadius),
          side: BorderSide(
            color: enabled
                ? (selected ? colors.selectedBackgroundColor : colors.borderColor)
                : AppColors.disabledBgLight,
            width: 1,
          ),
        ),
      );
    }

    // 정적 칩 (선택 불가능)
    return Chip(
      label: _buildLabel(specs),
      avatar: leadingIcon != null
          ? Icon(
              leadingIcon,
              size: specs.iconSize,
              color: enabled ? colors.foregroundColor : AppColors.disabledTextLight,
            )
          : null,
      deleteIcon: onDeleted != null
          ? Icon(
              Icons.close,
              size: specs.iconSize,
              color: enabled ? colors.foregroundColor : AppColors.disabledTextLight,
            )
          : null,
      onDeleted: enabled && onDeleted != null ? onDeleted : null,
      backgroundColor: enabled ? colors.backgroundColor : AppColors.disabledBgLight,
      labelStyle: TextStyle(
        fontSize: specs.fontSize,
        fontWeight: FontWeight.w400,
        color: enabled ? colors.foregroundColor : AppColors.disabledTextLight,
      ),
      padding: specs.padding,
      labelPadding: specs.labelPadding,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(specs.borderRadius),
        side: BorderSide(
          color: enabled ? colors.borderColor : AppColors.disabledBgLight,
          width: 1,
        ),
      ),
      side: BorderSide(
        color: enabled ? colors.borderColor : AppColors.disabledBgLight,
        width: 1,
      ),
    );
  }

  /// 라벨 위젯 생성
  Widget _buildLabel(_ChipSizeSpecs specs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (trailingIcon != null && onDeleted == null) ...[
          SizedBox(width: specs.iconSpacing),
          Icon(
            trailingIcon,
            size: specs.iconSize,
            color: enabled
                ? (selected ? _getColors().selectedForegroundColor : _getColors().foregroundColor)
                : AppColors.disabledTextLight,
          ),
        ],
      ],
    );
  }

  /// Variant에 따른 색상 반환
  _ChipColors _getColors() {
    switch (variant) {
      case AppChipVariant.primary:
        return _ChipColors(
          backgroundColor: AppColors.brandLight,
          selectedBackgroundColor: AppColors.brand,
          foregroundColor: AppColors.brand,
          selectedForegroundColor: Colors.white,
          borderColor: AppColors.brand,
        );

      case AppChipVariant.success:
        return _ChipColors(
          backgroundColor: AppColors.success.withOpacity(0.1),
          selectedBackgroundColor: AppColors.success,
          foregroundColor: AppColors.success,
          selectedForegroundColor: Colors.white,
          borderColor: AppColors.success,
        );

      case AppChipVariant.warning:
        return _ChipColors(
          backgroundColor: AppColors.warning.withOpacity(0.1),
          selectedBackgroundColor: AppColors.warning,
          foregroundColor: AppColors.warning,
          selectedForegroundColor: Colors.white,
          borderColor: AppColors.warning,
        );

      case AppChipVariant.error:
        return _ChipColors(
          backgroundColor: AppColors.error.withOpacity(0.1),
          selectedBackgroundColor: AppColors.error,
          foregroundColor: AppColors.error,
          selectedForegroundColor: Colors.white,
          borderColor: AppColors.error,
        );

      case AppChipVariant.defaultVariant:
      default:
        return _ChipColors(
          backgroundColor: AppColors.neutral100,
          selectedBackgroundColor: AppColors.brandLight,
          foregroundColor: AppColors.neutral700,
          selectedForegroundColor: AppColors.brand,
          borderColor: AppColors.neutral400,
        );
    }
  }

  /// Size에 따른 스펙 반환
  _ChipSizeSpecs _getSizeSpecs() {
    switch (size) {
      case AppChipSize.small:
        return _ChipSizeSpecs(
          fontSize: 12,
          iconSize: 14,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          borderRadius: AppRadius.sm,
          iconSpacing: 4,
        );

      case AppChipSize.large:
        return _ChipSizeSpecs(
          fontSize: 16,
          iconSize: 20,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          borderRadius: AppRadius.button,
          iconSpacing: 8,
        );

      case AppChipSize.medium:
      default:
        return _ChipSizeSpecs(
          fontSize: 14,
          iconSize: 16,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          borderRadius: AppRadius.sm,
          iconSpacing: 6,
        );
    }
  }
}

/// Chip 색상 스펙
class _ChipColors {
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color foregroundColor;
  final Color selectedForegroundColor;
  final Color borderColor;

  _ChipColors({
    required this.backgroundColor,
    required this.selectedBackgroundColor,
    required this.foregroundColor,
    required this.selectedForegroundColor,
    required this.borderColor,
  });
}

/// Chip 크기 스펙
class _ChipSizeSpecs {
  final double fontSize;
  final double iconSize;
  final EdgeInsets padding;
  final EdgeInsets labelPadding;
  final double borderRadius;
  final double iconSpacing;

  _ChipSizeSpecs({
    required this.fontSize,
    required this.iconSize,
    required this.padding,
    required this.labelPadding,
    required this.borderRadius,
    required this.iconSpacing,
  });
}
