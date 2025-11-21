import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/status_button_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/component_size_tokens.dart';

// Export status for convenience
export '../theme/colors/status_button_colors.dart' show IssueStatus;

/// 이슈 상태 변경 버튼 (Done/In Progress/Pending/Cancelled)
///
/// **기능**:
/// - DropdownMenu 기반 상태 선택
/// - 현재 상태 표시
/// - 상태별 색상 자동 적용
///
/// **사용 예시**:
/// ```dart
/// StatusButton(
///   currentStatus: IssueStatus.inProgress,
///   onStatusChanged: (status) => print(status),
/// )
/// ```
class StatusButton extends StatefulWidget {
  /// 현재 상태
  final IssueStatus currentStatus;

  /// 상태 변경 콜백
  final Function(IssueStatus) onStatusChanged;

  /// 읽기 전용 모드
  final bool isReadOnly;

  const StatusButton({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
    this.isReadOnly = false,
  });

  @override
  State<StatusButton> createState() => _StatusButtonState();
}

class _StatusButtonState extends State<StatusButton> {
  late IssueStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  void didUpdateWidget(covariant StatusButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      _selectedStatus = widget.currentStatus;
    }
  }

  String _statusLabel(IssueStatus status) {
    return switch (status) {
      IssueStatus.done => 'Done',
      IssueStatus.inProgress => 'In Progress',
      IssueStatus.pending => 'Pending',
      IssueStatus.cancelled => 'Cancelled',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final width = MediaQuery.sizeOf(context).width;

    // ========================================================
    // Step 1: 현재 상태에 따른 색상 결정
    // ========================================================
    final statusColors = switch (_selectedStatus) {
      IssueStatus.done => StatusButtonColors.done(colorExt),
      IssueStatus.inProgress => StatusButtonColors.inProgress(colorExt),
      IssueStatus.pending => StatusButtonColors.pending(colorExt),
      IssueStatus.cancelled => StatusButtonColors.cancelled(colorExt),
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
              IssueStatus.done,
              IssueStatus.inProgress,
              IssueStatus.pending,
              IssueStatus.cancelled,
            ]
            .map(
              (status) =>
                  DropdownMenuEntry(value: status, label: _statusLabel(status)),
            )
            .toList();

    // ========================================================
    // Step 3: 버튼 빌드
    // ========================================================
    if (widget.isReadOnly) {
      return Container(
        decoration: BoxDecoration(
          color: statusColors.background,
          border: Border.all(color: statusColors.border, width: 1),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: statusColors.icon,
              size: ComponentSizeTokens.iconXSmall,
            ),
            SizedBox(width: ComponentSizeTokens.iconTextGap),
            Text(
              _statusLabel(_selectedStatus),
              style:
                  Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: statusColors.text) ??
                  TextStyle(color: statusColors.text),
            ),
          ],
        ),
      );
    }

    return DropdownMenu<IssueStatus>(
      initialSelection: _selectedStatus,
      onSelected: (status) {
        if (status != null) {
          setState(() => _selectedStatus = status);
          widget.onStatusChanged(status);
        }
      },
      dropdownMenuEntries: menuItems,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: statusColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: statusColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: statusColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: statusColors.border, width: 2),
        ),
        contentPadding: padding,
        isDense: true,
      ),
    );
  }
}
