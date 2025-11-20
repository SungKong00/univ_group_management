import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';
import '../theme/typography_tokens.dart';
import '../theme/animation_tokens.dart';

/// Linear 스타일 AI Agent Selector
///
/// 특징:
/// - Avatar + Badge + Name
/// - 선택 가능한 수평 리스트
/// - Hover 효과 + 선택 상태 표시
class AppAgentSelector extends StatefulWidget {
  final List<AppAgent> agents;
  final int? selectedIndex;
  final ValueChanged<int>? onAgentSelected;
  final double avatarSize;
  final AppBadgeStyle badgeStyle;

  const AppAgentSelector({
    super.key,
    required this.agents,
    this.selectedIndex,
    this.onAgentSelected,
    this.avatarSize = 18,
    this.badgeStyle = AppBadgeStyle.subtle,
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
    setState(() => _selectedIndex = index);
    widget.onAgentSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            if (i < widget.agents.length - 1) const SizedBox(width: 8),
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
  final AppBadgeStyle badgeStyle;

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
    final backgroundColor = widget.isSelected
        ? ColorTokens.accent.withValues(alpha: 0.1)
        : (_isHovered
            ? ColorTokens.backgroundLevel2
            : ColorTokens.backgroundLevel1);

    final borderColor = widget.isSelected
        ? ColorTokens.accent
        : (_isHovered ? ColorTokens.borderPrimary : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.fast,
          curve: AnimationTokens.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: widget.avatarSize / 2,
                backgroundColor: ColorTokens.accent,
                child: widget.agent.icon != null
                    ? Icon(
                        widget.agent.icon,
                        size: widget.avatarSize * 0.6,
                        color: ColorTokens.brandText,
                      )
                    : Text(
                        widget.agent.name[0].toUpperCase(),
                        style: TypographyTokens.textSmall.copyWith(
                          color: ColorTokens.brandText,
                          fontWeight: TypographyTokens.medium,
                        ),
                      ),
              ),

              const SizedBox(width: 8),

              // Name
              Text(
                widget.agent.name,
                style: TypographyTokens.textSmall.copyWith(
                  color: ColorTokens.textPrimary,
                  fontWeight: widget.isSelected
                      ? TypographyTokens.medium
                      : FontWeight.normal,
                ),
              ),

              // Badge (optional)
              if (widget.agent.badge != null) ...[
                const SizedBox(width: 6),
                _Badge(
                  label: widget.agent.badge!,
                  style: widget.badgeStyle,
                ),
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
  final AppBadgeStyle style;

  const _Badge({
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (style) {
      AppBadgeStyle.subtle => (
          ColorTokens.backgroundLevel3,
          ColorTokens.textTertiary,
        ),
      AppBadgeStyle.prominent => (
          ColorTokens.accent.withValues(alpha: 0.15),
          ColorTokens.accent,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TypographyTokens.textSmall.copyWith(
          color: textColor,
          fontSize: 11,
        ),
      ),
    );
  }
}

class AppAgent {
  final String name;
  final String? badge;
  final IconData? icon;
  final String? description;

  const AppAgent({
    required this.name,
    this.badge,
    this.icon,
    this.description,
  });
}

enum AppBadgeStyle {
  subtle,
  prominent,
}
