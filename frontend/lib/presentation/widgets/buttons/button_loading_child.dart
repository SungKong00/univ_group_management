import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// 모든 버튼의 로딩 상태를 표시하는 공통 컴포넌트
///
/// 버튼의 로딩 UI 로직을 중앙화하여 다음의 이점을 제공합니다:
/// - 로딩 중 일관된 CircularProgressIndicator 표시
/// - 아이콘 + 텍스트 조합 지원
/// - 일관된 스타일 (크기, 색상, 간격)
///
/// 사용 예시:
/// ```dart
/// FilledButton(
///   onPressed: isEnabled ? onPressed : null,
///   child: ButtonLoadingChild(
///     text: '확인',
///     icon: Icons.check,
///     isLoading: isLoading,
///     textStyle: textStyle,
///     indicatorColor: Colors.white,
///   ),
/// )
/// ```
class ButtonLoadingChild extends StatelessWidget {
  final String text;
  final Widget? icon;
  final bool isLoading;
  final TextStyle textStyle;
  final Color indicatorColor;

  const ButtonLoadingChild({super.key, 
    required this.text,
    this.icon,
    required this.isLoading,
    required this.textStyle,
    required this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    // 로딩 중: CircularProgressIndicator 표시
    if (isLoading) {
      return SizedBox(
        width: AppComponents.progressIndicatorSize,
        height: AppComponents.progressIndicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      );
    }

    // 아이콘이 없으면: 텍스트만 표시
    if (icon == null) {
      return Text(text, style: textStyle, textAlign: TextAlign.center);
    }

    // 아이콘 + 텍스트: Row로 배치
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTheme(
          data: IconThemeData(
            size: AppComponents.googleIconSize,
            color: textStyle.color,
          ),
          child: icon!,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: textStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
