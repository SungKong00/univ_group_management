import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';

/// 통일된 뒤로가기 버튼 컴포넌트
///
/// 세 페이지의 뒤로가기 로직을 통일하기 위해 만들어진 컴포넌트입니다.
/// 기본 색상과 크기는 디자인 시스템에서 정의된 값을 사용합니다.
class AppBackButton extends StatelessWidget {
  /// 뒤로가기 버튼을 클릭했을 때 호출될 콜백
  /// null이면 Navigator.of(context).pop() 사용
  final VoidCallback? onPressed;

  /// 아이콘 크기 (기본값: 24)
  final double iconSize;

  /// 아이콘 색상 (기본값: textSecondary)
  /// null이면 현재 테마의 textSecondary 사용
  final Color? iconColor;

  /// 버튼 패딩 (기본값: 8)
  final double padding;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.iconSize = 24,
    this.iconColor,
    this.padding = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final actualColor = iconColor ?? colorExt.textSecondary;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: IconButton(
        icon: Icon(Icons.arrow_back, size: iconSize),
        color: actualColor,
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        tooltip: 'Back',
      ),
    );
  }
}
