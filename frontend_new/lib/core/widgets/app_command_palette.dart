import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/command_palette_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';
import '../models/app_command.dart';

// Export command model for convenience
export '../models/app_command.dart';

/// 커맨드 팔레트 표시 함수
///
/// 빠른 검색 및 명령 실행을 위한 팔레트
///
/// ```dart
/// showAppCommandPalette(
///   context: context,
///   commands: [
///     AppCommand(
///       id: 'new_file',
///       label: '새 파일',
///       icon: Icons.add,
///       shortcut: '⌘N',
///       onExecute: () => createNewFile(),
///     ),
///     AppCommand(
///       id: 'save',
///       label: '저장',
///       icon: Icons.save,
///       shortcut: '⌘S',
///       category: '파일',
///       onExecute: () => saveFile(),
///     ),
///   ],
/// )
/// ```
Future<AppCommand?> showAppCommandPalette({
  required BuildContext context,
  required List<AppCommand> commands,
  String placeholder = '명령어 검색...',
  List<AppCommand>? recentCommands,
}) {
  return showGeneralDialog<AppCommand>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '커맨드 팔레트 닫기',
    barrierColor: Colors.transparent,
    transitionDuration: AnimationTokens.durationStandard,
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AppCommandPalette(
        commands: commands,
        placeholder: placeholder,
        recentCommands: recentCommands,
        animation: animation,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

class _AppCommandPalette extends StatefulWidget {
  final List<AppCommand> commands;
  final String placeholder;
  final List<AppCommand>? recentCommands;
  final Animation<double> animation;

  const _AppCommandPalette({
    required this.commands,
    required this.placeholder,
    required this.animation,
    this.recentCommands,
  });

  @override
  State<_AppCommandPalette> createState() => _AppCommandPaletteState();
}

class _AppCommandPaletteState extends State<_AppCommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<AppCommand> _filteredCommands = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredCommands = widget.commands;
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCommands = widget.commands;
      } else {
        _filteredCommands = widget.commands.where((cmd) {
          return cmd.label.toLowerCase().contains(query) ||
              (cmd.description?.toLowerCase().contains(query) ?? false) ||
              (cmd.category?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      _selectedIndex = 0;
    });
  }

  void _selectCommand(AppCommand command) {
    Navigator.of(context).pop(command);
    command.onExecute?.call();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _filteredCommands.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex =
            (_selectedIndex - 1 + _filteredCommands.length) %
            _filteredCommands.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_filteredCommands.isNotEmpty) {
        _selectCommand(_filteredCommands[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = CommandPaletteColors.from(colorExt);

    final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animation,
        curve: AnimationTokens.curveSmooth,
      ),
    );
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animation,
        curve: AnimationTokens.curveDefault,
      ),
    );

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Stack(
        children: [
          // 오버레이
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: Container(color: colors.overlay),
            ),
          ),

          // 팔레트
          Align(
            alignment: const Alignment(0, -0.3),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 560,
                    constraints: const BoxConstraints(maxHeight: 480),
                    margin: EdgeInsets.all(spacingExt.large),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(
                        BorderTokens.radiusLarge,
                      ),
                      border: Border.all(
                        color: colors.border,
                        width: BorderTokens.widthThin,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 검색 입력
                        _buildSearchInput(colors, spacingExt),

                        // 구분선
                        Container(height: 1, color: colors.divider),

                        // 결과 목록
                        Flexible(child: _buildResultsList(colors, spacingExt)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput(
    CommandPaletteColors colors,
    AppSpacingExtension spacingExt,
  ) {
    return Container(
      padding: EdgeInsets.all(spacingExt.medium),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: ComponentSizeTokens.iconMedium,
            color: colors.searchIcon,
          ),
          SizedBox(width: spacingExt.small),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.inputText),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.inputPlaceholder),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.shortcutBackground,
              borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
            ),
            child: Text(
              'ESC',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.shortcutText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(
    CommandPaletteColors colors,
    AppSpacingExtension spacingExt,
  ) {
    if (_filteredCommands.isEmpty) {
      return _buildEmptyState(colors, spacingExt);
    }

    // 카테고리별 그룹화
    final grouped = <String?, List<AppCommand>>{};
    for (final cmd in _filteredCommands) {
      grouped.putIfAbsent(cmd.category, () => []).add(cmd);
    }

    return ListView(
      padding: EdgeInsets.symmetric(vertical: spacingExt.small),
      shrinkWrap: true,
      children: [
        for (final entry in grouped.entries) ...[
          if (entry.key != null)
            _buildCategoryHeader(entry.key!, colors, spacingExt),
          for (int i = 0; i < entry.value.length; i++)
            _buildCommandItem(
              entry.value[i],
              _filteredCommands.indexOf(entry.value[i]) == _selectedIndex,
              colors,
              spacingExt,
            ),
        ],
      ],
    );
  }

  Widget _buildCategoryHeader(
    String category,
    CommandPaletteColors colors,
    AppSpacingExtension spacingExt,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacingExt.medium,
        spacingExt.small,
        spacingExt.medium,
        spacingExt.xs,
      ),
      child: Text(
        category,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.groupHeader,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCommandItem(
    AppCommand command,
    bool isSelected,
    CommandPaletteColors colors,
    AppSpacingExtension spacingExt,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _selectCommand(command),
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          margin: EdgeInsets.symmetric(
            horizontal: spacingExt.small,
            vertical: 2,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: spacingExt.medium,
            vertical: spacingExt.small,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.itemBackgroundSelected
                : colors.itemBackground,
            borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
          ),
          child: Row(
            children: [
              if (command.icon != null) ...[
                Icon(
                  command.icon,
                  size: ComponentSizeTokens.iconSmall,
                  color: colors.itemIcon,
                ),
                SizedBox(width: spacingExt.small),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.itemText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (command.description != null)
                      Text(
                        command.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.itemDescription,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (command.shortcut != null) ...[
                SizedBox(width: spacingExt.small),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.shortcutBackground,
                    borderRadius: BorderRadius.circular(
                      BorderTokens.radiusSmall,
                    ),
                  ),
                  child: Text(
                    command.shortcut!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.shortcutText,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    CommandPaletteColors colors,
    AppSpacingExtension spacingExt,
  ) {
    return Padding(
      padding: EdgeInsets.all(spacingExt.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: colors.emptyIcon),
          SizedBox(height: spacingExt.small),
          Text(
            '검색 결과가 없습니다',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.emptyText),
          ),
        ],
      ),
    );
  }
}
