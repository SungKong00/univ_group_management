import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/otp_input_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

/// OTP/인증 코드 입력 필드
///
/// **용도**: 이메일 인증, SMS 인증, 2FA 인증 코드 입력
/// **접근성**: 키보드 네비게이션, 붙여넣기 지원, Semantics 지원
/// **반응형**: 화면 크기에 맞게 자동 조정
///
/// ```dart
/// // 기본 사용 (6자리)
/// AppOtpInput(
///   length: 6,
///   onCompleted: (code) => _verifyCode(code),
/// )
///
/// // 4자리 코드
/// AppOtpInput(
///   length: 4,
///   onChanged: (code) => setState(() => _code = code),
///   onCompleted: (code) => _verifyCode(code),
/// )
///
/// // 에러 상태
/// AppOtpInput(
///   length: 6,
///   errorText: '잘못된 인증 코드입니다',
///   onCompleted: (code) => _verifyCode(code),
/// )
///
/// // 성공 상태
/// AppOtpInput(
///   length: 6,
///   isSuccess: true,
///   successText: '인증되었습니다',
/// )
///
/// // 비밀번호 마스킹
/// AppOtpInput(
///   length: 6,
///   obscureText: true,
///   onCompleted: (code) => _verifyCode(code),
/// )
/// ```
class AppOtpInput extends StatefulWidget {
  /// 입력 칸 수 (기본 6자리)
  final int length;

  /// 값 변경 콜백
  final ValueChanged<String>? onChanged;

  /// 입력 완료 콜백
  final ValueChanged<String>? onCompleted;

  /// 라벨 텍스트
  final String? label;

  /// 에러 텍스트
  final String? errorText;

  /// 성공 텍스트
  final String? successText;

  /// 성공 상태
  final bool isSuccess;

  /// 비활성화 상태
  final bool isDisabled;

  /// 비밀번호 마스킹
  final bool obscureText;

  /// 자동 포커스
  final bool autofocus;

  /// 숫자만 입력
  final bool numbersOnly;

  /// 셀 너비
  final double? cellWidth;

  /// 셀 높이
  final double? cellHeight;

  /// 셀 간격
  final double? cellSpacing;

  const AppOtpInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.label,
    this.errorText,
    this.successText,
    this.isSuccess = false,
    this.isDisabled = false,
    this.obscureText = false,
    this.autofocus = false,
    this.numbersOnly = true,
    this.cellWidth,
    this.cellHeight,
    this.cellSpacing,
  });

  @override
  State<AppOtpInput> createState() => _AppOtpInputState();
}

