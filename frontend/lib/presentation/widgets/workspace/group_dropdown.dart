import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/group_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/my_groups_provider.dart';

/// 그룹 선택 드롭다운
///
/// 워크스페이스 헤더에서 사용되며, 사용자가 속한 모든 그룹 목록을 표시하고
/// 다른 그룹으로 워크스페이스를 전환할 수 있게 합니다.
///
/// **기능:**
/// - 현재 그룹명 + 드롭다운 아이콘 표시 (headlineMedium: 20px/600)
/// - 클릭 시 인라인으로 그룹 목록 펼침/접힘
/// - 계층 구조를 들여쓰기로 표시 (level × 16px)
/// - 현재 선택된 그룹 강조
/// - **DFS 기반 계층적 정렬**: 부모-자식 관계 유지
///
/// **정렬 알고리즘:**
/// - 부모 그룹 아래에 자식 그룹들이 바로 표시됨
/// - 같은 부모의 자식들은 id 오름차순 정렬
/// - 예: 대학 → 학부1 → 학과1-1 → 학과1-2 → 학부2 → 학과2-1
///
/// **디자인:**
/// - 토스 디자인 철학 적용 (Simplicity First, Easy to Answer)
/// - 기존 디자인 토큰 활용
class GroupDropdown extends ConsumerStatefulWidget {
  const GroupDropdown({
    super.key,
    required this.currentGroupId,
    required this.currentGroupName,
  });

  final String currentGroupId;
  final String currentGroupName;

  @override
  ConsumerState<GroupDropdown> createState() => _GroupDropdownState();
}

class _GroupDropdownState extends ConsumerState<GroupDropdown> {
  bool _isExpanded = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isExpanded) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: _buildDropdownList(),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdownList() {
    final groupsAsync = ref.watch(myGroupsProvider);

    return groupsAsync.when(
      data: (groups) => _buildGroupList(groups),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildGroupList(List<GroupMembership> groups) {
    if (groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          '소속된 그룹이 없습니다',
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.neutral600,
          ),
        ),
      );
    }

    // DFS 기반 계층적 정렬 적용
    final sortedGroups = _sortGroupsHierarchically(groups);

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral300, width: 1),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedGroups.length,
        itemBuilder: (context, index) {
          final group = sortedGroups[index];
          final isSelected = group.id.toString() == widget.currentGroupId;
          final indentLevel = group.level;

          return _buildGroupItem(
            group: group,
            isSelected: isSelected,
            indentLevel: indentLevel,
          );
        },
      ),
    );
  }

  /// DFS 기반 계층적 정렬
  ///
  /// 부모-자식 관계를 유지하며 그룹을 정렬합니다.
  /// 알고리즘:
  /// 1. 부모별 자식 맵 생성
  /// 2. 각 부모의 자식들을 id 오름차순 정렬
  /// 3. DFS 탐색으로 계층 구조 유지
  ///
  /// 예시 결과:
  /// - 한신대학교 (level 0, parent: null)
  ///   - AI/SW학부 (level 1, parent: 1)
  ///     - 컴퓨터공학과 (level 2, parent: 2)
  ///   - 다른학부 (level 1, parent: 1)
  ///     - 다른학과 (level 2, parent: 3)
  List<GroupMembership> _sortGroupsHierarchically(List<GroupMembership> groups) {
    // 1. 부모별 자식 맵 생성
    final Map<int?, List<GroupMembership>> childrenByParent = {};
    for (var group in groups) {
      childrenByParent.putIfAbsent(group.parentId, () => []).add(group);
    }

    // 2. 각 부모의 자식들을 id 오름차순 정렬
    for (var children in childrenByParent.values) {
      children.sort((a, b) => a.id.compareTo(b.id));
    }

    // 3. DFS 탐색 (루트부터)
    final List<GroupMembership> result = [];

    void dfs(int? parentId) {
      final children = childrenByParent[parentId] ?? [];
      for (var child in children) {
        result.add(child);
        dfs(child.id); // 재귀: 자식의 자식들
      }
    }

    dfs(null); // parentId가 null인 루트부터 시작
    return result;
  }

  Widget _buildGroupItem({
    required GroupMembership group,
    required bool isSelected,
    required int indentLevel,
  }) {
    return InkWell(
      onTap: () {
        if (!isSelected) {
          context.go('/workspace/${group.id}');
        }
        _toggleDropdown();
      },
      child: Container(
        height: 44,
        padding: EdgeInsets.only(
          left: 12 + (indentLevel * 16.0),
          right: 12,
          top: 8,
          bottom: 8,
        ),
        color: isSelected ? AppColors.actionTonalBg : Colors.transparent,
        child: Row(
          children: [
            // 계층 구조 표시 아이콘
            if (indentLevel > 0) ...[
              Icon(
                Icons.subdirectory_arrow_right,
                size: 16,
                color: AppColors.neutral500,
              ),
              const SizedBox(width: 8),
            ],
            // 그룹 이름
            Expanded(
              child: Text(
                group.name,
                style: AppTheme.bodyMedium.copyWith(
                  color: isSelected ? AppColors.action : AppColors.neutral700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 현재 선택된 그룹 표시
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: AppColors.action,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '그룹 목록 불러오는 중...',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        '그룹 목록을 불러올 수 없습니다',
        style: AppTheme.bodyMedium.copyWith(
          color: AppColors.error,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 그룹명: 좁은 공간에서는 bodyLarge (16px/600)으로 축소
              // 긴 그룹명 대응: Flexible로 동적 너비 조정 + 말줄임 + 툴팁
              Flexible(
                child: Tooltip(
                  message: widget.currentGroupName,
                  child: Text(
                    widget.currentGroupName,
                    style: AppTheme.titleLarge.copyWith(
                      color: AppColors.neutral900,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // 드롭다운 아이콘
              Icon(
                _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 18,
                color: AppColors.neutral600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
