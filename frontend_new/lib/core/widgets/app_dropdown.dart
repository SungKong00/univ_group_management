import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/dropdown_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/responsive_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppDropdownSize;

/// 드롭다운 아이템 모델
class AppDropdownItem<T> {
  /// 아이템 값
  final T value;

  /// 표시 라벨
  final String label;

  /// 설명 텍스트 (선택)
  final String? description;

  /// 선행 아이콘 (선택)
  final IconData? icon;

  /// 그룹 헤더 (선택)
  final String? group;

  /// 비활성화 여부
  final bool isDisabled;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.description,
    this.icon,
    this.group,
    this.isDisabled = false,
  });
}

/// 드롭다운 선택기 컴포넌트
///
/// **용도**: 폼 입력, 필터링, 옵션 선택
/// **접근성**: 키보드 네비게이션, 스크린 리더 지원
///
/// ```dart
/// // 기본 사용
/// AppDropdown<String>(
///   items: [
///     AppDropdownItem(value: 'kr', label: '한국'),
///     AppDropdownItem(value: 'us', label: '미국'),
///     AppDropdownItem(value: 'jp', label: '일본'),
///   ],
///   value: _selectedCountry,
///   onChanged: (value) => setState(() => _selectedCountry = value),
///   placeholder: '국가 선택',
/// )
///
/// // 검색 가능
/// AppDropdown<String>(
///   items: _countries,
///   value: _selected,
///   onChanged: (v) => setState(() => _selected = v),
///   isSearchable: true,
///   placeholder: '검색하여 선택...',
/// )
///
/// // 그룹화된 아이템
/// AppDropdown<String>(
///   items: [
///     AppDropdownItem(value: 'seoul', label: '서울', group: '한국'),
///     AppDropdownItem(value: 'busan', label: '부산', group: '한국'),
///     AppDropdownItem(value: 'tokyo', label: '도쿄', group: '일본'),
///   ],
///   value: _selected,
///   onChanged: (v) => setState(() => _selected = v),
/// )
/// ```
class AppDropdown<T> extends StatefulWidget {
  /// 드롭다운 아이템 목록
  final List<AppDropdownItem<T>> items;

  /// 현재 선택 값
  final T? value;

  /// 값 변경 콜백
  final ValueChanged<T?>? onChanged;

  /// Placeholder 텍스트
  final String? placeholder;

  /// 라벨 텍스트
  final String? label;

  /// 도움말 텍스트
  final String? helperText;

  /// 에러 텍스트
  final String? errorText;

  /// 검색 가능 여부
  final bool isSearchable;

  /// 비활성화 여부
  final bool isDisabled;

  /// 로딩 중 여부
  final bool isLoading;

  /// 드롭다운 크기
  final AppDropdownSize size;

  /// 커스텀 아이템 빌더
  final Widget Function(AppDropdownItem<T>)? itemBuilder;

  const AppDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.placeholder,
    this.label,
    this.helperText,
    this.errorText,
    this.isSearchable = false,
    this.isDisabled = false,
    this.isLoading = false,
    this.size = AppDropdownSize.medium,
    this.itemBuilder,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isHovered = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (widget.isDisabled || widget.isLoading) return;

    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _DropdownMenu<T>(
        link: _layerLink,
        items: _filteredItems,
        selectedValue: widget.value,
        onSelect: _selectItem,
        onClose: _closeDropdown,
        isSearchable: widget.isSearchable,
        searchController: _searchController,
        onSearchChanged: (query) {
          setState(() => _searchQuery = query);
          _overlayEntry?.markNeedsBuild();
        },
        size: widget.size,
        itemBuilder: widget.itemBuilder,
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _focusNode.requestFocus();
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectItem(T value) {
    widget.onChanged?.call(value);
    _closeDropdown();
  }

  List<AppDropdownItem<T>> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;

    return widget.items
        .where((item) =>
            item.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (item.description
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false))
        .toList();
  }

