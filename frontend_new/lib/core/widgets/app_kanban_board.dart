import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/kanban_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppKanbanCardSize;

/// 칸반 보드 컴포넌트
///
/// **용도**: 태스크 관리, 워크플로우 시각화
/// **접근성**: 키보드 네비게이션 지원
///
/// ```dart
/// // 기본 사용
/// AppKanbanBoard(
///   columns: [
///     KanbanColumn(
///       id: 'todo',
///       title: 'To Do',
///       cards: [
///         KanbanCard(id: '1', title: 'Task 1'),
///         KanbanCard(id: '2', title: 'Task 2'),
///       ],
///     ),
///     KanbanColumn(
///       id: 'in_progress',
///       title: 'In Progress',
///       cards: [],
///     ),
///     KanbanColumn(
///       id: 'done',
///       title: 'Done',
///       cards: [],
///     ),
///   ],
///   onCardMoved: (card, fromColumn, toColumn, newIndex) {
///     // 카드 이동 처리
///   },
/// )
/// ```
class AppKanbanBoard extends StatefulWidget {
  /// 컬럼 목록
  final List<KanbanColumn> columns;

  /// 카드 크기
  final AppKanbanCardSize cardSize;

  /// 컬럼 너비
  final double columnWidth;

  /// 카드 이동 콜백
  final void Function(
    KanbanCard card,
    String fromColumnId,
    String toColumnId,
    int newIndex,
  )?
  onCardMoved;

  /// 카드 탭 콜백
  final void Function(KanbanCard card)? onCardTap;

  /// 카드 추가 콜백
  final void Function(String columnId)? onAddCard;

  /// 스크롤 가능 여부
  final bool isScrollable;

  /// 컬럼 추가 버튼 표시
  final bool showAddColumn;

  /// 카드 추가 버튼 표시
  final bool showAddCard;

  /// 컬럼 추가 콜백
  final VoidCallback? onAddColumn;

  const AppKanbanBoard({
    super.key,
    required this.columns,
    this.cardSize = AppKanbanCardSize.standard,
    this.columnWidth = 280,
    this.onCardMoved,
    this.onCardTap,
    this.onAddCard,
    this.isScrollable = true,
    this.showAddColumn = false,
    this.showAddCard = true,
    this.onAddColumn,
  });

  @override
  State<AppKanbanBoard> createState() => _AppKanbanBoardState();
}

class _AppKanbanBoardState extends State<AppKanbanBoard> {
  String? _draggingCardId;
  String? _draggingFromColumnId;
  String? _dropTargetColumnId;
  int? _dropTargetIndex;

  void _handleDragStart(KanbanCard card, String columnId) {
    setState(() {
      _draggingCardId = card.id;
      _draggingFromColumnId = columnId;
    });
  }

  void _handleDragEnd() {
    if (_draggingCardId != null &&
        _draggingFromColumnId != null &&
        _dropTargetColumnId != null) {
      final card = _findCard(_draggingCardId!);
      if (card != null) {
        widget.onCardMoved?.call(
          card,
          _draggingFromColumnId!,
          _dropTargetColumnId!,
          _dropTargetIndex ?? 0,
        );
      }
    }

    setState(() {
      _draggingCardId = null;
      _draggingFromColumnId = null;
      _dropTargetColumnId = null;
      _dropTargetIndex = null;
    });
  }

  void _handleDragUpdate(String columnId, int index) {
    setState(() {
      _dropTargetColumnId = columnId;
      _dropTargetIndex = index;
    });
  }

  KanbanCard? _findCard(String cardId) {
    for (final column in widget.columns) {
      for (final card in column.cards) {
        if (card.id == cardId) return card;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = KanbanColors.from(colorExt);

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.columns.map((column) {
          return Padding(
            padding: EdgeInsets.only(right: spacingExt.medium),
            child: _KanbanColumnWidget(
              column: column,
              width: widget.columnWidth,
              cardSize: widget.cardSize,
              colors: colors,
              showAddCard: widget.showAddCard,
              draggingCardId: _draggingCardId,
              draggingFromColumnId: _draggingFromColumnId,
              isDropTarget: _dropTargetColumnId == column.id,
              dropTargetIndex: _dropTargetColumnId == column.id
                  ? _dropTargetIndex
                  : null,
              onCardTap: widget.onCardTap,
              onAddCard: widget.onAddCard != null
                  ? () => widget.onAddCard!(column.id)
                  : null,
              onDragStart: (card) => _handleDragStart(card, column.id),
              onDragEnd: _handleDragEnd,
              onDragUpdate: (index) => _handleDragUpdate(column.id, index),
            ),
          );
        }),
        if (widget.showAddColumn)
          _AddColumnButton(
            width: widget.columnWidth,
            colors: colors,
            onPressed: widget.onAddColumn,
          ),
      ],
    );

    return Container(
      color: colors.boardBackground,
      padding: EdgeInsets.all(spacingExt.medium),
      child: widget.isScrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            )
          : content,
    );
  }
}

