import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// 컴팩트 칩 컴포넌트
///
/// **용도**: MultiSelectPopover 내부에서 사용하는 미니멀한 선택 칩
///
/// **특징**:
/// - 고정 높이 24px (선택 여부와 무관하게 사이즈 불변)
/// - 체크 아이콘 없음 (배경색만 변경)
/// - 완전히 둥근 모양 (borderRadius: 12px)
/// - 최소 터치 영역 44x44px 보장
///
/// **디자인 차이**:
/// - AppChip (Medium): 36px 높이, 체크 아이콘 표시
/// - CompactChip: 24px 높이, 배경색만 변경 (33% 더 컴팩트)
///
/// **사용 예시**:
/// ```dart
/// // 기본 사용
/// CompactChip(
///   label: '그룹장',
///   selected: true,
///   onTap: () => toggleSelection(),
/// )
///
/// // 비활성화
/// CompactChip(
///   label: '교수',
///   selected: false,
///   onTap: () {},
///   enabled: false,
/// )
/// ```
class CompactChip extends StatelessWidget {
  /// 칩에 표시될 텍스트 (필수)
  final String label;

  /// 선택 여부
  final bool selected;

  /// 탭 콜백
  final VoidCallback onTap;

  /// 활성화 여부
  final bool enabled;

  const CompactChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // 색상 결정
    final backgroundColor = _getBackgroundColor();
    final textColor = _getTextColor();
    final borderColor = _getBorderColor();

    return Semantics(
      button: true,
      label: label,
      selected: selected,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        hoverColor: _getHoverColor(),
        splashColor: selected
            ? Colors.white.withValues(alpha: 0.2)
            : AppColors.brand.withValues(alpha: 0.1),
        highlightColor: selected
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.brand.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: AppMotion.quick, // 120ms
          curve: AppMotion.easing, // Curves.easeOutCubic
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
              height: 1.33, // 16px line height
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// 배경색 결정
  Color _getBackgroundColor() {
    if (!enabled) {
      return AppColors.disabledBgLight;
    }
    return selected ? AppColors.brand : AppColors.neutral100;
  }

  /// 텍스트 색상 결정
  Color _getTextColor() {
    if (!enabled) {
      return AppColors.disabledTextLight;
    }
    return selected ? Colors.white : AppColors.neutral700;
  }

  /// 테두리 색상 결정
  Color _getBorderColor() {
    if (!enabled) {
      return AppColors.disabledBgLight;
    }
    return selected ? AppColors.brand : AppColors.neutral400;
  }

  /// 호버 색상 결정 (데스크톱)
  Color _getHoverColor() {
    if (!enabled) {
      return Colors.transparent;
    }
    return selected
        ? AppColors.brandStrong.withValues(alpha: 0.1)
        : AppColors.neutral200;
  }
}
