import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';

/// 이슈 네비게이션 카운터 컴포넌트 (5/12)
///
/// **기능**:
/// - 현재 이슈 위치와 전체 개수 표시
/// - 인라인 텍스트 기반 디자인
///
/// **사용 예시**:
/// ```dart
/// IssueNavigationCounter(
///   current: 5,
///   total: 12,
/// )
/// ```
class IssueNavigationCounter extends StatelessWidget {
  /// 현재 이슈 번호 (1부터 시작)
  final int current;

  /// 전체 이슈 개수
  final int total;

  const IssueNavigationCounter({
    super.key,
    required this.current,
    required this.total,
  }) : assert(
         current > 0 && current <= total,
         'current must be between 1 and total',
       );

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$current',
          style:
              Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorExt.textPrimary,
                fontWeight: FontWeight.w600,
              ) ??
              TextStyle(
                color: colorExt.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '/',
            style:
                Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorExt.textSecondary,
                ) ??
                TextStyle(color: colorExt.textSecondary),
          ),
        ),
        Text(
          '$total',
          style:
              Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: colorExt.textSecondary) ??
              TextStyle(color: colorExt.textSecondary),
        ),
      ],
    );
  }
}