/// 칸반 컬럼 데이터
class KanbanColumn {
  /// 컬럼 ID
  final String id;

  /// 컬럼 제목
  final String title;

  /// 카드 목록
  final List<KanbanCard> cards;

  /// 컬럼 색상 (null이면 기본)
  final Color? color;

  /// 카드 수 제한 (null이면 무제한)
  final int? cardLimit;

  const KanbanColumn({
    required this.id,
    required this.title,
    required this.cards,
    this.color,
    this.cardLimit,
  });

  KanbanColumn copyWith({
    String? id,
    String? title,
    List<KanbanCard>? cards,
    Color? color,
    int? cardLimit,
  }) {
    return KanbanColumn(
      id: id ?? this.id,
      title: title ?? this.title,
      cards: cards ?? this.cards,
      color: color ?? this.color,
      cardLimit: cardLimit ?? this.cardLimit,
    );
  }
}

/// 칸반 카드 데이터
class KanbanCard {
  /// 카드 ID
  final String id;

  /// 카드 제목
  final String title;

  /// 카드 설명
  final String? description;

  /// 라벨들
  final List<KanbanLabel>? labels;

  /// 담당자 아바타 URL들
  final List<String>? assigneeAvatars;

  /// 마감일
  final DateTime? dueDate;

  /// 댓글 수
  final int? commentCount;

  /// 첨부파일 수
  final int? attachmentCount;

  /// 우선순위 (1: 높음, 2: 중간, 3: 낮음)
  final int? priority;

  /// 커스텀 데이터
  final Map<String, dynamic>? metadata;

  const KanbanCard({
    required this.id,
    required this.title,
    this.description,
    this.labels,
    this.assigneeAvatars,
    this.dueDate,
    this.commentCount,
    this.attachmentCount,
    this.priority,
    this.metadata,
  });
}

/// 칸반 라벨 데이터
class KanbanLabel {
  final String text;
  final Color color;

  const KanbanLabel({required this.text, required this.color});
}

/// 칸반 컬럼 위젯
class _KanbanColumnWidget extends StatelessWidget {
  final KanbanColumn column;
  final double width;
  final AppKanbanCardSize cardSize;
  final KanbanColors colors;
  final bool showAddCard;
  final String? draggingCardId;
  final String? draggingFromColumnId;
  final bool isDropTarget;
  final int? dropTargetIndex;
  final void Function(KanbanCard)? onCardTap;
  final VoidCallback? onAddCard;
  final void Function(KanbanCard) onDragStart;
  final VoidCallback onDragEnd;
  final void Function(int) onDragUpdate;

