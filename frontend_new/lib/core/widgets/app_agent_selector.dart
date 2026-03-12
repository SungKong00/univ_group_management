import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/responsive_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/enums.dart';

/// Linear 스타일 AI Agent Selector
///
/// 특징:
/// - Avatar + Badge + Name
/// - 선택 가능한 수평 리스트
/// - Hover 효과 + 선택 상태 표시
class AppAgentSelector extends StatefulWidget {
  final List<AppAgent> agents;
  final int? selectedIndex;
  final ValueChanged<int?>? onAgentSelected;
  final double avatarSize;
  final AppBadgeVariant badgeStyle;

  const AppAgentSelector({
    super.key,
    required this.agents,
    this.selectedIndex,
    this.onAgentSelected,
    this.avatarSize = 18,
    this.badgeStyle = AppBadgeVariant.subtle,
  });

  @override
  State<AppAgentSelector> createState() => _AppAgentSelectorState();
}

class _AppAgentSelectorState extends State<AppAgentSelector> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  void _selectAgent(int index) {
    setState(() {
      // 이미 선택된 항목을 다시 클릭하면 선택 해제 (Radio.toggleable 패턴)
      if (_selectedIndex == index) {
        _selectedIndex = null;
      } else {
        _selectedIndex = index;
      }
    });
    widget.onAgentSelected?.call(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveTokens.cardGap(width) * 0.5,
      ),
      child: Row(
        children: [
          for (int i = 0; i < widget.agents.length; i++) ...[
            _AgentItem(
              agent: widget.agents[i],
              isSelected: _selectedIndex == i,
              onTap: () => _selectAgent(i),
              avatarSize: widget.avatarSize,
              badgeStyle: widget.badgeStyle,
            ),
            if (i < widget.agents.length - 1)
              const SizedBox(width: ResponsiveTokens.space8),
          ],
        ],
      ),
    );
  }
}

class _AgentItem extends StatefulWidget {
  final AppAgent agent;
  final bool isSelected;
  final VoidCallback onTap;
  final double avatarSize;
  final AppBadgeVariant badgeStyle;

  const _AgentItem({
    required this.agent,
    required this.isSelected,
    required this.onTap,
    required this.avatarSize,
    required this.badgeStyle,
  });

  @override
  State<_AgentItem> createState() => _AgentItemState();
}

class _AgentItemState extends State<_AgentItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;

    final backgroundColor = widget.isSelected
        ? colorExt.brandPrimary.withValues(alpha: 0.1)
        : (_isHovered ? colorExt.surfaceTertiary : colorExt.surfaceSecondary);

    final borderColor = widget.isSelected
        ? colorExt.brandPrimary
        : (_isHovered ? colorExt.borderPrimary : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          curve: AnimationTokens.curveSmooth,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveTokens.cardGap(width),
            vertical: ResponsiveTokens.cardGap(width) * 0.5,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderTokens.mediumRadius(),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: widget.avatarSize / 2,
                backgroundColor: colorExt.brandPrimary,
                child: widget.agent.icon != null
                    ? Icon(
                        widget.agent.icon,
                        size: widget.avatarSize * 0.6,
                        color: colorExt.brandText,
                      )
                    : Text(
                        widget.agent.name[0].toUpperCase(),
                        style: textTheme.bodySmall!.copyWith(
                          color: colorExt.brandText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              const SizedBox(width: 8.0),

              // Name
              Text(
                widget.agent.name,
                style: textTheme.bodySmall!.copyWith(
                  color: colorExt.textPrimary,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),

              // Badge (optional)
              if (widget.agent.badge != null) ...[
                const SizedBox(width: 6.0),
                _Badge(label: widget.agent.badge!, style: widget.badgeStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final AppBadgeVariant style;

  const _Badge({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final (bgColor, textColor) = switch (style) {
      AppBadgeVariant.subtle => (
        colorExt.surfaceQuaternary,
        colorExt.textTertiary,
      ),
      AppBadgeVariant.prominent => (
        colorExt.brandPrimary.withValues(alpha: 0.15),
        colorExt.brandPrimary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderTokens.smallRadius(),
      ),
      child: Text(
        label,
        style: textTheme.bodySmall!.copyWith(color: textColor, fontSize: 11),
      ),
    );
  }
}

class AppAgent {
  final String name;
  final String? badge;
  final IconData? icon;
  final String? description;

  const AppAgent({required this.name, this.badge, this.icon, this.description});
}
