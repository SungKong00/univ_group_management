import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/priority_button_colors.dart';
import '../theme/enums.dart';
import '../theme/responsive_tokens.dart';
import '../theme/component_size_tokens.dart';

// Export priority for convenience
export '../theme/enums.dart' show IssuePriority;

/// 우선순위 설정 버튼 (High/Medium/Low/None)
///
/// **기능**:
/// - DropdownMenu 기반 우선순위 선택
/// - 우선순위별 색상 표시
/// - 아이콘 자동 적용
///
/// **사용 예시**:
/// ```dart
/// PriorityButton(
///   currentPriority: IssuePriority.high,
///   onPriorityChanged: (priority) => print(priority),
/// )
/// ```
class PriorityButton extends StatefulWidget {
  /// 현재 우선순위
  final IssuePriority currentPriority;

  /// 우선순위 변경 콜백
  final Function(IssuePriority) onPriorityChanged;

  /// 읽기 전용 모드
  final bool isReadOnly;

  const PriorityButton({
    super.key,
    required this.currentPriority,
    required this.onPriorityChanged,
    this.isReadOnly = false,
  });

  @override
  State<PriorityButton> createState() => _PriorityButtonState();
}

class _PriorityButtonState extends State<PriorityButton> {
  late IssuePriority _selectedPriority;

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.currentPriority;
  }

  @override
  void didUpdateWidget(covariant PriorityButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPriority != widget.currentPriority) {
      _selectedPriority = widget.currentPriority;
    }
  }

  String _priorityLabel(IssuePriority priority) {
    return switch (priority) {
      IssuePriority.high => 'High',
      IssuePriority.medium => 'Medium',
      IssuePriority.low => 'Low',
      IssuePriority.none => 'None',
    };
  }

  IconData _priorityIcon(IssuePriority priority) {
    return switch (priority) {
      IssuePriority.high => Icons.priority_high,
      IssuePriority.medium => Icons.drag_handle,
      IssuePriority.low => Icons.arrow_downward,
      IssuePriority.none => Icons.remove,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final width = MediaQuery.sizeOf(context).width;

    // ========================================================
    // Step 1: 현재 우선순위에 따른 색상 결정
    // ========================================================
    final priorityColors = switch (_selectedPriority) {
      IssuePriority.high => PriorityButtonColors.high(colorExt),
      IssuePriority.medium => PriorityButtonColors.medium(colorExt),
      IssuePriority.low => PriorityButtonColors.low(colorExt),
      IssuePriority.none => PriorityButtonColors.none(colorExt),
    };

    final borderRadius = ResponsiveTokens.componentBorderRadius(width);
    final padding = EdgeInsets.symmetric(
      horizontal: ResponsiveTokens.buttonMediumPaddingH(width),
      vertical: ResponsiveTokens.buttonMediumPaddingV(width),
    );

    // ========================================================
    // Step 2: 드롭다운 메뉴 아이템 생성
    // ========================================================
    final menuItems =
        [
              IssuePriority.high,
              IssuePriority.medium,
              IssuePriority.low,
              IssuePriority.none,
            ]
            .map(
              (priority) => DropdownMenuEntry(
                value: priority,
                label: _priorityLabel(priority),
              ),
            )
            .toList();

    // ========================================================
    // Step 3: 버튼 빌드
    // ========================================================
    if (widget.isReadOnly) {
      return Container(
        decoration: BoxDecoration(
          color: priorityColors.background,
          border: Border.all(color: priorityColors.border, width: 1),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _priorityIcon(_selectedPriority),
              color: priorityColors.icon,
              size: ComponentSizeTokens.iconXSmall,
            ),
            SizedBox(width: ComponentSizeTokens.iconTextGap),
            Text(
              _priorityLabel(_selectedPriority),
              style:
                  Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: priorityColors.text,
                  ) ??
                  TextStyle(color: priorityColors.text),
            ),
          ],
        ),
      );
    }

    return DropdownMenu<IssuePriority>(
      initialSelection: _selectedPriority,
      onSelected: (priority) {
        if (priority != null) {
          setState(() => _selectedPriority = priority);
          widget.onPriorityChanged(priority);
        }
      },
      dropdownMenuEntries: menuItems,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: priorityColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: priorityColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: priorityColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: priorityColors.border, width: 2),
        ),
        contentPadding: padding,
        isDense: true,
      ),
    );
  }
}
