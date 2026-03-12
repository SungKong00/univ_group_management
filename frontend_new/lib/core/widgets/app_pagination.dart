import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/pagination_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/responsive_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppPaginationStyle;

/// 페이지네이션 컴포넌트
///
/// **용도**: 목록 페이지 이동, 데이터 테이블 페이지네이션
/// **접근성**: 키보드 네비게이션, 스크린 리더 지원
///
/// ```dart
/// // 기본 번호 스타일
/// AppPagination(
///   currentPage: 1,
///   totalPages: 10,
///   onPageChanged: (page) => setState(() => _currentPage = page),
/// )
///
/// // 간단 스타일
/// AppPagination.simple(
///   currentPage: 1,
///   totalPages: 10,
///   onPageChanged: (page) {},
/// )
///
/// // 컴팩트 스타일
/// AppPagination.compact(
///   currentPage: 1,
///   totalPages: 10,
///   onPageChanged: (page) {},
/// )
/// ```
class AppPagination extends StatelessWidget {
  /// 현재 페이지 (1부터 시작)
  final int currentPage;

  /// 총 페이지 수
  final int totalPages;

  /// 페이지 변경 콜백
  final ValueChanged<int> onPageChanged;

  /// 페이지네이션 스타일
  final AppPaginationStyle style;

  /// 표시할 페이지 버튼 수 (numbered 스타일용)
  final int visiblePages;

  /// 처음/끝 버튼 표시 여부
  final bool showFirstLast;

  /// 비활성화 여부
  final bool isDisabled;