  AppDropdownItem<T>? get _selectedItem {
    if (widget.value == null) return null;
    try {
      return widget.items.firstWhere((item) => item.value == widget.value);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final colors = DropdownColors.standard(colorExt);

    final hasError = widget.errorText != null;

    // 사이즈별 스타일
    final (height, paddingH) = switch (widget.size) {
      AppDropdownSize.small => (
        ResponsiveTokens.inputHeight(width) - 8,
        ResponsiveTokens.inputPaddingH(width),
      ),
      AppDropdownSize.medium => (
        ResponsiveTokens.inputHeight(width),
        ResponsiveTokens.inputPaddingH(width),
      ),
      AppDropdownSize.large => (
        ResponsiveTokens.inputHeight(width) + 8,
        ResponsiveTokens.inputPaddingH(width),
      ),
    };

    // 상태별 색상
    final backgroundColor = widget.isDisabled
        ? colors.triggerBackgroundDisabled
        : _isOpen
            ? colors.triggerBackgroundFocus
            : _isHovered
                ? colors.triggerBackgroundHover
                : colors.triggerBackground;

    final borderColor = hasError
        ? colors.errorBorder
        : _isOpen
            ? colors.triggerBorderFocus
            : colors.triggerBorder;

    final borderWidth =
        _isOpen ? BorderTokens.widthFocus : BorderTokens.widthThin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: textTheme.bodySmall?.copyWith(
              color: colorExt.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: spacingExt.xs),
        ],

        // Trigger
        CompositedTransformTarget(
          link: _layerLink,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: _toggleDropdown,
              child: AnimatedContainer(
                duration: AnimationTokens.durationQuick,
                height: height,
                padding: EdgeInsets.symmetric(horizontal: paddingH),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border.all(color: borderColor, width: borderWidth),
                  borderRadius: BorderTokens.smallRadius(),
                ),
                child: Row(
                  children: [
                    // Selected value or placeholder
                    Expanded(
                      child: Text(
                        _selectedItem?.label ?? widget.placeholder ?? '',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: fontSize,
                          color: _selectedItem != null
                              ? colors.triggerText
                              : colors.triggerPlaceholder,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Loading or chevron
                    if (widget.isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.triggerIcon,
                        ),
                      )
                    else
                      AnimatedRotation(
                        turns: _isOpen ? 0.5 : 0,
                        duration: AnimationTokens.durationQuick,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: colors.triggerIcon,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Helper or Error text
        if (widget.helperText != null || widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText ?? widget.helperText!,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: hasError ? colors.errorText : colorExt.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

/// 드롭다운 메뉴 Overlay
class _DropdownMenu<T> extends StatelessWidget {
  final LayerLink link;
  final List<AppDropdownItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T> onSelect;
  final VoidCallback onClose;
  final bool isSearchable;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final AppDropdownSize size;
  final Widget Function(AppDropdownItem<T>)? itemBuilder;

  const _DropdownMenu({
    required this.link,
    required this.items,
    required this.selectedValue,
    required this.onSelect,
    required this.onClose,
    required this.isSearchable,
    required this.searchController,
    required this.onSearchChanged,
    required this.size,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final colors = DropdownColors.standard(colorExt);
    final width = MediaQuery.sizeOf(context).width;

    // 사이즈별 스타일
    final itemHeight = switch (size) {
      AppDropdownSize.small => 36.0,
      AppDropdownSize.medium => 40.0,
      AppDropdownSize.large => 44.0,
    };

    // 그룹별 아이템 정리
    final groupedItems = <String?, List<AppDropdownItem<T>>>{};
    for (final item in items) {
      groupedItems.putIfAbsent(item.group, () => []).add(item);
    }

    final menuWidth = switch (ResponsiveTokens.screenSize(width)) {
      ScreenSize.xs => width - spacingExt.large,
      ScreenSize.sm => width - spacingExt.large,
      ScreenSize.md => 320.0,
      ScreenSize.lg => 360.0,
      ScreenSize.xl => 400.0,
    };

    final maxMenuHeight = switch (ResponsiveTokens.screenSize(width)) {
      ScreenSize.xs => 240.0,
      ScreenSize.sm => 280.0,
      ScreenSize.md => 320.0,
      ScreenSize.lg => 360.0,
      ScreenSize.xl => 400.0,
    };

    return GestureDetector(
      onTap: onClose,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Positioned(
            width: menuWidth,
            child: CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: Offset(0, spacingExt.xs),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(maxHeight: maxMenuHeight),
                  decoration: BoxDecoration(
                    color: colors.menuBackground,
                    border: Border.all(
                      color: colors.menuBorder,
                      width: BorderTokens.widthThin,
                    ),
                    borderRadius: BorderTokens.smallRadius(),
                    boxShadow: [
                      BoxShadow(
                        color: colorExt.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search input
                      if (isSearchable) ...[
                        Padding(
                          padding: EdgeInsets.all(spacingExt.xs),
                          child: TextField(
                            controller: searchController,
                            autofocus: true,
                            onChanged: onSearchChanged,
                            decoration: InputDecoration(
                              hintText: '검색...',
                              hintStyle: textTheme.bodySmall?.copyWith(
                                color: colorExt.textTertiary,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: ResponsiveTokens.iconSize(width) - 2,
                                color: colorExt.textTertiary,
                              ),
                              filled: true,
                              fillColor: colorExt.surfaceTertiary,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: spacingExt.medium,
                                vertical: spacingExt.xs,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderTokens.smallRadius(),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorExt.textPrimary,
                            ),
                          ),
                        ),
                        Divider(height: 1, color: colors.menuBorder),
                      ],

                      // Items
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(vertical: spacingExt.xs),
                          children: [
                            for (final entry in groupedItems.entries) ...[
                              // Group header
                              if (entry.key != null)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    spacingExt.medium,
                                    spacingExt.small,
                                    spacingExt.medium,
                                    spacingExt.xs,
                                  ),
                                  child: Text(
                                    entry.key!,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colors.groupHeader,
                                    ),
                                  ),
                                ),

                              // Items in group
                              for (final item in entry.value)
                                _DropdownMenuItem<T>(
                                  item: item,
                                  isSelected: item.value == selectedValue,
                                  height: itemHeight,
                                  onTap: () => onSelect(item.value),
                                  itemBuilder: itemBuilder,
                                ),
                            ],
                          ],
                        ),
                      ),

                      // Empty state
                      if (items.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(spacingExt.large),
                          child: Text(
                            '결과 없음',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorExt.textTertiary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 드롭다운 메뉴 아이템
class _DropdownMenuItem<T> extends StatefulWidget {
  final AppDropdownItem<T> item;
  final bool isSelected;
  final double height;
  final VoidCallback onTap;
  final Widget Function(AppDropdownItem<T>)? itemBuilder;

  const _DropdownMenuItem({
    required this.item,
    required this.isSelected,
    required this.height,
    required this.onTap,
    this.itemBuilder,
  });

  @override
  State<_DropdownMenuItem<T>> createState() => _DropdownMenuItemState<T>();
}

class _DropdownMenuItemState<T> extends State<_DropdownMenuItem<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final colors = DropdownColors.standard(colorExt);

    final backgroundColor = widget.item.isDisabled
        ? colors.itemBackground
        : widget.isSelected
            ? colors.itemBackgroundSelected
            : _isHovered
                ? colors.itemBackgroundHover
                : colors.itemBackground;

    final textColor = widget.item.isDisabled
        ? colors.itemTextDisabled
        : widget.isSelected
            ? colors.itemTextSelected
            : colors.itemText;

    // Custom builder
    if (widget.itemBuilder != null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.item.isDisabled ? null : widget.onTap,
          child: Container(
            color: backgroundColor,
            child: widget.itemBuilder!(widget.item),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.item.isDisabled ? null : widget.onTap,
        child: Container(
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: spacingExt.medium),
          color: backgroundColor,
          child: Row(
            children: [
              // Icon
              if (widget.item.icon != null) ...[
                Icon(widget.item.icon, size: ResponsiveTokens.iconSize(width) - 2, color: textColor),
                SizedBox(width: spacingExt.componentIconGap),
              ],

              // Label & description
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight:
                            widget.isSelected ? FontWeight.w500 : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.item.description != null)
                      Text(
                        widget.item.description!,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: colors.itemDescription,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Check icon
              if (widget.isSelected)
                Icon(Icons.check, size: 18, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}
