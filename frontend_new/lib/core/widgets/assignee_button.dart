import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/assignee_button_colors.dart';
import '../theme/enums.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

// Export assignee state for convenience
export '../theme/enums.dart' show AssigneeState;

/// 담당자 선택 버튼
///
/// **기능**:
/// - 담당자 선택 (싱글/멀티)
/// - 아바타 표시
/// - 담당자 상태 표시 (Assigned/Unassigned/Multiple)
///
/// **사용 예시**:
/// ```dart
/// AssigneeButton(
///   state: AssigneeState.assigned,
///   assignees: ['John Doe'],
///   onAssigneeSelected: (names) => print(names),
/// )
/// ```
class AssigneeButton extends StatefulWidget {
  /// 담당자 상태
  final AssigneeState state;

  /// 담당자 이름 리스트
  final List<String> assignees;

  /// 담당자 선택 콜백
  final Function(List<String>) onAssigneeSelected;

  /// 읽기 전용 모드
  final bool isReadOnly;

  const AssigneeButton({
    super.key,
    required this.state,
    required this.assignees,
    required this.onAssigneeSelected,
    this.isReadOnly = false,
  });

  @override
  State<AssigneeButton> createState() => _AssigneeButtonState();
}

class _AssigneeButtonState extends State<AssigneeButton> {
  late AssigneeState _state;
  late List<String> _assignees;

  @override
  void initState() {
    super.initState();
    _state = widget.state;
    _assignees = widget.assignees;
  }