  const AppPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.style = AppPaginationStyle.numbered,
    this.visiblePages = 5,
    this.showFirstLast = false,
    this.isDisabled = false,
  });

  /// 간단 스타일 팩토리
  factory AppPagination.simple({
    Key? key,
    required int currentPage,
    required int totalPages,
    required ValueChanged<int> onPageChanged,
    bool showFirstLast = false,
    bool isDisabled = false,
  }) {
    return AppPagination(
      key: key,
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChanged: onPageChanged,
      style: AppPaginationStyle.simple,
      showFirstLast: showFirstLast,
      isDisabled: isDisabled,
    );
  }

  /// 컴팩트 스타일 팩토리
  factory AppPagination.compact({
    Key? key,
    required int currentPage,
    required int totalPages,
    required ValueChanged<int> onPageChanged,
    bool isDisabled = false,
  }) {
    return AppPagination(
      key: key,
      currentPage: currentPage,
      totalPages: totalPages,
      onPageChanged: onPageChanged,
      style: AppPaginationStyle.compact,
      isDisabled: isDisabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = PaginationColors.from(colorExt, style);

    return Semantics(
      label: '페이지 $currentPage / $totalPages',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: switch (style) {
          AppPaginationStyle.numbered => _buildNumbered(colors, spacingExt),
          AppPaginationStyle.simple => _buildSimple(colors, spacingExt),
          AppPaginationStyle.compact => _buildCompact(colors, spacingExt),
        },
      ),
    );
  }

  List<Widget> _buildNumbered(
    PaginationColors colors,
    AppSpacingExtension spacing,
  ) {
    final List<Widget> buttons = [];

    // 처음 버튼
    if (showFirstLast) {
      buttons.add(
        _PageButton(
          icon: Icons.first_page,
          onTap: currentPage > 1 && !isDisabled ? () => onPageChanged(1) : null,
          colors: colors,
          isDisabled: currentPage <= 1 || isDisabled,
        ),
      );
      buttons.add(SizedBox(width: spacing.xs));
    }

    // 이전 버튼
    buttons.add(
      _PageButton(
        icon: Icons.chevron_left,
        onTap: currentPage > 1 && !isDisabled
            ? () => onPageChanged(currentPage - 1)
            : null,
        colors: colors,
        isDisabled: currentPage <= 1 || isDisabled,
      ),
    );
    buttons.add(SizedBox(width: spacing.xs));

    // 페이지 번호들
    final pageNumbers = _calculatePageNumbers();
    for (int i = 0; i < pageNumbers.length; i++) {
      final page = pageNumbers[i];
      if (page == -1) {
        buttons.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.xs),
            child: Text('...', style: TextStyle(color: colors.text)),
          ),
        );
      } else {
        buttons.add(
          _PageButton(
            label: '$page',
            isActive: page == currentPage,
            onTap: !isDisabled ? () => onPageChanged(page) : null,
            colors: colors,
            isDisabled: isDisabled,
          ),
        );
      }
      if (i < pageNumbers.length - 1) {
        buttons.add(SizedBox(width: spacing.xs));
      }
    }

    // 다음 버튼
    buttons.add(SizedBox(width: spacing.xs));
    buttons.add(
      _PageButton(
        icon: Icons.chevron_right,
        onTap: currentPage < totalPages && !isDisabled
            ? () => onPageChanged(currentPage + 1)
            : null,
        colors: colors,
        isDisabled: currentPage >= totalPages || isDisabled,
      ),
    );

    // 끝 버튼
    if (showFirstLast) {
      buttons.add(SizedBox(width: spacing.xs));
      buttons.add(
        _PageButton(
          icon: Icons.last_page,
          onTap: currentPage < totalPages && !isDisabled
              ? () => onPageChanged(totalPages)
              : null,
          colors: colors,
          isDisabled: currentPage >= totalPages || isDisabled,
        ),
      );
    }

    return buttons;
  }

  List<int> _calculatePageNumbers() {
    if (totalPages <= visiblePages) {
      return List.generate(totalPages, (i) => i + 1);
    }

    final List<int> pages = [];
    final int halfVisible = visiblePages ~/ 2;

    int start = currentPage - halfVisible;
    int end = currentPage + halfVisible;

    if (start < 1) {
      start = 1;
      end = visiblePages;
    }

    if (end > totalPages) {
      end = totalPages;
      start = totalPages - visiblePages + 1;
    }

    // 첫 페이지
    if (start > 1) {
      pages.add(1);
      if (start > 2) {
        pages.add(-1); // ellipsis
      }
    }

    // 중간 페이지들
    for (int i = start; i <= end; i++) {
      pages.add(i);
    }

    // 마지막 페이지
    if (end < totalPages) {
      if (end < totalPages - 1) {
        pages.add(-1); // ellipsis
      }
      pages.add(totalPages);
    }

    return pages;
  }

  List<Widget> _buildSimple(
    PaginationColors colors,
    AppSpacingExtension spacing,
  ) {
    return [
      if (showFirstLast) ...[
        _PageButton(
          icon: Icons.first_page,
          onTap: currentPage > 1 && !isDisabled ? () => onPageChanged(1) : null,
          colors: colors,
          isDisabled: currentPage <= 1 || isDisabled,
        ),
        SizedBox(width: spacing.xs),
      ],
      _PageButton(
        icon: Icons.chevron_left,
        onTap: currentPage > 1 && !isDisabled
            ? () => onPageChanged(currentPage - 1)
            : null,
        colors: colors,
        isDisabled: currentPage <= 1 || isDisabled,
      ),
      SizedBox(width: spacing.medium),
      Text(
        '$currentPage / $totalPages',
        style: TextStyle(
          color: colors.text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(width: spacing.medium),
      _PageButton(
        icon: Icons.chevron_right,
        onTap: currentPage < totalPages && !isDisabled
            ? () => onPageChanged(currentPage + 1)
            : null,
        colors: colors,
        isDisabled: currentPage >= totalPages || isDisabled,
      ),
      if (showFirstLast) ...[
        SizedBox(width: spacing.xs),
        _PageButton(
          icon: Icons.last_page,
          onTap: currentPage < totalPages && !isDisabled
              ? () => onPageChanged(totalPages)
              : null,
          colors: colors,
          isDisabled: currentPage >= totalPages || isDisabled,
        ),
      ],
    ];
  }

  List<Widget> _buildCompact(
    PaginationColors colors,
    AppSpacingExtension spacing,
  ) {
    return [
      _PageButton(
        icon: Icons.chevron_left,
        onTap: currentPage > 1 && !isDisabled
            ? () => onPageChanged(currentPage - 1)
            : null,
        colors: colors,
        isDisabled: currentPage <= 1 || isDisabled,
      ),
      SizedBox(width: spacing.xs),
      _PageButton(
        icon: Icons.chevron_right,
        onTap: currentPage < totalPages && !isDisabled
            ? () => onPageChanged(currentPage + 1)
            : null,
        colors: colors,
        isDisabled: currentPage >= totalPages || isDisabled,
      ),
    ];
  }
}

/// 페이지 버튼 위젯
class _PageButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback? onTap;
  final PaginationColors colors;
  final bool isDisabled;

  const _PageButton({
    this.label,
    this.icon,
    this.isActive = false,
    this.onTap,
    required this.colors,
    this.isDisabled = false,
  });

  @override
  State<_PageButton> createState() => _PageButtonState();
}

class _PageButtonState extends State<_PageButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final width = MediaQuery.sizeOf(context).width;

    final backgroundColor = widget.isActive
        ? colors.backgroundActive
        : _isHovered && !widget.isDisabled
        ? colors.backgroundHover
        : colors.background;

    final contentColor = widget.isActive
        ? colors.textActive
        : widget.isDisabled
        ? colors.textDisabled
        : colors.text;

    final buttonSize = ResponsiveTokens.isXS(width) ? 32.0 : 36.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          width: widget.label != null ? null : buttonSize,
          height: buttonSize,
          constraints: widget.label != null
              ? BoxConstraints(minWidth: buttonSize)
              : null,
          padding: widget.label != null
              ? const EdgeInsets.symmetric(horizontal: 12)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderTokens.smallRadius(),
            border: !widget.isActive
                ? Border.all(
                    color: colors.border,
                    width: BorderTokens.widthThin,
                  )
                : null,
          ),
          child: Center(
            child: widget.icon != null
                ? Icon(widget.icon, size: 18, color: contentColor)
                : Text(
                    widget.label ?? '',
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 13,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
