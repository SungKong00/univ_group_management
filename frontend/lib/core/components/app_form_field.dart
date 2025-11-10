import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/theme.dart';

/// 통합 Form Field 컴포넌트
///
/// 프로젝트 전반에서 일관된 입력 필드 스타일을 제공합니다.
/// AppColors, AppTextStyles, AppTheme과 통합되어 있습니다.
///
/// 사용 예시:
/// ```dart
/// AppFormField(
///   label: '이메일',
///   controller: _emailController,
///   hintText: '이메일을 입력하세요',
///   keyboardType: TextInputType.emailAddress,
/// )
/// ```
class AppFormField extends StatelessWidget {
  /// 필드 레이블 (필수)
  final String label;

  /// 힌트 텍스트
  final String? hintText;

  /// TextField 컨트롤러
  final TextEditingController? controller;

  /// 초기 값 (controller가 없을 때 사용)
  final String? initialValue;

  /// 검증 함수
  final String? Function(String?)? validator;

  /// 비밀번호 필드 여부
  final bool obscureText;

  /// 키보드 타입
  final TextInputType? keyboardType;

  /// 최대 줄 수
  final int? maxLines;

  /// 활성화 여부
  final bool enabled;

  /// 읽기 전용 여부
  final bool readOnly;

  /// 값 변경 콜백
  final void Function(String)? onChanged;

  /// 포커스 노드
  final FocusNode? focusNode;

  /// 최대 길이
  final int? maxLength;

  /// 접두사 아이콘
  final Widget? prefixIcon;

  /// 접미사 아이콘
  final Widget? suffixIcon;

  /// 에러 텍스트 (validator 대신 사용 가능)
  final String? errorText;

  /// 입력 완료 콜백
  final void Function(String)? onSubmitted;

  /// TextInputAction
  final TextInputAction? textInputAction;

  /// 자동 포커스
  final bool autofocus;

  const AppFormField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.initialValue,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.focusNode,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.onSubmitted,
    this.textInputAction,
    this.autofocus = false,
  }) : assert(
         controller == null || initialValue == null,
         'controller와 initialValue는 동시에 사용할 수 없습니다.',
       );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 레이블
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: isDark
                  ? AppColors.darkOnSurface
                  : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 8),

          // 입력 필드
          TextFormField(
            controller: controller,
            initialValue: initialValue,
            validator: validator,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            readOnly: readOnly,
            onChanged: onChanged,
            focusNode: focusNode,
            maxLength: maxLength,
            onFieldSubmitted: onSubmitted,
            textInputAction: textInputAction,
            autofocus: autofocus,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: enabled
                  ? (isDark
                        ? AppColors.darkOnSurface
                        : AppColors.lightOnSurface)
                  : (isDark
                        ? AppColors.disabledTextDark
                        : AppColors.disabledTextLight),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              errorText: errorText,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: enabled
                  ? (isDark ? AppColors.darkSurface : Colors.white)
                  : (isDark
                        ? AppColors.disabledBgDark
                        : AppColors.disabledBgLight),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              hintStyle: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.darkSecondary : AppColors.neutral500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkOutline
                      : AppColors.lightOutline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkOutline
                      : AppColors.lightOutline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(
                  color: AppColors.focusRing,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.disabledBgDark
                      : AppColors.disabledBgLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
