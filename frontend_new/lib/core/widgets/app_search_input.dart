import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/search_input_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/responsive_tokens.dart';
import '../theme/component_size_tokens.dart';

/// 검색 전용 입력 필드
///
/// **용도**: 검색 기능, 자동완성, 검색 히스토리
/// **접근성**: 최소 터치 영역 44px 보장, 키보드 네비게이션, Semantics 지원
/// **반응형**: 화면 크기에 따라 자동 조정
///
/// ```dart
/// // 기본 사용
/// AppSearchInput(
///   onChanged: (value) => _handleSearch(value),
///   onSubmitted: (value) => _performSearch(value),
///   placeholder: '검색어를 입력하세요',
/// )
///
/// // 자동완성 서제스천
/// AppSearchInput(
///   controller: _searchController,
///   suggestions: _filteredSuggestions,
///   onChanged: (value) => _filterSuggestions(value),
///   onSuggestionSelected: (suggestion) => _selectSuggestion(suggestion),
/// )
///
/// // 검색 히스토리
/// AppSearchInput(
///   history: _searchHistory,
///   onHistorySelected: (item) => _searchFromHistory(item),
///   onHistoryClear: () => _clearHistory(),
/// )
///
/// // 디바운스 적용
/// AppSearchInput(
///   debounce: Duration(milliseconds: 300),
///   onChanged: (value) => _searchWithDebounce(value),
/// )
/// ```
class AppSearchInput extends StatefulWidget {
  /// 텍스트 컨트롤러
  final TextEditingController? controller;

  /// 플레이스홀더 텍스트
  final String? placeholder;

  /// 값 변경 콜백
  final ValueChanged<String>? onChanged;

  /// 검색 제출 콜백
  final ValueChanged<String>? onSubmitted;

  /// 클리어 버튼 콜백
  final VoidCallback? onClear;

  /// 자동완성 서제스천 목록
  final List<String>? suggestions;

  /// 서제스천 선택 콜백
  final ValueChanged<String>? onSuggestionSelected;

  /// 검색 히스토리 목록
  final List<String>? history;

  /// 히스토리 선택 콜백
  final ValueChanged<String>? onHistorySelected;

  /// 히스토리 전체 삭제 콜백
  final VoidCallback? onHistoryClear;

  /// 히스토리 개별 삭제 콜백
  final ValueChanged<String>? onHistoryRemove;

  /// 클리어 버튼 표시 여부
  final bool showClearButton;

  /// 로딩 상태
  final bool isLoading;

  /// 비활성화 상태
  final bool isDisabled;

  /// 디바운스 시간
  final Duration? debounce;

  /// 자동 포커스
  final bool autofocus;

  /// 최대 서제스천 개수
  final int maxSuggestions;

  /// 최대 히스토리 개수
  final int maxHistory;

  const AppSearchInput({
    super.key,
    this.controller,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.suggestions,
    this.onSuggestionSelected,
    this.history,
    this.onHistorySelected,
    this.onHistoryClear,
    this.onHistoryRemove,
    this.showClearButton = true,
    this.isLoading = false,
    this.isDisabled = false,
    this.debounce,
    this.autofocus = false,
    this.maxSuggestions = 5,
    this.maxHistory = 5,
  });

  @override
  State<AppSearchInput> createState() => _AppSearchInputState();
}