  const _KanbanColumnWidget({
    required this.column,
    required this.width,
    required this.cardSize,
    required this.colors,
    required this.showAddCard,
    this.draggingCardId,
    this.draggingFromColumnId,
    required this.isDropTarget,
    this.dropTargetIndex,
    this.onCardTap,
    this.onAddCard,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.columnBackground,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: isDropTarget
            ? Border.all(color: colors.dropIndicator, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.all(spacingExt.small),
            decoration: BoxDecoration(
              color: column.color ?? colors.columnHeaderBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(BorderTokens.radiusMedium),
                topRight: Radius.circular(BorderTokens.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    column.title,
                    style: TextStyle(
                      color: colors.columnHeaderText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacingExt.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.countBadgeBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${column.cards.length}',
                    style: TextStyle(
                      color: colors.countBadgeText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 카드 목록 - DragTarget을 Column 밖으로 분리하여 unbounded 제약 문제 해결
          Padding(
            padding: EdgeInsets.all(spacingExt.small),
            child: DragTarget<KanbanCard>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                onDragEnd();
              },
              onMove: (details) {
                // 드롭 위치 계산
                final index = _calculateDropIndex(context, details.offset);
                onDragUpdate(index);
              },
              builder: (context, candidateData, rejectedData) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...column.cards.asMap().entries.map((entry) {
                      final index = entry.key;
                      final card = entry.value;
                      final isDragging = card.id == draggingCardId;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDropTarget && dropTargetIndex == index)
                            _DropIndicator(color: colors.dropIndicator),
                          Opacity(
                            opacity: isDragging ? 0.5 : 1.0,
                            child: Draggable<KanbanCard>(
                              data: card,
                              onDragStarted: () => onDragStart(card),
                              onDragEnd: (_) => onDragEnd(),
                              feedback: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(
                                  BorderTokens.radiusMedium,
                                ),
                                child: SizedBox(
                                  width: width - spacingExt.medium * 2,
                                  child: _KanbanCardWidget(
                                    card: card,
                                    size: cardSize,
                                    colors: colors,
                                    isDragging: true,
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _KanbanCardWidget(
                                  card: card,
                                  size: cardSize,
                                  colors: colors,
                                  isDragging: false,
                                ),
                              ),
                              child: GestureDetector(
                                onTap: onCardTap != null
                                    ? () => onCardTap!(card)
                                    : null,
                                child: _KanbanCardWidget(
                                  card: card,
                                  size: cardSize,
                                  colors: colors,
                                  isDragging: false,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacingExt.small),
                        ],
                      );
                    }),
                    if (isDropTarget &&
                        (dropTargetIndex == null ||
                            dropTargetIndex! >= column.cards.length))
                      _DropIndicator(color: colors.dropIndicator),
                  ],
                );
              },
            ),
          ),
          // 카드 추가 버튼
          if (showAddCard && onAddCard != null)
            Padding(
              padding: EdgeInsets.all(spacingExt.small),
              child: _AddCardButton(colors: colors, onPressed: onAddCard!),
            ),
        ],
      ),
    );
  }

  int _calculateDropIndex(BuildContext context, Offset globalOffset) {
    // 간단한 계산: 카드 수 기반
    return column.cards.length;
  }
}

/// 칸반 카드 위젯
class _KanbanCardWidget extends StatefulWidget {
  final KanbanCard card;
  final AppKanbanCardSize size;
  final KanbanColors colors;
  final bool isDragging;

  const _KanbanCardWidget({
    required this.card,
    required this.size,
    required this.colors,
    required this.isDragging,
  });

  @override
  State<_KanbanCardWidget> createState() => _KanbanCardWidgetState();
}

