import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/data_table_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart'
    show
        AppDataTableSortDirection,
        AppDataTableDensity,
        AppDataTableSelectionMode;

/// 테이블 컬럼 정의
class AppTableColumn<T> {
  /// 컬럼 ID
  final String id;

  /// 헤더 라벨
  final String label;

  /// 컬럼 너비 (null이면 자동)
  final double? width;

  /// 최소 너비
  final double? minWidth;

  /// 정렬 가능 여부
  final bool isSortable;

  /// 셀 빌더
  final Widget Function(T item, int index) cellBuilder;

  /// 정렬 비교 함수
  final int Function(T a, T b)? comparator;

  /// 텍스트 정렬
  final TextAlign textAlign;

  const AppTableColumn({
    required this.id,
    required this.label,
    required this.cellBuilder,
    this.width,
    this.minWidth,
    this.isSortable = true,
    this.comparator,
    this.textAlign = TextAlign.left,
  });
}

/// 데이터 테이블 컴포넌트
///
/// **용도**: 정렬, 필터, 페이지네이션을 지원하는 데이터 테이블
/// **접근성**: 키보드 네비게이션, Semantics 지원
/// **반응형**: 화면 크기에 맞게 스크롤 지원
///
/// ```dart
/// // 기본 사용
/// AppDataTable<User>(
///   columns: [
///     AppTableColumn(
///       id: 'name',
///       label: '이름',
///       cellBuilder: (user, _) => Text(user.name),
///     ),
///     AppTableColumn(
///       id: 'email',
///       label: '이메일',
///       cellBuilder: (user, _) => Text(user.email),
///     ),
///   ],
///   data: users,
/// )
///
/// // 정렬 및 선택 지원
/// AppDataTable<User>(
///   columns: columns,
///   data: users,
///   selectionMode: AppDataTableSelectionMode.multiple,
///   selectedRows: _selectedUsers,
///   onSelectionChanged: (selected) => setState(() => _selectedUsers = selected),
///   sortColumnId: 'name',
///   sortDirection: AppDataTableSortDirection.ascending,
///   onSort: (columnId, direction) => _handleSort(columnId, direction),
/// )
/// ```
class AppDataTable<T> extends StatefulWidget {
  /// 컬럼 정의
  final List<AppTableColumn<T>> columns;

  /// 데이터 목록
  final List<T> data;

  /// 테이블 밀도
  final AppDataTableDensity density;

  /// 선택 모드
  final AppDataTableSelectionMode selectionMode;

  /// 선택된 행
  final Set<T>? selectedRows;

  /// 선택 변경 콜백
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// 정렬 컬럼 ID
  final String? sortColumnId;

  /// 정렬 방향
  final AppDataTableSortDirection? sortDirection;

  /// 정렬 변경 콜백
  final void Function(String columnId, AppDataTableSortDirection direction)?
  onSort;

  /// 행 클릭 콜백
  final ValueChanged<T>? onRowTap;

  /// 행 키 추출 함수
  final String Function(T item)? rowKey;

  /// 스트라이프 표시 여부
  final bool showStripes;

  /// 테두리 표시 여부
  final bool showBorder;

  /// 헤더 고정 여부
  final bool stickyHeader;

  /// 로딩 상태
  final bool isLoading;

  /// 빈 상태 위젯
  final Widget? emptyWidget;

  /// 빈 상태 메시지
  final String? emptyMessage;

