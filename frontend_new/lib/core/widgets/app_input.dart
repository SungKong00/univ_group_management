import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/input_colors.dart';
import '../theme/responsive_tokens.dart';

/// App 스타일 입력 필드
///
/// **접근성**: 최소 터치 영역 44px 보장
/// **반응형**: 화면 크기에 따라 자동 조정
enum AppInputCursorColor { primary }

/// 입력 필드 설정 구조체
///
/// 입력 필드 관련 파라미터들을 하나의 클래스로 통합하여
/// 코드 복잡도를 줄이고 재사용성을 높입니다.
class InputConfig {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const InputConfig({
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
  });
}

class AppInput extends StatelessWidget {
  /// 입력 필드 설정 (라벨, 플레이스홀더, 헬퍼 텍스트 등)
  final InputConfig? config;

  // 레거시 호환성을 위한 개별 파라미터
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final AppInputCursorColor cursorColor;

  const AppInput({
    super.key,
    this.config,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onEditingComplete,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.cursorColor = AppInputCursorColor.primary,
  });

  /// InputConfig를 우선 사용, 없으면 개별 파라미터 사용
  String? get _label => config?.label ?? label;
  String? get _placeholder => config?.placeholder ?? placeholder;
  String? get _helperText => config?.helperText ?? helperText;
  String? get _errorText => config?.errorText ?? errorText;
  Widget? get _prefixIcon => config?.prefixIcon ?? prefixIcon;
  Widget? get _suffixIcon => config?.suffixIcon ?? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final inputColors = InputColors.standard(colorExt);

    final width = MediaQuery.sizeOf(context).width;
    final cursorColorValue = colorExt.brandPrimary;
    const disabledOpacityValue = 0.75;
    final borderRadius = ResponsiveTokens.componentBorderRadius(width);
    final contentPadding = EdgeInsets.symmetric(
      horizontal: ResponsiveTokens.inputPaddingH(width),
      vertical: ResponsiveTokens.inputPaddingV(width),
    );

    // 텍스트 색상 (disabled 시 투명도 적용)
    final textColor = enabled
        ? inputColors.text
        : inputColors.text.withValues(alpha: disabledOpacityValue);
    final labelColor = enabled
        ? inputColors.label
        : inputColors.label.withValues(alpha: disabledOpacityValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_label != null) ...[
          Text(
            _label!,
            style: textTheme.bodySmall!.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6.0),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          cursorColor: cursorColorValue,
          style: textTheme.bodyMedium!.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: _placeholder,
            hintStyle: textTheme.bodyMedium!.copyWith(
              color: enabled
                  ? inputColors.placeholder
                  : inputColors.placeholder.withValues(
                      alpha: disabledOpacityValue,
                    ),
            ),
            helperText: _helperText,
            helperStyle: textTheme.bodySmall!.copyWith(
              color: enabled
                  ? inputColors.helper
                  : inputColors.helper.withValues(alpha: disabledOpacityValue),
            ),
            errorText: _errorText,
            errorStyle: textTheme.bodySmall!.copyWith(
              color: inputColors.errorText,
            ),
            filled: true,
            fillColor: enabled
                ? inputColors.background
                : inputColors.backgroundDisabled,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: inputColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: inputColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: inputColors.borderFocused,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: inputColors.borderError, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: inputColors.borderError, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: inputColors.border.withValues(
                  alpha: disabledOpacityValue,
                ),
                width: 1,
              ),
            ),
            contentPadding: contentPadding,
            prefixIcon: _prefixIcon,
            suffixIcon: _suffixIcon,
          ),
        ),
      ],
    );
  }
}