  @override
  void didUpdateWidget(covariant AssigneeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state ||
        oldWidget.assignees != widget.assignees) {
      _state = widget.state;
      _assignees = widget.assignees;
    }
  }

  String _stateLabel(AssigneeState state, List<String> assignees) {
    return switch (state) {
      AssigneeState.assigned =>
        assignees.isNotEmpty ? assignees.first : 'Assigned',
      AssigneeState.unassigned => 'Unassigned',
      AssigneeState.multiple => '${assignees.length} assignees',
    };
  }

  IconData _stateIcon(AssigneeState state) {
    return switch (state) {
      AssigneeState.assigned => Icons.person,
      AssigneeState.unassigned => Icons.person_outline,
      AssigneeState.multiple => Icons.people,
    };
  }

  Color _getAvatarColor(String name, AppColorExtension colorExt) {
    final hash = name.hashCode;
    final colors = [
      colorExt.brandPrimary,
      colorExt.brandSecondary,
      colorExt.stateSuccessBg,
      colorExt.stateWarningBg,
      colorExt.stateInfoText,
    ];
    return colors[hash % colors.length];
  }

  /// 담당자 선택 다이얼로그 표시
  void _showAssigneeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('담당자 선택'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 선택 안함
              CheckboxListTile(
                title: const Text('선택 안함'),
                value: _state == AssigneeState.unassigned,
                onChanged: (_) {
                  setState(() {
                    _state = AssigneeState.unassigned;
                    _assignees = [];
                  });
                  widget.onAssigneeSelected([]);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              // 기존 담당자 목록 또는 입력 필드
              for (final assignee in _assignees)
                CheckboxListTile(
                  title: Text(assignee),
                  value: true,
                  onChanged: (_) {
                    setState(() {
                      _assignees.remove(assignee);
                      if (_assignees.isEmpty) {
                        _state = AssigneeState.unassigned;
                      } else {
                        _state = _assignees.length == 1
                            ? AssigneeState.assigned
                            : AssigneeState.multiple;
                      }
                    });
                    widget.onAssigneeSelected(_assignees);
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final width = MediaQuery.sizeOf(context).width;

    // ========================================================
    // Step 1: 상태에 따른 색상 결정
    // ========================================================
    final assigneeColors = switch (_state) {
      AssigneeState.assigned => AssigneeButtonColors.assigned(colorExt),
      AssigneeState.unassigned => AssigneeButtonColors.unassigned(colorExt),
      AssigneeState.multiple => AssigneeButtonColors.multiple(colorExt),
    };

    final borderRadius = ResponsiveTokens.componentBorderRadius(width);
    final padding = EdgeInsets.symmetric(
      horizontal: ResponsiveTokens.buttonMediumPaddingH(width),
      vertical: ResponsiveTokens.buttonMediumPaddingV(width),
    );

    // ========================================================
    // Step 2: 읽기 전용 모드
    // ========================================================
    if (widget.isReadOnly) {
      return Container(
        decoration: BoxDecoration(
          color: assigneeColors.background,
          border: Border.all(
            color: assigneeColors.border,
            width: BorderTokens.widthThin,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아바타
            if (_state == AssigneeState.assigned && _assignees.isNotEmpty)
              Container(
                width: ComponentSizeTokens.avatarXSmall,
                height: ComponentSizeTokens.avatarXSmall,
                decoration: BoxDecoration(
                  color: _getAvatarColor(_assignees.first, colorExt),
                  borderRadius: BorderTokens.xlRadius(),
                ),
                alignment: Alignment.center,
                child: Text(
                  _assignees.first[0].toUpperCase(),
                  style:
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              )
            else
              Icon(
                _stateIcon(_state),
                color: assigneeColors.icon,
                size: ComponentSizeTokens.iconXSmall,
              ),
            SizedBox(width: ComponentSizeTokens.iconTextGap),
            Text(
              _stateLabel(_state, _assignees),
              style:
                  Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: assigneeColors.text,
                  ) ??
                  TextStyle(color: assigneeColors.text),
            ),
          ],
        ),
      );
    }

    // ========================================================
    // Step 3: 인터랙티브 모드
    // ========================================================
    return GestureDetector(
      onTap: () => _showAssigneeSelector(context),
      child: Container(
        decoration: BoxDecoration(
          color: assigneeColors.background,
          border: Border.all(
            color: assigneeColors.border,
            width: BorderTokens.widthThin,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아바타들
            if (_state == AssigneeState.assigned && _assignees.isNotEmpty)
              Container(
                width: ComponentSizeTokens.avatarXSmall,
                height: ComponentSizeTokens.avatarXSmall,
                decoration: BoxDecoration(
                  color: _getAvatarColor(_assignees.first, colorExt),
                  border: Border.all(
                    color: assigneeColors.avatarBg,
                    width: BorderTokens.widthFocus,
                  ),
                  borderRadius: BorderTokens.xlRadius(),
                ),
                alignment: Alignment.center,
                child: Text(
                  _assignees.first[0].toUpperCase(),
                  style:
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              )
            else if (_state == AssigneeState.multiple && _assignees.isNotEmpty)
              SizedBox(
                width: ComponentSizeTokens.boxSmall,
                height: ComponentSizeTokens.avatarXSmall,
                child: Stack(
                  children: [
                    for (
                      int i = 0;
                      i < (_assignees.length > 2 ? 2 : _assignees.length);
                      i++
                    )
                      Positioned(
                        left: i * 12.0,
                        child: Container(
                          width: ComponentSizeTokens.avatarXSmall,
                          height: ComponentSizeTokens.avatarXSmall,
                          decoration: BoxDecoration(
                            color: _getAvatarColor(_assignees[i], colorExt),
                            border: Border.all(
                              color: assigneeColors.avatarBg,
                              width: BorderTokens.widthFocus,
                            ),
                            borderRadius: BorderTokens.xlRadius(),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _assignees[i][0].toUpperCase(),
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ) ??
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Icon(
                _stateIcon(_state),
                color: assigneeColors.icon,
                size: ComponentSizeTokens.iconXSmall,
              ),
            SizedBox(width: ComponentSizeTokens.iconTextGap),
            Text(
              _stateLabel(_state, _assignees),
              style:
                  Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: assigneeColors.text,
                  ) ??
                  TextStyle(color: assigneeColors.text),
            ),
            const SizedBox(width: ResponsiveTokens.space4),
            Icon(
              Icons.arrow_drop_down,
              color: assigneeColors.icon,
              size: ComponentSizeTokens.iconXSmall,
            ),
          ],
        ),
      ),
    );
  }
}