  /// 최대 높이
  final double? maxHeight;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.data,
    this.density = AppDataTableDensity.standard,
    this.selectionMode = AppDataTableSelectionMode.none,
    this.selectedRows,
    this.onSelectionChanged,
    this.sortColumnId,
    this.sortDirection,
    this.onSort,
    this.onRowTap,
    this.rowKey,
    this.showStripes = false,
    this.showBorder = true,
    this.stickyHeader = true,
    this.isLoading = false,
    this.emptyWidget,
    this.emptyMessage,
    this.maxHeight,
  });

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T> extends State<AppDataTable<T>> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  double _getRowHeight() {
    return switch (widget.density) {
      AppDataTableDensity.compact => 40.0,
      AppDataTableDensity.standard => 52.0,
      AppDataTableDensity.comfortable => 64.0,
    };
  }

  EdgeInsets _getCellPadding(AppSpacingExtension spacingExt) {
    return switch (widget.density) {
      AppDataTableDensity.compact => EdgeInsets.symmetric(
        horizontal: spacingExt.small,
        vertical: spacingExt.xs,
      ),
      AppDataTableDensity.standard => EdgeInsets.symmetric(
        horizontal: spacingExt.medium,
        vertical: spacingExt.small,
      ),
      AppDataTableDensity.comfortable => EdgeInsets.symmetric(
        horizontal: spacingExt.large,
        vertical: spacingExt.medium,
      ),
    };
  }

  bool _isRowSelected(T item) {
    return widget.selectedRows?.contains(item) ?? false;
  }

  void _toggleRowSelection(T item) {
    if (widget.selectionMode == AppDataTableSelectionMode.none) return;

    final currentSelection = widget.selectedRows ?? <T>{};
    final newSelection = <T>{...currentSelection};

    if (widget.selectionMode == AppDataTableSelectionMode.single) {
      if (_isRowSelected(item)) {
        newSelection.clear();
      } else {
        newSelection.clear();
        newSelection.add(item);
      }
    } else {
      if (_isRowSelected(item)) {
        newSelection.remove(item);
      } else {
        newSelection.add(item);
      }
    }

    widget.onSelectionChanged?.call(newSelection);
  }

  void _toggleSelectAll() {
    if (widget.selectionMode != AppDataTableSelectionMode.multiple) return;

    final allSelected =
        widget.selectedRows?.length == widget.data.length &&
        widget.data.isNotEmpty;

    if (allSelected) {
      widget.onSelectionChanged?.call({});
    } else {
      widget.onSelectionChanged?.call(Set.from(widget.data));
    }
  }

  void _handleSort(String columnId) {
    if (widget.onSort == null) return;

    final column = widget.columns.firstWhere((c) => c.id == columnId);
    if (!column.isSortable) return;

    final newDirection =
        widget.sortColumnId == columnId &&
            widget.sortDirection == AppDataTableSortDirection.ascending
        ? AppDataTableSortDirection.descending
        : AppDataTableSortDirection.ascending;

    widget.onSort!(columnId, newDirection);
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = DataTableColors.from(colorExt);
    final cellPadding = _getCellPadding(spacingExt);

    if (widget.isLoading) {
      return _buildLoadingState(colors);
    }

    if (widget.data.isEmpty) {
      return _buildEmptyState(colors, spacingExt);
    }

    Widget table = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더
        _buildHeader(colors, cellPadding),

        // 데이터 행
        Flexible(
          child: ListView.builder(
            controller: _verticalController,
            shrinkWrap: widget.maxHeight == null,
            itemCount: widget.data.length,
            itemBuilder: (context, index) {
              return _buildRow(colors, cellPadding, widget.data[index], index);
            },
          ),
        ),
      ],
    );

    // 테두리 적용
    if (widget.showBorder) {
      table = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.border,
            width: BorderTokens.widthThin,
          ),
          borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        ),
        clipBehavior: Clip.antiAlias,
        child: table,
      );
    }

    // 최대 높이 적용
    if (widget.maxHeight != null) {
      table = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: table,
      );
    }

    // 가로 스크롤 지원
    // IntrinsicWidth 대신 고정 너비 계산 (ListView와의 충돌 방지)
    final hasSelection = widget.selectionMode != AppDataTableSelectionMode.none;
    final selectionWidth = hasSelection ? 48.0 : 0.0;
    final columnsWidth = widget.columns.fold<double>(
      0.0,
      (sum, col) => sum + (col.width ?? col.minWidth ?? 80.0),
    );
    final totalWidth = selectionWidth + columnsWidth;

    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: totalWidth, child: table),
      ),
    );
  }

  Widget _buildHeader(DataTableColors colors, EdgeInsets cellPadding) {
    final hasSelection = widget.selectionMode != AppDataTableSelectionMode.none;
    final allSelected =
        widget.selectedRows?.length == widget.data.length &&
        widget.data.isNotEmpty;
    final someSelected =
        (widget.selectedRows?.isNotEmpty ?? false) && !allSelected;

    return Container(
      height: _getRowHeight(),
      decoration: BoxDecoration(
        color: colors.headerBackground,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: BorderTokens.widthThin,
          ),
        ),
      ),
      child: Row(
        children: [
          // 선택 체크박스
          if (hasSelection)
            _buildCheckboxCell(
              colors: colors,
              isChecked: allSelected,
              isIndeterminate: someSelected,
              onChanged: (_) => _toggleSelectAll(),
              cellPadding: cellPadding,
            ),

          // 컬럼 헤더
          ...widget.columns.map((column) {
            return _buildHeaderCell(colors, cellPadding, column);
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    DataTableColors colors,
    EdgeInsets cellPadding,
    AppTableColumn<T> column,
  ) {
    final isSorted = widget.sortColumnId == column.id;
    final isAscending =
        widget.sortDirection == AppDataTableSortDirection.ascending;

    Widget content = Text(
      column.label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: colors.headerText,
        fontWeight: FontWeight.w600,
      ),
      textAlign: column.textAlign,
    );

    // 정렬 아이콘 추가
    if (column.isSortable && widget.onSort != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: content),
          const SizedBox(width: 4),
          Icon(
            isSorted
                ? (isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: ComponentSizeTokens.iconXSmall,
            color: isSorted ? colors.sortIconActive : colors.sortIcon,
          ),
        ],
      );

      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _handleSort(column.id),
          child: content,
        ),
      );
    }

    return Container(
      width: column.width,
      constraints: BoxConstraints(minWidth: column.minWidth ?? 80),
      padding: cellPadding,
      alignment: _getAlignment(column.textAlign),
      child: content,
    );
  }

  Widget _buildRow(
    DataTableColors colors,
    EdgeInsets cellPadding,
    T item,
    int index,
  ) {
    final isSelected = _isRowSelected(item);
    final hasSelection = widget.selectionMode != AppDataTableSelectionMode.none;
    final isEvenRow = index % 2 == 0;

    return _TableRow(
      height: _getRowHeight(),
      backgroundColor: isSelected
          ? colors.rowBackgroundSelected
          : widget.showStripes && !isEvenRow
          ? colors.rowBackgroundAlt
          : colors.rowBackground,
      hoverColor: colors.rowBackgroundHover,
      borderColor: colors.border,
      showBorder: index < widget.data.length - 1,
      onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
      child: Row(
        children: [
          // 선택 체크박스
          if (hasSelection)
            _buildCheckboxCell(
              colors: colors,
              isChecked: isSelected,
              onChanged: (_) => _toggleRowSelection(item),
              cellPadding: cellPadding,
            ),

          // 데이터 셀
          ...widget.columns.map((column) {
            return Container(
              width: column.width,
              constraints: BoxConstraints(minWidth: column.minWidth ?? 80),
              padding: cellPadding,
              alignment: _getAlignment(column.textAlign),
              child: DefaultTextStyle(
                style:
                    Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colors.cellText) ??
                    const TextStyle(),
                child: column.cellBuilder(item, index),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCheckboxCell({
    required DataTableColors colors,
    required bool isChecked,
    bool isIndeterminate = false,
    required ValueChanged<bool?> onChanged,
    required EdgeInsets cellPadding,
  }) {
    return Container(
      width: 48,
      padding: cellPadding,
      alignment: Alignment.center,
      child: Checkbox(
        value: isIndeterminate ? null : isChecked,
        tristate: isIndeterminate,
        onChanged: onChanged,
        activeColor: colors.checkboxSelected,
        side: BorderSide(color: colors.checkbox),
      ),
    );
  }

  Widget _buildLoadingState(DataTableColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colors.loading),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    DataTableColors colors,
    AppSpacingExtension spacingExt,
  ) {
    if (widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacingExt.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: colors.emptyIcon),
            SizedBox(height: spacingExt.medium),
            Text(
              widget.emptyMessage ?? '데이터가 없습니다',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.emptyText),
            ),
          ],
        ),
      ),
    );
  }

  Alignment _getAlignment(TextAlign textAlign) {
    return switch (textAlign) {
      TextAlign.left || TextAlign.start => Alignment.centerLeft,
      TextAlign.right || TextAlign.end => Alignment.centerRight,
      TextAlign.center => Alignment.center,
      TextAlign.justify => Alignment.centerLeft,
    };
  }
}

/// 테이블 행 위젯
class _TableRow extends StatefulWidget {
  final double height;
  final Color backgroundColor;
  final Color hoverColor;
  final Color borderColor;
  final bool showBorder;
  final VoidCallback? onTap;
  final Widget child;

  const _TableRow({
    required this.height,
    required this.backgroundColor,
    required this.hoverColor,
    required this.borderColor,
    required this.showBorder,
    required this.child,
    this.onTap,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          height: widget.height,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : widget.backgroundColor,
            border: widget.showBorder
                ? Border(
                    bottom: BorderSide(
                      color: widget.borderColor,
                      width: BorderTokens.widthThin,
                    ),
                  )
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