class _AppSearchInputState extends State<AppSearchInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(AppSearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onTextChanged);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onTextChanged);
      _hasText = _controller.text.isNotEmpty;
    }
    // 서제스천이나 히스토리가 변경되면 오버레이 업데이트
    if (widget.suggestions != oldWidget.suggestions ||
        widget.history != oldWidget.history) {
      _updateOverlay();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }

    // 디바운스 적용
    if (widget.debounce != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(widget.debounce!, () {
        widget.onChanged?.call(_controller.text);
      });
    } else {
      widget.onChanged?.call(_controller.text);
    }

    _updateOverlay();
  }

  void _onFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // 약간의 딜레이를 주어 클릭 이벤트가 처리되도록 함
      Future.delayed(const Duration(milliseconds: 200), _removeOverlay);
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    if (!_shouldShowOverlay()) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      if (_shouldShowOverlay()) {
        _overlayEntry!.markNeedsBuild();
      } else {
        _removeOverlay();
      }
    } else if (_isFocused && _shouldShowOverlay()) {
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  bool _shouldShowOverlay() {
    final hasSuggestions =
        widget.suggestions != null && widget.suggestions!.isNotEmpty;
    final hasHistory =
        widget.history != null &&
        widget.history!.isNotEmpty &&
        _controller.text.isEmpty;
    return hasSuggestions || hasHistory;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(BorderTokens.radiusLarge),
            child: _buildDropdownContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContent() {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = SearchInputColors.from(colorExt);

    // 서제스천 표시 (텍스트가 있을 때)
    if (_hasText &&
        widget.suggestions != null &&
        widget.suggestions!.isNotEmpty) {
      final displaySuggestions = widget.suggestions!
          .take(widget.maxSuggestions)
          .toList();
      return Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: colors.suggestionBackground,
          borderRadius: BorderRadius.circular(BorderTokens.radiusLarge),
          border: Border.all(color: colors.border),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(vertical: spacingExt.xs),
          itemCount: displaySuggestions.length,
          itemBuilder: (context, index) {
            return _SuggestionItem(
              text: displaySuggestions[index],
              searchText: _controller.text,
              colors: colors,
              onTap: () {
                widget.onSuggestionSelected?.call(displaySuggestions[index]);
                _controller.text = displaySuggestions[index];
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
                _removeOverlay();
              },
            );
          },
        ),
      );
    }

    // 히스토리 표시 (텍스트가 없을 때)
    if (!_hasText && widget.history != null && widget.history!.isNotEmpty) {
      final displayHistory = widget.history!.take(widget.maxHistory).toList();
      return Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: colors.suggestionBackground,
          borderRadius: BorderRadius.circular(BorderTokens.radiusLarge),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 히스토리 헤더
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacingExt.medium,
                vertical: spacingExt.small,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '최근 검색',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.placeholder,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.onHistoryClear != null)
                    GestureDetector(
                      onTap: () {
                        widget.onHistoryClear?.call();
                        _removeOverlay();
                      },
                      child: Text(
                        '전체 삭제',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.suggestionHighlight,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 히스토리 목록
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: spacingExt.xs),
              itemCount: displayHistory.length,
              itemBuilder: (context, index) {
                return _HistoryItem(
                  text: displayHistory[index],
                  colors: colors,
                  onTap: () {
                    widget.onHistorySelected?.call(displayHistory[index]);
                    _controller.text = displayHistory[index];
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: _controller.text.length),
                    );
                    _removeOverlay();
                  },
                  onRemove: widget.onHistoryRemove != null
                      ? () {
                          widget.onHistoryRemove?.call(displayHistory[index]);
                        }
                      : null,
                );
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
    _focusNode.requestFocus();
  }

  void _handleSubmit(String value) {
    widget.onSubmitted?.call(value);
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = SearchInputColors.from(colorExt);
    final width = MediaQuery.sizeOf(context).width;

    final borderRadius = ResponsiveTokens.componentBorderRadius(width);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        textField: true,
        label: widget.placeholder ?? '검색',
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: !widget.isDisabled,
          autofocus: widget.autofocus,
          onSubmitted: _handleSubmit,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.text),
          decoration: InputDecoration(
            hintText: widget.placeholder ?? '검색',
            hintStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.placeholder),
            filled: true,
            fillColor: _isFocused
                ? colors.backgroundFocused
                : colors.background,
            contentPadding: EdgeInsets.symmetric(
              horizontal: spacingExt.medium,
              vertical: spacingExt.small,
            ),
            constraints: const BoxConstraints(
              minHeight: ComponentSizeTokens.minTouchTarget,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                left: spacingExt.medium,
                right: spacingExt.small,
              ),
              child: Icon(
                Icons.search,
                color: _isFocused ? colors.iconHover : colors.icon,
                size: ComponentSizeTokens.iconSmall,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: _buildSuffixIcon(colors, spacingExt),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: colors.borderFocused,
                width: BorderTokens.widthFocus,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: colors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(
    SearchInputColors colors,
    AppSpacingExtension spacingExt,
  ) {
    if (widget.isLoading) {
      return Padding(
        padding: EdgeInsets.only(
          left: spacingExt.small,
          right: spacingExt.medium,
        ),
        child: SizedBox(
          width: ComponentSizeTokens.iconSmall,
          height: ComponentSizeTokens.iconSmall,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.loadingSpinner,
          ),
        ),
      );
    }

    if (widget.showClearButton && _hasText) {
      return Padding(
        padding: EdgeInsets.only(
          left: spacingExt.small,
          right: spacingExt.medium,
        ),
        child: GestureDetector(
          onTap: _handleClear,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: ComponentSizeTokens.iconMedium,
              height: ComponentSizeTokens.iconMedium,
              decoration: BoxDecoration(
                color: colors.clearButtonBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: ComponentSizeTokens.iconXSmall,
                color: colors.clearButtonIcon,
              ),
            ),
          ),
        ),
      );
    }

    return null;
  }
}

/// 서제스천 아이템 위젯
class _SuggestionItem extends StatefulWidget {
  final String text;
  final String searchText;
  final SearchInputColors colors;
  final VoidCallback onTap;

  const _SuggestionItem({
    required this.text,
    required this.searchText,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_SuggestionItem> createState() => _SuggestionItemState();
}

class _SuggestionItemState extends State<_SuggestionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          padding: EdgeInsets.symmetric(
            horizontal: spacingExt.medium,
            vertical: spacingExt.small,
          ),
          color: _isHovered
              ? widget.colors.suggestionBackgroundHover
              : Colors.transparent,
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: ComponentSizeTokens.iconSmall,
                color: widget.colors.icon,
              ),
              SizedBox(width: spacingExt.small),
              Expanded(child: _buildHighlightedText()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText() {
    final text = widget.text;
    final searchText = widget.searchText.toLowerCase();
    final textLower = text.toLowerCase();

    if (searchText.isEmpty || !textLower.contains(searchText)) {
      return Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: widget.colors.suggestionText),
      );
    }

    final startIndex = textLower.indexOf(searchText);
    final endIndex = startIndex + searchText.length;

    return RichText(
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: widget.colors.suggestionText),
        children: [
          if (startIndex > 0) TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: TextStyle(
              color: widget.colors.suggestionHighlight,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (endIndex < text.length) TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }
}

/// 히스토리 아이템 위젯
class _HistoryItem extends StatefulWidget {
  final String text;
  final SearchInputColors colors;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _HistoryItem({
    required this.text,
    required this.colors,
    required this.onTap,
    this.onRemove,
  });

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          padding: EdgeInsets.symmetric(
            horizontal: spacingExt.medium,
            vertical: spacingExt.small,
          ),
          color: _isHovered
              ? widget.colors.suggestionBackgroundHover
              : Colors.transparent,
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: ComponentSizeTokens.iconSmall,
                color: widget.colors.historyIcon,
              ),
              SizedBox(width: spacingExt.small),
              Expanded(
                child: Text(
                  widget.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.colors.suggestionText,
                  ),
                ),
              ),
              if (widget.onRemove != null && _isHovered)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Icon(
                    Icons.close,
                    size: ComponentSizeTokens.iconSmall,
                    color: widget.colors.icon,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
