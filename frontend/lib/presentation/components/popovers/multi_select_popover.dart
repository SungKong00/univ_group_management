import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../chips/compact_chip.dart';

/// 다중 선택 팝오버 컴포넌트
///
/// **용도**: 칩 형태로 여러 항목을 선택할 수 있는 드롭다운
///
/// **특징**:
/// - 제네릭 타입 지원 (역할, 그룹, 학년 등 다양한 데이터 타입)
/// - Draft-Commit 패턴 (임시 선택 → 확정)
/// - Desktop: Context Popover / Mobile: BottomSheet
/// - 외부 클릭 시 자동 닫기
/// - 선택 개수 배지 표시
///
/// **사용 예시**:
/// ```dart
/// MultiSelectPopover<GroupRole>(
///   label: '역할',
///   items: roles,
///   selectedItems: selectedRoles,
///   itemLabel: (role) => role.name,
///   onChanged: (selected) => updateRoleFilter(selected),
///   emptyLabel: '전체',
/// )
/// ```
class MultiSelectPopover<T> extends StatefulWidget {
  /// 팝오버 라벨 (예: "역할", "그룹")
  final String label;

  /// 선택 가능한 항목 목록
  final List<T> items;

  /// 현재 선택된 항목 목록
  final List<T> selectedItems;

  /// 항목 → 라벨 변환 함수
  final String Function(T) itemLabel;

  /// 선택 변경 콜백
  final void Function(List<T>) onChanged;

  /// 선택 없을 때 표시 라벨 (기본값: "전체")
  final String emptyLabel;

  const MultiSelectPopover({
    super.key,
    required this.label,
    required this.items,
    required this.selectedItems,
    required this.itemLabel,
    required this.onChanged,
    this.emptyLabel = '전체',
  });

  @override
  State<MultiSelectPopover<T>> createState() => _MultiSelectPopoverState<T>();
}

class _MultiSelectPopoverState<T> extends State<MultiSelectPopover<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  /// Draft 선택 (팝오버 내에서 임시 선택)
  late List<T> _draftSelection;

  /// Draft 선택 개수 추적 (버튼 실시간 업데이트용)
  late ValueNotifier<int> _draftCountNotifier;

  /// Overlay 내부 리빌드용 setState 콜백
  StateSetter? _overlaySetState;

  @override
  void initState() {
    super.initState();
    _draftSelection = List.from(widget.selectedItems);
    _draftCountNotifier = ValueNotifier<int>(_draftSelection.length);
  }

  @override
  void didUpdateWidget(MultiSelectPopover<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 selectedItems 변경 시 draft 동기화
    if (oldWidget.selectedItems != widget.selectedItems) {
      _draftSelection = List.from(widget.selectedItems);
    }
  }

  @override
  void dispose() {
    // dispose 시에는 setState를 호출하지 않고 overlay만 정리
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlaySetState = null;
    _draftCountNotifier.dispose();
    super.dispose();
  }

  /// 팝오버 토글
  void _togglePopover() {
    if (_isOpen) {
      _closePopover();
    } else {
      _openPopover();
    }
  }

  /// 팝오버 열기
  void _openPopover() {
    // Draft 초기화
    _draftSelection = List.from(widget.selectedItems);

    // 모바일 체크 (900px 기준)
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      _showBottomSheet();
    } else {
      _showPopover();
    }
  }

  /// Desktop Popover 표시
  void _showPopover() {
    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _commitAndClose,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            Positioned(
              width: 300,
              child: CompositedTransformFollower(
                link: _layerLink,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 8),
                child: GestureDetector(
                  onTap: () {}, // 팝오버 내부 클릭 시 닫히지 않도록
                  behavior: HitTestBehavior.opaque, // 완벽한 이벤트 차단
                  child: StatefulBuilder(
                    builder: (context, setStateInOverlay) {
                      // setState 콜백 저장
                      _overlaySetState = setStateInOverlay;
                      return _buildPopoverContent();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  /// Mobile BottomSheet 표시
  void _showBottomSheet() {
    setState(() => _isOpen = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: _buildPopoverContent()),
          ],
        ),
      ),
    ).whenComplete(() {
      setState(() => _isOpen = false);
    });
  }

  /// 팝오버 닫기
  void _closePopover() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlaySetState = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  /// Draft 확정 및 닫기
  void _commitAndClose() {
    widget.onChanged(_draftSelection);
    _closePopover();
  }

  /// 항목 토글
  void _toggleItem(T item) {
    setState(() {
      if (_draftSelection.contains(item)) {
        _draftSelection.remove(item);
      } else {
        _draftSelection.add(item);
      }
      // 버튼 실시간 업데이트
      _draftCountNotifier.value = _draftSelection.length;
    });

    // Overlay 내부도 리빌드
    _overlaySetState?.call(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: _layerLink, child: _buildButton());
  }

  /// 버튼 (닫힌 상태)
  Widget _buildButton() {
    return ValueListenableBuilder<int>(
      valueListenable: _draftCountNotifier,
      builder: (context, draftCount, child) {
        // 팝오버가 열려있으면 draft 선택을 반영, 아니면 확정된 선택 사용
        final displayCount = _isOpen ? draftCount : widget.selectedItems.length;
        final displayText = displayCount == 0
            ? '${widget.label}: ${widget.emptyLabel}'
            : '${widget.label} ($displayCount)';

        return InkWell(
          onTap: _togglePopover,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: _isOpen ? AppColors.brand : AppColors.neutral400,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayText,
                  style: AppTheme.bodyMedium.copyWith(
                    color: displayCount == 0
                        ? AppColors.neutral600
                        : AppColors.neutral900,
                    fontWeight: displayCount == 0
                        ? FontWeight.w400
                        : FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  _isOpen ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: AppColors.neutral600,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 팝오버 컨텐츠 (Desktop & Mobile 공통)
  Widget _buildPopoverContent() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppRadius.card),
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.neutral200, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            const Divider(height: 1),

            // Chip List
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: _buildChipList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 헤더 (라벨 + 배지 + 닫기 버튼)
  Widget _buildHeader() {
    final draftCount = _draftSelection.length;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Text(
            '${widget.label} 선택',
            style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (draftCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(AppComponents.badgeRadius),
              ),
              child: Text(
                '$draftCount',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: '닫기',
            onPressed: _commitAndClose,
            icon: const Icon(Icons.close, size: 20),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// 칩 리스트 (Wrap)
  Widget _buildChipList() {
    if (widget.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: Text(
            '선택 가능한 항목이 없습니다',
            style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral600),
          ),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: widget.items.map((item) {
        final isSelected = _draftSelection.contains(item);
        return CompactChip(
          label: widget.itemLabel(item),
          selected: isSelected,
          onTap: () => _toggleItem(item),
        );
      }).toList(),
    );
  }
}