class _KanbanCardWidgetState extends State<_KanbanCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    final padding = switch (widget.size) {
      AppKanbanCardSize.compact => spacingExt.small,
      AppKanbanCardSize.standard => spacingExt.medium,
      AppKanbanCardSize.detailed => spacingExt.medium,
    };

    final titleFontSize = switch (widget.size) {
      AppKanbanCardSize.compact => 13.0,
      AppKanbanCardSize.standard => 14.0,
      AppKanbanCardSize.detailed => 15.0,
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AnimationTokens.durationQuick,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: widget.isDragging
              ? widget.colors.cardBackgroundDrag
              : _isHovered
              ? widget.colors.cardBackgroundHover
              : widget.colors.cardBackground,
          borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
          border: Border.all(
            color: widget.colors.cardBorder,
            width: BorderTokens.widthThin,
          ),
          boxShadow: widget.isDragging
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 라벨
            if (widget.card.labels != null && widget.card.labels!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: spacingExt.xs),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.card.labels!.map((label) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: label.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label.text,
                        style: TextStyle(
                          color: label.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            // 제목
            Text(
              widget.card.title,
              style: TextStyle(
                color: widget.colors.cardText,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            // 설명
            if (widget.card.description != null &&
                widget.size == AppKanbanCardSize.detailed)
              Padding(
                padding: EdgeInsets.only(top: spacingExt.xs),
                child: Text(
                  widget.card.description!,
                  style: TextStyle(
                    color: widget.colors.cardDescription,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // 하단 정보
            if (_hasBottomInfo)
              Padding(
                padding: EdgeInsets.only(top: spacingExt.small),
                child: Row(
                  children: [
                    // 마감일
                    if (widget.card.dueDate != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: _getDueDateColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDueDate(widget.card.dueDate!),
                        style: TextStyle(
                          color: _getDueDateColor(),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // 댓글
                    if (widget.card.commentCount != null &&
                        widget.card.commentCount! > 0) ...[
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: widget.colors.cardDescription,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.card.commentCount}',
                        style: TextStyle(
                          color: widget.colors.cardDescription,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // 첨부파일
                    if (widget.card.attachmentCount != null &&
                        widget.card.attachmentCount! > 0) ...[
                      Icon(
                        Icons.attach_file,
                        size: 14,
                        color: widget.colors.cardDescription,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.card.attachmentCount}',
                        style: TextStyle(
                          color: widget.colors.cardDescription,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // 담당자 아바타
                    if (widget.card.assigneeAvatars != null &&
                        widget.card.assigneeAvatars!.isNotEmpty)
                      _AssigneeAvatars(
                        avatars: widget.card.assigneeAvatars!,
                        size: 24,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _hasBottomInfo {
    return widget.card.dueDate != null ||
        (widget.card.commentCount != null && widget.card.commentCount! > 0) ||
        (widget.card.attachmentCount != null &&
            widget.card.attachmentCount! > 0) ||
        (widget.card.assigneeAvatars != null &&
            widget.card.assigneeAvatars!.isNotEmpty);
  }

  Color _getDueDateColor() {
    if (widget.card.dueDate == null) return widget.colors.cardDescription;

    final now = DateTime.now();
    final due = widget.card.dueDate!;
    final diff = due.difference(now);

    if (diff.isNegative) {
      return Colors.red; // 지남
    } else if (diff.inDays <= 1) {
      return Colors.orange; // 임박
    }
    return widget.colors.cardDescription;
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.isNegative) {
      return '지연';
    } else if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '내일';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 후';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

/// 담당자 아바타 그룹
class _AssigneeAvatars extends StatelessWidget {
  final List<String> avatars;
  final double size;

  const _AssigneeAvatars({required this.avatars, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final displayAvatars = avatars.take(3).toList();
    final remaining = avatars.length - 3;

    return SizedBox(
      width: displayAvatars.length * (size - 6) + 6,
      height: size,
      child: Stack(
        children: [
          ...displayAvatars.asMap().entries.map((entry) {
            final index = entry.key;
            final url = entry.value;

            return Positioned(
              left: index * (size - 6),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                  color: Colors.grey.shade300,
                ),
                child: url.isEmpty
                    ? Icon(Icons.person, size: size - 8, color: Colors.grey)
                    : null,
              ),
            );
          }),
          if (remaining > 0)
            Positioned(
              left: displayAvatars.length * (size - 6),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade400,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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

/// 드롭 인디케이터
class _DropIndicator extends StatelessWidget {
  final Color color;

  const _DropIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// 카드 추가 버튼
class _AddCardButton extends StatefulWidget {
  final KanbanColors colors;
  final VoidCallback onPressed;

  const _AddCardButton({required this.colors, required this.onPressed});

  @override
  State<_AddCardButton> createState() => _AddCardButtonState();
}

class _AddCardButtonState extends State<_AddCardButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? widget.colors.addButtonBackground : null,
            borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 16, color: widget.colors.addButtonText),
              const SizedBox(width: 4),
              Text(
                '카드 추가',
                style: TextStyle(
                  color: widget.colors.addButtonText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 컬럼 추가 버튼
class _AddColumnButton extends StatefulWidget {
  final double width;
  final KanbanColors colors;
  final VoidCallback? onPressed;

  const _AddColumnButton({
    required this.width,
    required this.colors,
    this.onPressed,
  });

  @override
  State<_AddColumnButton> createState() => _AddColumnButtonState();
}

class _AddColumnButtonState extends State<_AddColumnButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          width: widget.width,
          padding: EdgeInsets.all(spacingExt.medium),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.colors.columnBackground
                : widget.colors.columnBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
            border: Border.all(
              color: widget.colors.cardBorder,
              width: BorderTokens.widthThin,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20, color: widget.colors.addButtonText),
              const SizedBox(width: 8),
              Text(
                '컬럼 추가',
                style: TextStyle(
                  color: widget.colors.addButtonText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
