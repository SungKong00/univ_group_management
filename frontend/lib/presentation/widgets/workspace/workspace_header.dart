import 'package:flutter/material.dart';
import '../../../core/models/page_breadcrumb.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import 'group_dropdown.dart';

/// 워크스페이스 전용 헤더 위젯
///
/// 워크스페이스 페이지의 상단 제목 영역을 담당합니다.
/// 일반 브레드크럼과 달리, 그룹 전환 드롭다운 기능을 지원합니다.
///
/// **디자인 원칙 (Toss):**
/// - Simplicity First: "워크스페이스" 제목 제거, 그룹명만 표시
/// - Easy to Answer: 현재 위치를 즉시 파악 가능
/// - Typography Hierarchy: headlineMedium (20px/600)으로 그룹명 강조
///
/// **구성:**
/// - 그룹명: headlineMedium (20px/600/neutral900) + 드롭다운 아이콘
/// - 채널명: bodyMedium (14px/400/neutral600) - 옵션
///
/// **사용 예시:**
/// ```dart
/// WorkspaceHeader(
///   breadcrumb: PageBreadcrumb(
///     title: "",  // 제목 없음 (그룹명만 표시)
///     path: ["컴퓨터공학과", "공지사항"],
///   ),
///   currentGroupId: "1",
/// )
/// ```
class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.breadcrumb,
    this.currentGroupId,
    this.onChannelActionTap,
  });

  final PageBreadcrumb breadcrumb;

  /// 현재 선택된 그룹 ID (드롭다운에 필요)
  final String? currentGroupId;

  /// 채널 액션 버튼 클릭 핸들러 (향후 구현)
  final VoidCallback? onChannelActionTap;

  @override
  Widget build(BuildContext context) {
    // Simplicity First: 제목 제거, 그룹명만 크고 굵게 표시
    return _buildHeaderRow();
  }

  /// 헤더 행 (그룹명 + 채널명)
  Widget _buildHeaderRow() {
    if (!breadcrumb.hasPath || breadcrumb.path!.isEmpty) {
      return const SizedBox.shrink();
    }

    final path = breadcrumb.path!;
    final groupName = path.first; // 첫 번째 항목이 그룹명
    final hasChannel = path.length > 1;
    final channelName = hasChannel ? path[1] : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 그룹명 섹션 (headlineMedium + 드롭다운)
        _buildGroupNameSection(groupName),

        // 채널명 (있을 경우만)
        if (hasChannel && channelName != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              '>',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral500,
                height: 1.3,
              ),
            ),
          ),
          _buildChannelNameSection(channelName),
        ],
      ],
    );
  }

  /// 그룹명 섹션 (headlineMedium + 드롭다운)
  Widget _buildGroupNameSection(String groupName) {
    // currentGroupId가 있으면 드롭다운 표시, 없으면 크고 굵은 텍스트
    if (currentGroupId != null) {
      return GroupDropdown(
        currentGroupId: currentGroupId!,
        currentGroupName: groupName,
      );
    }

    // Fallback: 드롭다운 없이 크고 굵은 텍스트만 표시
    return Text(
      groupName,
      style: AppTheme.headlineMedium.copyWith(
        color: AppColors.neutral900,
        height: 1.2,
      ),
    );
  }

  /// 채널명 섹션 (향후 액션 버튼 추가 예정)
  Widget _buildChannelNameSection(String channelName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          channelName,
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.neutral600,
            height: 1.3,
          ),
        ),
        // TODO: 채널 액션 버튼 추가
        // if (onChannelActionTap != null) ...[
        //   const SizedBox(width: 4),
        //   IconButton(
        //     icon: const Icon(Icons.settings_outlined, size: 16),
        //     onPressed: onChannelActionTap,
        //     padding: EdgeInsets.zero,
        //     constraints: const BoxConstraints(),
        //   ),
        // ],
      ],
    );
  }
}
