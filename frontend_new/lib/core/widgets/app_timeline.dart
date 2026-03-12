import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/timeline_colors.dart';
import '../theme/border_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart'
    show AppTimelineOrientation, AppTimelineItemStatus, AppTimelinePosition;

/// 타임라인 컴포넌트
///
/// **용도**: 활동 내역, 이벤트 기록, 진행 상황 표시
/// **접근성**: Semantics 지원
///
/// ```dart
/// // 기본 사용
/// AppTimeline(
///   items: [
///     AppTimelineItem(
///       title: '주문 접수',
///       timestamp: DateTime.now(),
///       status: AppTimelineItemStatus.completed,
///     ),
///     AppTimelineItem(
///       title: '배송 중',
///       status: AppTimelineItemStatus.active,
///     ),
///   ],
/// )
/// ```
class AppTimeline extends StatelessWidget {
  /// 타임라인 아이템 목록
  final List<AppTimelineItem> items;

  /// 방향
  final AppTimelineOrientation orientation;

  /// 콘텐츠 위치 (세로 타임라인 전용)
  final AppTimelinePosition position;

  /// 라인 두께
  final double lineWidth;

  /// 노드 크기
  final double nodeSize;

  const AppTimeline({
    super.key,
    required this.items,
    this.orientation = AppTimelineOrientation.vertical,
    this.position = AppTimelinePosition.right,
    this.lineWidth = 2.0,
    this.nodeSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = TimelineColors.from(colorExt);

    if (orientation == AppTimelineOrientation.horizontal) {
      return _HorizontalTimeline(
        items: items,
        colors: colors,
        colorExt: colorExt,
        lineWidth: lineWidth,
        nodeSize: nodeSize,
      );
    }

    return _VerticalTimeline(
      items: items,
      position: position,
      colors: colors,
      colorExt: colorExt,
      lineWidth: lineWidth,
      nodeSize: nodeSize,
    );
  }
}

/// 세로 타임라인
class _VerticalTimeline extends StatelessWidget {
  final List<AppTimelineItem> items;
  final AppTimelinePosition position;
  final TimelineColors colors;
  final AppColorExtension colorExt;
  final double lineWidth;
  final double nodeSize;

  const _VerticalTimeline({
    required this.items,
    required this.position,
    required this.colors,
    required this.colorExt,
    required this.lineWidth,
    required this.nodeSize,
  });

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isFirst = index == 0;
        final isLast = index == items.length - 1;

        final isLeft =
            position == AppTimelinePosition.left ||
            (position == AppTimelinePosition.alternate && index.isEven);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isLeft) ...[
              Expanded(
                child: _TimelineContent(
                  item: item,
                  colors: colors,
                  colorExt: colorExt,
                  alignment: CrossAxisAlignment.end,
                ),
              ),
              SizedBox(width: spacingExt.medium),
            ],
            _TimelineNodeSimple(
              item: item,
              colors: colors,
              colorExt: colorExt,
              lineWidth: lineWidth,
              nodeSize: nodeSize,
              isFirst: isFirst,
              isLast: isLast,
            ),
            if (isLeft) ...[
              SizedBox(width: spacingExt.medium),
              Expanded(
                child: _TimelineContent(
                  item: item,
                  colors: colors,
                  colorExt: colorExt,
                  alignment: CrossAxisAlignment.start,
                ),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }
}

/// 가로 타임라인
class _HorizontalTimeline extends StatelessWidget {
  final List<AppTimelineItem> items;
  final TimelineColors colors;
  final AppColorExtension colorExt;
  final double lineWidth;
  final double nodeSize;