class _AppOtpInputState extends State<AppOtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _values;
  int _currentFocusIndex = -1;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode()
        ..addListener(() {
          if (_focusNodes[index].hasFocus) {
            setState(() => _currentFocusIndex = index);
          }
        }),
    );
    _values = List.filled(widget.length, '');
  }

  @override
  void didUpdateWidget(AppOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.length != oldWidget.length) {
      _disposeControllers();
      _initControllers();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
  }

  String get _currentValue => _values.join();

  void _onChanged(int index, String value) {
    if (value.isEmpty) {
      _values[index] = '';
      widget.onChanged?.call(_currentValue);
      return;
    }

    // 붙여넣기 처리 (여러 문자가 한번에 입력됨)
    if (value.length > 1) {
      _handlePaste(value);
      return;
    }

    // 숫자만 입력 모드일 때 숫자가 아니면 무시
    if (widget.numbersOnly && !RegExp(r'^[0-9]$').hasMatch(value)) {
      _controllers[index].clear();
      return;
    }

    _values[index] = value;
    _controllers[index].text = value;
    widget.onChanged?.call(_currentValue);

    // 다음 칸으로 이동
    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      // 마지막 칸이면 완료 콜백
      if (_currentValue.length == widget.length) {
        widget.onCompleted?.call(_currentValue);
      }
    }
  }

  void _handlePaste(String pastedText) {
    // 숫자만 입력 모드일 때 숫자만 필터링
    String filtered = pastedText;
    if (widget.numbersOnly) {
      filtered = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    }

    // 각 칸에 분배
    for (int i = 0; i < widget.length && i < filtered.length; i++) {
      _values[i] = filtered[i];
      _controllers[i].text = filtered[i];
    }

    widget.onChanged?.call(_currentValue);

    // 적절한 위치로 포커스 이동
    final targetIndex = (filtered.length < widget.length)
        ? filtered.length
        : widget.length - 1;
    _focusNodes[targetIndex].requestFocus();

    // 모두 채워졌으면 완료 콜백
    if (_currentValue.length == widget.length) {
      widget.onCompleted?.call(_currentValue);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        // 현재 칸이 비어있으면 이전 칸으로 이동하고 삭제
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        _values[index - 1] = '';
        widget.onChanged?.call(_currentValue);
      } else {
        // 현재 칸 삭제
        _controllers[index].clear();
        _values[index] = '';
        widget.onChanged?.call(_currentValue);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && index > 0) {
      _focusNodes[index - 1].requestFocus();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
        index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = OtpInputColors.from(colorExt);

    final hasError = widget.errorText != null;
    final cellWidth = widget.cellWidth ?? ComponentSizeTokens.boxMedium;
    final cellHeight = widget.cellHeight ?? ComponentSizeTokens.boxLarge;
    final cellSpacing = widget.cellSpacing ?? spacingExt.small;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: widget.isDisabled ? colors.textDisabled : colors.labelText,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: spacingExt.small),
        ],

        // OTP 입력 셀들
        Semantics(
          label: widget.label ?? 'OTP 입력',
          textField: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (index) {
              final isFocused = _currentFocusIndex == index;
              final isFilled = _values[index].isNotEmpty;

              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.length - 1 ? cellSpacing : 0,
                ),
                child: _OtpCell(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  width: cellWidth,
                  height: cellHeight,
                  isFocused: isFocused,
                  isFilled: isFilled,
                  hasError: hasError,
                  isSuccess: widget.isSuccess,
                  isDisabled: widget.isDisabled,
                  obscureText: widget.obscureText,
                  autofocus: widget.autofocus && index == 0,
                  colors: colors,
                  onChanged: (value) => _onChanged(index, value),
                  onKeyEvent: (event) => _onKeyEvent(index, event),
                  numbersOnly: widget.numbersOnly,
                ),
              );
            }),
          ),
        ),

        // 에러/성공 텍스트
        if (widget.errorText != null) ...[
          SizedBox(height: spacingExt.xs),
          Text(
            widget.errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.errorText),
          ),
        ] else if (widget.successText != null && widget.isSuccess) ...[
          SizedBox(height: spacingExt.xs),
          Text(
            widget.successText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.successText),
          ),
        ],
      ],
    );
  }
}

/// 개별 OTP 셀 위젯
class _OtpCell extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double width;
  final double height;
  final bool isFocused;
  final bool isFilled;
  final bool hasError;
  final bool isSuccess;
  final bool isDisabled;
  final bool obscureText;
  final bool autofocus;
  final OtpInputColors colors;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;
  final bool numbersOnly;

  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.width,
    required this.height,
    required this.isFocused,
    required this.isFilled,
    required this.hasError,
    required this.isSuccess,
    required this.isDisabled,
    required this.obscureText,
    required this.autofocus,
    required this.colors,
    required this.onChanged,
    required this.onKeyEvent,
    required this.numbersOnly,
  });

  @override
  Widget build(BuildContext context) {
    // 상태별 색상
    final backgroundColor = isDisabled
        ? colors.backgroundDisabled
        : isFocused
        ? colors.backgroundFocused
        : isFilled
        ? colors.backgroundFilled
        : colors.background;

    final borderColor = hasError
        ? colors.borderError
        : isSuccess
        ? colors.borderSuccess
        : isFocused
        ? colors.borderFocused
        : isFilled
        ? colors.borderFilled
        : colors.border;

    final borderWidth = isFocused
        ? BorderTokens.widthFocus
        : BorderTokens.widthThin;

    return AnimatedContainer(
      duration: AnimationTokens.durationQuick,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKeyEvent,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: !isDisabled,
          autofocus: autofocus,
          obscureText: obscureText,
          textAlign: TextAlign.center,
          maxLength: 1,
          keyboardType: numbersOnly ? TextInputType.number : TextInputType.text,
          inputFormatters: numbersOnly
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: isDisabled ? colors.textDisabled : colors.text,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: colors.cursor,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
