import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/textarea_colors.dart';
import '../theme/border_tokens.dart';
import '../theme/responsive_tokens.dart';

/// 여러 줄 텍스트 입력 필드
///
/// **용도**: 긴 텍스트 입력, 설명, 메모, 댓글
/// **접근성**: 최소 터치 영역 보장, Semantics 지원
/// **반응형**: 화면 크기에 따라 자동 조정
///
/// ```dart
/// // 기본 사용
/// AppTextarea(
///   controller: _descriptionController,
///   placeholder: '설명을 입력하세요',
/// )
///
/// // 라벨 및 헬퍼 텍스트
/// AppTextarea(
///   label: '자기소개',
///   placeholder: '자신에 대해 소개해 주세요',
///   helperText: '최대 500자까지 입력 가능합니다',
///   maxLength: 500,
/// )
///
/// // 에러 상태
/// AppTextarea(
///   label: '메시지',
///   errorText: '메시지를 입력해 주세요',
/// )
///
/// // 자동 높이 조절
/// AppTextarea(
///   controller: _noteController,
///   minLines: 3,
///   maxLines: 10,
///   autoResize: true,
/// )
///
/// // 글자 수 표시
/// AppTextarea(
///   controller: _bioController,
///   maxLength: 200,
///   showCharacterCount: true,
/// )
/// ```
class AppTextarea extends StatefulWidget {
  /// 텍스트 컨트롤러
  final TextEditingController? controller;

  /// 라벨 텍스트
  final String? label;

  /// 플레이스홀더 텍스트
  final String? placeholder;

  /// 헬퍼 텍스트
  final String? helperText;

  /// 에러 텍스트
  final String? errorText;

  /// 최소 줄 수
  final int minLines;

  /// 최대 줄 수
  final int? maxLines;

  /// 최대 글자 수
  final int? maxLength;

  /// 글자 수 표시 여부
  final bool showCharacterCount;

  /// 자동 높이 조절 여부
  final bool autoResize;

  /// 값 변경 콜백
  final ValueChanged<String>? onChanged;

  /// 편집 완료 콜백
  final VoidCallback? onEditingComplete;

  /// 제출 콜백
  final ValueChanged<String>? onSubmitted;

  /// 비활성화 상태
  final bool isDisabled;

  /// 읽기 전용 상태
  final bool isReadOnly;

  /// 자동 포커스
  final bool autofocus;

  /// 키보드 타입
  final TextInputType? keyboardType;

  /// 텍스트 정렬
  final TextAlign textAlign;

  const AppTextarea({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.minLines = 3,
    this.maxLines,
    this.maxLength,
    this.showCharacterCount = false,
    this.autoResize = false,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.isDisabled = false,
    this.isReadOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textAlign = TextAlign.start,
  });

  @override
  State<AppTextarea> createState() => _AppTextareaState();
}

class _AppTextareaState extends State<AppTextarea> {
  late TextEditingController _controller;
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _characterCount = _controller.text.length;
    _controller.addListener(_updateCharacterCount);
  }

  @override
  void didUpdateWidget(AppTextarea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_updateCharacterCount);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_updateCharacterCount);
      _characterCount = _controller.text.length;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateCharacterCount);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _controller.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final textareaColors = TextareaColors.from(colorExt);

    final width = MediaQuery.sizeOf(context).width;
    final borderRadius = ResponsiveTokens.componentBorderRadius(width);
    final contentPadding = EdgeInsets.symmetric(
      horizontal: ResponsiveTokens.inputPaddingH(width),
      vertical: ResponsiveTokens.inputPaddingV(width),
    );

    final isEnabled = !widget.isDisabled;
    final hasError = widget.errorText != null;
    const disabledOpacity = 0.75;

    // 텍스트 색상
    final textColor = isEnabled
        ? textareaColors.text
        : textareaColors.text.withValues(alpha: disabledOpacity);
    final labelColor = isEnabled
        ? textareaColors.labelText
        : textareaColors.labelText.withValues(alpha: disabledOpacity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: textTheme.bodySmall!.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacingExt.formLabelGap),
        ],

        // 텍스트 영역
        Semantics(
          textField: true,
          multiline: true,
          label: widget.label ?? widget.placeholder,
          child: TextField(
            controller: _controller,
            enabled: isEnabled,
            readOnly: widget.isReadOnly,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType ?? TextInputType.multiline,
            textAlign: widget.textAlign,
            minLines: widget.minLines,
            maxLines: widget.autoResize
                ? null
                : (widget.maxLines ?? widget.minLines),
            maxLength: widget.maxLength,
            buildCounter: widget.showCharacterCount || widget.maxLength != null
                ? null
                : (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
            onChanged: widget.onChanged,
            onEditingComplete: widget.onEditingComplete,
            onSubmitted: widget.onSubmitted,
            cursorColor: colorExt.brandPrimary,
            style: textTheme.bodyMedium!.copyWith(color: textColor),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: textTheme.bodyMedium!.copyWith(
                color: isEnabled
                    ? textareaColors.placeholder
                    : textareaColors.placeholder.withValues(
                        alpha: disabledOpacity,
                      ),
              ),
              filled: true,
              fillColor: isEnabled
                  ? textareaColors.background
                  : textareaColors.backgroundDisabled,
              contentPadding: contentPadding,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: textareaColors.border,
                  width: BorderTokens.widthThin,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: hasError
                      ? textareaColors.borderError
                      : textareaColors.border,
                  width: BorderTokens.widthThin,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: hasError
                      ? textareaColors.borderError
                      : textareaColors.borderFocus,
                  width: BorderTokens.widthFocus,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: textareaColors.borderError,
                  width: BorderTokens.widthThin,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: textareaColors.borderError,
                  width: BorderTokens.widthFocus,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: textareaColors.border.withValues(alpha: disabledOpacity),
                  width: BorderTokens.widthThin,
                ),
              ),
            ),
          ),
        ),

        // 하단 정보 (헬퍼 텍스트, 에러 텍스트, 글자 수)
        if (widget.helperText != null ||
            widget.errorText != null ||
            widget.showCharacterCount ||
            widget.maxLength != null) ...[
          SizedBox(height: spacingExt.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 에러 또는 헬퍼 텍스트
              Expanded(
                child: widget.errorText != null
                    ? Text(
                        widget.errorText!,
                        style: textTheme.bodySmall!.copyWith(
                          color: textareaColors.errorText,
                        ),
                      )
                    : widget.helperText != null
                    ? Text(
                        widget.helperText!,
                        style: textTheme.bodySmall!.copyWith(
                          color: isEnabled
                              ? textareaColors.helperText
                              : textareaColors.helperText.withValues(
                                  alpha: disabledOpacity,
                                ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // 글자 수 표시
              if (widget.showCharacterCount || widget.maxLength != null)
                Text(
                  widget.maxLength != null
                      ? '$_characterCount / ${widget.maxLength}'
                      : '$_characterCount',
                  style: textTheme.bodySmall!.copyWith(
                    color:
                        widget.maxLength != null &&
                            _characterCount > widget.maxLength!
                        ? textareaColors.errorText
                        : (isEnabled
                              ? textareaColors.helperText
                              : textareaColors.helperText.withValues(
                                  alpha: disabledOpacity,
                                )),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