  const _HorizontalTimeline({
    required this.items,
    required this.colors,
    required this.colorExt,
    required this.lineWidth,
    required this.nodeSize,
  });

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _HorizontalNode(
                    item: item,
                    colors: colors,
                    colorExt: colorExt,
                    nodeSize: nodeSize,
                  ),
                  SizedBox(height: spacingExt.small),
                  SizedBox(
                    width: 120,
                    child: _TimelineContent(
                      item: item,
                      colors: colors,
                      colorExt: colorExt,
                      alignment: CrossAxisAlignment.center,
                      compact: true,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Container(
                  width: 60,
                  height: lineWidth,
                  margin: EdgeInsets.only(top: nodeSize / 2),
                  color: colors.line,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// 타임라인 노드 (세로) - 간소화된 버전 (Expanded 없음)
class _TimelineNodeSimple extends StatelessWidget {
  final AppTimelineItem item;
  final TimelineColors colors;
  final AppColorExtension colorExt;
  final double lineWidth;
  final double nodeSize;
  final bool isFirst;
  final bool isLast;

  const _TimelineNodeSimple({
    required this.item,
    required this.colors,
    required this.colorExt,
    required this.lineWidth,
    required this.nodeSize,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final nodeColor = colors.getNodeColorForStatus(item.status, colorExt);
    final iconColor = colors.getIconColorForStatus(item.status, colorExt);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 상단 라인
        if (!isFirst)
          Container(width: lineWidth, height: 16, color: colors.line),
        // 노드
        Container(
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(
            color: nodeColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.nodeBorder,
              width: BorderTokens.widthThin,
            ),
          ),
          child: item.icon != null
              ? Icon(item.icon, size: nodeSize * 0.6, color: iconColor)
              : null,
        ),
        // 하단 라인 (고정 높이)
        if (!isLast)
          Container(width: lineWidth, height: 40, color: colors.line),
      ],
    );
  }
}

/// 가로 타임라인 노드
class _HorizontalNode extends StatelessWidget {
  final AppTimelineItem item;
  final TimelineColors colors;
  final AppColorExtension colorExt;
  final double nodeSize;

  const _HorizontalNode({
    required this.item,
    required this.colors,
    required this.colorExt,
    required this.nodeSize,
  });

  @override
  Widget build(BuildContext context) {
    final nodeColor = colors.getNodeColorForStatus(item.status, colorExt);
    final iconColor = colors.getIconColorForStatus(item.status, colorExt);

    return Container(
      width: nodeSize,
      height: nodeSize,
      decoration: BoxDecoration(
        color: nodeColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.nodeBorder,
          width: BorderTokens.widthThin,
        ),
      ),
      child: item.icon != null
          ? Icon(item.icon, size: nodeSize * 0.6, color: iconColor)
          : null,
    );
  }
}

/// 타임라인 콘텐츠
class _TimelineContent extends StatelessWidget {
  final AppTimelineItem item;
  final TimelineColors colors;
  final AppColorExtension colorExt;
  final CrossAxisAlignment alignment;
  final bool compact;

  const _TimelineContent({
    required this.item,
    required this.colors,
    required this.colorExt,
    required this.alignment,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Padding(
      padding: EdgeInsets.only(bottom: spacingExt.medium),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.contentText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: alignment == CrossAxisAlignment.center
                ? TextAlign.center
                : null,
          ),
          if (item.description != null && !compact) ...[
            SizedBox(height: spacingExt.xs),
            Text(
              item.description!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorExt.textSecondary),
              textAlign: alignment == CrossAxisAlignment.center
                  ? TextAlign.center
                  : null,
            ),
          ],
          if (item.timestamp != null) ...[
            SizedBox(height: spacingExt.xs),
            Text(
              _formatTimestamp(item.timestamp!),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.timestamp),
            ),
          ],
          if (item.content != null && !compact) ...[
            SizedBox(height: spacingExt.small),
            item.content!,
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}

/// 타임라인 아이템 데이터
class AppTimelineItem {
  /// 제목
  final String title;

  /// 설명
  final String? description;

  /// 타임스탬프
  final DateTime? timestamp;

  /// 아이콘
  final IconData? icon;

  /// 상태
  final AppTimelineItemStatus status;

  /// 추가 콘텐츠
  final Widget? content;

  const AppTimelineItem({
    required this.title,
    this.description,
    this.timestamp,
    this.icon,
    this.status = AppTimelineItemStatus.pending,
    this.content,
  });
}
