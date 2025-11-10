import 'package:flutter/material.dart';

/// CalendarAddButton - 캘린더 일정 추가 버튼 컴포넌트
///
/// 개인/그룹/장소 캘린더에서 일정 추가 시 사용하는 공통 버튼입니다.
/// 일관된 스타일과 로딩 상태 처리를 제공합니다.
///
/// 사용 예시:
/// ```dart
/// CalendarAddButton(
///   onPressed: () => _showCreateDialog(),
///   isLoading: state.isMutating,
/// )
/// ```
class CalendarAddButton extends StatelessWidget {
  /// 버튼 클릭 시 실행되는 콜백
  final VoidCallback? onPressed;

  /// 로딩 상태 여부 (true일 경우 버튼 비활성화)
  final bool isLoading;

  /// 버튼에 표시될 텍스트 (기본값: '일정 추가')
  final String label;

  /// 버튼에 표시될 아이콘 (기본값: Icons.add_circle_outline)
  final IconData icon;

  /// 접근성 레이블 (스크린 리더용)
  final String? semanticLabel;

  const CalendarAddButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = '일정 추가',
    this.icon = Icons.add_circle_outline,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isLoading && onPressed != null,
      label: semanticLabel ?? label,
      child: SizedBox(
        width: 110,
        height: 44,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            backgroundColor: Theme.of(context).colorScheme.primary,
            disabledBackgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
