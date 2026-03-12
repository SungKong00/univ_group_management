import 'package:flutter/material.dart';
import '../../../core/models/page_breadcrumb.dart';
import '../../../core/navigation/layout_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import 'group_dropdown.dart';

/// 워크스페이스 전용 헤더 위젯
///
/// 워크스페이스 페이지의 상단 제목 영역을 담당합니다.
/// 일반 브레드크럼과 달리, 그룹 전환 드롭다운 기능을 지원합니다.
///
/// **디자인 원칙 (Toss):**
/// - Explicit Title: 명시적으로 전달된 타이틀(예: "워크스페이스", "댓글")은 2단 계층 구조로 표시
/// - Simplicity First: 타이틀이 없는 경우에는 기존처럼 그룹/채널 단일 행으로 간결하게 표시
/// - Easy to Answer: 현재 위치를 즉시 파악 가능하도록 경로를 유지
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
    this.channelBarWidth,
    this.currentGroupRole,
  });

  final PageBreadcrumb breadcrumb;

  /// 현재 선택된 그룹 ID (드롭다운에 필요)
  final String? currentGroupId;

  /// 채널 액션 버튼 클릭 핸들러 (향후 구현)
  final VoidCallback? onChannelActionTap;

  /// 채널바 너비 (그룹 드롭다운 반응형 스타일 결정에 사용)
  final double? channelBarWidth;

  /// 현재 사용자의 그룹 역할명 (예: "그룹장", "교수", "멤버")
  final String? currentGroupRole;

  @override
  Widget build(BuildContext context) {
    final trimmedTitle = breadcrumb.title.trim();

    if (trimmedTitle.isNotEmpty) {
      return _buildStructuredHeader(trimmedTitle);
    }

    return _buildLegacyHeader();
  }

  /// 명시적인 타이틀이 있는 경우 (예: "워크스페이스", "댓글")
  Widget _buildStructuredHeader(String title) {
    return Builder(
      builder: (context) {
        final layoutMode = LayoutModeExtension.fromContext(context);
        final pathSegments = _resolvePathSegments(title);

        // 모바일 모드: 그룹명 > 채널명 (역할명) 표시
        if (layoutMode.isCompact) {
          return _buildLegacyHeader();
        }

        // 웹/태블릿 모드: "워크스페이스 (역할명)" 표시
        if (pathSegments.isEmpty) {
          return _buildTitleWithRole(title);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitleWithRole(title),
            const SizedBox(height: 4),
            _buildPathRow(pathSegments, useTitleStyleForGroup: false),
          ],
        );
      },
    );
  }

  /// 타이틀과 역할명을 함께 표시하는 위젯
  Widget _buildTitleWithRole(String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.neutral900,
            height: 1.2,
          ),
        ),
        if (currentGroupRole != null) ...[
          const SizedBox(width: 4),
          Text(
            '($currentGroupRole)',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.neutral600,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  /// 기존 그룹/채널 단일 행 렌더링 (명시적 타이틀 없음)
  Widget _buildLegacyHeader() {
    if (!breadcrumb.hasPath || breadcrumb.path!.isEmpty) {
      return const SizedBox.shrink();
    }

    final path = breadcrumb.path!;
    final isWorkspacePrefixed = path.first == '워크스페이스';

    final groupName = isWorkspacePrefixed
        ? (path.length > 1 ? path[1] : path.first)
        : path.first;

    final secondItem = isWorkspacePrefixed
        ? (path.length > 2 ? path[2] : null)
        : (path.length > 1 ? path[1] : null);

    if (groupName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGroupNameSection(groupName, useTitleStyle: true),
        if (currentGroupRole != null) ...[
          const SizedBox(width: 4),
          Text(
            '($currentGroupRole)',
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.neutral600,
              height: 1.2,
            ),
          ),
        ],
        if (secondItem != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              '>',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.neutral500,
                height: 1.2,
              ),
            ),
          ),
          _buildChannelNameSection(secondItem),
        ],
      ],
    );
  }

  /// 경로에서 타이틀과 중복되는 첫 항목 제거 후 세그먼트 반환
  List<String> _resolvePathSegments(String resolvedTitle) {
    if (!breadcrumb.hasPath) {
      return const [];
    }

    final segments = List<String>.from(breadcrumb.path!);
    if (segments.isNotEmpty && segments.first == resolvedTitle) {
      segments.removeAt(0);
    }

    return segments;
  }

  /// 헤더 하단 경로 렌더링 (그룹 + 채널/기능)
  Widget _buildPathRow(
    List<String> segments, {
    required bool useTitleStyleForGroup,
  }) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    final groupName = segments.first;
    final remainder = segments.length > 1
        ? segments.sublist(1)
        : const <String>[];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGroupNameSection(groupName, useTitleStyle: useTitleStyleForGroup),
        for (final segment in remainder) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              '>',
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.neutral500,
                height: 1.2,
              ),
            ),
          ),
          _buildChannelNameSection(segment),
        ],
      ],
    );
  }

  /// 그룹명 섹션 (headlineMedium + 드롭다운)
  Widget _buildGroupNameSection(
    String groupName, {
    required bool useTitleStyle,
  }) {
    if (currentGroupId != null) {
      return GroupDropdown(
        currentGroupId: currentGroupId!,
        currentGroupName: groupName,
        channelBarWidth: channelBarWidth,
      );
    }

    final textStyle = useTitleStyle
        ? AppTheme.titleLarge.copyWith(color: AppColors.neutral900, height: 1.2)
        : AppTheme.bodySmall.copyWith(color: AppColors.neutral600, height: 1.2);

    return Text(groupName, style: textStyle);
  }

  /// 채널명 섹션 (향후 액션 버튼 추가 예정)
  Widget _buildChannelNameSection(String channelName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          channelName,
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.neutral600,
            height: 1.2,
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
